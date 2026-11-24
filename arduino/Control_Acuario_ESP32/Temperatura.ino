// ============================================================================
//  TEMPERATURA: lectura del DS18B20 sin bloqueo, calentador y alarmas
//  - Conversión de 12 bits: se pide y se recoge a los 800 ms (la hoja de datos da 750 ms),
//    sin detener el programa.
//  - Un salto de más de 3 ºC entre lecturas se confirma con una segunda lectura.
//  - Si no hay lectura válida en 15 s: calentador APAGADO al momento y alarma V60.
// ============================================================================

const unsigned long CONVERSION_MS = 800UL;
const unsigned long PERIODO_LECTURA_MS = 1000UL;

bool convirtiendo = false;
unsigned long t_peticion = 0;
unsigned long t_ultima_valida = 0;
unsigned long t_ultimo_cambio_rele = 0;
bool rele_libre = true;              // aún no se ha conmutado nunca desde el arranque
bool salto_pendiente = false;

void temperaturaIniciar() {
  sonda.begin();
  sonda.setResolution(12);
  sonda.setWaitForConversion(false);   // NO bloquear
  sonda.requestTemperatures();
  t_peticion = millis();
  t_ultima_valida = millis();
  convirtiendo = true;
  ponerCalentador(false);
}

void ponerCalentador(bool encender) {
  calentador = encender;
  digitalWrite(PIN_CALENTADOR, encender ? RELE_ON : RELE_OFF);
  V[V_CALENTADOR_ON] = encender ? 1 : 0;
  V[V_CALENTADOR_OFF] = encender ? 0 : 1;
}

void temperaturaActualizar() {
  unsigned long ahora = millis();
  if (convirtiendo && ahora - t_peticion >= CONVERSION_MS) {
    convirtiendo = false;
    float t = sonda.getTempCByIndex(0);
    if (Logica::lectura_valida(t)) {
      bool salto = !isnan(temperatura) && fabs(t - temperatura) > Logica::SALTO_SOSPECHOSO;
      if (salto && !salto_pendiente) {
        salto_pendiente = true;       // se confirma con la siguiente lectura
      } else {
        salto_pendiente = false;
        temperatura = t;
        t_ultima_valida = ahora;
        V[V_TEMP] = t;
        V[V_TEMP_DEC] = t;
      }
    }
  }
  if (!convirtiendo && ahora - t_peticion >= PERIODO_LECTURA_MS) {
    sonda.requestTemperatures();
    t_peticion = ahora;
    convirtiendo = true;
  }

  // Fallo: 15 s sin ninguna lectura válida (también si nunca la hubo desde el arranque)
  fallo_sonda = (ahora - t_ultima_valida) > Logica::FALLO_SONDA_MS;
  if (fallo_sonda || isnan(temperatura)) {
    if (calentador) {
      ponerCalentador(false);         // por seguridad, sin esperar los 3 min
      t_ultimo_cambio_rele = ahora;
      rele_libre = false;
      depurar("FALLO DE SONDA: calentador apagado");
    }
  }
  if (!fallo_sonda && !isnan(temperatura)) {
    bool nuevo = Logica::decidir_calentador(calentador, temperatura, ajustes.consigna, ajustes.histeresis,
                                           ahora, t_ultimo_cambio_rele, rele_libre);
    if (nuevo != calentador) {
      ponerCalentador(nuevo);
      t_ultimo_cambio_rele = ahora;
      rele_libre = false;
    }
  }
  bool alta = !fallo_sonda && !isnan(temperatura) && temperatura > ajustes.alarma_alta;
  bool baja = !fallo_sonda && !isnan(temperatura) && temperatura < ajustes.alarma_baja;
  V[V_FALLO_SONDA] = fallo_sonda ? 1 : 0;
  V[V_TEMP_ALTA] = alta ? 1 : 0;
  V[V_TEMP_BAJA] = baja ? 1 : 0;
  V[V_ESTADO] = Logica::codigo_estado(fallo_sonda, alta, baja, hora_perdida);
}
