// Ejecuta el sketch Control_Acuario_V2 REAL en el PC con imitaciones de las librerías de Arduino.
// Uso: ./test_sketch <escenario>    (lo lanza ejecutar_pruebas.sh con todos los escenarios)
#include <cstdio>
#include <cstring>
#include <string>
#include "Arduino.h"
#include "Wire.h"
#include "EEPROM.h"
#include "avr/wdt.h"
#include "DallasTemperature.h"
#include "RTClib.h"

uint32_t g_millis = 0;
uint8_t g_pin[80];
int g_pwm[80];
int g_wdt_activo = 0;
SerialPrueba Serial, Serial1;
TwoWire Wire;
EEPROMPrueba EEPROM;
float g_temp_agua = 24.5f;
bool g_sonda_conectada = true;
int g_peticiones_temp = 0;
long g_rtc_base = 15 * 3600L + 30 * 60L;
uint32_t g_rtc_millis_base = 0;
bool g_rtc_presente = true, g_rtc_perdio = false;
uint8_t MCUSR = 0;
char __heap_start;          // símbolos de avr-libc que usa memoriaLibre()
char* __brkval = nullptr;

#include "sketch_combinado.cpp"

static int ok = 0, fallos = 0;
#define COMPROBAR(c, txt) do { if (c) ok++; else { fallos++; std::printf("  FALLO: %s (linea %d)\n", txt, __LINE__); } } while (0)

static void correr(uint32_t ms) {          // pasos de 5 ms, como un loop() rápido
  uint32_t fin = g_millis + ms;
  while (g_millis < fin) { loop(); g_millis += 5; }
}

static std::string pedir(const char* cmd, uint32_t ms = 50) {   // envía y recoge la respuesta
  Serial1.salida.clear();
  for (const char* p = cmd; *p; p++) Serial1.entrada.push_back(*p);
  correr(ms);
  return Serial1.salida;
}

static void hora(int h, int m, int s = 0) { g_rtc_base = h * 3600L + m * 60L + s; g_rtc_millis_base = g_millis; }

static void arrancar() { std::memset(EEPROM.mem, 0xFF, sizeof EEPROM.mem); setup(); }

int main(int argc, char** argv) {
  std::string e = argc > 1 ? argv[1] : "";
  if (e == "eeprom_vacia") {
    arrancar();
    COMPROBAR(V[27] == 25.0f && V[28] == 125 && V[50] == 1600 && V[53] == 1500, "EEPROM vacía: valores por defecto seguros");
    COMPROBAR(V[71] == 1 && V[70] == 200, "contador de reinicios y versión");
    Ajustes a; EEPROM.get(32, a);
    COMPROBAR(a.magia == Logica::MAGIA_AJUSTES && a.suma == Logica::calcular_suma(a), "bloque de ajustes guardado con comprobación");
    COMPROBAR(g_pin[2] == LOW && g_pin[4] == LOW, "relés apagados al arrancar");
  } else if (e == "migracion") {
    std::memset(EEPROM.mem, 0xFF, sizeof EEPROM.mem);
    int lumen = 200; float consigna = 26.5f;          // como los guardaba el sketch anterior
    EEPROM.put(0, lumen); EEPROM.put(2, consigna);
    setup();
    COMPROBAR(V[28] == 200 && V[27] == 26.5f, "recupera intensidad y consigna del sketch anterior");
  } else if (e == "termostato") {
    g_temp_agua = 24.5f; arrancar(); correr(2000);
    COMPROBAR(g_pin[2] == HIGH && V[6] == 1 && V[7] == 0, "agua fría: calentador encendido al poco de arrancar");
    g_temp_agua = 25.3f; correr(60000);
    COMPROBAR(g_pin[2] == HIGH, "respeta los 3 min mínimos del relé");
    correr(125000);
    COMPROBAR(g_pin[2] == LOW, "apaga al superar consigna + histéresis pasados 3 min");
    g_temp_agua = 25.1f; correr(200000);
    COMPROBAR(g_pin[2] == LOW, "dentro de la histéresis no cambia");
  } else if (e == "sonda") {
    g_temp_agua = 24.0f; arrancar(); correr(2000);
    COMPROBAR(g_pin[2] == HIGH, "calentador encendido antes del fallo");
    g_sonda_conectada = false; correr(10000);
    COMPROBAR(g_pin[2] == HIGH && V[60] == 0, "a los 10 s sin sonda aún no actúa");
    correr(7000);
    COMPROBAR(g_pin[2] == LOW, "FALLO DE SONDA: calentador APAGADO");
    COMPROBAR(V[60] == 1 && V[63] == 3, "alarma de sonda y código de estado 3");
    g_sonda_conectada = true; correr(3000);
    COMPROBAR(V[60] == 0, "al volver la sonda se quita la alarma");
  } else if (e == "salto") {
    g_temp_agua = 25.0f; arrancar(); correr(3000);
    g_temp_agua = 31.0f; correr(1000);
    COMPROBAR(V[35] == 25.0f, "un salto brusco se ignora hasta confirmarlo");
    correr(1100);
    COMPROBAR(V[35] == 31.0f, "si se repite, se acepta");
  } else if (e == "bluetooth") {
    arrancar(); correr(1500);
    std::string r = pedir("!V35=?$");
    COMPROBAR(r == "!V35=24.50$", "responde a la lectura con el formato de VirtuinoCM");
    int sin_respuesta = 0;
    for (int i = 0; i < 40; i++) { if (pedir("!V02=?$", 20).find("!V2=") == std::string::npos) sin_respuesta++; }
    COMPROBAR(sin_respuesta == 0, "responde en menos de 20 ms siempre (la sonda no bloquea)");
    COMPROBAR(pedir("!V05=?$").find("!V5=24.50$") != std::string::npos, "V5 también con la temperatura");
  } else if (e == "ajustes") {
    arrancar(); correr(500);
    pedir("!V27=26.5$");
    COMPROBAR(V[27] == 26.5f && ajustes.consigna == 26.5f, "consigna aceptada");
    int antes = EEPROM.escrituras; correr(1000);
    COMPROBAR(EEPROM.escrituras == antes, "no guarda al instante (espera 2 s)");
    correr(1500);
    Ajustes a; EEPROM.get(32, a);
    COMPROBAR(a.consigna == 26.5f && EEPROM.escrituras > antes, "consigna guardada en la EEPROM");
    pedir("!V27=99$");
    COMPROBAR(V[27] == 26.5f && ajustes.consigna == 26.5f, "consigna absurda rechazada y restaurada");
    pedir("!V50=1730$");
    COMPROBAR(ajustes.luz_on == 1730 && V[50] == 1730, "hora de encendido de luces cambiada");
    pedir("!V50=2575$");
    COMPROBAR(ajustes.luz_on == 1730 && V[50] == 1730, "HHMM no válido rechazado");
    pedir("!V58=30$");
    COMPROBAR(ajustes.alarma_baja == 21.0f && V[58] == 21.0f, "alarma baja por encima de la alta: rechazada");
    pedir("!V28=300$");
    COMPROBAR(ajustes.intensidad == 125 && V[28] == 125, "intensidad fuera de 0..255 rechazada");
    pedir("!V28=180$");
    COMPROBAR(ajustes.intensidad == 180 && V[10] == 180, "intensidad aceptada y visible en V10");
  } else if (e == "luces") {
    arrancar(); hora(16, 7, 30); correr(600);
    COMPROBAR(g_pwm[3] >= 61 && g_pwm[3] <= 63 && g_pwm[6] == g_pwm[3], "amanecer a mitad: ~50 %");
    hora(18, 0); correr(600);
    COMPROBAR(g_pwm[3] == 125 && V[11] == 125, "de día al máximo configurado");
    hora(23, 0); correr(600);
    COMPROBAR(g_pwm[3] == 0, "de noche apagadas");
    pedir("!V16=1$"); correr(300);
    COMPROBAR(g_pwm[3] == 125, "manual: al máximo");
  } else if (e == "bomba") {
    arrancar(); hora(15, 30); correr(600);
    COMPROBAR(g_pin[4] == HIGH && V[8] == 1, "bomba en horario");
    hora(23, 0); correr(600);
    COMPROBAR(g_pin[4] == LOW && V[8] == 0, "bomba fuera de horario");
    pedir("!V29=1$"); pedir("!V15=1$"); correr(300);
    COMPROBAR(g_pin[4] == HIGH, "manual encendida");
    pedir("!V54=200$"); pedir("!V29=0$"); hora(1, 0); correr(600);
    COMPROBAR(g_pin[4] == HIGH, "horario que cruza la medianoche (15:00-02:00)");
  } else if (e == "reloj") {
    g_rtc_perdio = true; g_temp_agua = 25.0f; arrancar(); correr(1500);
    COMPROBAR(V[62] == 1 && V[63] == 4, "hora perdida: aviso y estado 4");
    pedir("!V44=930$"); correr(600);
    COMPROBAR(V[2] == 9 && V[3] == 30 && V[62] == 0 && V[44] == 0, "puesto en hora a las 09:30 desde la app");
  } else if (e == "alarmas") {
    g_temp_agua = 30.0f; arrancar(); correr(2000);
    COMPROBAR(V[61] == 1 && V[63] == 1, "temperatura alta");
    g_temp_agua = 20.0f; correr(2200);
    COMPROBAR(V[65] == 1 && V[61] == 0 && V[63] == 2, "temperatura baja");
  } else if (e == "watchdog") {
    copia_mcusr = _BV(WDRF); arrancar();
    COMPROBAR(V[72] == 4 && g_wdt_activo == 1, "causa del reinicio: watchdog; watchdog activo");
  } else {
    std::printf("Escenario desconocido\n");
    return 2;
  }
  std::printf("  %-14s %d correctas, %d fallos\n", e.c_str(), ok, fallos);
  return fallos ? 1 : 0;
}
