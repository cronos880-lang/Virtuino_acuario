# Auditoría del sketch `Control_Acuario_01_09_2026_Final`

- **Fecha:** 20-11-2026.
- **Placa:** Arduino Mega 2560 con HC-05, DS18B20, DS3231, módulo de 4 relés y MOSFET IRF520.
- **Alcance:** revisión del código fuente tal como está, sin modificarlo. No se ha compilado ni ejecutado en la placa.
- **Lo que no es una prueba:** el simulador de Acuaris imita la lógica del sketch, pero no es el Arduino real.
- **Hechos e hipótesis:** se indica en cada punto qué está comprobado en el código y qué es una hipótesis que hay que verificar en el hardware.

## 1. Lo que está bien hecho

- **Estructura clara:** una pestaña por función (Reloj, Bomba, Luces, Temperatura, Config) y comentarios en castellano.
- **Temperatura:**
  - Termostato con **histéresis** (±0,2 °C) y **tiempo mínimo de 3 min entre cambios del relé**. Es muy buena práctica: protege el relé y el calentador frente al "rebote".
  - **Filtro de lecturas erróneas** del DS18B20 (−127, 85, <0, >40 °C).
- **Watchdog de 8 s:** si el programa se cuelga, la placa se reinicia sola.
- **Lectura de temperatura temporizada con `millis()`** (cada 1 s), sin `delay()`.
- **Bomba y luces en modo automático o manual** desde el móvil. Las luces tienen amanecer y atardecer.
- **EEPROM con `EEPROM.put`:** solo escribe los bytes que cambian, así que no la desgasta.

## 2. Hallazgos, ordenados por gravedad

### CRÍTICOS (pueden afectar a los peces)

**C1. Si la sonda falla, el calentador se queda como estaba, quizá encendido.**
- **Qué pasa:** `Temperature()` hace `return` cuando la lectura no es válida, por ejemplo con el cable suelto (−127). Así que, si el relé estaba **encendido**, sigue encendido indefinidamente.
- **Consecuencia:** sobrecalentamiento del agua.
- **Solución:** contar las lecturas fallidas seguidas. Si pasan unos 10–30 s sin lectura válida, apagar el calentador y activar una variable de alarma para la app.

**C2. El menú `Config()` bloquea todo el control.**
- **Qué pasa:** mientras está dentro del menú (bucles `while` con el watchdog desactivado), **no se regula la temperatura, ni la bomba, ni las luces**.
- **Si se corta el Bluetooth o se cierra la app dentro de una opción:** el bucle interior (`while (bucle==0)`) solo sale con "Aceptar" (V24), así que se queda **atrapado para siempre**. El calentador conserva el último estado y el watchdog no actúa porque está desactivado.
- **Solución:** sustituir el menú bloqueante por escrituras directas que el `loop()` atiende sin pararse (ver objetivos). Tu versión comentada ya añade un tiempo límite de 3 min, que es un buen parche intermedio.

**C3. La consigna y la intensidad no se validan.**
- **Qué pasa:** el valor que llega del móvil (V23) se guarda tal cual.
- **Consigna absurda** (99 °C por un error al escribir): el calentador se queda siempre encendido.
- **EEPROM nueva o borrada:** todo son 0xFF, así que `Setpoint` = NaN y `lumen` = −1. Con NaN ninguna comparación se cumple y el calentador **no se enciende nunca**. Con −1, `analogWrite` envía 255 (luz al máximo).
- **Solución:** límites, por ejemplo consigna entre 18 y 30 °C e intensidad entre 0 y 255. Además, valores por defecto al arrancar si lo leído de la EEPROM está fuera de rango.

### ALTOS

**A1. Arranque tras un reinicio del watchdog.**
- **Hecho:** `wdt_disable()` solo se ejecuta si `debug == true`.
- **Comportamiento de los ATmega:** tras un reinicio por watchdog, este sigue activo, con el tiempo mínimo, hasta que el programa lo desactiva.
- **Riesgo:** si algún día pones `debug = false`, o con algunos cargadores de arranque antiguos o clónicos del Mega, la placa podría quedarse **reiniciándose en bucle**.
- **Solución:** `MCUSR = 0; wdt_disable();` como primera línea de `setup()`, siempre.
- **Hipótesis a verificar en tu placa:** provocar un cuelgue a propósito y ver que se recupera sola.

**A2. La lectura del DS18B20 bloquea unos 750 ms cada segundo.**
- **Qué pasa:** con resolución de 12 bits, `requestTemperatures()` espera a que termine la conversión (750 ms según la hoja de datos de Maxim).
- **Consecuencia:** durante ese tiempo no se atiende el Bluetooth. Si llegan peticiones, el buffer de `Serial1` (64 bytes) puede desbordarse y perderse comandos. De ahí que, a veces, haya respuestas lentas o faltas de dato.
- **Solución:** `sensors.setWaitForConversion(false)`: se pide la conversión y el valor se recoge al cabo de 750 ms, sin parar el programa.

**A3. Ajuste de hora con datos viejos.**
- **Qué pasa:** `Config()` guarda año, mes, día, hora, minuto y segundo **al entrar** en el menú. Al cambiar la hora, `rtc.adjust` vuelve a escribir esos minutos y segundos antiguos.
- **Consecuencia:** si pasas un rato en el menú, el reloj se atrasa.
- **Solución:** leer `rtc.now()` justo en el momento de ajustar.

**A4. Fallos de lógica en el menú activo.**
- **No se reinician las banderas:** `bucle` no vuelve a 0 y `V[24]` (Aceptar) tampoco. Tras usar una opción, las demás no responden o se aceptan solas con el valor anterior. Tu versión comentada ya corrige esto.
- **Valores en pantalla desfasados:** al cambiar la consigna o la intensidad no se actualizan `V[27]` ni `V[28]`, así que la app muestra el valor anterior hasta reiniciar.

**A5. El reloj puede perder la hora sin avisar.**
- **Qué pasa:** no se comprueba `rtc.begin()` ni `rtc.lostPower()`.
- **Consecuencia:** si se agota la pila del DS3231, la hora vuelve a 2000-01-01 00:00 y los horarios de luces y bomba se desplazan, sin ningún aviso.

### MEDIOS

- **M1. Mensajes de depuración por USB a 9600 baudios** (`debug = true`). Escribir cada comando y su respuesta ralentiza el bucle. **Solución:** `debug = false` en uso normal, o 115200 baudios.
- **M2. Rampas de luz por minutos.** La rampa de 15 min avanza en 15 saltos de unos 9 niveles de PWM cada uno (con intensidad 125), y puede notarse en el agua. **Solución:** calcular el nivel con los segundos para que sea continua.
- **M3. Horarios fijos en el código** (bomba de 15 a 22 h, luces de 16:00 a 22:00). Cambiarlos obliga a reprogramar. **Solución:** guardarlos en la EEPROM y ajustarlos desde la app.
- **M4. Primer arranque del termostato.** Al encender la placa (`millis` < 3 min) el relé no puede cambiar durante 3 minutos. Es inocuo, pero conviene saberlo al probar.
- **M5. Uso de `String`** en la librería VirtuinoCM y en `virtuinoRun()`. Con días de funcionamiento continuo puede fragmentar la memoria (el Mega tiene 8 KB). Es un riesgo bajo o medio que se vigila con un contador de memoria libre.

### BAJOS (orden y mantenimiento)

- **B1. Versiones antiguas en subcarpetas.** `Bomba/`, `Config/`, `Luces/`, `Reloj/` y `Temperatura/` son versiones antiguas que el IDE no compila y que confunden. Conviene moverlas a una carpeta de histórico fuera del sketch.
- **B2. Variables sin uso:** `luz1`, `lumen1`, `bomba_max`, `Vtemp` (int), `v_temp`, `v_hora`, `v_min` y `v_lumens` (además, `v_min` y `v_lumens` valen las dos 4).
- **B3. Tabla de variables desactualizada.** `Variables.xlsx` y la lista del código no coinciden con las variables V que se usan de verdad (V26–V40). Hay que unificarlas en un único mapa de variables V.
- **B4. Pines como números sueltos** (2, 3, 4, 6, 8, 12). Conviene usar constantes con nombre (`PIN_CALENTADOR`, ...).
- **B5. Placa del proyecto Proteus:** es un UNO con HC-06, pero el montaje real es un Mega con HC-05.

## 3. Electrónica real (a comprobar en el montaje, no en el código)

1. **MOSFET IRF520 con 5 V en la puerta.** No es de nivel lógico: su resistencia mínima está especificada con 10 V en la puerta. Con 5 V conduce peor y se calienta más con corrientes altas. Si los LED consumen más de 1–2 A, conviene un MOSFET de nivel lógico (por ejemplo IRLZ44N) o un driver. Comprueba la temperatura del MOSFET con las luces al máximo.
2. **Lógica del módulo de relés.** Muchos módulos de 4 relés se activan con nivel BAJO; el código usa ALTO = encendido. Como te funciona, tu módulo o tu cableado está a nivel alto, pero conviene confirmarlo. También conviene fijar el nivel de los pines (`digitalWrite`) **antes** del `pinMode(OUTPUT)` para evitar un pulso del relé al arrancar.
3. **HC-05 a 3,3 V.** Su pin RX trabaja a 3,3 V y el TX1 del Mega da 5 V. Lo recomendado es un divisor de tensión (por ejemplo 1 kΩ y 2 kΩ). Muchos módulos lo toleran, pero acorta su vida.
4. **DS18B20:** resistencia de 4,7 kΩ entre datos y 5 V. Con cables largos, cable apantallado o una resistencia algo menor.
   - Su precisión es de **±0,5 °C** (hoja de datos), mayor que la histéresis de ±0,2 °C.
   - El control funciona bien gracias a la resolución de 0,0625 °C, pero la temperatura "real" puede diferir hasta medio grado de la mostrada.
   - Si quieres más exactitud: calibrar contra un termómetro de referencia y aplicar un desplazamiento.
5. **Ruido de los relés y alimentación.** Al conmutar cargas de 230 V pueden producirse reinicios por ruido. Ayudan las masas comunes bien hechas, alimentación separada para los relés (jumper JD-VCC) y un condensador cerca del Arduino. El watchdog ya ayuda a recuperarse.
6. **Tiempos reales:** relés de unos 10 ms, DS18B20 de 750 ms, HC-05 a 9600 baudios con latencias de decenas de ms. Por eso los objetivos usan **márgenes y tiempos de espera**, no tiempos exactos.

## 4. Objetivos propuestos (por fases)

### Fase 1: seguridad (sin cambiar lo que ves en el móvil)

1. Calentador apagado y alarma (nueva V) si la sonda falla durante más de 15 s.
2. Validar la consigna (18–30 °C) y la intensidad (0–255). Valores por defecto si la EEPROM está vacía o corrupta.
3. `MCUSR = 0; wdt_disable();` al inicio de `setup()`, siempre. Niveles de los relés antes de `pinMode`.
4. Lectura del DS18B20 sin bloqueo.
5. `debug = false` para uso normal.

### Fase 2: configuración sin menú bloqueante

6. Escritura directa desde la app: la consigna, la intensidad, la hora y los horarios se escriben en sus V y el `loop()` los valida y los guarda, sin pararse.
   - Acuaris lo hace con un "Valor editable" o un deslizador, con PIN si se quiere.
   - Si quieres mantener Virtuino 6 a la vez, se puede conservar el menú con tiempo límite.
7. Horarios de bomba y luces configurables y guardados en la EEPROM.
8. Ajuste de hora correcto (leyendo el reloj al momento) y aviso si el DS3231 perdió la hora.

### Fase 3: diagnóstico y calidad

9. Variables de estado para la app: alarma de sonda, horas de calentador encendido, número de reinicios y motivo (watchdog o alimentación), memoria libre y hora perdida.
10. Rampas de luz suaves (por segundos).
11. Limpieza: subcarpetas antiguas a histórico, constantes de pines, un único mapa de variables V y número de versión del sketch visible desde la app.
12. **Comprobación de compilación automática** del sketch para el Mega 2560 en GitHub Actions (arduino-cli con versiones fijadas de librerías). **Necesita tu aprobación**, porque es una herramienta nueva.

### Pruebas propuestas

- **Simulador de Acuaris:** se actualiza a la nueva lógica y se añaden pruebas automáticas (sonda desconectada, EEPROM vacía, valores fuera de rango, corte del Bluetooth).
- **Banco de pruebas en tu mesa antes del acuario:**
  - Una bombilla o un piloto en lugar del calentador.
  - Desconectar la sonda a propósito y comprobar que se apaga en 15 s y salta la alarma.
  - Cortar el Bluetooth en mitad de un ajuste.
  - Borrar la EEPROM.
- **Recuperación:** se conserva tu sketch actual como versión de vuelta atrás (está en `arduino/` sin modificar).
