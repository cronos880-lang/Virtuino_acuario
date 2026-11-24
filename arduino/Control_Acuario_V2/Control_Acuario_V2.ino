// ============================================================================
//  CONTROL ACUARIO V2  (versión 2.1.0 de prueba)
//  Arduino Mega 2560 · HC-05 (Serial1) · DS18B20 (pin 8) · DS3231 (I2C)
//  Relés de estado sólido: calentador (pin 2) y bomba (pin 4)
//  MOSFET IRLZ44N de las luces: PWM en pines 3 y 6
//
//  Basado en Control_Acuario_01_09_2026_Final (que sigue siendo la versión de vuelta atrás).
//  Cambios principales (ver LEEME.md):
//   - Si la sonda falla 15 s, el calentador se APAGA y salta una alarma.
//   - Lectura del DS18B20 sin bloquear el programa (el Bluetooth responde siempre).
//   - Sin menú bloqueante: consigna, intensidad, hora y horarios se escriben directamente
//     desde la app y se validan y guardan sin parar el control.
//   - Ajustes en la EEPROM con comprobación (y recuperación de los del sketch anterior).
//   - Amanecer y atardecer suaves (por segundos), horarios configurables.
//   - Watchdog desactivado al arrancar (avr-libc, sección .init3) y causa del reinicio.
//   - Alarmas y diagnóstico visibles en la app.
//  2.1.0: intensidad temporal V12 (no se guarda; vuelve a la referencia al amanecer), resumen del
//         día (mín./máx. de temperatura, calentador, luz y bomba) y aviso de calentador sin efecto.
//
//  Librerías: VirtuinoCM 1.0.02, OneWire, DallasTemperature, RTClib (Adafruit), EEPROM.
// ============================================================================

#include <Wire.h>
#include <EEPROM.h>
#include <avr/wdt.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "RTClib.h"
#include "VirtuinoCM.h"
#include "Logica.h"

// ----------------------------------------------------------------------------- versión
const int VERSION_FIRMWARE = 210;   // 2.1.0  (se publica en V70)

// ----------------------------------------------------------------------------- pines
const uint8_t PIN_CALENTADOR = 2;
const uint8_t PIN_LUZ_A = 3;        // PWM
const uint8_t PIN_BOMBA = 4;
const uint8_t PIN_LUZ_B = 6;        // PWM
const uint8_t PIN_SONDA = 8;        // OneWire
const uint8_t PIN_LUZ_NOCHE = 12;   // reservado (apagado)
const uint8_t PIN_LED = 13;         // latido: parpadea si el programa está vivo

// Nivel que ENCIENDE los relés. El sketch anterior usaba HIGH y funciona en tu montaje.
// Si algún día cambias a un módulo que se activa con nivel bajo, pon LOW aquí.
const uint8_t RELE_ON = HIGH;
const uint8_t RELE_OFF = (RELE_ON == HIGH) ? LOW : HIGH;

// ----------------------------------------------------------------------------- depuración
// true = mensajes por el USB a 115200 baudios. En uso normal, false.
const bool DEPURAR = false;

// ----------------------------------------------------------------------------- mapa de variables V
// Lecturas (compatibles con el panel actual del acuario)
const uint8_t V_HORA = 2, V_MIN = 3, V_SEG = 4;
const uint8_t V_TEMP = 5, V_TEMP_DEC = 35;
const uint8_t V_CALENTADOR_ON = 6, V_CALENTADOR_OFF = 7;
const uint8_t V_BOMBA = 8;
const uint8_t V_INTENSIDAD_VER = 10;   // intensidad configurada (0..255)
const uint8_t V_LUZ_ACTUAL = 11;       // PWM que se aplica ahora mismo (0..255)
// Intensidad temporal ("para jugar"): NO se guarda; vuelve a la referencia al empezar el amanecer
const uint8_t V_INTENSIDAD_TEMP = 12;  // escribir 0..255: cambia la luz al momento
const uint8_t V_VOLVER_REFERENCIA = 13; // escribir 1: vuelve a la referencia (V28)
// Mandos manuales (igual que antes)
const uint8_t V_BOMBA_MANUAL_ON = 15, V_LUCES_MAX = 16, V_BOMBA_MODO_MANUAL = 29;
// Ajustes que la app puede ESCRIBIR (se validan; si no son válidos se restaura el anterior)
const uint8_t V_CONSIGNA = 27;         // ºC (18..32)
const uint8_t V_INTENSIDAD = 28;       // referencia 0..255 (la única que se guarda)
const uint8_t V_PONER_HORA = 44;       // HHMM: escribir 1630 pone el reloj a las 16:30:00
const uint8_t V_LUZ_ON = 50, V_LUZ_OFF = 51, V_RAMPA = 52;      // HHMM, HHMM, minutos
const uint8_t V_BOMBA_ON = 53, V_BOMBA_OFF = 54;                // HHMM, HHMM
const uint8_t V_HISTERESIS = 55;       // ºC (0,1..2)
const uint8_t V_ALARMA_ALTA = 57, V_ALARMA_BAJA = 58;           // ºC
// Alarmas (1 = activa)
const uint8_t V_FALLO_SONDA = 60, V_TEMP_ALTA = 61, V_HORA_PERDIDA = 62, V_ESTADO = 63, V_TEMP_BAJA = 65;
const uint8_t V_SIN_EFECTO = 64;       // calentador 60 min encendido sin que suba el agua (solo aviso)
// Diagnóstico
const uint8_t V_VERSION = 70, V_REINICIOS = 71, V_CAUSA_REINICIO = 72;
const uint8_t V_MIN_CALENTADOR_HOY = 73, V_MEMORIA_LIBRE = 74, V_MIN_ENCENDIDO = 75;
// Resumen de hoy (se pone a cero al cambiar de día)
const uint8_t V_TEMP_MIN_HOY = 76, V_HORA_MIN_HOY = 77, V_TEMP_MAX_HOY = 78, V_HORA_MAX_HOY = 79;   // ºC y HHMM
const uint8_t V_ENCENDIDOS_HOY = 90, V_MIN_LUZ_HOY = 91, V_MIN_BOMBA_HOY = 92;

// ----------------------------------------------------------------------------- objetos
RTC_DS3231 rtc;
VirtuinoCM virtuino;
OneWire bus_sonda(PIN_SONDA);
DallasTemperature sonda(&bus_sonda);

const int V_MEMORIA = 100;   // variables V0..V99 (suficiente; ahorra RAM frente a 256)
float V[V_MEMORIA];

Ajustes ajustes;

// Estado compartido entre pestañas
float temperatura = NAN;          // última lectura válida
bool fallo_sonda = false;
bool calentador = false;
bool hora_perdida = false;
long segundos_del_dia = 0;
uint8_t intensidad_actual = 0;    // la que se aplica: temporal (V12) o la referencia
uint8_t causa_reinicio = 0;       // 0 desconocida, 1 encendido, 2 reset externo, 3 caída de tensión, 4 watchdog

// ----------------------------------------------------------------------------- watchdog al arrancar
// Tras un reinicio por watchdog, el watchdog SIGUE activo con el tiempo mínimo: hay que
// desactivarlo antes de nada (método recomendado por avr-libc, sección .init3).
uint8_t copia_mcusr __attribute__((section(".noinit")));
#if defined(__AVR__)
void leer_mcusr(void) __attribute__((naked, used, section(".init3")));
void leer_mcusr(void) {
  copia_mcusr = MCUSR;
  MCUSR = 0;
  wdt_disable();
}
#endif

void setup() {
  // Salidas a su nivel seguro ANTES de configurarlas (sin pulsos al arrancar)
  digitalWrite(PIN_CALENTADOR, RELE_OFF);
  digitalWrite(PIN_BOMBA, RELE_OFF);
  digitalWrite(PIN_LUZ_NOCHE, LOW);
  pinMode(PIN_CALENTADOR, OUTPUT);
  pinMode(PIN_BOMBA, OUTPUT);
  pinMode(PIN_LUZ_NOCHE, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  analogWrite(PIN_LUZ_A, 0);
  analogWrite(PIN_LUZ_B, 0);

  if (copia_mcusr & _BV(WDRF)) causa_reinicio = 4;
  else if (copia_mcusr & _BV(BORF)) causa_reinicio = 3;
  else if (copia_mcusr & _BV(EXTRF)) causa_reinicio = 2;
  else if (copia_mcusr & _BV(PORF)) causa_reinicio = 1;

  if (DEPURAR) Serial.begin(115200);
  Serial1.begin(9600);          // HC-05
  Serial1.setTimeout(50);
  Wire.begin();

  for (int i = 0; i < V_MEMORIA; i++) V[i] = 0;
  virtuino.begin(alRecibir, alPedir, 256);

  ajustesIniciar();             // EEPROM -> ajustes (validados) y publica en V
  relojIniciar();
  temperaturaIniciar();

  V[V_VERSION] = VERSION_FIRMWARE;
  V[V_CAUSA_REINICIO] = causa_reinicio;
  depurar(F("Control Acuario V2 arrancado"));
  wdt_enable(WDTO_8S);
}

void loop() {
  wdt_reset();
  virtuinoRun();
  relojActualizar();            // segundos_del_dia, V2..V4, poner en hora
  ajustesRevisar();             // ¿la app ha escrito un ajuste?
  temperaturaActualizar();      // sonda sin bloqueo + calentador + alarmas
  virtuinoRun();
  bombaActualizar();
  lucesActualizar();
  diagnosticoActualizar();
}

void depurar(const __FlashStringHelper* t) {
  if (DEPURAR) Serial.println(t);
}
