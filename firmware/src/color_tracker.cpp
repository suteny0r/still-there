#include "color_tracker.h"
#include <math.h>
#include <string.h>

// RGB565 (big-endian in the camera buffer) -> histogram bin.
inline int ColorTracker::binOf(uint8_t b0, uint8_t b1) {
  int r = b0 & 0xF8;
  int g = ((b0 & 0x07) << 5) | ((b1 & 0xE0) >> 3);
  int b = (b1 & 0x1F) << 3;
  int mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
  int mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
  if (mx < 40) return HB * SB;                    // dark
  int d = mx - mn;
  int s = d * 255 / mx;
  if (s < 40) return HB * SB + 1;                 // gray / white
  int h;                                          // 0..359
  if (mx == r) h = (60 * (g - b) / d + 360) % 360;
  else if (mx == g) h = 60 * (b - r) / d + 120;
  else h = 60 * (r - g) / d + 240;
  int hb = h * HB / 360;
  int sb = (s - 40) * SB / 216;
  if (sb >= SB) sb = SB - 1;
  return hb * SB + sb;
}

static inline void clampBox(camera_fb_t* fb, int& x0, int& y0, int& x1, int& y1) {
  if (x0 < 0) x0 = 0;
  if (y0 < 0) y0 = 0;
  if (x1 > fb->width) x1 = fb->width;
  if (y1 > fb->height) y1 = fb->height;
}

void ColorTracker::buildHist(camera_fb_t* fb, int cx, int cy, int w, int h, float* out) {
  float roi[NB] = {0}, all[NB] = {0};
  const uint8_t* p = fb->buf;
  const int W = fb->width;
  int x0 = cx - w / 2, y0 = cy - h / 2, x1 = x0 + w, y1 = y0 + h;
  clampBox(fb, x0, y0, x1, y1);
  for (int y = 0; y < fb->height; y += STEP) {
    const uint8_t* row = p + (y * W) * 2;
    bool iny = y >= y0 && y < y1;
    for (int x = 0; x < W; x += STEP) {
      int b = binOf(row[x * 2], row[x * 2 + 1]);
      all[b] += 1;
      if (iny && x >= x0 && x < x1) roi[b] += 1;
    }
  }
  // Ratio histogram: how much more common each color is inside the ROI than in the frame.
  float mx = 0;
  for (int i = 0; i < NB; i++) {
    out[i] = all[i] > 0 ? roi[i] / all[i] : 0;
    if (out[i] > mx) mx = out[i];
  }
  if (mx > 0)
    for (int i = 0; i < NB; i++) out[i] /= mx;
}

void ColorTracker::init(camera_fb_t* fb, int cx, int cy, int w, int h, float aimRelY) {
  buildHist(fb, cx, cy, w, h, _hist);
  _cx = cx; _cy = cy; _w = _w0 = w; _h = _h0 = h;
  _aimRelY = aimRelY;
  _conf = 1.0f;
  _active = true;
}

void ColorTracker::refresh(camera_fb_t* fb, int cx, int cy, int w, int h, float aimRelY, float alpha) {
  if (!_active) { init(fb, cx, cy, w, h, aimRelY); return; }
  float fresh[NB];
  buildHist(fb, cx, cy, w, h, fresh);
  for (int i = 0; i < NB; i++) _hist[i] = (1 - alpha) * _hist[i] + alpha * fresh[i];
  _cx = cx; _cy = cy; _w = _w0 = w; _h = _h0 = h;
  _aimRelY = aimRelY;
}

bool ColorTracker::track(camera_fb_t* fb, Target& t) {
  if (!_active || !fb || fb->format != PIXFORMAT_RGB565) return false;
  const uint8_t* p = fb->buf;
  const int W = fb->width;
  float cx = _cx, cy = _cy;
  float sw = _w * 1.4f, sh = _h * 1.4f;             // search window, a bit larger than the blob
  float m00 = 0;

  for (int it = 0; it < 8; it++) {
    int x0 = (int)(cx - sw / 2), y0 = (int)(cy - sh / 2);
    int x1 = (int)(cx + sw / 2), y1 = (int)(cy + sh / 2);
    clampBox(fb, x0, y0, x1, y1);
    if (x1 - x0 < 4 || y1 - y0 < 4) { _conf = 0; return false; }
    float m10 = 0, m01 = 0;
    m00 = 0;
    for (int y = y0; y < y1; y += STEP) {
      const uint8_t* row = p + (y * W) * 2;
      for (int x = x0; x < x1; x += STEP) {
        float v = _hist[binOf(row[x * 2], row[x * 2 + 1])];
        if (v < 0.05f) continue;
        m00 += v; m10 += v * x; m01 += v * y;
      }
    }
    if (m00 < 1.0f) { _conf = 0; return false; }
    float nx = m10 / m00, ny = m01 / m00;
    float moved = fabsf(nx - cx) + fabsf(ny - cy);
    cx = nx; cy = ny;
    if (moved < 1.0f) break;
  }

  // Matching area in pixels -> adapt window size (CAMShift), bounded around the seed size.
  float area = m00 * STEP * STEP;
  float aspect = _h0 / _w0;
  float nw = sqrtf(area / aspect) * 1.15f;
  float nh = nw * aspect;
  if (nw < _w0 * 0.5f) { nw = _w0 * 0.5f; nh = nw * aspect; }
  if (nw > _w0 * 1.8f) { nw = _w0 * 1.8f; nh = nw * aspect; }
  _w = 0.7f * _w + 0.3f * nw;
  _h = 0.7f * _h + 0.3f * nh;
  _cx = cx; _cy = cy;
  _conf = area / (sw * sh);

  if (_conf < minConfidence) return false;
  t.found = true;
  t.kind = TARGET_TORSO;
  t.x = (int)_cx;
  t.y = (int)_cy;
  t.w = (int)_w;
  t.h = (int)_h;
  t.score = _conf;
  return true;
}
