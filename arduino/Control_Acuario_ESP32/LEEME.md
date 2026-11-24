# Control Acuario ESP32 (3.0.0 de prueba)

Programa para la placa **Controlador de Acuario V1.0** (ESP32-DevKitC-32E). Es el **Control_Acuario_V2**
del Mega pasado al ESP32: la misma lógica probada (`Logica.h`, idéntico) y las **mismas variables V**,
así que el proyecto «Acuario V2» de Acuaris funciona igual. **No es oficial** hasta que lo apruebes.
No toca ni el sketch original ni el V2.

## Qué cambia respecto al V2 del Mega
| V2 (Mega) | ESP32 |
|---|---|
| HC-05 en Serial1 | **Bluetooth del ESP32**, nombre **«Acuario»**, sin PIN |
| EEPROM | **Memoria NVS** del ESP32 (reparte el desgaste); se guarda 2 s después del último cambio |
| MOSFET con PWM en pines 3 y 6 | **Fuente de luz de la placa**: buck con tensión por DAC + eFuse + PWM a **490 Hz** (configurable) |
| Una sola intensidad | **Referencia** (V28, se guarda) y **temporal** (V12, no se guarda; vuelve a la referencia al empezar el amanecer, con V13 = 1 o al reiniciar) |
| Watchdog del AVR | Watchdog de tareas del ESP32 (8 s) |

## La fuente de luz (lo más importante para la seguridad)
**Encendido** (ningún paso se salta):
1. DAC a 6 V y PWM a 0.
2. `BUCK_EN`.
3. `LED_EN` (rearma el eFuse), y comprobación de que la salida llega a unos 6 V sin aviso del eFuse.
4. Rampa de tensión hasta la configurada (4 V/s): arranque suave.
5. PWM según el horario (modo PWM) o al 100 % (modo continua).

**Apagado:** PWM 0 → `LED_EN` 0 → `BUCK_EN` 0 → DAC al mínimo. Se hace 30 s después de que la luz llegue a 0.

**Se apaga todo al instante y queda bloqueada** hasta que escribas V86 = 1 (o reinicies) si:
- el eFuse avisa (`LED_FAULT_N` en bajo 5 ms);
- hay sobretensión (más de la ordenada + 10 % + 1 V durante 0,1 s);
- no se alcanza la tensión (al encender, o 2 s por debajo estando encendida);
- la corriente pasa de 4,7 A durante 2 s;
- el DAC no responde. En ese caso el buck no se habilita nunca.

Además:
- La primera vez se graba **4095 en la EEPROM del DAC**, para que siempre arranque a la tensión mínima. Solo se regraba si ese valor cambia.
- La tensión nunca supera **21 V** por software.

## Variables V nuevas (el resto, igual que el V2: ver `Control_Acuario_V2/LEEME.md`)
| V | Qué es |
|---|---|
| V12 | Intensidad **temporal** 0–255 (escribir: cambia la luz al momento; no se guarda) |
| V13 | Escribir 1: volver a la intensidad de referencia |
| V28 | Intensidad de **referencia** (se guarda; como antes) |
| V66 | Alarma de la fuente de luz (1 = fallo) |
| V72 | Causa del reinicio: igual que el V2 y además 5 = fallo del programa, 6 = reinicio por software |
| V74 | Memoria libre del ESP32 (bytes) |
| V80 | **Ajuste:** tensión de las luces, 5–21 V (por defecto **10 V**, la de hoy) |
| V81 / V82 / V83 | Tensión medida (V) / corriente (A) / potencia (W) |
| V84 | Estado de la fuente: 0 apagada, 1 comprobando, 2 subiendo, 3 encendida, 4 fallo |
| V85 | Fallo: 0 ninguno, 1 eFuse, 2 sobretensión, 3 tensión, 4 DAC, 5 corriente |
| V86 | Escribir 1: rearmar la fuente tras un fallo |
| V87 | **Ajuste:** 0 = PWM (como hoy), 1 = continua (encendido/apagado sin regular) |
| V88 | **Ajuste:** frecuencia del PWM, 100–5000 Hz (por defecto 490) |
| V89 | Tensión que se está ordenando ahora |

## Cargar en la placa
1. Arduino IDE → abrir `Control_Acuario_ESP32/Control_Acuario_ESP32.ino`.
2. Núcleo **esp32 by Espressif 3.x**. Placa: **ESP32 Dev Module**.
3. Librerías: **VirtuinoCM**, **OneWire** (2.3.8 o posterior: las anteriores fallan con el núcleo 3.x), **DallasTemperature** y **RTClib** (Adafruit).
4. Verificar → Subir. Para ver mensajes: `DEPURAR = true` y Monitor Serie a 115200.
5. En el móvil: emparejar «Acuario» y conectarlo desde Acuaris.

## Primera prueba en banco (sin las dicroicas)
1. Sin carga en la salida de luz y con un polímetro en ella. Pon la luz en horario.
   - Debe subir a 6 V y luego a 10 V.
   - V84 debe pasar a 3.
2. Compara V81 con el polímetro. Si difieren más de 0,5 V, avísame: se puede calibrar.
3. Prueba los fallos:
   - Con V80 = 12, la salida sube en rampa.
   - Desconecta el DAC (con la placa apagada) y arranca: V85 debe ser 4 y el buck no debe habilitarse.
4. Después, una sola dicroica, y luego todas, como dice el plan de pruebas de la placa.

## Cómo se ha comprobado (y qué falta)
- `pruebas/test_fuente.cpp`: 20 pruebas de los cálculos de la fuente (DAC inverso, límite de 21 V, ADC, márgenes y rampas).
- `pruebas/test_sketch.cpp`: **el sketch completo se ejecuta en el PC** con imitaciones de las librerías del ESP32 y un modelo de la placa (DAC → buck → eFuse → ADC), más la librería VirtuinoCM original. Son 42 comprobaciones en 12 escenarios: arranque, secuencia y orden de encendido, sobretensión, eFuse, falta de tensión, DAC ausente, intensidad temporal, noche, modo continua, ajustes, termostato y Bluetooth.
- `Logica.h` es idéntico al del V2 (sus 30 pruebas pasan).
- Ejecutar: `pruebas/ejecutar_pruebas.sh` (g++ e Internet para descargar VirtuinoCM).
- **Falta:**
  - **Compilarlo para ESP32**: aquí no he podido instalar el compilador. Hazlo con el Arduino IDE.
  - **Probarlo en la placa**, que aún no está fabricada.

## Puntos a vigilar (de los documentos de la placa)
- Según el esquema, `LED_V_ADC` mide la **salida del eFuse**, no la del buck. Por eso la tensión no se puede medir antes de `LED_EN`. Se comprueba justo después, a 6 V (inofensiva), antes de subir.
- El documento de la placa avisa: con PWM, el disparo rápido del eFuse **podría enclavarlo**. Si pasa, saldrá V85 = 1. Prueba con el modo continua (V87 = 1) para comparar.
- La tensión real depende de los 3,3 V del DevKit (unos ±0,2 V).
- El ADC del ESP32 tiene error propio. Por eso los márgenes son amplios (10 % + 1 V).
