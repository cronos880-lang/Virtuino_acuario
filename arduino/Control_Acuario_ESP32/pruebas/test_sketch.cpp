// Ejecuta el sketch Control_Acuario_ESP32 REAL en el PC con imitaciones de las librerías y un
// modelo sencillo de la placa (DAC → buck → eFuse → ADC). Uso: ./test_sketch <escenario>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>
#include <map>
#include "Arduino.h"
#include "Wire.h"
#include "Preferences.h"
#include "BluetoothSerial.h"
#include "esp_task_wdt.h"
#include "esp_system.h"
#include "DallasTemperature.h"
#include "RTClib.h"
#include "../Fuente.h"

uint32_t g_millis = 0;
uint8_t g_pin[80];
int g_pwm[80];
SerialPrueba Serial, Serial1;
TwoWire Wire;
EspPrueba ESP;
std::vector<std::string> g_eventos;
uint32_t g_pwm_ciclo = 0, g_pwm_frec = 0;
bool g_dac_presente = true;
uint16_t g_dac = 2048, g_dac_eeprom = 2048;   // MCP4725 de fábrica: 2048 (mitad)
int g_dac_grabaciones = 0;
std::map<std::string, std::vector<uint8_t>> g_nvs;
int g_nvs_escrituras = 0;
int g_wdt_reinicios = 0;
esp_reset_reason_t g_causa = ESP_RST_POWERON;
float g_temp_agua = 24.5f;
bool g_sonda_conectada = true;
int g_peticiones_temp = 0;
long g_rtc_base = 16 * 3600L + 30 * 60L;
uint32_t g_rtc_millis_base = 0;
bool g_rtc_presente = true, g_rtc_perdio = false;

// Modelo de la placa
float g_error_buck = 1.0f;     // 1 = el buck da lo calculado; 1,5 = sobretensión; 0 = no da tensión
float g_carga_a = 3.0f;        // corriente con PWM al 100 %
float salida_v() { return (g_pin[26] && g_pin[27]) ? Fuente::tension_de_codigo(g_dac) * g_error_buck : 0.0f; }
uint32_t analogReadMilliVolts(uint8_t pin) {
  if (pin == 34) return (uint32_t)(salida_v() / 13.2f * 1000.0f);
  if (pin == 35) return (uint32_t)(g_carga_a * (g_pwm_ciclo / 255.0f) * (salida_v() > 1 ? 1 : 0) * 0.1897f * 1000.0f);
  return 0;
}

#include "sketch_combinado.cpp"

static int ok = 0, fallos = 0;
#define COMPROBAR(c, txt) do { if (c) ok++; else { fallos++; std::printf("  FALLO: %s (linea %d)\n", txt, __LINE__); } } while (0)

// Vigilancia de la secuencia en cada paso
static float v_max = 0; static bool orden_ok = true; static bool pwm_antes_de_tiempo = false;
static uint8_t buck_prev = 0, led_prev = 0;
static void vigilar() {
  float v = salida_v(); if (v > v_max) v_max = v;
  if (g_pin[26] && !buck_prev && Fuente::tension_de_codigo(g_dac) > 6.05f) orden_ok = false;   // buck con DAC alto
  if (g_pin[27] && !led_prev && !g_pin[26]) orden_ok = false;                                  // eFuse sin buck
  if (g_pwm_ciclo > 0 && estado_fuente != Fuente::ENCENDIDA && !(estado_fuente == Fuente::SUBIENDO && modo_luz == 1)) pwm_antes_de_tiempo = true;
  buck_prev = g_pin[26]; led_prev = g_pin[27];
}
static void correr(uint32_t ms) { uint32_t fin = g_millis + ms; while (g_millis < fin) { loop(); vigilar(); g_millis += 5; } }
static std::string pedir(const char* cmd, uint32_t ms = 50) {
  bt.salida.clear();
  for (const char* p = cmd; *p; p++) bt.entrada.push_back(*p);
  correr(ms);
  return bt.salida;
}
static void hora(int h, int m, int s = 0) { g_rtc_base = h * 3600L + m * 60L + s; g_rtc_millis_base = g_millis; }
static bool todo_apagado() { return g_pwm_ciclo == 0 && !g_pin[27] && !g_pin[26] && g_dac == 4095; }

int main(int argc, char** argv) {
  std::string e = argc > 1 ? argv[1] : "";
  g_pin[39] = HIGH;   // LED_FAULT_N en reposo (resistencia a 3,3 V en la placa)
  std::printf("[%s]\n", e.c_str());
  if (e == "arranque") {
    hora(23, 0);
    setup(); correr(100);
    COMPROBAR(V[27] == 25.0f && V[28] == 125 && V[80] == 10.0f && V[87] == 0 && V[88] == 490, "NVS vacía: valores por defecto");
    COMPROBAR(V[70] == 300 && V[71] == 1 && V[72] == 1, "versión, arranques y causa");
    COMPROBAR(g_dac_eeprom == 4095 && g_dac_grabaciones == 1, "EEPROM del DAC grabada a 4095 una vez");
    COMPROBAR(todo_apagado() && V[84] == 0, "de noche: fuente apagada");
    COMPROBAR(g_pin[16] == LOW && g_pin[17] == LOW, "relés apagados");
    COMPROBAR(bt.nombre == "Acuario", "Bluetooth «Acuario»");
    setup();
    COMPROBAR(g_dac_grabaciones == 1 && V[71] == 2, "2.º arranque: no regraba el DAC; arranques = 2");
  } else if (e == "secuencia") {
    setup(); correr(3000);
    COMPROBAR(orden_ok, "orden DAC → BUCK_EN → LED_EN respetado");
    COMPROBAR(!pwm_antes_de_tiempo, "PWM a 0 hasta terminar la rampa");
    COMPROBAR(V[84] == 3 && V[85] == 0, "fuente encendida sin fallo");
    COMPROBAR(V[89] == 10.0f && v_max <= 10.05f, "tensión 10 V sin pasarse");
    COMPROBAR(g_pwm_ciclo == 125 && V[11] == 125 && g_pwm_frec == 490, "PWM 125 a 490 Hz");
    COMPROBAR(V[81] > 9.5f && V[81] < 10.5f, "tensión medida publicada");
    correr(2000);
    COMPROBAR(V[82] > 1.2f && V[82] < 1.8f && V[83] > 10, "corriente (~1,5 A al 49 %) y potencia");
  } else if (e == "sobretension") {
    setup(); correr(3000);
    g_error_buck = 1.5f; correr(300);
    COMPROBAR(V[84] == 4 && V[85] == 2 && V[66] == 1 && todo_apagado(), "sobretensión: todo apagado y aviso");
    correr(5000);
    COMPROBAR(todo_apagado(), "queda bloqueada sin rearme");
    g_error_buck = 1.0f; pedir("!V86=1$"); correr(3000);
    COMPROBAR(V[84] == 3 && V[85] == 0 && V[66] == 0, "rearme desde la app");
  } else if (e == "efuse") {
    setup(); correr(3000);
    g_pin[39] = LOW; correr(20);
    COMPROBAR(V[84] == 4 && V[85] == 1 && todo_apagado(), "LED_FAULT_N: apagado en < 20 ms");
    g_pin[39] = HIGH; pedir("!V86=1$"); correr(3000);
    COMPROBAR(V[84] == 3, "rearme del eFuse");
  } else if (e == "sin_tension") {
    g_error_buck = 0; setup(); correr(3000);
    COMPROBAR(V[84] == 4 && V[85] == 3 && todo_apagado() && !pwm_antes_de_tiempo, "no llega tensión: fallo sin aplicar PWM");
  } else if (e == "sin_dac") {
    g_dac_presente = false; setup(); correr(3000);
    COMPROBAR(V[84] == 4 && V[85] == 4 && !g_pin[26] && !g_pin[27], "sin DAC: el buck no se habilita nunca");
  } else if (e == "temporal") {
    setup(); correr(3000);
    pedir("!V12=40$"); correr(100);
    COMPROBAR(g_pwm_ciclo == 40 && V[10] == 125, "intensidad temporal aplicada; referencia intacta");
    correr(3000);
    Ajustes a; memoria.getBytes("ajustes", &a, sizeof a);
    COMPROBAR(a.intensidad == 125, "la temporal no se guarda");
    pedir("!V13=1$"); correr(100);
    COMPROBAR(g_pwm_ciclo == 125 && V[12] == 125, "V13 = volver a la referencia");
    pedir("!V12=60$"); hora(21, 59, 50); correr(15000);     // atardecer y noche
    hora(15, 59, 58); correr(4000);                          // nuevo amanecer
    COMPROBAR(V[12] == 125, "al empezar el amanecer vuelve a la referencia");
    pedir("!V28=200$"); correr(3000);
    memoria.getBytes("ajustes", &a, sizeof a);
    COMPROBAR(V[12] == 200 && a.intensidad == 200, "nueva referencia: se guarda y se aplica");
  } else if (e == "noche") {
    setup(); correr(3000);
    hora(21, 59, 58); correr(5000);
    COMPROBAR(V[84] == 3 && g_pwm_ciclo == 0, "a las 22:00 PWM 0, fuente aún encendida");
    correr(30000);
    COMPROBAR(V[84] == 0 && todo_apagado(), "30 s después: todo apagado");
  } else if (e == "continua") {
    g_nvs.clear(); setup(); pedir("!V87=1$"); correr(3000);
    COMPROBAR(V[84] == 3 && g_pwm_ciclo == 255 && V[11] == 255, "modo continua: 100 %");
  } else if (e == "ajustes") {
    setup(); correr(3000);
    pedir("!V80=30$"); correr(100);
    COMPROBAR(V[80] == 10.0f && V[89] == 10.0f, "30 V rechazado");
    pedir("!V80=12$"); correr(200);
    COMPROBAR(V[89] > 10.0f && V[89] < 12.0f, "sube en rampa");
    correr(1000);
    COMPROBAR(V[89] == 12.0f && V[84] == 3, "llega a 12 V sin fallo");
    pedir("!V80=9$"); correr(3000);
    COMPROBAR(V[89] == 9.0f && V[84] == 3, "bajar a 9 V no da falsa sobretensión");
    pedir("!V88=1000$"); correr(2500);
    COMPROBAR(g_pwm_frec == 1000 && memoria.getFloat("tension", 0) == 9.0f && memoria.getUShort("frec", 0) == 1000, "frecuencia y tensión guardadas");
    pedir("!V88=20$"); correr(100);
    COMPROBAR(V[88] == 1000, "frecuencia no válida rechazada");
    setup();
    COMPROBAR(V[80] == 9.0f && V[88] == 1000 && V[12] == V[28], "tras reiniciar: ajustes guardados y temporal = referencia");
  } else if (e == "termostato") {
    setup(); g_temp_agua = 23.0f; correr(3000);
    COMPROBAR(g_pin[17] == HIGH && V[6] == 1, "agua fría: calentador (GPIO17) encendido");
    g_sonda_conectada = false; correr(16000);
    COMPROBAR(g_pin[17] == LOW && V[60] == 1, "sonda desconectada: calentador apagado y alarma");
    COMPROBAR(g_pin[16] == HIGH && V[8] == 1, "bomba (GPIO16) por horario");
  } else if (e == "bluetooth") {
    setup(); correr(100);
    COMPROBAR(pedir("!V70=?$") == "!V70=300.00$", "lectura por Bluetooth");
    COMPROBAR(pedir("!C00=?$").rfind("!C=VirtuinoCM", 0) == 0, "saludo VirtuinoCM");
    COMPROBAR(g_wdt_reinicios > 0, "watchdog atendido");
  } else {
    std::printf("escenario desconocido\n"); return 2;
  }
  std::printf("  %d bien, %d mal\n", ok, fallos);
  return fallos ? 1 : 0;
}
