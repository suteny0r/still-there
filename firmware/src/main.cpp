// Tracking turret: Seeed Studio XIAO ESP32S3 Sense + 2x SG90/MG90S pan-tilt.
//
// Tasks:
//   detectorTask (core 1): grab RGB565 240x240 frame -> face (esp-dl) or motion
//                          detection -> feed tracker -> draw overlay -> JPEG -> FrameStore
//   controlTask  (core 1): 50 Hz servo slew / scan / laser
//   httpd (core 0):        :80 UI + JSON + control, :81 MJPEG stream
//   loop():                status LED, trigger button

#include <Arduino.h>
#include <WiFi.h>
#include <ESPmDNS.h>
#include "esp_system.h"
#include "esp_log.h"
#include "esp_camera.h"
#include "img_converters.h"
#if defined(__has_include)
#if __has_include("fb_gfx.h")
#include "fb_gfx.h"
#define HAVE_FB_GFX 1
#endif
#endif
#ifndef HAVE_FB_GFX
#define HAVE_FB_GFX 0
// Minimal stand-in so the overlay compiles without the fb_gfx component: same field names,
// RGB565 only, 0x00BBGGRR color like fb_gfx, no text.
typedef enum { FB_RGB888, FB_BGR888, FB_RGB565, FB_BGR565, FB_GRAY } fb_format_t;
typedef struct { int width; int height; int bytes_per_pixel; fb_format_t format; uint8_t* data; } fb_data_t;
static inline void fbPix(fb_data_t* g, int x, int y, uint32_t c) {
  uint8_t r = c & 0xFF, gr = (c >> 8) & 0xFF, b = (c >> 16) & 0xFF;
  uint16_t v = ((r >> 3) << 11) | ((gr >> 2) << 5) | (b >> 3);
  uint8_t* p = g->data + (y * g->width + x) * 2;
  p[0] = v >> 8; p[1] = v & 0xFF;
}
static void fb_gfx_drawFastHLine(fb_data_t* g, int32_t x, int32_t y, int32_t w, uint32_t c) { for (int i = 0; i < w; i++) fbPix(g, x + i, y, c); }
static void fb_gfx_drawFastVLine(fb_data_t* g, int32_t x, int32_t y, int32_t h, uint32_t c) { for (int i = 0; i < h; i++) fbPix(g, x, y + i, c); }
static void fb_gfx_fillRect(fb_data_t* g, int32_t x, int32_t y, int32_t w, int32_t h, uint32_t c) { for (int j = 0; j < h; j++) fb_gfx_drawFastHLine(g, x, y + j, w, c); }
static uint32_t fb_gfx_print(fb_data_t*, int32_t, int32_t, uint32_t, const char*) { return 0; }
#endif
#include "config.h"
#include "camera_pins.h"
#include "detector.h"
#include "color_tracker.h"
#include "tracker.h"
#include "frame_store.h"
#include "web.h"
#include "display.h"

static Detector detector;
static ColorTracker torso;
static Tracker tracker;
static Target lastFace;          // most recent face detection, for the overlay
static FrameStore frames;
static Stats stats;
static bool apMode = false;
static String netInfo;

#define COLOR_WHITE  0x00FFFFFF
#define COLOR_RED    0x000000FF
#define COLOR_GREEN  0x0000FF00
#define COLOR_YELLOW 0x0000FFFF
#define COLOR_CYAN   0x00FFFF00
#define COLOR_MAGENTA 0x00FF00FF

// IDF-component log sink. The esp32-camera driver task (cam_task) runs on a 2 KB stack in
// this SDK build. Its "EV-VSYNC-OVF" message is routed by the esp_diagnostics log wrappers
// into esp_log_writev -> vprintf -> stdio -> newlib lock creation, which overflowed that
// stack (panic observed and decoded from the backtrace). esp_log_level_set() does not stop
// it, so the IDF log vprintf is replaced with a no-op. The short "cam_hal: EV-VSYNC-OVF"
// line still appears on the console via the ROM printf path; that one is harmless.
// Everything this firmware prints itself goes through Serial and is unaffected.
static int idfLogSink(const char*, va_list) { return 0; }

static bool cameraInit() {
  esp_log_set_vprintf(idfLogSink);

  camera_config_t c = {};
  c.ledc_channel = LEDC_CHANNEL_0;
  c.ledc_timer = LEDC_TIMER_0;
  c.pin_d0 = Y2_GPIO_NUM;
  c.pin_d1 = Y3_GPIO_NUM;
  c.pin_d2 = Y4_GPIO_NUM;
  c.pin_d3 = Y5_GPIO_NUM;
  c.pin_d4 = Y6_GPIO_NUM;
  c.pin_d5 = Y7_GPIO_NUM;
  c.pin_d6 = Y8_GPIO_NUM;
  c.pin_d7 = Y9_GPIO_NUM;
  c.pin_xclk = XCLK_GPIO_NUM;
  c.pin_pclk = PCLK_GPIO_NUM;
  c.pin_vsync = VSYNC_GPIO_NUM;
  c.pin_href = HREF_GPIO_NUM;
  c.pin_sccb_sda = SIOD_GPIO_NUM;
  c.pin_sccb_scl = SIOC_GPIO_NUM;
  c.pin_pwdn = PWDN_GPIO_NUM;
  c.pin_reset = RESET_GPIO_NUM;
  c.xclk_freq_hz = CAM_XCLK_HZ;
  c.pixel_format = PIXFORMAT_RGB565;   // raw pixels for esp-dl and motion detection
  c.frame_size = CAM_FRAMESIZE;
  c.jpeg_quality = 12;
  c.fb_count = 3;                      // one held by the detector, two for the driver to cycle
  c.fb_location = CAMERA_FB_IN_PSRAM;
  c.grab_mode = CAMERA_GRAB_LATEST;

  esp_err_t err = esp_camera_init(&c);
  if (err != ESP_OK) {
    Serial.printf("camera init failed 0x%x\n", err);
    return false;
  }
  sensor_t* s = esp_camera_sensor_get();
  if (s) {
    s->set_framesize(s, CAM_FRAMESIZE);
    s->set_hmirror(s, tracker.settings.hmirror ? 1 : 0);
    s->set_vflip(s, tracker.settings.vflip ? 1 : 0);
    s->set_brightness(s, 0);
    s->set_saturation(s, 0);
  }
  return true;
}

// fb_gfx has no bounds checking: a negative or oversized coordinate writes outside the
// frame buffer and corrupts the heap (observed: StoreProhibited in tlsf_malloc after a face
// near the top edge). Everything drawn on the frame goes through these clipped helpers.
static inline void gfxH(fb_data_t* g, int x, int y, int w, uint32_t c) {
  if (y < 0 || y >= g->height) return;
  if (x < 0) { w += x; x = 0; }
  if (x + w > g->width) w = g->width - x;
  if (w > 0) fb_gfx_drawFastHLine(g, x, y, w, c);
}
static inline void gfxV(fb_data_t* g, int x, int y, int h, uint32_t c) {
  if (x < 0 || x >= g->width) return;
  if (h < 0) { y += h; h = -h; }
  if (y < 0) { h += y; y = 0; }
  if (y + h > g->height) h = g->height - y;
  if (h > 0) fb_gfx_drawFastVLine(g, x, y, h, c);
}
static inline void gfxFill(fb_data_t* g, int x, int y, int w, int h, uint32_t c) {
  if (x < 0) { w += x; x = 0; }
  if (y < 0) { h += y; y = 0; }
  if (x + w > g->width) w = g->width - x;
  if (y + h > g->height) h = g->height - y;
  if (w > 0 && h > 0) fb_gfx_fillRect(g, x, y, w, h, c);
}
// fb_gfx text is FreeMonoBold 12pt: 14 px advance per character, glyphs drawn downward from
// y over up to 24 rows. Refuse anything that would leave the frame.
static inline void gfxText(fb_data_t* g, int x, int y, uint32_t c, const char* s) {
  int w = 14 * (int)strlen(s);
  if (x < 0 || y < 0 || x + w > g->width || y + 24 > g->height) return;
  fb_gfx_print(g, x, y, c, s);
}
static inline void gfxBox(fb_data_t* g, int cx, int cy, int w, int h, uint32_t c) {
  int x = cx - w / 2, y = cy - h / 2;
  gfxH(g, x, y, w, c);
  gfxH(g, x, y + h - 1, w, c);
  gfxV(g, x, y, h, c);
  gfxV(g, x + w - 1, y, h, c);
}

static void drawOverlay(camera_fb_t* fb, const Target& t) {
  fb_data_t g;
  g.width = fb->width;
  g.height = fb->height;
  g.data = fb->buf;
  g.bytes_per_pixel = 2;
  g.format = FB_RGB565;

  // crosshair + deadband
  int cx = fb->width / 2, cy = fb->height / 2;
  gfxH(&g, cx - 10, cy, 21, COLOR_WHITE);
  gfxV(&g, cx, cy - 10, 21, COLOR_WHITE);
  int db = tracker.settings.deadbandPx;
  if (db > 0) gfxBox(&g, cx, cy, 2 * db, 2 * db, COLOR_WHITE);

  // last detected face stays on screen (green) while the torso tracker carries the target
  if (t.found && t.kind == TARGET_TORSO && lastFace.found) {
    gfxBox(&g, lastFace.x, lastFace.y, lastFace.w, lastFace.h, COLOR_GREEN);
    char s[24];
    snprintf(s, sizeof(s), "%s %lums", lastFace.kind == TARGET_PERSON ? "body" : "face",
             (unsigned long)(millis() - tracker.lastFaceMs));
    gfxText(&g, 4, 30, COLOR_GREEN, s);              // second text row, below SCAN
  }
  if (t.found) {
    uint32_t color = tracker.locked() ? COLOR_RED
                     : (t.kind == TARGET_FACE ? COLOR_GREEN
                        : (t.kind == TARGET_PERSON ? COLOR_MAGENTA
                           : (t.kind == TARGET_TORSO ? COLOR_CYAN : COLOR_YELLOW)));
    gfxBox(&g, t.x, t.y, t.w, t.h, color);
    gfxFill(&g, t.x - 2, t.y - 2, 5, 5, color);
    int ax, ay;
    if (tracker.aimPoint(ax, ay) && ay != t.y) {
      gfxH(&g, ax - 6, ay, 13, color);                // aim point (offset from the face center)
      gfxV(&g, ax, ay - 6, 13, color);
      gfxV(&g, t.x, t.y, ay - t.y, color);            // tether to the face center
    }
  }
  if (tracker.scanning()) gfxText(&g, 4, 4, COLOR_YELLOW, "SCAN");
  if (tracker.locked()) gfxText(&g, fb->width - 14 * 4 - 4, 4, COLOR_RED, "LOCK");
}

// Person mode: the face detector acquires (and periodically re-anchors) the target, the
// color tracker follows the torso in between, so the person can turn or walk sideways.
static Target personPipeline(camera_fb_t* fb, uint32_t now) {
  static uint32_t lastFaceRun = 0;
  const Settings& s = tracker.settings;
  torso.minConfidence = s.torsoMinConf;

  if (!s.torsoTrack) {
    torso.reset();
#if HAVE_ESPDET
    Target f = personDetect(fb, s.personThr);
#else
    Target f = detector.detectFace(fb);
#endif
    lastFace = f;
    return f;
  }

  bool runFace = !torso.active() || (now - lastFaceRun) >= (uint32_t)s.redetectMs;
  Target face;
  if (runFace) {
#if HAVE_ESPDET
    face = personDetect(fb, s.personThr);       // whole-body box; "face" name kept for the flow below
#else
    face = detector.detectFace(fb);
#endif
    lastFaceRun = now;
  }

  if (face.found) {
    lastFace = face;
    tracker.lastFaceMs = now;
    int tw, th, tcx, tcy;
    float aimY;
    if (face.kind == TARGET_PERSON) {
      // Body box: seed the color tracker on the upper torso (below the head, above the waist).
      int top = face.y - face.h / 2;
      tw = (int)(face.w * 0.8f);
      th = (int)(face.h * 0.35f);
      tcx = face.x;
      tcy = top + (int)(face.h * 0.20f) + th / 2;
      aimY = top + s.aimFrac * face.h;
    } else {
      // Face box: torso 1.6 face widths wide, 1.4 face heights tall, starting half a face below the chin.
      tw = (int)(face.w * 1.6f);
      th = (int)(face.h * 1.4f);
      tcx = face.x;
      tcy = face.y + face.h + th / 2;
      aimY = face.y + s.aimBelow * face.w;
    }
    if (tcy + th / 2 > fb->height) tcy = fb->height - th / 2;
    if (tcy - th / 2 < 0) tcy = th / 2;
    // Aim point relative to the torso center, in torso heights, so it rides along with the blob.
    float aimRel = th > 0 ? (aimY - tcy) / (float)th : 0;
    if (th >= 8 && tw >= 8) torso.refresh(fb, tcx, tcy, tw, th, aimRel, torso.active() ? 0.3f : 1.0f);
    tracker.torsoAimY = -1;
    return face;
  }

  Target t;
  // A color track that no face has confirmed for faceTimeoutMs is more likely background
  // than a person who turned away; drop it and wait for the next face.
  if (torso.active() && tracker.lastFaceMs && (now - tracker.lastFaceMs) > (uint32_t)s.faceTimeoutMs) {
    torso.reset();
    lastFace = Target();
    tracker.lastFaceMs = 0;
    tracker.torsoAimY = -1;
    return t;
  }
  if (torso.active() && torso.track(fb, t)) {
    tracker.torsoAimY = torso.aimY();
    return t;
  }
  tracker.torsoAimY = -1;
  if (!tracker.targetFresh(now)) {
    torso.reset();            // give up after lostMs; the next face starts a new track
    lastFace = Target();
    tracker.lastFaceMs = 0;
  }
  return t;
}

static void detectorTask(void*) {
  uint32_t fpsWindowStart = millis();
  int fpsFrames = 0;
  Mode prevMode = tracker.mode();

  // Work on a private copy of each frame and hand the driver's buffer back immediately
  // (a 115 KB PSRAM memcpy, ~2 ms). Detection can then take as long as it likes without
  // starving the camera DMA, which is what triggered the driver's overflow path.
  // Guard bands around the work frame: an overlay slip lands in unused PSRAM, not a heap header.
  const size_t GUARD = 8192;
  camera_fb_t work = {};
  uint8_t* raw_buf = (uint8_t*)ps_malloc(CAM_W * CAM_H * 2 + 2 * GUARD);
  work.buf = raw_buf ? raw_buf + GUARD : nullptr;
  if (!work.buf) {
    Serial.println("[turret] no PSRAM for the work frame");
    vTaskDelete(nullptr);
    return;
  }

  for (;;) {
    camera_fb_t* raw = esp_camera_fb_get();
    if (!raw) {
      vTaskDelay(pdMS_TO_TICKS(10));
      continue;
    }
    uint32_t t0 = millis();
    if (raw->format != PIXFORMAT_RGB565 || raw->len > (size_t)(CAM_W * CAM_H * 2)) {
      esp_camera_fb_return(raw);
      continue;
    }
    memcpy(work.buf, raw->buf, raw->len);
    work.len = raw->len;
    work.width = raw->width;
    work.height = raw->height;
    work.format = raw->format;
    work.timestamp = raw->timestamp;
    esp_camera_fb_return(raw);
    camera_fb_t* fb = &work;
    Mode mode = tracker.mode();
    if (mode != prevMode) {
      detector.resetMotion();
      torso.reset();
      lastFace = Target();
      tracker.lastFaceMs = 0;
      prevMode = mode;
    }

    Target t;
    if (mode == MODE_FACE) {
      t = personPipeline(fb, t0);
    } else if (mode == MODE_MOTION) {
      bool suppress = tracker.moving() || tracker.msSinceMove(t0) < (uint32_t)tracker.settings.settleMs;
      t = detector.detectMotion(fb, suppress, tracker.settings.motionThr, tracker.settings.motionMinCells);
    }
    stats.inferMs = millis() - t0;
    if (mode == MODE_FACE || mode == MODE_MOTION) tracker.onDetection(t, millis());

    drawOverlay(fb, t);

    uint8_t* jpg = nullptr;
    size_t len = 0;
    if (frame2jpg(fb, tracker.settings.jpegQuality, &jpg, &len)) {
      frames.publish(jpg, len);
    }

    fpsFrames++;
    uint32_t now = millis();
    if (now - fpsWindowStart >= 1000) {
      stats.fps = fpsFrames * 1000.0f / (now - fpsWindowStart);
      fpsFrames = 0;
      fpsWindowStart = now;
    }
    stats.frameMs = now - t0;
    if (mode == MODE_MANUAL || mode == MODE_SCAN) vTaskDelay(pdMS_TO_TICKS(40));  // cap ~20 fps
    else taskYIELD();
  }
}

static void controlTask(void*) {
  TickType_t last = xTaskGetTickCount();
  const TickType_t period = pdMS_TO_TICKS(1000 / CONTROL_HZ);
  for (;;) {
    vTaskDelayUntil(&last, period);
    tracker.tick(millis());
  }
}

static void wifiBegin() {
  WiFi.persistent(false);
  if (strlen(WIFI_SSID) > 0) {
    WiFi.mode(WIFI_STA);
    WiFi.setHostname(HOSTNAME);
    WiFi.setSleep(false);
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    Serial.printf("WiFi: connecting to %s", WIFI_SSID);
    uint32_t t0 = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t0 < WIFI_CONNECT_MS) {
      digitalWrite(PIN_STATUS_LED, (millis() / 100) & 1);
      delay(50);
      if ((millis() / 500) % 2 == 0) Serial.print('.');
    }
    Serial.println();
  }
  if (WiFi.status() != WL_CONNECTED) {
    apMode = true;
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASS);
    Serial.printf("WiFi: AP mode  ssid=%s pass=%s  http://%s/\n", AP_SSID, AP_PASS,
                  WiFi.softAPIP().toString().c_str());
    netInfo = String("AP ") + AP_SSID + " " + WiFi.softAPIP().toString();
  } else {
    Serial.printf("WiFi: connected  http://%s/  (http://%s.local/)\n", WiFi.localIP().toString().c_str(), HOSTNAME);
    netInfo = WiFi.localIP().toString();
  }
  if (MDNS.begin(HOSTNAME)) {
    MDNS.addService("http", "tcp", 80);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, HIGH);  // off (active low)
  pinMode(PIN_TRIGGER_BTN, INPUT_PULLUP);
  delay(300);
  Serial.printf("\n[turret] XIAO ESP32S3 Sense tracking turret  (reset reason %d)\n", (int)esp_reset_reason());
  Serial.printf("[turret] psram %u bytes, detector: %s\n", (unsigned)ESP.getPsramSize(),
                HAVE_ESPDET ? "ESPDet-Pico person (esp-dl 3.x)" : (HAVE_ESP_DL ? "esp-dl 1.x face" : "none"));

  displayBegin();
  buzzerBegin();
  displayBoot("booting", "camera + wifi");
  tracker.begin();           // servos to center, settings from NVS
  if (!cameraInit()) {
    // Keep going: manual/scan still work without a camera, web UI shows no stream.
    Serial.println("[turret] camera unavailable");
  }
  detector.begin();
  if (HAVE_ESPDET) Serial.printf("[turret] ESPDet-Pico person detector %s\n", personDetectBegin() ? "loaded" : "FAILED");
  frames.begin();
  wifiBegin();
  webBegin(&tracker, &frames, &stats);

  displayBoot("ready", netInfo.c_str());
  buzzerBeep(1000, 60);
  xTaskCreatePinnedToCore(controlTask, "control", 4096, nullptr, 3, nullptr, 1);
  xTaskCreatePinnedToCore(detectorTask, "detect", 16384, nullptr, 1, nullptr, 1);
  Serial.println("[turret] ready");
}

void loop() {
  static uint32_t lastBtn = 0;
  static bool btnWas = false;
  uint32_t now = millis();

  // Trigger button toggles the laser (debounced).
  bool btn = digitalRead(PIN_TRIGGER_BTN) == LOW;
  if (btn && !btnWas && now - lastBtn > 250) {
    tracker.setLaser(!tracker.laserOn());
    lastBtn = now;
  }
  btnWas = btn;

  // Status LED (active low): AP mode slow blink, locked solid, tracking short blink, else off.
  bool on;
  if (tracker.locked()) on = true;
  else if (apMode) on = (now % 2000) < 100;
  else if (tracker.targetFresh(now)) on = (now % 500) < 60;
  else on = false;
  digitalWrite(PIN_STATUS_LED, on ? LOW : HIGH);

  buzzerUpdate(tracker);
  static uint32_t lastDisp = 0;
  if (now - lastDisp > 250) {
    lastDisp = now;
    displayUpdate(tracker, stats, netInfo);
  }

  static uint32_t lastLog = 0;
  if (now - lastLog > 5000) {
    lastLog = now;
    Target t = tracker.lastTarget();
    Serial.printf("[turret] up=%us mode=%d pan=%.1f tilt=%.1f target=%s(%d,%d) fps=%.1f infer=%ums heap=%u\n",
                  (unsigned)(now / 1000), (int)tracker.mode(), tracker.pan(), tracker.tilt(), t.found ? "yes" : "no",
                  t.x, t.y, stats.fps, (unsigned)stats.inferMs, (unsigned)ESP.getFreeHeap());
  }
  delay(20);
}
