#pragma once
#include <Arduino.h>
#include "config.h"
#include "servo_ctl.h"
#include "detector.h"

enum Mode : uint8_t { MODE_MANUAL = 0, MODE_FACE = 1, MODE_MOTION = 2, MODE_SCAN = 3 };

struct Settings {
  float kp = 18.0f;          // degrees of servo per unit of normalized error (-1..1)
  float smooth = 0.35f;      // fraction of remaining error applied per control tick
  float maxStep = 3.0f;      // max degrees per control tick (50 Hz -> 150 deg/s)
  int deadbandPx = 12;       // no correction inside this radius from frame center
  bool invertPan = false;
  bool invertTilt = false;
  int settleMs = 350;        // ignore motion for this long after the servos move
  int lostMs = 2500;         // target lost after this long without a detection
  bool scanWhenLost = true;  // sweep pan when target lost (tracking modes)
  float scanSpeed = 25.0f;   // deg/s
  float scanTilt = 90.0f;
  int lockMs = 600;          // on target this long -> locked
  float lockRelease = 3.0f;  // lock is kept until the error exceeds deadband * lockRelease
  float aimBelow = 2.3f;     // person mode: aim this many face-widths below the face center
                             // (2.3 = chest for a boresighted laser at any range; 0 = the face)
  float aimFrac = 0.25f;     // person (body) detector: aim this fraction down the body box (0.25 = chest)
  float personThr = 0.5f;    // person detector score threshold
  bool torsoTrack = true;    // person mode: after a face is found, follow the torso by color
  int redetectMs = 300;      // person mode: re-run the face detector this often while tracking
                             // (12-40 ms per run, so a few frames apart is affordable)
  float torsoMinConf = 0.12f;// color tracker confidence below which the torso is "not seen"
  int faceTimeoutMs = 8000;  // drop a torso track that has not been re-confirmed by a face this long
  bool autoFire = false;     // laser follows lock state
  int motionThr = 22;        // per-cell luma delta
  int motionMinCells = 3;
  int jpegQuality = 80;
  bool hmirror = false;
  bool vflip = false;
  float panTrim = 0, tiltTrim = 0;
  int bootMode = 1;          // mode entered at power-up (1 = Person); Save stores the current mode
};

class Tracker {
 public:
  void begin();
  void setMode(Mode m);
  Mode mode() const { return _mode; }

  // Called from the detector task after each frame.
  void onDetection(const Target& t, uint32_t nowMs);

  // Called at CONTROL_HZ.
  void tick(uint32_t nowMs);

  // Manual control.
  void setAbsolute(float pan, float tilt);
  void nudge(float dPan, float dTilt);
  void center();
  void aimAtPixel(int px, int py);   // one proportional step toward a pixel (manual mode)

  void setLaser(bool on) { _laserManual = on; }
  bool laserOn() const { return _laserOut; }
  bool locked() const { return _locked; }
  bool scanning() const { return _scanning; }
  bool targetFresh(uint32_t nowMs) const { return _lastSeenMs && (nowMs - _lastSeenMs) < (uint32_t)settings.lostMs; }
  uint32_t msSinceMove(uint32_t nowMs) const { return nowMs - _lastMoveMs; }
  bool moving() const { return _moving; }

  float pan() const { return _pan; }
  float tilt() const { return _tilt; }
  float panSet() const { return _panSet; }
  float tiltSet() const { return _tiltSet; }
  Target lastTarget() const { return _last; }
  bool aimPoint(int& x, int& y) const;   // current aim point in the frame (false if none)
  int torsoAimY = -1;                     // set by the detector task for torso targets
  uint32_t lastFaceMs = 0;                // millis() of the last face detection (0 = none)

  Settings settings;
  void loadSettings();
  void saveSettings(bool storeCurrentMode = true);   // false: keep bootMode as loaded (first-boot defaults)

 private:
  void applyLaser();
  float clampPan(float v) const;
  float clampTilt(float v) const;

  ServoOut _panServo, _tiltServo;
  Mode _mode = MODE_MANUAL;
  float _pan = PAN_CENTER_DEG, _tilt = TILT_CENTER_DEG;
  float _panSet = PAN_CENTER_DEG, _tiltSet = TILT_CENTER_DEG;
  uint32_t _lastSeenMs = 0, _lastMoveMs = 0, _onTargetSince = 0, _lastTickMs = 0;
  bool _locked = false, _scanning = false, _moving = false;
  int _scanDir = 1;
  bool _laserManual = false, _laserOut = false;
  Target _last;
};
