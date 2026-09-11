#pragma once

// ---------------------------------------------------------------------------
// WiFi: copy include/secrets.h.example to include/secrets.h and edit.
// With no secrets.h (or empty SSID) the turret starts its own AP.
// ---------------------------------------------------------------------------
#if defined(__has_include)
#if __has_include("secrets.h")
#include "secrets.h"
#endif
#endif

#ifndef WIFI_SSID
#define WIFI_SSID ""
#endif
#ifndef WIFI_PASS
#define WIFI_PASS ""
#endif

#define HOSTNAME        "turret"     // http://turret.local
#define AP_SSID         "turret"
#define AP_PASS         "turret123"  // min 8 chars
#define WIFI_CONNECT_MS 15000

// ---------------------------------------------------------------------------
// Pins (XIAO ESP32S3 silkscreen -> GPIO). D0..D3 are free on the Sense board;
// GPIO10..18,38..40,47,48 are the camera, GPIO21 is the user LED / SD CS,
// GPIO41/42 are the PDM mic.
// ---------------------------------------------------------------------------
#ifndef EXPANSION_BOARD
#define EXPANSION_BOARD  0
#endif

#if EXPANSION_BOARD
// XIAO on the Seeed Expansion Board: D1 is its user button (to GND), D3/A3 drives its
// buzzer transistor, D4/D5 are the OLED I2C. Keep the servo/laser lines off those.
#define PIN_SERVO_PAN    1   // D0
#define PIN_SERVO_TILT   3   // D2
#define PIN_LASER       43   // D6 (Grove UART TX pin, free)
#define PIN_TRIGGER_BTN  2   // D1  expansion-board user button
#define PIN_BUZZER       4   // D3  expansion-board buzzer
#else
#define PIN_SERVO_PAN    1   // D0
#define PIN_SERVO_TILT   2   // D1
#define PIN_LASER        3   // D2  (laser / LED "fire" output, active HIGH)
#define PIN_TRIGGER_BTN  4   // D3  (momentary to GND, optional)
#endif
#define PIN_STATUS_LED  21   // onboard user LED, active LOW

// LEDC channels 0/1 (timer 0) are used by the camera XCLK.
#define LEDC_CH_PAN      2
#define LEDC_CH_TILT     3
#define SERVO_FREQ_HZ    50
#define SERVO_RES_BITS   14  // 50 Hz / 14 bit = 1.22 us per step; S3 hardware maximum
// MG90S: 180 deg over roughly 544..2400 us on most units. Wider ranges drive the
// gear train into the end stops and cook the motor; widen only after checking travel.
#define SERVO_MIN_US     544
#define SERVO_MAX_US     2400

// Mechanical limits (degrees). Tilt limits keep the head off the yoke base.
#define PAN_MIN_DEG      0.0f
#define PAN_MAX_DEG    180.0f
#define TILT_MIN_DEG    35.0f
#define TILT_MAX_DEG   145.0f
#define PAN_CENTER_DEG  90.0f
#define TILT_CENTER_DEG 90.0f

// Camera
#define CAM_W            240
#define CAM_H            240
#define CAM_FRAMESIZE    FRAMESIZE_240X240
#define CAM_XCLK_HZ      20000000

// Control loop
#define CONTROL_HZ       50
