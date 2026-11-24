# Encargo: Acuaris para la placa Controlador de Acuario V1.0 (ESP32)

Estado: **fase 1 hecha (24-11-2026)**: sketch `arduino/Control_Acuario_ESP32` sin compilar para ESP32 ni probar en placa. Pendiente: WiFi, página «Fuente de luz» en la app y simulador.

## Alcance
- **Sketch** nuevo para el Arduino IDE en `arduino/Control_Acuario_ESP32`. No se tocan ni el original
  (`Control_Acuario_01_09_2026_Final`) ni el `Control_Acuario_V2` del Mega.
- **App del móvil:** el proyecto «Acuario V2» más una página **«Fuente de luz»**: tensión y corriente
  reales, tensión configurada con su límite, estado del eFuse, rearme y modo continua/PWM.
- **El editor no se cambia** en este encargo.

## Decisiones del propietario
1. Puede leerse todo el repositorio `cronos880-lang/Montaje_Electronico` (rama `acuario-v1-esquema`,
   carpeta `Control_Acuario_V1_0_Proyecto_KiCad`).
2. Luces: 7 dicroicas **LED con driver incorporado, 8 W cada una**.
3. Calentador: **igual que hoy**. La placa hace de termostato principal y el termostato del Eheim
   350 W queda como seguridad, ajustado por encima de la consigna.
4. Bluetooth: nombre **«Acuario»**, **sin PIN**. **WiFi activado**: el propietario quiere ver el estado
   del acuario **desde cualquier lugar** (hay que decidir cómo acceder desde fuera de casa).
5. Núcleo: **esp32 by Espressif** (instalado). El sketch se escribe para la versión 3.x.
6. App: añadir la página «Fuente de luz» al proyecto Acuario V2.

## Datos de la placa (recibidos de la sesión «Reglamentación de proyectos personales»)
- ESP32-DevKitC-32E (WROOM-32E), Bluetooth clásico SPP (`BluetoothSerial`) para VirtuinoCM y WiFi.
- **Luz:**
  - GPIO33: PWM de la luz.
  - GPIO26: BUCK_EN.
  - GPIO27: LED_EN (eFuse TPS26632; se rearma poniéndolo a 0 y luego a 1).
  - GPIO39: LED_FAULT_N (activo bajo).
  - GPIO34: LED_V_ADC (×13,2).
  - GPIO35: LED_I_ADC (unos 0,19 V por amperio).
- **Resto:**
  - GPIO32: DS18B20.
  - I²C en GPIO21/GPIO22: DAC MCP4725 en 0x62 y DS3231 en 0x68.
  - GPIO16: relé de la bomba. GPIO17: relé del calentador. Los dos se activan con nivel alto.
- **Tensión de la luz:** VBUCK ≈ 23,86 − 6,09 × VDAC (relación **inversa**: DAC a 0 da la tensión máxima).
  Con la fuente de 24 V / 5 A la salida llega como mucho a unos 21–22 V, así que hay que limitar el DAC por software.
- **Seguridad:**
  - Grabar 4095 en la EEPROM del MCP4725 para que arranque a la tensión mínima.
  - Orden de encendido: DAC → BUCK_EN → comprobar la tensión → LED_EN → PWM. Al apagar, el orden inverso.
  - Apagar y avisar si hay sobretensión o si LED_FAULT_N está en bajo.
  - No activar nada hasta tener una configuración válida.
- **Límites de la placa:** unos 4,85–5,58 A (eFuse), unos 68 W y 4,7 A de diseño.

## Puntos abiertos (antes de programar)
- **Corriente de las luces: RESUELTO** (ver C.3). Planteamiento inicial: 7 × 8 W = 56 W. A 10 V serían unos **5,6 A**, por encima del límite del
  eFuse (unos 4,85–5,58 A) y de los 4,7 A de diseño. A 12 V serían unos 4,7 A.
  Hay que confirmar la tensión de trabajo de las dicroicas, su consumo real y si la placa lo admite.
- **Acceso desde fuera de casa:** decidir el sistema (servicio en la nube, VPN o abrir un puerto) teniendo
  en cuenta la seguridad.
- **Preguntas pendientes del propietario:** las planteará antes de empezar.

## Notas añadidas por el propietario (20-11-2026)

### A. Intensidad de referencia frente a regulación temporal (también para el sketch V2)
- **Propuesta del propietario:**
  - La página **Consignas** fija la **intensidad de referencia**, que es la que se guarda en la EEPROM.
  - La barra de la **primera página** sirve para **jugar**: cambia la luz al momento pero **no se guarda**.
- **Comportamiento propuesto:**
  - La intensidad temporal va en una variable V nueva y no toca la EEPROM.
  - Se vuelve a la referencia: con un botón «Volver a la referencia», al empezar el siguiente amanecer o al reiniciar la placa.
- **Datos de desgaste de la memoria:**
  - EEPROM del ATmega2560: 100 000 escrituras por celda, según la hoja de datos de Microchip.
  - El V2 ya espera 2 s sin cambios antes de guardar, así que un movimiento de la barra = una escritura.
  - En el ESP32 no hay EEPROM: se usa la memoria flash (NVS, Preferences), que reparte el desgaste. Se aplicará la misma separación entre referencia y valor temporal.

### B. Regulación de la luz en la placa ESP32 (a decidir con pruebas)
- Las dicroicas son LED con driver incorporado y **no regulables**. Bajar la tensión no garantiza
  atenuar: muchos drivers mantienen el brillo hasta una tensión mínima y por debajo parpadean o se apagan.
- **Plan:**
  1. **Modo tensión fija (por defecto):** encendido y apagado a la tensión configurada. La tensión sube en rampa en
     unos segundos para evitar el pico de arranque. Funciona con el horario y con el manual.
  2. **Página de prueba en la app:** barrido de tensión controlado, con lectura de corriente y tensión, para medir
     si las dicroicas se atenúan de forma útil y en qué margen.
  3. Si hay margen útil, **regulación por tensión** dentro de ese margen, con amanecer y atardecer suaves.
     Si no lo hay, solo encendido y apagado.
  4. **Modo PWM** disponible para futuras luminarias regulables.
- Siempre dentro de los límites de seguridad: tensión máxima por software, fallo del eFuse y sobretensión.
- Pendiente: el consumo real (7 × 8 W) frente al límite de corriente del eFuse (ver puntos abiertos).

### C. Decisiones del 20-11-2026 (respuestas del propietario)
1. La intensidad temporal vuelve a la referencia **al empezar el amanecer**. Como no se guarda en
   memoria, después de un reinicio también se arranca con la referencia.
2. **Hoy las luces se regulan por PWM en el Mega y funcionan bien**, aunque el fabricante diga que
   no son regulables por PWM. En la placa ESP32:
   - **Modo principal: el mismo que hoy.** El buck da una tensión fija y el PWM regula
     (TC4427 + MOSFET Q1).
   - **Frecuencia:** igual que la actual del Mega en los pines 3 y 6 (unos 490 Hz), configurable por si
     hiciera falta.
   - **Riesgo a vigilar:** el aviso del fabricante podría significar que el driver interno sufre más
     (temperatura, duración). Hay que observar si las dicroicas se calientan.
   - El modo tensión regulable queda como alternativa, a probar si algún día hace falta.
3. **Luces reales: 2 × 8 W + 4 × 6 W = 40 W como máximo** (6 lámparas), con la misma fuente de 24 V / 5 A.
   A 10 V son unos 4,0 A y a 12 V unos 3,3 A: **dentro del límite de la placa** (4,7 A de diseño). Queda
   resuelto el punto abierto de la corriente. Hay margen, pero conviene un arranque suave de la tensión
   por el pico de los drivers.
