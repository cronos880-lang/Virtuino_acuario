# Normas para agentes (Codex, Claude) en Acuaris

- Idioma: castellano en código, comentarios, documentación y mensajes.
- El propietario fija objetivos y **aprueba versiones oficiales**; publicar código o compilar no es aprobar.
- No generar versiones, etiquetas, releases ni ZIP salvo petición expresa.
- Rama de trabajo: la indicada en el encargo; nada de force-push ni reescritura de historial.
- `arduino/` contiene el sketch original del propietario: no modificarlo sin encargo expreso.
- Compatibilidad obligatoria con VirtuinoCM 1.0.02 (ver `docs/ESPECIFICACION.md`): pines con dos
  cifras (`!V05=?$`), escrituras sin respuesta, una petición de lectura en vuelo.
- Gráficos: todo vectorial y medido en dp; se dibuja a la resolución real (px = dp × escala).
  No usar imágenes escaladas para elementos de interfaz.
- Antes de push: ejecutar las pruebas (`godot --headless --path acuaris -s res://tests/ejecutar_pruebas.gd`).
- Consultar antes de añadir dependencias, cambiar de motor o tocar la firma de la app.
- Versiones fijadas: Godot 4.7.2, Java 17, AGP 8.7.3, Gradle 8.11.1.
