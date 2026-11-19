void Temperature(int *Vtemp, float *Setpoint, float *Hismax, float *Hismin)
{
   static bool estadoCalentador = false;                 // false = apagado, true = encendido
   static unsigned long ultimoCambio = 0;                // momento del último cambio de estado
   const unsigned long TIEMPO_MINIMO_RELE = 180000;      // 3 minutos en milisegundos

   sensors.requestTemperatures();                        // Pedimos lectura al DS18B20
   float temp = sensors.getTempCByIndex(0);              // Leemos temperatura en ºC

   // Filtrado básico de lecturas erróneas típicas del DS18B20
   if (temp == -127.0 || temp == 85.0 || temp < 0.0 || temp > 40.0) {
      return;
   }

   *Vtemp = temp;        // Se mantiene tu variable original
   V[5]   = temp;        // Temperatura para Virtuino
   V[35]  = temp;        // Temperatura con decimales

   // Estado actual según salidas
   if (digitalRead(2) == HIGH) {
      estadoCalentador = true;
   } else {
      estadoCalentador = false;
   }

   // Solo permitimos cambiar el relé si ha pasado el tiempo mínimo
   if (millis() - ultimoCambio >= TIEMPO_MINIMO_RELE) {

      // Apagar calentador
      if (temp >= (*Setpoint + *Hismax) && estadoCalentador == true) {
         digitalWrite(2, LOW);
         V[6] = 0;
         V[7] = 1;
         ultimoCambio = millis();
      }

      // Encender calentador
      else if (temp <= (*Setpoint - *Hismin) && estadoCalentador == false) {
         digitalWrite(2, HIGH);
         V[6] = 1;
         V[7] = 0;
         ultimoCambio = millis();
      }
   }

   // Reflejar estado actual en Virtuino aunque no haya cambiado
   if (digitalRead(2) == HIGH) {
      V[6] = 1;
      V[7] = 0;
   } else {
      V[6] = 0;
      V[7] = 1;
   }

   vDelay(50);
}

///////////////////////////////////////////////////////////////////////////////////////////


/*
void Temperature(int *Vtemp, float *Setpoint, float *Hismax, float *Hismin)
{
   sensors.requestTemperatures();                 // Pedimos lectura al DS18B20
   float temp = sensors.getTempCByIndex(0);      // Leemos temperatura en ºC

   // Filtrado básico de lecturas erróneas típicas del DS18B20
   if (temp == -127.0 || temp == 85.0 || temp < 0.0 || temp > 40.0) {
      return;
   }

   *Vtemp = temp;        // Se mantiene tu variable original
  // V[5]   = temp;        // Temperatura para Virtuino
   V[35]  = temp;        // Temperatura con decimales

   // Control con histéresis
   if (temp >= (*Setpoint + *Hismax)) {
      V[6] = 0;                  // Heating ON apagado
      V[7] = 1;                  // Heating OFF encendido
      digitalWrite(2, LOW);      // Relé calentador apagado
   }
   else if (temp <= (*Setpoint - *Hismin)) {
      V[6] = 1;                  // Heating ON encendido
      V[7] = 0;                  // Heating OFF apagado
      digitalWrite(2, HIGH);     // Relé calentador encendido
   }

   vDelay(50);
}
*/
///////////////////////////////////////////////////////////////////////////////////////////////////
