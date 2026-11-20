#pragma once
#include "OneWire.h"
#include "Arduino.h"
#define DEVICE_DISCONNECTED_C -127
extern float g_temp_agua;
extern bool g_sonda_conectada;
extern int g_peticiones_temp;
class DallasTemperature {
 public:
  explicit DallasTemperature(OneWire*) {}
  void begin() {}
  void setResolution(uint8_t) {}
  bool espera = true;
  void setWaitForConversion(bool e) { espera = e; }
  void requestTemperatures() { g_peticiones_temp++; if (espera) g_millis += 750; }  // con espera bloquea 750 ms
  float getTempCByIndex(uint8_t) { return g_sonda_conectada ? g_temp_agua : DEVICE_DISCONNECTED_C; }
};
