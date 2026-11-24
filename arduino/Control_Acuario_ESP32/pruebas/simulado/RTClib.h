#pragma once
#include <cstdint>
#include "Arduino.h"
extern long g_rtc_base;          // segundos del día cuando g_millis == g_rtc_millis_base
extern uint32_t g_rtc_millis_base;
extern bool g_rtc_presente, g_rtc_perdio;
class DateTime {
 public:
  uint16_t y; uint8_t mo, d, h, mi, s;
  DateTime(uint16_t yy, uint8_t mm, uint8_t dd, uint8_t hh = 0, uint8_t mn = 0, uint8_t ss = 0) : y(yy), mo(mm), d(dd), h(hh), mi(mn), s(ss) {}
  uint16_t year() const { return y; } uint8_t month() const { return mo; } uint8_t day() const { return d; }
  uint8_t hour() const { return h; } uint8_t minute() const { return mi; } uint8_t second() const { return s; }
};
class RTC_DS3231 {
 public:
  bool begin() { return g_rtc_presente; }
  bool lostPower() { return g_rtc_perdio; }
  DateTime now() {
    long t = g_rtc_base + (long)((g_millis - g_rtc_millis_base) / 1000);
    long dias = t / 86400; t %= 86400;
    return DateTime(2026, 11, (uint8_t)(20 + dias), t / 3600, (t / 60) % 60, t % 60);
  }
  void adjust(const DateTime& n) { g_rtc_base = n.h * 3600L + n.mi * 60L + n.s; g_rtc_millis_base = g_millis; g_rtc_perdio = false; }
};
