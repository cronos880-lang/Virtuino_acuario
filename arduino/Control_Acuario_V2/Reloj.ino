// ============================================================================
//  RELOJ DS3231: hora para la app, poner en hora (V44 = HHMM) y aviso de hora perdida.
// ============================================================================

bool rtc_presente = false;
unsigned long t_ultima_lectura_rtc = 0;
uint8_t dia_actual = 0;

void relojIniciar() {
  rtc_presente = rtc.begin();
  hora_perdida = !rtc_presente || rtc.lostPower();
  V[V_HORA_PERDIDA] = hora_perdida ? 1 : 0;
  if (!rtc_presente) depurar(F("No se encuentra el reloj DS3231"));
}

void relojActualizar() {
  // Poner en hora desde la app: V44 = HHMM (segundos a 0, se conserva la fecha)
  if (escrito_por_app(V_PONER_HORA)) {
    long hhmm = lround(V[V_PONER_HORA]);
    if (rtc_presente && Logica::hhmm_valido(hhmm)) {
      DateTime n = rtc.now();   // fecha leída en este momento (no una copia antigua)
      rtc.adjust(DateTime(n.year(), n.month(), n.day(), hhmm / 100, hhmm % 100, 0));
      hora_perdida = false;
      V[V_HORA_PERDIDA] = 0;
      depurar(F("Reloj puesto en hora desde la app"));
    }
    publicar(V_PONER_HORA, 0);
  }
  // Leer el reloj 4 veces por segundo (I2C es rápido, pero no hace falta más)
  if (millis() - t_ultima_lectura_rtc < 250 && t_ultima_lectura_rtc != 0) return;
  t_ultima_lectura_rtc = millis();
  if (!rtc_presente) return;
  DateTime ahora = rtc.now();
  segundos_del_dia = ahora.hour() * 3600L + ahora.minute() * 60L + ahora.second();
  V[V_HORA] = ahora.hour();
  V[V_MIN] = ahora.minute();
  V[V_SEG] = ahora.second();
  if (dia_actual != ahora.day()) {
    if (dia_actual != 0) nuevoDia();
    dia_actual = ahora.day();
  }
}
