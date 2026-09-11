#pragma once
#include <Arduino.h>
#include "esp_camera.h"
#include "detector.h"

// CAMShift-style color blob tracker on RGB565 frames.
//
// Seeded once from a region of interest (the torso below a detected face). It builds a
// hue/saturation ratio histogram (ROI over whole frame, so colors that are also common in
// the background are down-weighted), then on every frame back-projects the histogram and
// mean-shifts a window onto the densest matching area. It does not use the previous frame,
// so it keeps working while the servos move the camera, and it does not care which way
// the person is facing.
class ColorTracker {
 public:
  // Seed from a box (center cx,cy size w,h in pixels). aimRelY: where the aim point sits
  // relative to the window center, in window heights (carried along as the window moves).
  void init(camera_fb_t* fb, int cx, int cy, int w, int h, float aimRelY);
  // Blend a fresh histogram in (alpha 0..1) and re-center the window on the box.
  void refresh(camera_fb_t* fb, int cx, int cy, int w, int h, float aimRelY, float alpha);
  // One tracking step. Returns true and fills t while the match is good enough.
  bool track(camera_fb_t* fb, Target& t);
  void reset() { _active = false; }
  bool active() const { return _active; }
  float confidence() const { return _conf; }
  int aimY() const { return (int)(_cy + _aimRelY * _h); }

  float minConfidence = 0.12f;   // fraction of the window that must match

 private:
  static constexpr int HB = 12, SB = 6;          // hue x saturation bins
  static constexpr int NB = HB * SB + 2;         // + dark, + gray
  static constexpr int STEP = 2;                 // pixel subsampling

  void buildHist(camera_fb_t* fb, int cx, int cy, int w, int h, float* out);
  static inline int binOf(uint8_t b0, uint8_t b1);

  float _hist[NB];
  float _cx = 0, _cy = 0, _w = 0, _h = 0;
  float _w0 = 0, _h0 = 0;                        // seed size, bounds the adaptive window
  float _aimRelY = 0;
  float _conf = 0;
  bool _active = false;
};
