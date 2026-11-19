# Acuaris: especificación técnica (fase 0)

## 1. Arquitectura

```
 Diseñador (PC, Godot)  ──►  proyecto .acuaris.json  ──►  App (Android/PC, Godot)
                                                          │
                                   Enlace: Simulador │ Bluetooth SPP (complemento Java)
                                                          │
                                       Arduino Mega 2560 + HC-06 + VirtuinoCM
```

El mismo código Godot dibuja en el PC y en el móvil: lo que se diseña es lo que se ve.
Al arrancar: en móvil/tablet se abre la app; en el PC, el editor (`ui/editor/`).
El editor trabaja sobre `ModeloEditor` (operaciones, rejilla de 4 dp, deshacer/rehacer, abrir/guardar)
y dibuja con los mismos elementos que la app. Catálogo de elementos y propiedades: `widgets/esquema.gd`.

## 2. Protocolo VirtuinoCM 1.0.02

Verificado contra el código fuente oficial de la librería (`VirtuinoCM.cpp`, Ilias Lamprou).

| Acción | Envío | Respuesta |
|---|---|---|
| Leer V35 | `!V35=?$` | `!V35=25.31$` (float con 2 decimales) |
| Leer V5 | `!V05=?$` | `!V5=24.50$` (el pin vuelve sin ceros) |
| Escribir V15=1 | `!V15=1$` | *(ninguna)* |
| Saludo | `!C00=?$` | `!C=VirtuinoCM 1.0.02` (sin `$`) |
| Comando mal formado | | `E00=7$` |

Reglas:
- La librería ignora comandos de 5 caracteres o menos entre `!` y `$`: `!V5=?$` **no funciona**,
  por eso los pines se envían con dos cifras.
- El sketch atiende **un** comando por pasada de `virtuinoRun()`; el buffer de `Serial1` es de 64 bytes.
  Acuaris mantiene una sola lectura en vuelo y espera hasta 2 s (la lectura del DS18B20 a 12 bits
  bloquea unos 750 ms).
- Tras escribir, se descartan las lecturas de ese pin pedidas antes de la escritura.

## 3. Formato de proyecto `*.acuaris.json` (versión 1)

```json
{
  "formato": "acuaris-proyecto", "version": 1, "nombre": "Acuario",
  "perfil": "samsung_galaxy_a56", "lienzo_dp": [384, 832],
  "conexion": {"tipo": "bluetooth_spp", "nombre_dispositivo": "HC-06", "intervalo_ms": 400},
  "paginas": [{"id": "principal", "nombre": "Acuario", "widgets": [
    {"id": "temp", "tipo": "indicador", "x": 24, "y": 124, "w": 204, "h": 204,
     "pin": "V35", "props": {"min": 18, "max": 32, "unidad": "°C", "pin_consigna": "V27"}}
  ]}]
}
```

- `orientacion`: "vertical" u "horizontal". La app gira la pantalla según el proyecto.
- Varias páginas: la app muestra pestañas si hay más de una.
- Medidas en **dp**. En el dispositivo: `px = dp × (ancho de pantalla en px / lienzo_dp[0])`.
- `pin` es el pin principal; cualquier propiedad `pin_*` es un pin adicional que también se lee.
- Tipos: `panel`, `etiqueta`, `valor`, `led`, `interruptor`, `pulsador` (conmutado, momentáneo o valor),
  `indicador`, `barra`, `reloj`, `deslizador`.

## 4. Perfiles de dispositivo y nitidez (DPI)

Tipos: `movil`, `tablet`, `pc`. Incluidos: Galaxy A56, dos móviles genéricos, tablets genéricas de 8" y 10"
y PC (ventana 1280 × 800 y pantalla 1920 × 1080). Los "genéricos" no son modelos concretos.


`acuaris/data/perfiles_moviles.json`. Samsung Galaxy A56 5G: 1080 × 2340 px, 6,7", 385 ppi (ficha pública).
La **densidad lógica** (px por dp) es una **estimación (2,8125, es decir 450 dpi lógicos: 384 × 832 dp)**
hasta medirla con *Conexión → Medir este móvil* en el teléfono, que da los valores reales del sistema
(DPI, tamaño y márgenes).

Nitidez: los elementos se dibujan con primitivas vectoriales (arcos, círculos y rectángulos redondeados
con suavizado) y el texto se rasteriza al tamaño final en píxeles. No se escalan imágenes, así que no hay
desenfoque a ninguna densidad ni en ningún zoom.

## 5. Simulador

`core/simulador_arduino.gd` reproduce `getResponse()` de VirtuinoCM y la lógica del sketch:
reloj (V2–V4), bomba (V8, con V29/V15 o el horario de 15 a 22 h), luces (V16, rampas, V10),
temperatura (V5, V35, V6, V7, histéresis ±0,2 °C y relé mínimo de 3 min) con un modelo térmico sencillo.
**No** reproduce el menú bloqueante `Config()` (V9).

## 6. Límites conocidos (V0.1.0)

- La app del móvil abre de momento solo el proyecto incluido; falta "pasar al móvil" los proyectos del editor.
- Editor y .exe sin probar aún en un Windows real.
- Bluetooth no probado aún en el A56 real (no hay acceso al hardware desde la nube).
- El menú de configuración del sketch (V9, V20–V26) no está en el panel de ejemplo: es un bucle
  bloqueante con riesgo (ver el informe inicial) y conviene rediseñarlo en el Arduino antes de llevarlo a la app.
- APK firmado con clave de depuración (`firma/`). Para publicar en tiendas habría que crear una clave privada.
