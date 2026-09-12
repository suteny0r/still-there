#include "display.h"
#include "config.h"

#if EXPANSION_BOARD && !defined(NO_OLED)
#include <Wire.h>
#include <U8g2lib.h>

static U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE);
static bool s_ok = false;
static uint32_t s_lastProbe = 0, s_lastReinit = 0;

// If a reset landed mid-transfer the SSD1306 can hold SDA low forever; clocking SCL
// releases it. Done with the pins as plain GPIO before Wire takes them.
static void i2cBusRecover() {
  pinMode(SDA, INPUT_PULLUP);
  pinMode(SCL, OUTPUT_OPEN_DRAIN);
  digitalWrite(SCL, HIGH);
  for (int i = 0; i < 9 && digitalRead(SDA) == LOW; i++) {
    digitalWrite(SCL, LOW);
    delayMicroseconds(5);
    digitalWrite(SCL, HIGH);
    delayMicroseconds(5);
  }
  pinMode(SCL, INPUT_PULLUP);
}

static bool oledPresent() {
  Wire.beginTransmission(0x3C);
  return Wire.endTransmission() == 0;
}

static void oledInit() {
  u8g2.begin();
  u8g2.setFont(u8g2_font_6x10_tf);
  s_ok = true;
  s_lastReinit = millis();
}

void displayBegin() {
  i2cBusRecover();
  Wire.begin();                      // SDA 5 / SCL 6 on the XIAO
  Wire.setTimeOut(20);
  // the panel needs ~100 ms after power before it answers; try for 1.5 s
  for (int i = 0; i < 15 && !oledPresent(); i++) delay(100);
  s_ok = oledPresent();
  Serial.printf("[turret] OLED at 0x3C: %s\n", s_ok ? "found" : "not found (will keep trying)");
  s_lastProbe = millis();
  if (s_ok) oledInit();
}

// Call periodically (from displayUpdate): re-probe a missing panel every 2 s, and re-send the
// init sequence every 15 s so a panel reset by a supply dip comes back without a reboot.
static void displayMaintain() {
  uint32_t now = millis();
  if (!s_ok) {
    if (now - s_lastProbe > 2000) {
      s_lastProbe = now;
      if (oledPresent()) {
        Serial.println("[turret] OLED came up");
        oledInit();
      }
    }
    return;
  }
  if (now - s_lastReinit > 15000) {
    s_lastReinit = now;
    if (oledPresent()) {
      u8g2.initDisplay();
      u8g2.setPowerSave(0);
    } else {
      Serial.println("[turret] OLED lost");
      s_ok = false;
      s_lastProbe = now;
    }
  }
}

void displayBoot(const char* line1, const char* line2) {
  if (!s_ok) return;
  u8g2.clearBuffer();
  u8g2.drawStr(0, 12, "turret");
  u8g2.drawStr(0, 30, line1);
  u8g2.drawStr(0, 44, line2);
  u8g2.sendBuffer();
}

void displayUpdate(Tracker& tracker, const Stats& stats, const String& netInfo) {
  displayMaintain();
  if (!s_ok) return;
  static const char* modes[] = {"MANUAL", "PERSON", "MOTION", "SCAN"};
  static const char* kinds[] = {"", "face", "torso", "motion"};
  Target t = tracker.lastTarget();
  char l[32];
  u8g2.clearBuffer();
  snprintf(l, sizeof(l), "%-7s %s%s", modes[tracker.mode() & 3], tracker.locked() ? "LOCK" : "",
           tracker.scanning() ? "SCAN" : "");
  u8g2.drawStr(0, 10, l);
  u8g2.drawStr(0, 21, netInfo.c_str());
  if (t.found)
    snprintf(l, sizeof(l), "%s %d,%d %dx%d", kinds[t.kind & 3], t.x, t.y, t.w, t.h);
  else
    snprintf(l, sizeof(l), tracker.targetFresh(millis()) ? "target coasting" : "no target");
  u8g2.drawStr(0, 32, l);
  snprintf(l, sizeof(l), "%.1f fps  det %u ms", stats.fps, (unsigned)stats.inferMs);
  u8g2.drawStr(0, 43, l);
  snprintf(l, sizeof(l), "pan %.0f  tilt %.0f %s", tracker.pan(), tracker.tilt(), tracker.laserOn() ? "FIRE" : "");
  u8g2.drawStr(0, 54, l);
  // 240x240 frame miniature with the target box, right-aligned bottom
  const int fx = 128 - 24, fy = 64 - 24, fs = 24;
  u8g2.drawFrame(fx, fy, fs, fs);
  if (t.found) {
    int bx = fx + t.x * fs / CAM_W, by = fy + t.y * fs / CAM_H;
    int bw = t.w * fs / CAM_W, bh = t.h * fs / CAM_H;
    if (bw < 2) bw = 2;
    if (bh < 2) bh = 2;
    u8g2.drawFrame(bx - bw / 2, by - bh / 2, bw, bh);
  }
  u8g2.sendBuffer();
}

void buzzerBegin() {
  pinMode(PIN_BUZZER, OUTPUT);
  digitalWrite(PIN_BUZZER, LOW);
#if ESP_ARDUINO_VERSION_MAJOR < 3
  setToneChannel(4);                 // channels 0/1 are the camera XCLK timer, 2/3 the servos
#endif
}

void buzzerBeep(uint16_t freqHz, uint16_t ms) { tone(PIN_BUZZER, freqHz, ms); }

void buzzerUpdate(Tracker& tracker) {
  static bool wasLocked = false, wasFresh = false;
  bool locked = tracker.locked();
  bool fresh = tracker.targetFresh(millis());
  if (locked && !wasLocked) buzzerBeep(2200, 120);        // lock acquired
  else if (fresh && !wasFresh) buzzerBeep(1400, 40);      // target acquired
  else if (!fresh && wasFresh) buzzerBeep(700, 80);       // target lost
  wasLocked = locked;
  wasFresh = fresh;
}

#elif EXPANSION_BOARD
// Expansion board without the OLED driver: keep the buzzer, stub the display.
void displayBegin() {}
void displayBoot(const char*, const char*) {}
void displayUpdate(Tracker&, const Stats&, const String&) {}
void buzzerBegin() {
  pinMode(PIN_BUZZER, OUTPUT);
  digitalWrite(PIN_BUZZER, LOW);
#if ESP_ARDUINO_VERSION_MAJOR < 3
  setToneChannel(4);
#endif
}
void buzzerBeep(uint16_t freqHz, uint16_t ms) { tone(PIN_BUZZER, freqHz, ms); }
void buzzerUpdate(Tracker& tracker) {
  static bool wasLocked = false, wasFresh = false;
  bool locked = tracker.locked();
  bool fresh = tracker.targetFresh(millis());
  if (locked && !wasLocked) buzzerBeep(2200, 120);
  else if (fresh && !wasFresh) buzzerBeep(1400, 40);
  else if (!fresh && wasFresh) buzzerBeep(700, 80);
  wasLocked = locked;
  wasFresh = fresh;
}
#else
void displayBegin() {}
void displayBoot(const char*, const char*) {}
void displayUpdate(Tracker&, const Stats&, const String&) {}
void buzzerBegin() {}
void buzzerBeep(uint16_t, uint16_t) {}
void buzzerUpdate(Tracker&) {}
#endif
