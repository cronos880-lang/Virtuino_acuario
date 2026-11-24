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
// Vigilancia del calentador y resumen de hoy
unsigned long t_calentador_on = 0;
float temp_al_encender = NAN;
bool sin_efecto = false;
float temp_min_hoy = NAN, temp_max_hoy = NAN;
uint16_t encendidos_hoy = 0;

void resumenTemperatura(float t) {
  long hhmm = (segundos_del_dia / 3600) * 100 + (segundos_del_dia / 60) % 60;
  if (isnan(temp_min_hoy) || t < temp_min_hoy) { temp_min_hoy = t; V[V_TEMP_MIN_HOY] = t; V[V_HORA_MIN_HOY] = hhmm; }
  if (isnan(temp_max_hoy) || t > temp_max_hoy) { temp_max_hoy = t; V[V_TEMP_MAX_HOY] = t; V[V_HORA_MAX_HOY] = hhmm; }
}

void resumenTemperaturaNuevoDia() {
  temp_min_hoy = temp_max_hoy = NAN;
  encendidos_hoy = 0;
  V[V_ENCENDIDOS_HOY] = 0;
  if (!isnan(temperatura)) resumenTemperatura(temperatura);
}

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
  if (encender && !calentador) {
    t_calentador_on = millis();
    temp_al_encender = temperatura;
    encendidos_hoy++;
    V[V_ENCENDIDOS_HOY] = encendidos_hoy;
  }
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
        resumenTemperatura(t);
        if (calentador && isnan(temp_al_encender)) temp_al_encender = t;
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
      depurar(F("FALLO DE SONDA: calentador apagado"));
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
  sin_efecto = Logica::calentador_sin_efecto(calentador, ahora - t_calentador_on, temp_al_encender, temperatura);
  V[V_SIN_EFECTO] = sin_efecto ? 1 : 0;
  V[V_ESTADO] = Logica::codigo_estado(fallo_sonda, alta, baja, hora_perdida, sin_efecto);
}
