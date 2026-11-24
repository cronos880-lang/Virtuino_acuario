// Pruebas de Fuente.h en el PC:  g++ -std=c++17 -Wall -o /tmp/t test_fuente.cpp && /tmp/t
#include <cstdio>
#include "../Fuente.h"
using namespace Fuente;
static int ok = 0, mal = 0;
static void comprobar(bool c, const char* n) { if (c) ok++; else { mal++; printf("FALLO: %s\n", n); } }
static bool cerca(float a, float b, float t) { return fabsf(a - b) <= t; }

int main() {
  // Relación inversa del buck: 4095 = mínimo (~3,8 V), menos código = más tensión
  comprobar(cerca(tension_de_codigo(4095), 23.86f - 6.09f * 3.3f, 0.01f), "4095 = tensión mínima");
  comprobar(codigo_dac(10.0f) > codigo_dac(12.0f), "más tensión = menos código");
  comprobar(cerca(tension_de_codigo(codigo_dac(10.0f)), 10.0f, 0.02f), "10 V ida y vuelta");
  comprobar(cerca(tension_de_codigo(codigo_dac(6.0f)), 6.0f, 0.02f), "6 V ida y vuelta");
  // Nunca por encima del límite, aunque se pida más (o un valor no válido)
  comprobar(tension_de_codigo(codigo_dac(30.0f)) <= TENSION_MAX, "límite de 21 V");
  comprobar(tension_de_codigo(codigo_dac(21.0f)) <= TENSION_MAX, "21 V exactos sin pasarse");
  comprobar(tension_de_codigo(codigo_dac(NAN)) < 4.0f, "NaN = tensión mínima");
  comprobar(codigo_dac(-5.0f) == 4095, "negativo = mínimo");
  // Medidas
  comprobar(cerca(tension_de_adc(1820.0f), 24.0f, 0.05f), "ADC 1,82 V = 24 V");
  comprobar(cerca(corriente_de_adc(1140.0f), 6.0f, 0.1f), "IMON 1,14 V ≈ 6 A");
  // Tolerancias
  comprobar(!sobretension(11.5f, 10.0f) && sobretension(12.1f, 10.0f), "sobretensión a 10 V: margen 2 V");
  comprobar(tension_correcta(6.8f, 6.0f) && !tension_correcta(4.0f, 6.0f), "comprobación a 6 V");
  comprobar(tension_valida(10.0f) && !tension_valida(4.9f) && !tension_valida(21.5f) && !tension_valida(NAN), "ajuste de tensión");
  comprobar(frecuencia_valida(490) && !frecuencia_valida(50) && !frecuencia_valida(6000), "frecuencia");
  // PWM
  comprobar(ciclo_pwm(125, false) == 125 && ciclo_pwm(0, false) == 0, "PWM sigue el nivel");
  comprobar(ciclo_pwm(1, true) == 255 && ciclo_pwm(0, true) == 0, "continua: todo o nada");
  // Rampa: 6 → 10 V a 4 V/s = 1 s; bajadas inmediatas
  float v = 6.0f; int pasos = 0;
  while (v < 10.0f && pasos < 1000) { v = avanzar_rampa(v, 10.0f, 10); pasos++; }
  comprobar(pasos >= 100 && pasos <= 101 && v == 10.0f, "rampa de 1 s (±1 paso por redondeo)");
  comprobar(avanzar_rampa(12.0f, 8.0f, 10) == 8.0f, "bajada inmediata");
  // Referencia de sobretensión al bajar: baja 0,5 V/s
  comprobar(cerca(bajar_referencia(12.0f, 8.0f, 1000), 11.5f, 0.001f), "referencia baja despacio");
  comprobar(bajar_referencia(8.0f, 10.0f, 10) == 10.0f, "referencia sube al momento");
  printf("Fuente: %d bien, %d mal\n", ok, mal);
  return mal ? 1 : 0;
}
