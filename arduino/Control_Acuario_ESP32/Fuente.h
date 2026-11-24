// Fuente.h — cálculos de la fuente de luz de la placa Controlador de Acuario V1.0, sin
// dependencias de Arduino (se prueban en el PC con pruebas/test_fuente.cpp).
//
// Datos de la placa (repositorio Montaje_Electronico, revisión B y revisión final):
//  - Consigna del buck: VBUCK ≈ 23,86 − 6,09 × VDAC (relación INVERSA: DAC a 0 = tensión máxima).
//  - MCP4725 con referencia = su alimentación de 3,3 V (12 bits, 0..4095).
//  - Con la fuente de 24 V la salida alcanzable ronda 21–22 V: el software limita a 21 V.
//  - LED_V_ADC: divisor 100 kΩ / 8,2 kΩ → factor 13,2 (24 V → 1,82 V).
//  - LED_I_ADC: IMON del TPS26632, 27,9 µA/A sobre 6,8 kΩ → unos 0,19 V por amperio.
//  - Diseño: 4,7 A; el eFuse corta entre 4,85 y 5,58 A.
#pragma once
#include <stdint.h>
#include <math.h>

namespace Fuente {

// Límites de la tensión de las luces (V). El eFuse solo conecta por encima de unos 4,84 V.
const float TENSION_MIN = 5.0f;
const float TENSION_MAX = 21.0f;
const float TENSION_DEFECTO = 10.0f;   // tus dicroicas trabajan hoy a 10 V (documento de la placa)
const float TENSION_ARRANQUE = 6.0f;   // se enciende aquí, se comprueba y luego se sube en rampa
const float SUBIDA_V_POR_S = 4.0f;     // velocidad de la rampa de tensión (arranque suave)

// Frecuencia del PWM (Hz). 490 Hz = la del pin 3 del Mega (el pin 6 del Mega va a unos 980 Hz).
const uint16_t FRECUENCIA_MIN = 100, FRECUENCIA_MAX = 5000, FRECUENCIA_DEFECTO = 490;

// Corriente
const float CORRIENTE_MAX_A = 4.7f;    // por encima de esto durante 2 s: se apaga (aviso propio)

// Conversión
const float K_A = 23.86f, K_B = 6.09f, VREF_DAC = 3.3f;
const float DIVISOR_TENSION = 13.2f;
const float VOLTIOS_POR_AMPERIO = 0.1897f;
const uint16_t CODIGO_MIN_TENSION = 4095;   // DAC a 4095 = tensión mínima (~3,8 V: eFuse sin conectar)

inline float limitar(float v, float mn, float mx) {
  if (isnan(v)) return mn;
  return v < mn ? mn : (v > mx ? mx : v);
}

// Código del DAC para una tensión de salida. Nunca da una tensión por encima de TENSION_MAX.
inline uint16_t codigo_dac(float voltios) {
  float v = limitar(voltios, 0.0f, TENSION_MAX);
  float vdac = (K_A - v) / K_B;
  long c = lroundf(vdac / VREF_DAC * 4095.0f);
  long c_min = (long)ceilf(((K_A - TENSION_MAX) / K_B) / VREF_DAC * 4095.0f);  // hacia menos tensión
  if (c < c_min) c = c_min;
  if (c > 4095) c = 4095;
  return (uint16_t)c;
}

inline float tension_de_codigo(uint16_t c) {
  return K_A - K_B * ((float)c / 4095.0f * VREF_DAC);
}

inline float tension_de_adc(float milivoltios) { return milivoltios / 1000.0f * DIVISOR_TENSION; }
inline float corriente_de_adc(float milivoltios) { return milivoltios / 1000.0f / VOLTIOS_POR_AMPERIO; }

// Tolerancias: la tensión real puede diferir de la calculada (3,3 V del DevKit ±2 % → ±0,2 V,
// resistencias y error del ADC del ESP32). Margen = 10 % + 1 V.
inline float margen(float objetivo) { return objetivo * 0.10f + 1.0f; }
inline bool sobretension(float medida, float objetivo) { return medida > objetivo + margen(objetivo); }
inline bool tension_correcta(float medida, float objetivo) { return fabsf(medida - objetivo) <= margen(objetivo); }

inline bool tension_valida(float v) { return !isnan(v) && v >= TENSION_MIN && v <= TENSION_MAX; }
inline bool frecuencia_valida(long f) { return f >= FRECUENCIA_MIN && f <= FRECUENCIA_MAX; }

// Ciclo del PWM con 8 bits. 255 = siempre encendido, como analogWrite(255) en el Mega
// (el núcleo 3.x del ESP32 convierte el valor máximo en 100 %).
inline uint32_t ciclo_pwm(uint8_t nivel, bool continua) {
  if (continua) return nivel > 0 ? 255u : 0u;
  return nivel;
}

// Referencia para detectar sobretensión: al bajar la tensión, los condensadores de salida tardan en
// descargarse, así que la referencia baja despacio (0,5 V/s) en vez de saltar.
inline float bajar_referencia(float referencia, float ordenada, uint32_t ms) {
  if (ordenada >= referencia) return ordenada;
  float n = referencia - 0.5f * (float)ms / 1000.0f;
  return n < ordenada ? ordenada : n;
}

// Avanza la tensión ordenada hacia el objetivo a SUBIDA_V_POR_S (las bajadas son inmediatas).
inline float avanzar_rampa(float actual, float objetivo, uint32_t ms) {
  if (actual >= objetivo) return objetivo;
  float n = actual + SUBIDA_V_POR_S * (float)ms / 1000.0f;
  return n > objetivo ? objetivo : n;
}

// Estados y fallos (se publican en la app)
enum Estado : uint8_t { APAGADA = 0, COMPROBANDO = 1, SUBIENDO = 2, ENCENDIDA = 3, FALLO = 4 };
enum Fallo : uint8_t {
  SIN_FALLO = 0,
  FALLO_EFUSE = 1,        // LED_FAULT_N en bajo (sobrecorriente o cortocircuito: el eFuse se ha enclavado)
  FALLO_SOBRETENSION = 2, // la tensión medida supera la ordenada + margen
  FALLO_TENSION = 3,      // no se alcanza la tensión ordenada (o hay tensión con el eFuse apagado)
  FALLO_DAC = 4,          // el MCP4725 no responde por I²C
  FALLO_CORRIENTE = 5     // más de 4,7 A durante 2 s
};

}  // namespace Fuente
