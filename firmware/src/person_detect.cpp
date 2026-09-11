// ESPDet-Pico pedestrian (whole-body person) detector, esp-dl 3.x.
// Compiled only in the hybrid Arduino + ESP-IDF environment where the
// espressif/pedestrian_detect component is available (HAVE_ESPDET).
#include "detector.h"

#if HAVE_ESPDET
#include "pedestrian_detect.hpp"
#include "dl_image_define.hpp"

static PedestrianDetect* s_det = nullptr;

bool personDetectBegin() {
  if (!s_det) s_det = new PedestrianDetect();   // PICO_S8_V1 from flash rodata, lazy-loaded
  return s_det != nullptr;
}

Target personDetect(camera_fb_t* fb, float scoreThr) {
  Target t;
  if (!fb || fb->format != PIXFORMAT_RGB565 || !s_det) return t;
  s_det->set_score_thr(scoreThr);
  dl::image::img_t img;
  img.data = fb->buf;
  img.width = fb->width;
  img.height = fb->height;
  img.pix_type = dl::image::DL_IMAGE_PIX_TYPE_RGB565BE;   // camera byte order
  std::list<dl::detect::result_t>& results = s_det->run(img);
  int bestArea = -1;
  for (auto& r : results) {
    if (r.box.size() < 4) continue;
    int x1 = r.box[0], y1 = r.box[1], x2 = r.box[2], y2 = r.box[3];
    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x2 > (int)fb->width) x2 = fb->width;
    if (y2 > (int)fb->height) y2 = fb->height;
    int area = (x2 - x1) * (y2 - y1);
    if (area > bestArea && area > 0) {
      bestArea = area;
      t.found = true;
      t.kind = TARGET_PERSON;
      t.x = (x1 + x2) / 2;
      t.y = (y1 + y2) / 2;
      t.w = x2 - x1;
      t.h = y2 - y1;
      t.score = r.score;
    }
  }
  return t;
}
#else
bool personDetectBegin() { return false; }
Target personDetect(camera_fb_t*, float) { return Target(); }
#endif
