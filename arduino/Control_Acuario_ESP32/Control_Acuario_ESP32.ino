// ============================================================================
//  CONTROL ACUARIO ESP32  (versión 3.0.0 de prueba)
//  Placa «Controlador de Acuario V1.0» · ESP32-DevKitC-32E · núcleo «esp32 by Espressif» 3.x
//  Bluetooth del ESP32 (nombre «Acuario», sin PIN) · DS18B20 (GPIO32) · DS3231 + MCP4725 (I²C)
//  SSR externos: bomba (GPIO16) y calentador (GPIO17), activos en alto
//  Fuente de luz: buck LM76005 con consigna por DAC + eFuse TPS26632 + PWM (TC4427 + MOSFET)
//
//  Basado en Control_Acuario_V2 (Mega). Misma lógica probada (Logica.h) y mismas variables V,
//  así que el proyecto «Acuario V2» de Acuaris funciona igual. Novedades:
//   - Fuente de luz con secuencia segura: DAC → BUCK_EN → LED_EN → comprobación → rampa → PWM,
//     y apagado inmediato si el eFuse avisa, hay sobretensión o no se alcanza la tensión.
//   - Intensidad de referencia (se guarda) e intensidad temporal (no se guarda; vuelve a la
//     referencia al empezar el amanecer y al reiniciar).
//   - Ajustes en la memoria NVS del ESP32 (Preferences).
//   - Igual que el V2 2.1.0: resumen del día y aviso de calentador sin efecto.
//
//  Librerías: VirtuinoCM 1.0.02, OneWire (2.3.8 o posterior), DallasTemperature,
//  RTClib (Adafruit). BluetoothSerial, Preferences y Wire vienen con el núcleo del ESP32.
// ============================================================================

#include <Wire.h>
#include <Preferences.h>
#include <BluetoothSerial.h>
#include <esp_task_wdt.h>
#include <esp_system.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "RTClib.h"
#include "VirtuinoCM.h"
#include "Logica.h"
#include "Fuente.h"

// ----------------------------------------------------------------------------- versión
const int VERSION_FIRMWARE = 300;   // 3.0.0  (se publica en V70)

// ----------------------------------------------------------------------------- pines de la placa
const uint8_t PIN_BOMBA = 16;        // SSR_PUMP_GPIO
const uint8_t PIN_CALENTADOR = 17;   // SSR_HEAT_GPIO
const uint8_t PIN_SONDA = 32;        // DS18B20
const uint8_t PIN_SDA = 21, PIN_SCL = 22;
const uint8_t PIN_LUZ_PWM = 33;      // LED_PWM → TC4427 → MOSFET Q1
const uint8_t PIN_BUCK_EN = 26;      // habilita el buck
const uint8_t PIN_LED_EN = 27;       // SHDN del eFuse (se rearma con 0 → 1)
const uint8_t PIN_LED_FALLO = 39;    // LED_FAULT_N (activo en bajo; solo entrada)
const uint8_t PIN_ADC_TENSION = 34;  // LED_V_ADC (×13,2)
const uint8_t PIN_ADC_CORRIENTE = 35; // LED_I_ADC (~0,19 V/A)
const uint8_t DIRECCION_DAC = 0x62;  // MCP4725A1

// La placa activa los SSR con nivel alto (etapa de 5 V por canal).
const uint8_t RELE_ON = HIGH;
const uint8_t RELE_OFF = LOW;

// ----------------------------------------------------------------------------- depuración
// true = mensajes por el USB a 115200 baudios. En uso normal, false.
const bool DEPURAR = false;

// ----------------------------------------------------------------------------- mapa de variables V
// Lecturas (iguales que en el V2)
const uint8_t V_HORA = 2, V_MIN = 3, V_SEG = 4;
const uint8_t V_TEMP = 5, V_TEMP_DEC = 35;
const uint8_t V_CALENTADOR_ON = 6, V_CALENTADOR_OFF = 7;
const uint8_t V_BOMBA = 8;
const uint8_t V_INTENSIDAD_VER = 10;   // intensidad de referencia (0..255)
const uint8_t V_LUZ_ACTUAL = 11;       // nivel que se aplica ahora mismo (0..255)
// Nuevas: intensidad temporal ("para jugar", no se guarda)
const uint8_t V_INTENSIDAD_TEMP = 12;  // escribir 0..255: cambia la luz al momento
const uint8_t V_VOLVER_REFERENCIA = 13; // escribir 1: vuelve a la referencia
// Mandos manuales (igual que antes)
const uint8_t V_BOMBA_MANUAL_ON = 15, V_LUCES_MAX = 16, V_BOMBA_MODO_MANUAL = 29;
// Ajustes que la app puede ESCRIBIR (se validan; si no son válidos se restaura el anterior)
const uint8_t V_CONSIGNA = 27;         // ºC (18..32)
const uint8_t V_INTENSIDAD = 28;       // referencia 0..255 (se guarda)
const uint8_t V_PONER_HORA = 44;       // HHMM
const uint8_t V_LUZ_ON = 50, V_LUZ_OFF = 51, V_RAMPA = 52;
const uint8_t V_BOMBA_ON = 53, V_BOMBA_OFF = 54;
const uint8_t V_HISTERESIS = 55;
const uint8_t V_ALARMA_ALTA = 57, V_ALARMA_BAJA = 58;
// Alarmas (1 = activa)
const uint8_t V_FALLO_SONDA = 60, V_TEMP_ALTA = 61, V_HORA_PERDIDA = 62, V_ESTADO = 63, V_TEMP_BAJA = 65;
const uint8_t V_ALARMA_LUZ = 66;       // nuevo: fallo de la fuente de luz
const uint8_t V_SIN_EFECTO = 64;       // calentador 60 min encendido sin que suba el agua (solo aviso)
// Diagnóstico
const uint8_t V_VERSION = 70, V_REINICIOS = 71, V_CAUSA_REINICIO = 72;
const uint8_t V_MIN_CALENTADOR_HOY = 73, V_MEMORIA_LIBRE = 74, V_MIN_ENCENDIDO = 75;
// Resumen de hoy (se pone a cero al cambiar de día)
const uint8_t V_TEMP_MIN_HOY = 76, V_HORA_MIN_HOY = 77, V_TEMP_MAX_HOY = 78, V_HORA_MAX_HOY = 79;   // ºC y HHMM
const uint8_t V_ENCENDIDOS_HOY = 90, V_MIN_LUZ_HOY = 91, V_MIN_BOMBA_HOY = 92;
// Fuente de luz (nuevas)
const uint8_t V_TENSION_LUZ = 80;      // ajuste: tensión de las luces (5..21 V, se guarda)
const uint8_t V_TENSION_MEDIDA = 81;   // V medidos en la salida
const uint8_t V_CORRIENTE = 82;        // A
const uint8_t V_POTENCIA = 83;         // W
const uint8_t V_ESTADO_FUENTE = 84;    // 0 apagada, 1 comprobando, 2 subiendo, 3 encendida, 4 fallo
const uint8_t V_FALLO_FUENTE = 85;     // 0 ninguno, 1 eFuse, 2 sobretensión, 3 tensión, 4 DAC, 5 corriente
const uint8_t V_REARME = 86;           // escribir 1: rearma la fuente tras un fallo
const uint8_t V_MODO_LUZ = 87;         // ajuste: 0 PWM (como hoy), 1 continua (encendido/apagado)
const uint8_t V_FRECUENCIA = 88;       // ajuste: Hz del PWM (100..5000, se guarda)
const uint8_t V_TENSION_ORDENADA = 89; // V que se está ordenando al buck ahora mismo

// ----------------------------------------------------------------------------- objetos
RTC_DS3231 rtc;
VirtuinoCM virtuino;
BluetoothSerial bt;
Preferences memoria;
OneWire bus_sonda(PIN_SONDA);
DallasTemperature sonda(&bus_sonda);

const int V_MEMORIA = 100;
float V[V_MEMORIA];

Ajustes ajustes;
// Ajustes de la fuente (se guardan aparte en la NVS)
float tension_luz = Fuente::TENSION_DEFECTO;
uint8_t modo_luz = 0;
uint16_t frecuencia_pwm = Fuente::FRECUENCIA_DEFECTO;

// Estado compartido entre pestañas
float temperatura = NAN;
bool fallo_sonda = false;
bool calentador = false;
bool hora_perdida = false;
long segundos_del_dia = 0;
uint8_t causa_reinicio = 0;   // 0 desconocida, 1 encendido, 2 reset, 3 caída de tensión, 4 watchdog, 5 fallo del programa, 6 por software
uint8_t intensidad_actual = 0; // la que se aplica (temporal o referencia)
uint8_t nivel_luz = 0;         // nivel calculado en Luces (0..255) que aplica Fuente

void setup() {
  // Salidas a su nivel seguro ANTES de nada. Las resistencias de la placa ya las mantienen
  // apagadas mientras el ESP32 arranca; aquí se fijan por software.
  digitalWrite(PIN_CALENTADOR, RELE_OFF);
  digitalWrite(PIN_BOMBA, RELE_OFF);
  digitalWrite(PIN_LED_EN, LOW);
  digitalWrite(PIN_BUCK_EN, LOW);
  pinMode(PIN_CALENTADOR, OUTPUT);
  pinMode(PIN_BOMBA, OUTPUT);
  pinMode(PIN_LED_EN, OUTPUT);
  pinMode(PIN_BUCK_EN, OUTPUT);
  pinMode(PIN_LED_FALLO, INPUT);       // GPIO39 no tiene resistencias internas

  switch (esp_reset_reason()) {
    case ESP_RST_POWERON: causa_reinicio = 1; break;
    case ESP_RST_EXT: causa_reinicio = 2; break;
    case ESP_RST_BROWNOUT: causa_reinicio = 3; break;
    case ESP_RST_INT_WDT:
    case ESP_RST_TASK_WDT:
    case ESP_RST_WDT: causa_reinicio = 4; break;
    case ESP_RST_PANIC: causa_reinicio = 5; break;
    case ESP_RST_SW: causa_reinicio = 6; break;
    default: causa_reinicio = 0; break;
  }

  if (DEPURAR) Serial.begin(115200);
  Wire.begin(PIN_SDA, PIN_SCL);

  for (int i = 0; i < V_MEMORIA; i++) V[i] = 0;
  virtuino.begin(alRecibir, alPedir, 256);

  ajustesIniciar();             // NVS -> ajustes (validados) y publica en V
  fuenteIniciar();              // DAC al mínimo, todo apagado, PWM a 0
  relojIniciar();
  temperaturaIniciar();

  bt.begin("Acuario");          // Bluetooth clásico (SPP), sin PIN
  bt.setTimeout(50);

  V[V_VERSION] = VERSION_FIRMWARE;
  V[V_CAUSA_REINICIO] = causa_reinicio;
  depurar("Control Acuario ESP32 arrancado");

  // Watchdog: si el programa se cuelga 8 s, el ESP32 se reinicia (y la placa apaga la luz).
  esp_task_wdt_config_t wdt = {};
  wdt.timeout_ms = 8000;
  wdt.idle_core_mask = 0;
  wdt.trigger_panic = true;
  if (esp_task_wdt_reconfigure(&wdt) != ESP_OK) esp_task_wdt_init(&wdt);
  esp_task_wdt_add(NULL);
}

void loop() {
  esp_task_wdt_reset();
  virtuinoRun();
  relojActualizar();            // segundos_del_dia, V2..V4, poner en hora
  ajustesRevisar();             // ¿la app ha escrito un ajuste?
  temperaturaActualizar();      // sonda sin bloqueo + calentador + alarmas
  virtuinoRun();
  bombaActualizar();
  lucesActualizar();            // nivel de luz (horario, manual, temporal)
  fuenteActualizar();           // secuencia y vigilancia de la fuente de luz
  diagnosticoActualizar();
}

void depurar(const char* t) {
  if (DEPURAR) Serial.println(t);
}
