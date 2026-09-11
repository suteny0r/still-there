#pragma once
#include <Arduino.h>
#include "esp_camera.h"

// esp-dl face models ship with arduino-esp32 2.0.x (ESP32-S3 only).
#if defined(__has_include)
#if __has_include("human_face_detect_msr01.hpp")
#define HAVE_ESP_DL 1
#endif
#endif
#ifndef HAVE_ESP_DL
#define HAVE_ESP_DL 0
#endif

// ESPDet-Pico whole-body person detector (esp-dl 3.x, hybrid build only).
#if defined(__has_include)
#if __has_include("pedestrian_detect.hpp")
#define HAVE_ESPDET 1
#endif
#endif
#ifndef HAVE_ESPDET
#define HAVE_ESPDET 0
#endif

enum TargetKind : uint8_t { TARGET_NONE = 0, TARGET_FACE = 1, TARGET_TORSO = 2, TARGET_MOTION = 3, TARGET_PERSON = 4 };

struct Target {
  bool found = false;
  TargetKind kind = TARGET_NONE;
  int x = 0, y = 0;   // center, pixels
  int w = 0, h = 0;   // box size, pixels
  float score = 0;
};

// person_detect.cpp
bool personDetectBegin();
Target personDetect(camera_fb_t* fb, float scoreThr);

class Detector {
 public:
  void begin();

  // RGB565 frame -> largest face.
  Target detectFace(camera_fb_t* fb);

  // RGB565 frame -> centroid of changed 8x8 cells vs previous frame.
  // suppress=true only refreshes the reference (use while servos are moving).
  Target detectMotion(camera_fb_t* fb, bool suppress, int threshold, int minCells);

  void resetMotion() { _havePrev = false; }
  bool faceAvailable() const { return HAVE_ESP_DL; }

  static constexpr int GRID = 30;  // 240 / 8

 private:
  uint8_t _prev[GRID * GRID];
  bool _havePrev = false;
  void* _s1 = nullptr;
  void* _s2 = nullptr;
};
