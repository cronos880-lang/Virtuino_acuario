// ============================================================================
//  LUCES: amanecer y atardecer suaves (por segundos) con horario configurable.
//  Manual (V16 = 1): intensidad máxima.
//
//  Intensidad de referencia (V28, página Consignas): la única que se guarda en la EEPROM.
//  Intensidad temporal (V12, "para jugar"): cambia la luz al momento, NO se guarda y vuelve a
//  la referencia al empezar el siguiente amanecer, con V13 = 1 o al reiniciar.
// ============================================================================

bool estaba_en_horario = false;
bool primera_vez_luces = true;

void volverAReferencia() {
  intensidad_actual = ajustes.intensidad;
  publicar(V_INTENSIDAD_TEMP, intensidad_actual);
}

void lucesActualizar() {
  if (escrito_por_app(V_INTENSIDAD_TEMP)) {
    long n = lround(V[V_INTENSIDAD_TEMP]);
    if (n >= 0 && n <= 255) intensidad_actual = (uint8_t)n;
    publicar(V_INTENSIDAD_TEMP, intensidad_actual);
  }
  if (V[V_VOLVER_REFERENCIA] == 1) {
    volverAReferencia();
    V[V_VOLVER_REFERENCIA] = 0;
  }
  // Al empezar el amanecer: vuelta a la referencia
  bool en_horario = Logica::en_horario(segundos_del_dia, ajustes.luz_on, ajustes.luz_off);
  if (en_horario && !estaba_en_horario && !primera_vez_luces) volverAReferencia();
  estaba_en_horario = en_horario;
  primera_vez_luces = false;

  uint8_t nivel;
  if (V[V_LUCES_MAX] == 1) {
    nivel = intensidad_actual;
  } else {
    nivel = Logica::nivel_luz(segundos_del_dia, ajustes.luz_on, ajustes.luz_off, ajustes.rampa_min, intensidad_actual);
  }
  analogWrite(PIN_LUZ_A, nivel);
  analogWrite(PIN_LUZ_B, nivel);
  V[V_LUZ_ACTUAL] = nivel;
  digitalWrite(PIN_LUZ_NOCHE, LOW);   // luz nocturna: reservada, apagada
}
