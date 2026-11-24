// ============================================================================
//  BOMBA / AIREADOR: manual (V29 = 1, manda V15) o por horario configurable.
// ============================================================================

void bombaActualizar() {
  bool encendida;
  if (V[V_BOMBA_MODO_MANUAL] == 1) {
    encendida = (V[V_BOMBA_MANUAL_ON] == 1);
  } else {
    encendida = Logica::en_horario(segundos_del_dia, ajustes.bomba_on, ajustes.bomba_off);
  }
  digitalWrite(PIN_BOMBA, encendida ? RELE_ON : RELE_OFF);
  V[V_BOMBA] = encendida ? 1 : 0;
}
