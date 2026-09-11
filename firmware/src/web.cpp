#include "web.h"
#include <WiFi.h>
#include "esp_http_server.h"
#include "esp_camera.h"
#include "esp_system.h"
#include "index_html.h"

static Tracker* g_tracker = nullptr;
static FrameStore* g_frames = nullptr;
static Stats* g_stats = nullptr;
static httpd_handle_t s_ctrl = nullptr;
static httpd_handle_t s_stream = nullptr;

#define PART_BOUNDARY "123456789000000000000987654321"
static const char* STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";
static const size_t FRAME_CAP = 96 * 1024;

static esp_err_t index_handler(httpd_req_t* req) {
  httpd_resp_set_type(req, "text/html");
  return httpd_resp_send(req, INDEX_HTML, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t status_handler(httpd_req_t* req) {
  const Settings& s = g_tracker->settings;
  Target t = g_tracker->lastTarget();
  uint32_t now = millis();
  bool fresh = g_tracker->targetFresh(now);
  char buf[1200];
  snprintf(buf, sizeof(buf),
           "{\"mode\":%d,\"pan\":%.1f,\"tilt\":%.1f,\"panSet\":%.1f,\"tiltSet\":%.1f,"
           "\"found\":%s,\"fresh\":%s,\"tx\":%d,\"ty\":%d,\"tw\":%d,\"th\":%d,\"score\":%.2f,"
           "\"locked\":%s,\"scanning\":%s,\"laser\":%s,\"moving\":%s,"
           "\"fps\":%.1f,\"infer\":%u,\"rssi\":%d,\"heap\":%u,\"psram\":%u,\"uptime\":%u,\"resetReason\":%d,\"faceOk\":%s,"
           "\"kp\":%.1f,\"smooth\":%.2f,\"maxStep\":%.1f,\"dead\":%d,\"invPan\":%s,\"invTilt\":%s,"
           "\"settle\":%d,\"lost\":%d,\"scan\":%s,\"scanSpeed\":%.1f,\"scanTilt\":%.1f,\"lockMs\":%d,\"lockRelease\":%.1f,\"aimBelow\":%.2f,\"torso\":%s,\"redetect\":%d,\"torsoConf\":%.2f,\"kind\":%d,\"faceAge\":%d,\"faceTimeout\":%d,"
           "\"autoFire\":%s,\"mthr\":%d,\"mmin\":%d,\"quality\":%d,\"hmirror\":%s,\"vflip\":%s,"
           "\"panTrim\":%.1f,\"tiltTrim\":%.1f}",
           (int)g_tracker->mode(), g_tracker->pan(), g_tracker->tilt(), g_tracker->panSet(), g_tracker->tiltSet(),
           t.found ? "true" : "false", fresh ? "true" : "false", t.x, t.y, t.w, t.h, t.score,
           g_tracker->locked() ? "true" : "false", g_tracker->scanning() ? "true" : "false",
           g_tracker->laserOn() ? "true" : "false", g_tracker->moving() ? "true" : "false",
           g_stats->fps, (unsigned)g_stats->inferMs, WiFi.RSSI(), (unsigned)ESP.getFreeHeap(),
           (unsigned)ESP.getFreePsram(), (unsigned)(now / 1000), (int)esp_reset_reason(),
#if HAVE_ESP_DL
           "true",
#else
           "false",
#endif
           s.kp, s.smooth, s.maxStep, s.deadbandPx, s.invertPan ? "true" : "false",
           s.invertTilt ? "true" : "false", s.settleMs, s.lostMs, s.scanWhenLost ? "true" : "false",
           s.scanSpeed, s.scanTilt, s.lockMs, s.lockRelease, s.aimBelow, s.torsoTrack ? "true" : "false",
           s.redetectMs, s.torsoMinConf, (int)t.kind,
           g_tracker->lastFaceMs ? (int)(now - g_tracker->lastFaceMs) : -1, s.faceTimeoutMs,
           s.autoFire ? "true" : "false", s.motionThr,
           s.motionMinCells, s.jpegQuality, s.hmirror ? "true" : "false", s.vflip ? "true" : "false",
           s.panTrim, s.tiltTrim);
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Cache-Control", "no-store");
  return httpd_resp_send(req, buf, HTTPD_RESP_USE_STRLEN);
}

static bool get_query(httpd_req_t* req, char* out, size_t cap) {
  size_t len = httpd_req_get_url_query_len(req) + 1;
  if (len <= 1 || len > cap) return false;
  return httpd_req_get_url_query_str(req, out, len) == ESP_OK;
}

static void apply_sensor() {
  sensor_t* s = esp_camera_sensor_get();
  if (!s) return;
  s->set_hmirror(s, g_tracker->settings.hmirror ? 1 : 0);
  s->set_vflip(s, g_tracker->settings.vflip ? 1 : 0);
}

// /control?var=<name>&val=<value>
static esp_err_t control_handler(httpd_req_t* req) {
  char q[128], var[32] = {0}, val[32] = {0};
  if (!get_query(req, q, sizeof(q)) ||
      httpd_query_key_value(q, "var", var, sizeof(var)) != ESP_OK ||
      httpd_query_key_value(q, "val", val, sizeof(val)) != ESP_OK) {
    httpd_resp_send_404(req);
    return ESP_FAIL;
  }
  Settings& s = g_tracker->settings;
  float f = atof(val);
  int i = atoi(val);
  bool b = i != 0;
  bool ok = true;

  if (!strcmp(var, "mode")) {
    if (i < 0 || i > 3) ok = false;
#if !HAVE_ESP_DL
    if (i == MODE_FACE) ok = false;
#endif
    if (ok) g_tracker->setMode((Mode)i);
  } else if (!strcmp(var, "pan")) {
    g_tracker->setAbsolute(f, g_tracker->tiltSet());
  } else if (!strcmp(var, "tilt")) {
    g_tracker->setAbsolute(g_tracker->panSet(), f);
  } else if (!strcmp(var, "npan")) {
    g_tracker->nudge(f, 0);
  } else if (!strcmp(var, "ntilt")) {
    g_tracker->nudge(0, f);
  } else if (!strcmp(var, "center")) {
    g_tracker->center();
  } else if (!strcmp(var, "laser")) {
    g_tracker->setLaser(b);
  } else if (!strcmp(var, "autofire")) {
    s.autoFire = b;
  } else if (!strcmp(var, "kp")) {
    s.kp = constrain(f, 0.0f, 90.0f);
  } else if (!strcmp(var, "smooth")) {
    s.smooth = constrain(f, 0.02f, 1.0f);
  } else if (!strcmp(var, "maxstep")) {
    s.maxStep = constrain(f, 0.1f, 20.0f);
  } else if (!strcmp(var, "dead")) {
    s.deadbandPx = constrain(i, 0, 120);
  } else if (!strcmp(var, "invpan")) {
    s.invertPan = b;
  } else if (!strcmp(var, "invtilt")) {
    s.invertTilt = b;
  } else if (!strcmp(var, "settle")) {
    s.settleMs = constrain(i, 0, 5000);
  } else if (!strcmp(var, "lost")) {
    s.lostMs = constrain(i, 100, 60000);
  } else if (!strcmp(var, "scan")) {
    s.scanWhenLost = b;
  } else if (!strcmp(var, "scanspeed")) {
    s.scanSpeed = constrain(f, 1.0f, 180.0f);
  } else if (!strcmp(var, "scantilt")) {
    s.scanTilt = constrain(f, TILT_MIN_DEG, TILT_MAX_DEG);
  } else if (!strcmp(var, "lockms")) {
    s.lockMs = constrain(i, 0, 10000);
  } else if (!strcmp(var, "lockrel")) {
    s.lockRelease = constrain(f, 1.0f, 10.0f);
  } else if (!strcmp(var, "aimbelow")) {
    s.aimBelow = constrain(f, -2.0f, 4.0f);
  } else if (!strcmp(var, "torso")) {
    s.torsoTrack = b;
  } else if (!strcmp(var, "redetect")) {
    s.redetectMs = constrain(i, 100, 10000);
  } else if (!strcmp(var, "torsoconf")) {
    s.torsoMinConf = constrain(f, 0.02f, 0.9f);
  } else if (!strcmp(var, "facetmo")) {
    s.faceTimeoutMs = constrain(i, 1000, 60000);
  } else if (!strcmp(var, "mthr")) {
    s.motionThr = constrain(i, 1, 200);
  } else if (!strcmp(var, "mmin")) {
    s.motionMinCells = constrain(i, 1, 400);
  } else if (!strcmp(var, "quality")) {
    s.jpegQuality = constrain(i, 10, 95);
  } else if (!strcmp(var, "hmirror")) {
    s.hmirror = b;
    apply_sensor();
  } else if (!strcmp(var, "vflip")) {
    s.vflip = b;
    apply_sensor();
  } else if (!strcmp(var, "pantrim")) {
    s.panTrim = constrain(f, -30.0f, 30.0f);
  } else if (!strcmp(var, "tilttrim")) {
    s.tiltTrim = constrain(f, -30.0f, 30.0f);
  } else if (!strcmp(var, "save")) {
    g_tracker->saveSettings();
  } else if (!strcmp(var, "defaults")) {
    Settings d;
    d.hmirror = s.hmirror;
    d.vflip = s.vflip;
    s = d;
  } else {
    ok = false;
  }

  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  httpd_resp_set_type(req, "text/plain");
  return httpd_resp_send(req, ok ? "OK" : "ERR", HTTPD_RESP_USE_STRLEN);
}

// /aim?x=<px>&y=<px>   click-to-aim in the 240x240 frame
static esp_err_t aim_handler(httpd_req_t* req) {
  char q[64], xs[12] = {0}, ys[12] = {0};
  if (!get_query(req, q, sizeof(q)) ||
      httpd_query_key_value(q, "x", xs, sizeof(xs)) != ESP_OK ||
      httpd_query_key_value(q, "y", ys, sizeof(ys)) != ESP_OK) {
    httpd_resp_send_404(req);
    return ESP_FAIL;
  }
  g_tracker->aimAtPixel(atoi(xs), atoi(ys));
  httpd_resp_set_type(req, "text/plain");
  return httpd_resp_send(req, "OK", HTTPD_RESP_USE_STRLEN);
}

static esp_err_t capture_handler(httpd_req_t* req) {
  uint8_t* buf = (uint8_t*)malloc(FRAME_CAP);
  if (!buf) {
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  size_t n = g_frames->copyLatest(buf, FRAME_CAP, nullptr);
  if (!n) {
    free(buf);
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  httpd_resp_set_type(req, "image/jpeg");
  httpd_resp_set_hdr(req, "Content-Disposition", "inline; filename=capture.jpg");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  esp_err_t r = httpd_resp_send(req, (const char*)buf, n);
  free(buf);
  return r;
}

static esp_err_t stream_handler(httpd_req_t* req) {
  esp_err_t res = httpd_resp_set_type(req, STREAM_CONTENT_TYPE);
  if (res != ESP_OK) return res;
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  httpd_resp_set_hdr(req, "X-Framerate", "60");

  uint8_t* buf = (uint8_t*)malloc(FRAME_CAP);
  if (!buf) return ESP_FAIL;
  uint32_t lastSeq = 0;
  char part[64];

  while (true) {
    // Wait for a new frame (poll; frames arrive at a few Hz to ~20 Hz).
    uint32_t waited = 0;
    while (g_frames->seq() == lastSeq && waited < 2000) {
      vTaskDelay(pdMS_TO_TICKS(5));
      waited += 5;
    }
    uint32_t seq = 0;
    size_t n = g_frames->copyLatest(buf, FRAME_CAP, &seq);
    if (!n) {
      vTaskDelay(pdMS_TO_TICKS(20));
      continue;
    }
    lastSeq = seq;
    size_t hlen = snprintf(part, sizeof(part), STREAM_PART, (unsigned)n);
    if (httpd_resp_send_chunk(req, STREAM_BOUNDARY, strlen(STREAM_BOUNDARY)) != ESP_OK) break;
    if (httpd_resp_send_chunk(req, part, hlen) != ESP_OK) break;
    if (httpd_resp_send_chunk(req, (const char*)buf, n) != ESP_OK) break;
  }
  free(buf);
  return ESP_OK;
}

void webBegin(Tracker* tracker, FrameStore* frames, Stats* stats) {
  g_tracker = tracker;
  g_frames = frames;
  g_stats = stats;

  httpd_config_t cfg = HTTPD_DEFAULT_CONFIG();
  cfg.server_port = 80;
  cfg.ctrl_port = 32768;
  cfg.max_uri_handlers = 8;
  cfg.stack_size = 6144;

  httpd_uri_t u_index = {.uri = "/", .method = HTTP_GET, .handler = index_handler, .user_ctx = nullptr};
  httpd_uri_t u_status = {.uri = "/status", .method = HTTP_GET, .handler = status_handler, .user_ctx = nullptr};
  httpd_uri_t u_control = {.uri = "/control", .method = HTTP_GET, .handler = control_handler, .user_ctx = nullptr};
  httpd_uri_t u_aim = {.uri = "/aim", .method = HTTP_GET, .handler = aim_handler, .user_ctx = nullptr};
  httpd_uri_t u_capture = {.uri = "/capture", .method = HTTP_GET, .handler = capture_handler, .user_ctx = nullptr};
  httpd_uri_t u_stream = {.uri = "/stream", .method = HTTP_GET, .handler = stream_handler, .user_ctx = nullptr};

  if (httpd_start(&s_ctrl, &cfg) == ESP_OK) {
    httpd_register_uri_handler(s_ctrl, &u_index);
    httpd_register_uri_handler(s_ctrl, &u_status);
    httpd_register_uri_handler(s_ctrl, &u_control);
    httpd_register_uri_handler(s_ctrl, &u_aim);
    httpd_register_uri_handler(s_ctrl, &u_capture);
  }

  cfg.server_port = 81;
  cfg.ctrl_port = 32769;
  cfg.max_open_sockets = 3;
  if (httpd_start(&s_stream, &cfg) == ESP_OK) {
    httpd_register_uri_handler(s_stream, &u_stream);
  }
}
