# Handoff — still-there evaluation (2026-09-22)

## Objective
- Evaluate the codebase at `F:\still-there` — a face-tracking pan/tilt turret firmware + hardware project (architecture, code quality, potential issues, build health) and produce a final evaluation report

## Important Details
- PlatformIO project targeting Seeed Studio XIAO ESP32S3 Sense (OV2640 camera, 8 MB PSRAM, qio_opi)
- espressif32 6.13.0 / Arduino core 2.0.17; **default env `xiao_esp32s3_sense`**
- Three build envs: `xiao_esp32s3_sense`, `xiao_expansion` (SSD1306 + buzzer), ESPDet-Pico (pioarduino / Arduino 3.3.x / IDF 5.5)
- `lib_ignore = espdl, pedestrian_detect` in base — vendored esp-dl 3.x libs excluded from default and expansion envs
- Build flags: `-DFACE_TWO_STAGE=1`, `-DCAMERA_MODEL_XIAO_ESP32S3`, `-DBOARD_HAS_PSRAM`
- Architecture: `detectorTask` (core 1, 240x240 RGB565 -> detect -> tracker -> overlay -> JPEG -> FrameStore), `controlTask` (core 1, 50 Hz servo slew/scan/laser), `httpd` (core 0, :80 UI+JSON, :81 MJPEG), `loop()` (status LED, trigger button)
- **IDF log sink no-op**: `idfLogSink()` replaces `esp_log_set_vprintf` to prevent 2 KB cam_task stack overflow from EV-VSYNC-OVF -> vprintf -> newlib lock creation; ROM printf path still emits the short line (harmless)
- Tracker control: proportional correction (kp=18 deg) outside deadband (12 px), hysteresis lock release via `lockRelease` factor (3.0x deadband), `lockMs=600`, `settleMs=350`, `lostMs=2500`, `maxStep=3 deg/tick`
- `aimPoint()`: FACE -> y + 2.3*w below; PERSON -> y - h/2 + 0.25*h; TORSO -> torsoAimY
- Color tracker: 74-bin (12 hue x 6 sat + dark + gray) normalized ratio histogram; 8-iteration mean-shift; 1.4x search window; 0.05 per-bin threshold; `minConfidence=0.12`
- Motion detection: 30x30 grid, 2 px subsample per cell, luma from RGB565, frame-to-frame differencing with threshold + weighted centroid + bounding box
- Face detection: two-stage MSR01->MNP01 or single-stage; Person detection: `PedestrianDetect` (PICO_S8_V1) with `HAVE_ESPDET`
- Servo: LEDC 50 Hz, LEDC_CH_PAN=2, LEDC_CH_TILT=3, 14-bit (S3 max), range 544-2400 us; PAN 0-180 deg, TILT 35-145 deg, center 90/90
- `trackTiltMax=110 deg` caps tracking tilt; `torsoTrack=true` default
- OLED: I2C bus recovery, probe every 2 s for 30 s, re-init every 15 s; U8g2_SSD1306_128X64
- Camera 240x240, XCLK 20 MHz; `CONTROL_HZ=50`
- Web: MJPEG port 81, JSON port 80, mDNS `turret`; AP fallback `turret`/`turret123`
- Hardware: parametric OpenSCAD enclosure, 2x MG90S metal-gear servos, 5 printed parts
- BOM: PETG Pro filament, M2 self-tapping screws, M3 button-head Torx (tilt pivot), 470 uF electrolytic cap, 5 V 3 A USB-C supply
- web.cpp full review (287 lines, complete):
  - Routes: `/` (INDEX_HTML), `/status` (JSON, no-store), `/control?var=&val=` (GET, all settings, constrained), `/aim?x=&y=` (click-to-aim), `/capture` (single JPEG, heap alloc 96 KB), `/stream` (MJPEG multipart, 96 KB heap alloc, poll for new seq up to 2 s, break on send error, free buf)
  - Two httpd instances (core 0), ctrl_port 32768/32769, ctrl stack 6144; stream cfg `max_open_sockets = 3`
  - CORS `Access-Control-Allow-Origin: *` on control/capture/stream
  - `defaults` handler preserves hmirror/vflip, resets rest
  - `faceOk` reported via HAVE_ESP_DL compile-time, `detector` name: espdet-person / esp-dl-face / none
  - X-Framerate header hard-coded 60 (aspirational, not real)
  - No auth on any endpoint; control is unbounded-GET (CSRF-able from any page pointed at device); no rate limiting at IP level (httpd default connection limits only)
  - `capture_handler` and `stream_handler` malloc 96 KB heap each — concurrent stream + capture = 192 KB heap pressure
- color_tracker.cpp full review (126 lines, complete):
  - mean-shift: 8 iterations, `STEP` subsample (2 px), per-bin threshold v<0.05 skip, m00 minimum 1.0, converge when moved < 1.0 px
  - Window adaptation: `area = m00*STEP*STEP`, aspect from seed, clamp to 0.5x-1.8x seed, EMA 0.7/0.3
  - `_conf = area/(sw*sh)` where sw/sh are the 1.4x windows; minConfidence 0.12
  - `t.kind = TARGET_TORSO` — color tracker is the torso/presence fallback, not face
  - Histogram is a ratio hist (roi/all) normalized by max, so illumination-common modes wash out
  - `binOf` computes hue with integer math from 565 bits; dark (mx<40) and gray (s<40) are separate bins

## Work State
### Completed
- Listed top-level directory structure, globbed all firmware source files
- Read `README.md`, `platformio.ini` (all 3 envs), `tracker.h` (Settings, Mode, API)
- Read `detector.h` (complete), `servo_ctl.h` (complete), `person_detect.cpp` (complete), `web.h` (complete), `display.h` (complete), `frame_store.h` (complete), `camera_pins.h` (complete)
- Read `detector.cpp`: `begin()`, `detectFace()`, `detectMotion()` body (grid luma differencing, centroid, bbox)
- Read `config.h`: WiFi, pins, servo config, mechanical limits, camera, CONTROL_HZ (75 lines, complete)
- Read `display.cpp`: I2C bus recovery, OLED probe, init, `displayBegin`, start of `displayUpdate` (lines 1-54 confirmed; buzzer section and rest of draw not seen)
- Read `main.cpp`: includes, fb_gfx fallback stubs, task architecture comments, `idfLogSink` reference (lines 1-37 confirmed; detectorTask/controlTask/loop not seen)
- Read `web.cpp` **COMPLETE** (287 lines): index/status/control/aim/capture/stream handlers, webBegin config
- Read `tracker.cpp`: `writeServos` (invert about 180 + trim), `begin` (laser pin, LEDC, prefs, center), `setMode`, `aimPoint` start (lines 1-44 confirmed; controlTask tick, scan sweep, `update()` not seen)
- Read `color_tracker.h` (full), `color_tracker.cpp` **COMPLETE** (126 lines): binOf, clampBox, buildHist, init, refresh, track
- Read `docs/session-2026-09-10.md`: original creation request and session transcript (partial)
- Read `BOM.md`: parts list with Amazon links (partial, first 5 rows)

### Active
- Key sections still unreviewed due to truncation: `main.cpp` (detectorTask body, controlTask body, loop()), `tracker.cpp` (controlTask tick, scan sweep logic, `update()`), `display.cpp` (buzzer code, rest of `displayUpdate` draw)
- `index_html.h` (10309 B) not yet read
- `hardware/turret.scad` not yet reviewed
- **Final evaluation report not yet produced**

### Blocked
- (none)

## Next Move
1. Read `main.cpp` detectorTask/controlTask/loop (use offset/limit reads)
2. Read `tracker.cpp` controlTask/scan/update (use offset/limit reads)
3. Read `display.cpp` buzzer section + rest of draw
4. Read `index_html.h` (embedded web UI)
5. Optionally review `hardware/turret.scad`
6. Produce final evaluation report: architecture assessment, code quality observations, potential issues/risks, build health, recommendations

## Relevant Files
- `F:\still-there\README.md`: project overview, features
- `F:\still-there\BOM.md`: parts list with purchase links — partially read
- `F:\still-there\firmware\platformio.ini`: build config, 3 envs, pin/camera flags, lib_ignore
- `F:\still-there\firmware\src\main.cpp` (~19918 B): entry point, idfLogSink, task architecture — detectorTask/controlTask/loop not yet seen
- `F:\still-there\firmware\include\config.h` (75 lines): complete
- `F:\still-there\firmware\src\tracker.h`: Settings struct, Mode enum, Tracker API
- `F:\still-there\firmware\src\tracker.cpp`: writeServos, begin, aimPoint, onDetection — controlTask/scan/update not yet seen
- `F:\still-there\firmware\src\detector.h` (60 lines): complete
- `F:\still-there\firmware\src\detector.cpp`: detectFace, detectMotion (grid luma)
- `F:\still-there\firmware\src\servo_ctl.h` (57 lines): LEDC servo control, complete
- `F:\still-there\firmware\src\person_detect.cpp` (52 lines): ESPDet-Pico person detector, complete
- `F:\still-there\firmware\src\color_tracker.h`: full class definition
- `F:\still-there\firmware\src\color_tracker.cpp` (126 lines): **COMPLETE**
- `F:\still-there\firmware\src\web.h`: HTTP server API, complete
- `F:\still-there\firmware\src\web.cpp` (287 lines): **COMPLETE**
- `F:\still-there\firmware\src\display.h/.cpp`: OLED/buzzer — buzzer / rest of draw not seen
- `F:\still-there\firmware\src\frame_store.h` (46 lines): mutex-protected JPEG buffer, complete
- `F:\still-there\firmware\include\camera_pins.h` (20 lines): OV2640 pins, complete
- `F:\still-there\firmware\src\index_html.h` (10309 B): embedded web UI — not yet read
- `F:\still-there\docs\session-2026-09-10.md`: session transcript — partially read
- `F:\still-there\hardware\turret.scad`: parametric OpenSCAD enclosure — not yet reviewed
- `F:\still-there\hardware\stl\`: exported STL parts
- `F:\still-there\firmware\lib\pedestrian_detect\README.md`: person detector lib notes
