// ============================================================================
//  DIAGNÓSTICO: latido del LED 13, tiempo de calentador, memoria libre y tiempo encendido.
// ============================================================================

unsigned long t_diag = 0;
unsigned long ms_calentador_hoy = 0;
unsigned long t_anterior_diag = 0;

extern char __heap_start;   // símbolos de avr-libc (memoria dinámica)
extern char* __brkval;

int memoriaLibre() {
  int v;
  return (int)((char*)&v - (__brkval == 0 ? &__heap_start : __brkval));
}

void nuevoDia() {
  ms_calentador_hoy = 0;
}

void diagnosticoActualizar() {
  unsigned long ahora = millis();
  if (calentador) ms_calentador_hoy += ahora - t_anterior_diag;
  t_anterior_diag = ahora;
  digitalWrite(PIN_LED, (ahora / 500) % 2);
  if (ahora - t_diag < 1000) return;
  t_diag = ahora;
  V[V_MIN_CALENTADOR_HOY] = ms_calentador_hoy / 60000UL;
  V[V_MEMORIA_LIBRE] = memoriaLibre();
  V[V_MIN_ENCENDIDO] = ahora / 60000UL;
}
