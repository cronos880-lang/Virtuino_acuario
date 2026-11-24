// ============================================================================
//  DIAGNÓSTICO: tiempo de calentador, memoria libre y tiempo encendido.
//  (El DevKitC no tiene LED de usuario: no hay latido.)
// ============================================================================

unsigned long t_diag = 0;
unsigned long ms_calentador_hoy = 0;
unsigned long t_anterior_diag = 0;

void nuevoDia() {
  ms_calentador_hoy = 0;
}

void diagnosticoActualizar() {
  unsigned long ahora = millis();
  if (calentador) ms_calentador_hoy += ahora - t_anterior_diag;
  t_anterior_diag = ahora;
  if (ahora - t_diag < 1000) return;
  t_diag = ahora;
  V[V_MIN_CALENTADOR_HOY] = ms_calentador_hoy / 60000UL;
  V[V_MEMORIA_LIBRE] = ESP.getFreeHeap();
  V[V_MIN_ENCENDIDO] = ahora / 60000UL;
}
