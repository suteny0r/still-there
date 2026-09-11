#pragma once
#include "tracker.h"
#include "frame_store.h"

struct Stats {
  volatile float fps = 0;
  volatile uint32_t inferMs = 0;
  volatile uint32_t frameMs = 0;
};

void webBegin(Tracker* tracker, FrameStore* frames, Stats* stats);
