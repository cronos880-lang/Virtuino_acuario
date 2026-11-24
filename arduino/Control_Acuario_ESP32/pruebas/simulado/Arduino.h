// Imitación de Arduino.h del ESP32 para ejecutar el sketch en el PC (solo pruebas).
// Reutiliza la del V2 y añade lo propio del ESP32 (LEDC, ADC en mV, ESP).
#pragma once
#include "../../../Control_Acuario_V2/pruebas/simulado/Arduino.h"
#include <algorithm>
#include <string>
#include <vector>
using std::min;
using std::max;

extern std::vector<std::string> g_eventos;   // orden de las acciones sobre la fuente
extern uint32_t g_pwm_ciclo, g_pwm_frec;
inline bool ledcAttach(uint8_t, uint32_t f, uint8_t) { g_pwm_frec = f; g_pwm_ciclo = 0; return true; }
inline bool ledcWrite(uint8_t, uint32_t c) { if (c != g_pwm_ciclo) g_eventos.push_back("PWM=" + std::to_string(c)); g_pwm_ciclo = c; return true; }
inline uint32_t ledcChangeFrequency(uint8_t, uint32_t f, uint8_t) { g_pwm_frec = f; return f; }
uint32_t analogReadMilliVolts(uint8_t pin);   // modelo de la placa en test_sketch.cpp
struct EspPrueba { uint32_t getFreeHeap() { return 250000; } };
extern EspPrueba ESP;
