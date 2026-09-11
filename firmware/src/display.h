#pragma once
#include <Arduino.h>
#include "tracker.h"
#include "web.h"

// Optional 128x64 SSD1306 status display (Seeed XIAO Expansion Board) plus its buzzer.
// Compiled in with -DEXPANSION_BOARD=1; all functions are no-ops otherwise.
void displayBegin();
void displayBoot(const char* line1, const char* line2);
void displayUpdate(Tracker& tracker, const Stats& stats, const String& netInfo);

void buzzerBegin();
void buzzerBeep(uint16_t freqHz, uint16_t ms);
void buzzerUpdate(Tracker& tracker);   // lock / acquire cues, call from loop()
