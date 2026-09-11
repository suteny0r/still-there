#pragma once
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

// Latest JPEG frame, produced by the detector task, consumed by HTTP handlers.
class FrameStore {
 public:
  void begin() { _mtx = xSemaphoreCreateMutex(); }

  // Takes ownership of jpg (malloc'd by frame2jpg).
  void publish(uint8_t* jpg, size_t len) {
    xSemaphoreTake(_mtx, portMAX_DELAY);
    if (_buf) free(_buf);
    _buf = jpg;
    _len = len;
    _seq++;
    xSemaphoreGive(_mtx);
  }

  uint32_t seq() {
    xSemaphoreTake(_mtx, portMAX_DELAY);
    uint32_t s = _seq;
    xSemaphoreGive(_mtx);
    return s;
  }

  // Copies the latest frame into dst. Returns bytes copied (0 if none / too big).
  size_t copyLatest(uint8_t* dst, size_t cap, uint32_t* seqOut) {
    size_t n = 0;
    xSemaphoreTake(_mtx, portMAX_DELAY);
    if (_buf && _len <= cap) {
      memcpy(dst, _buf, _len);
      n = _len;
    }
    if (seqOut) *seqOut = _seq;
    xSemaphoreGive(_mtx);
    return n;
  }

 private:
  SemaphoreHandle_t _mtx = nullptr;
  uint8_t* _buf = nullptr;
  size_t _len = 0;
  uint32_t _seq = 0;
};
