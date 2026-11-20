// Logica.h — decisiones del controlador del acuario, sin dependencias de Arduino.
// Se usa desde el sketch y desde las pruebas nativas (pruebas/test_logica.cpp).
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <math.h>

// Ajustes guardados en la EEPROM (con número mágico y suma de comprobación).
struct Ajustes {
  uint16_t magia;       // MAGIA_AJUSTES si el bloque es de esta versión
  uint8_t version;      // VERSION_AJUSTES
  float consigna;       // ºC
  float histeresis;     // ºC (a cada lado de la consigna)
  float alarma_alta;    // ºC
  float alarma_baja;    // ºC
  uint8_t intensidad;   // 0..255 (PWM máximo de las luces)
  uint16_t luz_on;      // HHMM
  uint16_t luz_off;     // HHMM
  uint8_t rampa_min;    // minutos de amanecer y de atardecer (0..60)
  uint16_t bomba_on;    // HHMM
  uint16_t bomba_off;   // HHMM
  uint16_t reinicios;   // contador de arranques
  uint8_t suma;         // suma de comprobación del resto
};

namespace Logica {

const uint16_t MAGIA_AJUSTES = 0xAC02;
const uint8_t VERSION_AJUSTES = 1;

// Límites de seguridad de cada ajuste
const float CONSIGNA_MIN = 18.0f, CONSIGNA_MAX = 32.0f;
const float HIST_MIN = 0.1f, HIST_MAX = 2.0f;
const float ALARMA_MIN = 5.0f, ALARMA_MAX = 40.0f;
const uint8_t RAMPA_MAX = 60;

// Sonda DS18B20
const float TEMP_VALIDA_MIN = 0.0f, TEMP_VALIDA_MAX = 45.0f;
const float SALTO_SOSPECHOSO = 3.0f;           // ºC entre lecturas seguidas
// Tiempos en milisegundos como uint32_t: igual que millis() en el Arduino (32 bits) también en
// las pruebas del PC, para reproducir el desbordamiento de millis() a los 49,7 días.
const uint32_t FALLO_SONDA_MS = 15000UL;  // sin lectura válida -> calentador apagado
const uint32_t RELE_MIN_MS = 180000UL;    // 3 min entre cambios del calentador

inline bool hhmm_valido(long v) {
  return v >= 0 && v <= 2359 && (v % 100) < 60;
}

inline long segundos_de(uint16_t hhmm) {
  return (long)(hhmm / 100) * 3600L + (long)(hhmm % 100) * 60L;
}

// ¿Está "seg" (segundos del día) dentro de [inicio, fin)? Admite cruzar la medianoche.
inline bool en_horario(long seg, uint16_t inicio, uint16_t fin) {
  long a = segundos_de(inicio), b = segundos_de(fin);
  if (a == b) return false;
  if (a < b) return seg >= a && seg < b;
  return seg >= a || seg < b;
}

// Nivel de luz (0..maximo) con amanecer y atardecer lineales, calculado por segundos.
inline uint8_t nivel_luz(long seg, uint16_t on, uint16_t off, uint8_t rampa_min, uint8_t maximo) {
  if (!en_horario(seg, on, off)) return 0;
  const long dia = 86400L;
  long a = segundos_de(on), b = segundos_de(off);
  long desde_on = ((seg - a) % dia + dia) % dia;
  long hasta_off = ((b - seg) % dia + dia) % dia;
  long rampa = (long)rampa_min * 60L;
  long duracion = ((b - a) % dia + dia) % dia;
  if (rampa * 2 > duracion) rampa = duracion / 2;   // periodos muy cortos
  if (rampa <= 0) return maximo;
  long nivel = maximo;
  if (desde_on < rampa) nivel = (long)maximo * desde_on / rampa;
  if (hasta_off < rampa) {
    long baja = (long)maximo * hasta_off / rampa;
    if (baja < nivel) nivel = baja;
  }
  if (nivel < 0) nivel = 0;
  if (nivel > maximo) nivel = maximo;
  return (uint8_t)nivel;
}

inline bool lectura_valida(float t) {
  if (isnan(t)) return false;
  if (t <= -127.0f + 0.01f) return false;       // DEVICE_DISCONNECTED_C
  if (fabsf(t - 85.0f) < 0.001f) return false;  // valor de encendido del DS18B20
  return t >= TEMP_VALIDA_MIN && t <= TEMP_VALIDA_MAX;
}

// Termostato con histéresis y tiempo mínimo entre cambios del relé.
// Devuelve el estado nuevo del calentador. "libre" = aún no ha habido ningún cambio (permite
// actuar justo después de arrancar en vez de esperar 3 minutos).
inline bool decidir_calentador(bool actual, float temp, float consigna, float hist,
                               uint32_t ahora, uint32_t ultimo_cambio, bool libre) {
  if (!libre && (uint32_t)(ahora - ultimo_cambio) < RELE_MIN_MS) return actual;
  if (actual && temp >= consigna + hist) return false;
  if (!actual && temp <= consigna - hist) return true;
  return actual;
}

inline uint8_t calcular_suma(const Ajustes& a) {
  const uint8_t* p = (const uint8_t*)&a;
  uint8_t s = 0x5A;
  for (size_t i = 0; i < offsetof(Ajustes, suma); i++) s = (uint8_t)((s << 1) | (s >> 7)) ^ p[i];
  return s;
}

inline void por_defecto(Ajustes& a) {
  a.magia = MAGIA_AJUSTES;
  a.version = VERSION_AJUSTES;
  a.consigna = 25.0f;
  a.histeresis = 0.2f;
  a.alarma_alta = 29.0f;
  a.alarma_baja = 21.0f;
  a.intensidad = 125;
  a.luz_on = 1600;
  a.luz_off = 2200;
  a.rampa_min = 15;
  a.bomba_on = 1500;
  a.bomba_off = 2200;
  a.reinicios = 0;
  a.suma = calcular_suma(a);
}

inline bool en_rango(float v, float mn, float mx) {
  return !isnan(v) && v >= mn && v <= mx;
}

// Corrige cualquier campo fuera de rango. Devuelve true si todo estaba bien.
inline bool sanear(Ajustes& a) {
  Ajustes d;
  por_defecto(d);
  bool ok = true;
  if (!en_rango(a.consigna, CONSIGNA_MIN, CONSIGNA_MAX)) { a.consigna = d.consigna; ok = false; }
  if (!en_rango(a.histeresis, HIST_MIN, HIST_MAX)) { a.histeresis = d.histeresis; ok = false; }
  if (!en_rango(a.alarma_alta, ALARMA_MIN, ALARMA_MAX)) { a.alarma_alta = d.alarma_alta; ok = false; }
  if (!en_rango(a.alarma_baja, ALARMA_MIN, ALARMA_MAX)) { a.alarma_baja = d.alarma_baja; ok = false; }
  if (a.alarma_baja >= a.alarma_alta) { a.alarma_baja = d.alarma_baja; a.alarma_alta = d.alarma_alta; ok = false; }
  if (!hhmm_valido(a.luz_on)) { a.luz_on = d.luz_on; ok = false; }
  if (!hhmm_valido(a.luz_off)) { a.luz_off = d.luz_off; ok = false; }
  if (a.rampa_min > RAMPA_MAX) { a.rampa_min = d.rampa_min; ok = false; }
  if (!hhmm_valido(a.bomba_on)) { a.bomba_on = d.bomba_on; ok = false; }
  if (!hhmm_valido(a.bomba_off)) { a.bomba_off = d.bomba_off; ok = false; }
  a.magia = MAGIA_AJUSTES;
  a.version = VERSION_AJUSTES;
  a.suma = calcular_suma(a);
  return ok;
}

// Estado general para la app: 0 OK, 1 temperatura alta, 2 temperatura baja, 3 fallo de sonda,
// 4 hora perdida (la sonda tiene prioridad: es lo más peligroso).
inline uint8_t codigo_estado(bool fallo_sonda, bool alta, bool baja, bool hora_perdida) {
  if (fallo_sonda) return 3;
  if (alta) return 1;
  if (baja) return 2;
  if (hora_perdida) return 4;
  return 0;
}

}  // namespace Logica
