#include "detector.h"
#include <string.h>
#include <stdlib.h>

#if HAVE_ESP_DL
#include "human_face_detect_msr01.hpp"
#include "human_face_detect_mnp01.hpp"
#ifndef FACE_TWO_STAGE
#define FACE_TWO_STAGE 1
#endif
#endif

void Detector::begin() {
#if HAVE_ESP_DL
  // Same thresholds as the arduino-esp32 CameraWebServer example.
#if FACE_TWO_STAGE
  _s1 = new HumanFaceDetectMSR01(0.1F, 0.5F, 10, 0.2F);
  _s2 = new HumanFaceDetectMNP01(0.5F, 0.3F, 5);
#else
  _s1 = new HumanFaceDetectMSR01(0.3F, 0.5F, 10, 0.2F);
#endif
#endif
  _havePrev = false;
}

Target Detector::detectFace(camera_fb_t* fb) {
  Target t;
#if HAVE_ESP_DL
  if (!fb || fb->format != PIXFORMAT_RGB565 || !_s1) return t;
  HumanFaceDetectMSR01* s1 = (HumanFaceDetectMSR01*)_s1;
  std::vector<int> shape = {(int)fb->height, (int)fb->width, 3};
#if FACE_TWO_STAGE
  HumanFaceDetectMNP01* s2 = (HumanFaceDetectMNP01*)_s2;
  std::list<dl::detect::result_t>& cand = s1->infer((uint16_t*)fb->buf, shape);
  std::list<dl::detect::result_t>& results = s2->infer((uint16_t*)fb->buf, shape, cand);
#else
  std::list<dl::detect::result_t>& results = s1->infer((uint16_t*)fb->buf, shape);
#endif
  int bestArea = -1;
  for (auto& r : results) {
    if (r.box.size() < 4) continue;
    int x1 = r.box[0], y1 = r.box[1], x2 = r.box[2], y2 = r.box[3];
    int area = (x2 - x1) * (y2 - y1);
    if (area > bestArea) {
      bestArea = area;
      t.found = true;
      t.kind = TARGET_FACE;
      t.x = (x1 + x2) / 2;
      t.y = (y1 + y2) / 2;
      t.w = x2 - x1;
      t.h = y2 - y1;
      t.score = r.score;
    }
  }
#endif
  return t;
}

Target Detector::detectMotion(camera_fb_t* fb, bool suppress, int threshold, int minCells) {
  Target t;
  if (!fb || fb->format != PIXFORMAT_RGB565) return t;
  const int W = fb->width;
  const int cell = fb->width / GRID;
  const int gridH = fb->height / cell;
  if (gridH > GRID) return t;

  uint8_t cur[GRID * GRID];
  const uint8_t* p = fb->buf;
  // 4x4 subsample per 8x8 cell = 16 samples; luma from big-endian RGB565.
  for (int gy = 0; gy < gridH; gy++) {
    for (int gx = 0; gx < GRID; gx++) {
      uint32_t sum = 0;
      int n = 0;
      for (int yy = 0; yy < cell; yy += 2) {
        const uint8_t* row = p + (((gy * cell + yy) * W) + gx * cell) * 2;
        for (int xx = 0; xx < cell; xx += 2) {
          uint8_t b0 = row[xx * 2], b1 = row[xx * 2 + 1];
          uint32_t r = b0 >> 3;
          uint32_t g = ((b0 & 7) << 3) | (b1 >> 5);
          uint32_t b = b1 & 31;
          sum += (r * 19 + g * 19 + b * 7) >> 3;
          n++;
        }
      }
      cur[gy * GRID + gx] = (uint8_t)(sum / (n ? n : 1));
    }
  }

  if (!_havePrev || suppress) {
    memcpy(_prev, cur, sizeof(cur));
    _havePrev = true;
    return t;
  }

  int count = 0;
  uint32_t sw = 0, sx = 0, sy = 0;
  int minx = GRID, maxx = -1, miny = GRID, maxy = -1;
  for (int gy = 0; gy < gridH; gy++) {
    for (int gx = 0; gx < GRID; gx++) {
      int i = gy * GRID + gx;
      int d = abs((int)cur[i] - (int)_prev[i]);
      if (d > threshold) {
        count++;
        sw += d;
        sx += gx * d;
        sy += gy * d;
        if (gx < minx) minx = gx;
        if (gx > maxx) maxx = gx;
        if (gy < miny) miny = gy;
        if (gy > maxy) maxy = gy;
      }
    }
  }
  memcpy(_prev, cur, sizeof(cur));

  if (count >= minCells && sw > 0) {
    t.found = true;
    t.kind = TARGET_MOTION;
    t.x = (int)(((float)sx / sw + 0.5f) * cell);
    t.y = (int)(((float)sy / sw + 0.5f) * cell);
    t.w = (maxx - minx + 1) * cell;
    t.h = (maxy - miny + 1) * cell;
    t.score = (float)count / (GRID * gridH);
  }
  return t;
}
