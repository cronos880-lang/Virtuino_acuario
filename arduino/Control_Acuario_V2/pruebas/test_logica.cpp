// Pruebas nativas de Logica.h:  g++ -std=c++17 -Wall -Wextra test_logica.cpp -o t && ./t
#include <cstdio>
#include <cstring>
#include "../Logica.h"

static int ok = 0, fallos = 0;
#define COMPROBAR(c, txt) do { if (c) ok++; else { fallos++; std::printf("FALLO: %s (linea %d)\n", txt, __LINE__); } } while (0)

static long hms(int h, int m, int s = 0) { return h * 3600L + m * 60L + s; }

int main() {
  using namespace Logica;
  // HHMM
  COMPROBAR(hhmm_valido(0) && hhmm_valido(2359) && hhmm_valido(1630), "hhmm validos");
  COMPROBAR(!hhmm_valido(2400) && !hhmm_valido(1260) && !hhmm_valido(-1), "hhmm no validos");
  // Horarios
  COMPROBAR(en_horario(hms(15, 0), 1500, 2200) && !en_horario(hms(22, 0), 1500, 2200), "horario normal [inicio, fin)");
  COMPROBAR(en_horario(hms(23, 30), 2200, 600) && en_horario(hms(3, 0), 2200, 600) && !en_horario(hms(12, 0), 2200, 600), "horario que cruza medianoche");
  COMPROBAR(!en_horario(hms(10, 0), 1000, 1000), "inicio == fin: nunca");
  // Luz: igual que el sketch original en los puntos clave y suave entre medias
  COMPROBAR(nivel_luz(hms(15, 59, 59), 1600, 2200, 15, 125) == 0, "antes de amanecer: 0");
  COMPROBAR(nivel_luz(hms(16, 0, 0), 1600, 2200, 15, 125) == 0, "inicio amanecer: 0");
  COMPROBAR(nivel_luz(hms(16, 7, 30), 1600, 2200, 15, 125) == 62, "mitad del amanecer: ~50 %");
  COMPROBAR(nivel_luz(hms(16, 15, 0), 1600, 2200, 15, 125) == 125, "fin amanecer: maximo");
  COMPROBAR(nivel_luz(hms(21, 52, 30), 1600, 2200, 15, 125) == 62, "mitad del atardecer");
  COMPROBAR(nivel_luz(hms(22, 0, 0), 1600, 2200, 15, 125) == 0, "apagado a las 22:00");
  int saltos = 0; uint8_t ant = 0;
  for (long s = hms(16, 0); s < hms(16, 15); s++) { uint8_t n = nivel_luz(s, 1600, 2200, 15, 125); if (n > ant + 1) saltos++; ant = n; }
  COMPROBAR(saltos == 0, "amanecer sin saltos de mas de 1 nivel");
  COMPROBAR(nivel_luz(hms(1, 0), 2200, 600, 30, 200) == 200, "luz nocturna que cruza medianoche");
  COMPROBAR(nivel_luz(hms(12, 0), 1200, 1210, 15, 100) == 0 && nivel_luz(hms(12, 5), 1200, 1210, 15, 100) == 100, "periodo corto: rampa recortada");
  COMPROBAR(nivel_luz(hms(17, 0), 1600, 2200, 0, 80) == 80, "sin rampa");
  // Sonda
  COMPROBAR(!lectura_valida(-127.0f) && !lectura_valida(85.0f) && !lectura_valida(NAN) && !lectura_valida(50.0f), "lecturas invalidas");
  COMPROBAR(lectura_valida(24.5f) && lectura_valida(0.0f), "lecturas validas");
  // Termostato
  COMPROBAR(decidir_calentador(false, 24.7f, 25.0f, 0.2f, 1000, 0, true) == true, "enciende al arrancar sin esperar 3 min");
  COMPROBAR(decidir_calentador(true, 25.3f, 25.0f, 0.2f, 60000, 0, false) == true, "respeta 3 min antes de apagar");
  COMPROBAR(decidir_calentador(true, 25.3f, 25.0f, 0.2f, 181000, 0, false) == false, "apaga tras 3 min por encima");
  COMPROBAR(decidir_calentador(true, 25.1f, 25.0f, 0.2f, 999999, 0, false) == true, "dentro de la histeresis no cambia");
  COMPROBAR(decidir_calentador(false, 24.9f, 25.0f, 0.2f, 999999, 0, false) == false, "dentro de la histeresis no enciende");
  COMPROBAR(decidir_calentador(false, 24.8f, 25.0f, 0.2f, 5000, 4294967000UL, false) == false, "desbordamiento de millis: sigue esperando");
  // Ajustes
  Ajustes a; por_defecto(a);
  COMPROBAR(a.consigna == 25.0f && a.intensidad == 125 && a.luz_on == 1600 && a.bomba_on == 1500, "valores por defecto = sketch original");
  COMPROBAR(sanear(a) && a.suma == calcular_suma(a), "ajustes por defecto son validos");
  Ajustes b; std::memset(&b, 0xFF, sizeof b);   // EEPROM borrada
  COMPROBAR(!sanear(b), "EEPROM borrada detectada");
  COMPROBAR(b.consigna == 25.0f && b.luz_off == 2200 && b.rampa_min == 15, "EEPROM borrada -> valores seguros");
  Ajustes c; por_defecto(c); c.consigna = 99.0f; c.alarma_baja = 30; c.alarma_alta = 20;
  COMPROBAR(!sanear(c) && c.consigna == 25.0f && c.alarma_baja < c.alarma_alta, "consigna absurda y alarmas cruzadas corregidas");
  Ajustes d; por_defecto(d); d.intensidad = 7; uint8_t s0 = calcular_suma(d); d.intensidad = 8;
  COMPROBAR(s0 != calcular_suma(d), "la suma detecta cambios");
  // Estado
  COMPROBAR(codigo_estado(true, true, false, true) == 3 && codigo_estado(false, true, false, true) == 1 && codigo_estado(false, false, false, false) == 0, "codigo de estado y prioridad");
  std::printf("Pruebas de Logica.h: %d correctas, %d fallos\n", ok, fallos);
  return fallos ? 1 : 0;
}
