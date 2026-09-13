#include "tracker.h"
#include <Preferences.h>
#include <math.h>

static Preferences prefs;

void Tracker::begin() {
  pinMode(PIN_LASER, OUTPUT);
  digitalWrite(PIN_LASER, LOW);
  _panServo.attach(PIN_SERVO_PAN, LEDC_CH_PAN, PAN_MIN_DEG, PAN_MAX_DEG);
  _tiltServo.attach(PIN_SERVO_TILT, LEDC_CH_TILT, TILT_MIN_DEG, TILT_MAX_DEG);
  loadSettings();
  _pan = _panSet = PAN_CENTER_DEG;
  _tilt = _tiltSet = TILT_CENTER_DEG;
  _panServo.writeDeg(_pan + settings.panTrim);
  _tiltServo.writeDeg(_tilt + settings.tiltTrim);
  _lastMoveMs = millis();
}

float Tracker::clampPan(float v) const { return v < PAN_MIN_DEG ? PAN_MIN_DEG : (v > PAN_MAX_DEG ? PAN_MAX_DEG : v); }
float Tracker::clampTilt(float v) const { return v < TILT_MIN_DEG ? TILT_MIN_DEG : (v > TILT_MAX_DEG ? TILT_MAX_DEG : v); }

void Tracker::setMode(Mode m) {
  _mode = m;
  _locked = false;
  _onTargetSince = 0;
  _scanning = (m == MODE_SCAN);
  _lastSeenMs = 0;
  if (m == MODE_SCAN) _tiltSet = clampTilt(settings.scanTilt);
}

bool Tracker::aimPoint(int& x, int& y) const {
  if (!_last.found) return false;
  x = _last.x;
  if (_last.kind == TARGET_FACE) y = _last.y + (int)(settings.aimBelow * _last.w);
  else if (_last.kind == TARGET_PERSON) y = _last.y - _last.h / 2 + (int)(settings.aimFrac * _last.h);
  else if (_last.kind == TARGET_TORSO && torsoAimY >= 0) y = torsoAimY;
  else y = _last.y;
  return true;
}

void Tracker::onDetection(const Target& t, uint32_t nowMs) {
  _last = t;
  if (_mode != MODE_FACE && _mode != MODE_MOTION) return;

  if (t.found) {
    _lastSeenMs = nowMs;
    _scanning = false;
    int ax, ay;
    aimPoint(ax, ay);
    float exPx = (float)ax - CAM_W / 2.0f;
    float eyPx = (float)ay - CAM_H / 2.0f;
    float ex = exPx / (CAM_W / 2.0f);
    float ey = eyPx / (CAM_H / 2.0f);
    float dead = (float)settings.deadbandPx;

    // Proportional correction outside the deadband; keeps running while locked so a
    // slowly moving target is followed without dropping the lock.
    if (fabsf(exPx) > dead) {
      // Target right of center: pan toward it. Direction depends on servo mounting.
      _panSet = clampPan(_panSet + settings.kp * ex * (settings.invertPan ? -1.0f : 1.0f));
    }
    if (fabsf(eyPx) > dead) {
      // Target above center (ey < 0): tilt up. Default: larger angle = up.
      _tiltSet = clampTilt(_tiltSet + settings.kp * (-ey) * (settings.invertTilt ? -1.0f : 1.0f));
    }

    bool inside = fabsf(exPx) <= dead && fabsf(eyPx) <= dead;
    float rel = dead * (settings.lockRelease < 1.0f ? 1.0f : settings.lockRelease);
    bool outsideRelease = fabsf(exPx) > rel || fabsf(eyPx) > rel;

    if (_locked) {
      if (outsideRelease) {          // hysteresis: only a large excursion breaks the lock
        _locked = false;
        _onTargetSince = 0;
      }
    } else if (inside) {
      if (!_onTargetSince) _onTargetSince = nowMs;
      _locked = (nowMs - _onTargetSince) >= (uint32_t)settings.lockMs;
    } else {
      _onTargetSince = 0;
    }
  } else {
    _locked = false;
    _onTargetSince = 0;
    if (settings.scanWhenLost && _lastSeenMs && (nowMs - _lastSeenMs) > (uint32_t)settings.lostMs) {
      _scanning = true;
    }
    if (settings.scanWhenLost && !_lastSeenMs) {
      _scanning = true;  // never seen anything since mode change
    }
  }
}

void Tracker::tick(uint32_t nowMs) {
  float dt = _lastTickMs ? (nowMs - _lastTickMs) / 1000.0f : (1.0f / CONTROL_HZ);
  _lastTickMs = nowMs;
  if (dt > 0.2f) dt = 0.2f;

  if (_scanning && (_mode == MODE_SCAN || _mode == MODE_FACE || _mode == MODE_MOTION)) {
    _panSet += _scanDir * settings.scanSpeed * dt;
    if (_panSet >= PAN_MAX_DEG) { _panSet = PAN_MAX_DEG; _scanDir = -1; }
    if (_panSet <= PAN_MIN_DEG) { _panSet = PAN_MIN_DEG; _scanDir = 1; }
    if (_mode == MODE_SCAN) _tiltSet = clampTilt(settings.scanTilt);
  }

  auto step = [&](float cur, float set) {
    float e = (set - cur) * settings.smooth;
    if (e > settings.maxStep) e = settings.maxStep;
    if (e < -settings.maxStep) e = -settings.maxStep;
    if (fabsf(set - cur) < 0.05f) e = set - cur;
    return e;
  };
  float dp = step(_pan, _panSet);
  float dtl = step(_tilt, _tiltSet);
  _pan += dp;
  _tilt += dtl;
  _panServo.writeDeg(_pan + settings.panTrim);
  _tiltServo.writeDeg(_tilt + settings.tiltTrim);

  _moving = (fabsf(dp) > 0.08f) || (fabsf(dtl) > 0.08f);
  if (_moving) _lastMoveMs = nowMs;

  applyLaser();
}

void Tracker::applyLaser() {
  bool on = _laserManual || (settings.autoFire && _locked && (_mode == MODE_FACE || _mode == MODE_MOTION));
  if (on != _laserOut) {
    _laserOut = on;
    digitalWrite(PIN_LASER, on ? HIGH : LOW);
  }
}

void Tracker::setAbsolute(float pan, float tilt) {
  _panSet = clampPan(pan);
  _tiltSet = clampTilt(tilt);
}

void Tracker::nudge(float dPan, float dTilt) {
  _panSet = clampPan(_panSet + dPan);
  _tiltSet = clampTilt(_tiltSet + dTilt);
}

void Tracker::center() {
  _panSet = PAN_CENTER_DEG;
  _tiltSet = TILT_CENTER_DEG;
}

void Tracker::aimAtPixel(int px, int py) {
  float ex = ((float)px - CAM_W / 2.0f) / (CAM_W / 2.0f);
  float ey = ((float)py - CAM_H / 2.0f) / (CAM_H / 2.0f);
  _panSet = clampPan(_panSet + settings.kp * ex * (settings.invertPan ? -1.0f : 1.0f));
  _tiltSet = clampTilt(_tiltSet + settings.kp * (-ey) * (settings.invertTilt ? -1.0f : 1.0f));
}

void Tracker::loadSettings() {
  Settings d;
  prefs.begin("turret", false);   // read-write so the namespace is created on first boot
  settings.kp = prefs.getFloat("kp", d.kp);
  settings.smooth = prefs.getFloat("smooth", d.smooth);
  settings.maxStep = prefs.getFloat("maxstep", d.maxStep);
  settings.deadbandPx = prefs.getInt("dead", d.deadbandPx);
  settings.invertPan = prefs.getBool("invpan", d.invertPan);
  settings.invertTilt = prefs.getBool("invtilt", d.invertTilt);
  settings.settleMs = prefs.getInt("settle", d.settleMs);
  settings.lostMs = prefs.getInt("lost", d.lostMs);
  settings.scanWhenLost = prefs.getBool("scan", d.scanWhenLost);
  settings.scanSpeed = prefs.getFloat("scanspd", d.scanSpeed);
  settings.scanTilt = prefs.getFloat("scantilt", d.scanTilt);
  settings.lockMs = prefs.getInt("lockms", d.lockMs);
  settings.lockRelease = prefs.getFloat("lockrel", d.lockRelease);
  settings.aimBelow = prefs.getFloat("aimbelow", d.aimBelow);
  settings.torsoTrack = prefs.getBool("torso", d.torsoTrack);
  settings.aimFrac = prefs.getFloat("aimfrac", d.aimFrac);
  settings.personThr = prefs.getFloat("personthr", d.personThr);
  settings.redetectMs = prefs.getInt("redetect", d.redetectMs);
  settings.torsoMinConf = prefs.getFloat("torsoconf", d.torsoMinConf);
  settings.faceTimeoutMs = prefs.getInt("facetmo", d.faceTimeoutMs);
  settings.autoFire = prefs.getBool("autofire", d.autoFire);
  settings.motionThr = prefs.getInt("mthr", d.motionThr);
  settings.motionMinCells = prefs.getInt("mmin", d.motionMinCells);
  settings.jpegQuality = prefs.getInt("quality", d.jpegQuality);
  settings.hmirror = prefs.getBool("hmirror", d.hmirror);
  settings.vflip = prefs.getBool("vflip", d.vflip);
  settings.panTrim = prefs.getFloat("pantrim", d.panTrim);
  settings.tiltTrim = prefs.getFloat("tilttrim", d.tiltTrim);
  settings.bootMode = prefs.getInt("bootmode", d.bootMode);
  bool firstBoot = !prefs.isKey("kp");
  prefs.end();
  if (firstBoot) saveSettings(false);   // write defaults once; keep bootMode = Person, not the not-yet-set mode
}

void Tracker::saveSettings(bool storeCurrentMode) {
  prefs.begin("turret", false);
  prefs.putFloat("kp", settings.kp);
  prefs.putFloat("smooth", settings.smooth);
  prefs.putFloat("maxstep", settings.maxStep);
  prefs.putInt("dead", settings.deadbandPx);
  prefs.putBool("invpan", settings.invertPan);
  prefs.putBool("invtilt", settings.invertTilt);
  prefs.putInt("settle", settings.settleMs);
  prefs.putInt("lost", settings.lostMs);
  prefs.putBool("scan", settings.scanWhenLost);
  prefs.putFloat("scanspd", settings.scanSpeed);
  prefs.putFloat("scantilt", settings.scanTilt);
  prefs.putInt("lockms", settings.lockMs);
  prefs.putFloat("lockrel", settings.lockRelease);
  prefs.putFloat("aimbelow", settings.aimBelow);
  prefs.putBool("torso", settings.torsoTrack);
  prefs.putFloat("aimfrac", settings.aimFrac);
  prefs.putFloat("personthr", settings.personThr);
  prefs.putInt("redetect", settings.redetectMs);
  prefs.putFloat("torsoconf", settings.torsoMinConf);
  prefs.putInt("facetmo", settings.faceTimeoutMs);
  prefs.putBool("autofire", settings.autoFire);
  prefs.putInt("mthr", settings.motionThr);
  prefs.putInt("mmin", settings.motionMinCells);
  prefs.putInt("quality", settings.jpegQuality);
  prefs.putBool("hmirror", settings.hmirror);
  prefs.putBool("vflip", settings.vflip);
  prefs.putFloat("pantrim", settings.panTrim);
  prefs.putFloat("tilttrim", settings.tiltTrim);
  if (storeCurrentMode) settings.bootMode = (int)_mode;   // whatever mode is active when you press Save
  prefs.putInt("bootmode", settings.bootMode);
  prefs.end();
}
