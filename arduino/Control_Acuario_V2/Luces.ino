// ============================================================================
//  LUCES: amanecer y atardecer suaves (por segundos) con horario configurable.
//  Manual (V16 = 1): intensidad máxima configurada.
// ============================================================================

void lucesActualizar() {
  uint8_t nivel;
  if (V[V_LUCES_MAX] == 1) {
    nivel = ajustes.intensidad;
  } else {
    nivel = Logica::nivel_luz(segundos_del_dia, ajustes.luz_on, ajustes.luz_off, ajustes.rampa_min, ajustes.intensidad);
  }
  analogWrite(PIN_LUZ_A, nivel);
  analogWrite(PIN_LUZ_B, nivel);
  V[V_LUZ_ACTUAL] = nivel;
  digitalWrite(PIN_LUZ_NOCHE, LOW);   // luz nocturna: reservada, apagada
}
