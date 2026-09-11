#pragma once
#include <Arduino.h>
#include "config.h"

// Hobby servo on an LEDC channel, 50 Hz, 16-bit duty.
// Works on arduino-esp32 2.x (ledcSetup/ledcAttachPin) and 3.x (ledcAttachChannel).
class ServoOut {
 public:
  void attach(int pin, int channel, float minDeg, float maxDeg) {
    _pin = pin;
    _ch = channel;
    _min = minDeg;
    _max = maxDeg;
    // ESP32-S3 LEDC is limited to 14-bit resolution (16 fails with "No more LEDC channels").
#if ESP_ARDUINO_VERSION_MAJOR >= 3
    ledcAttachChannel(_pin, SERVO_FREQ_HZ, SERVO_RES_BITS, _ch);
#else
    ledcSetup(_ch, SERVO_FREQ_HZ, SERVO_RES_BITS);
    ledcAttachPin(_pin, _ch);
#endif
  }

  void writeDeg(float deg) {
    if (deg < _min) deg = _min;
    if (deg > _max) deg = _max;
    _deg = deg;
    uint32_t us = SERVO_MIN_US + (uint32_t)((SERVO_MAX_US - SERVO_MIN_US) * (deg / 180.0f));
    writeUs(us);
  }

  void writeUs(uint32_t us) {
    const uint32_t period_us = 1000000UL / SERVO_FREQ_HZ;
    const uint32_t maxDuty = (1UL << SERVO_RES_BITS) - 1;
    uint32_t duty = (uint32_t)(((uint64_t)us * maxDuty) / period_us);
#if ESP_ARDUINO_VERSION_MAJOR >= 3
    ledcWrite(_pin, duty);
#else
    ledcWrite(_ch, duty);
#endif
  }

  void detach() {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
    ledcDetach(_pin);
#else
    ledcDetachPin(_pin);
#endif
  }

  float deg() const { return _deg; }
  float minDeg() const { return _min; }
  float maxDeg() const { return _max; }

 private:
  int _pin = -1, _ch = -1;
  float _min = 0, _max = 180, _deg = 90;
};
