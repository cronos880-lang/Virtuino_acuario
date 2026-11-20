# Encargo: Acuaris para la placa Controlador de Acuario V1.0 (ESP32)

Estado: **pendiente de empezar** (decisiones tomadas el 20-11-2026; se retoma cuando el propietario diga).

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
- **Corriente de las luces:** 7 × 8 W = 56 W. A 10 V serían unos **5,6 A**, por encima del límite del
  eFuse (unos 4,85–5,58 A) y de los 4,7 A de diseño. A 12 V serían unos 4,7 A.
  Hay que confirmar la tensión de trabajo de las dicroicas, su consumo real y si la placa lo admite.
- **Acceso desde fuera de casa:** decidir el sistema (servicio en la nube, VPN o abrir un puerto) teniendo
  en cuenta la seguridad.
- **Preguntas pendientes del propietario:** las planteará antes de empezar.
