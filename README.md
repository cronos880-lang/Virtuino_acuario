# Acuaris

Diseñador de paneles de control en PC y app Android para controladores Arduino por Bluetooth,
compatible con el protocolo **VirtuinoCM**: tu sketch actual no necesita cambios.

> **Estado:** V0.1.0, prueba de concepto (fase 0 + POC). **No es una versión oficial**: solo el
> propietario aprueba versiones oficiales.

## Contenido

| Carpeta | Qué hay |
|---|---|
| `acuaris/` | Proyecto Godot 4.7.2: app Acuaris (Windows y Android), simulador, pruebas |
| `android-plugin/` | Complemento Android en Java: Bluetooth clásico SPP (HC-05/HC-06) |
| `arduino/` | Sketch original `Control_Acuario_01_09_2026_Final` (Mega 2560), sin modificar |
| `docs/` | Especificación técnica y capturas |
| `firma/` | Clave de firma **de depuración** (solo para instalar pruebas; no es una clave de publicación) |
| `.github/workflows/` | Compilación automática: pruebas + `.exe` + `.apk` |

## Descargar la app

Tras cada push, GitHub Actions compila. Ve a la pestaña **Actions** del repositorio, abre la
última ejecución de "Compilar Acuaris" y descarga en **Artifacts**:

- `Acuaris-Android` → `Acuaris.apk` (instalar en el móvil, permitiendo "orígenes desconocidos").
- El `.exe` de Windows no se publica hasta que el programa esté terminado.

## Uso con el acuario

1. Empareja el HC-06 en los ajustes de Bluetooth de Android (si ya usas Virtuino 6, ya lo está).
2. Abre Acuaris → **Conexión** → elige el HC-06. La app recuerda el dispositivo.
3. Cierra Virtuino 6 antes: el HC-06 solo admite una conexión a la vez.

En el PC se trabaja con el **simulador**, que reproduce la lógica del sketch.

## Desarrollo

- Godot 4.7.2 (renderizador de compatibilidad), GDScript.
- Complemento Android: Java 17, Android Gradle Plugin 8.7.3, Gradle 8.11.1, compileSdk 35, minSdk 21,
  compilado contra `org.godotengine:godot:4.7.2.stable`.
- Pruebas: `godot --headless --path acuaris -s res://tests/ejecutar_pruebas.gd`
- Maqueta del diseñador (fase 1, no funcional): `godot --path acuaris res://ui/disenador_maqueta.tscn`
- Capturas: `godot --path acuaris --resolution 1080x2340 -- --captura=salida.png [--pantalla=conexion|medir] [--hora=16:20] [--segundos=240]`

Más detalle en `docs/ESPECIFICACION.md`.
