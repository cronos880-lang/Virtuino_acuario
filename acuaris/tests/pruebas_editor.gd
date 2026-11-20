extends RefCounted
## Pruebas del modelo del editor (las llama ejecutar_pruebas.gd).

var t  # ejecutor (tiene comprobar())


func _init(ejecutor) -> void:
	t = ejecutor


func ejecutar() -> void:
	var m := ModeloEditor.new()
	m.nuevo("Prueba", "samsung_galaxy_a56")
	t.comprobar(m.lienzo() == Vector2(384, 832), "editor: lienzo del A56")
	t.comprobar(m.area_pagina() == Vector2(384, 772), "editor: área bajo la cabecera")
	t.comprobar(not m.puede_deshacer(), "editor: historial vacío al empezar")
	# Todos los tipos se crean válidos
	for tipo in Esquema.ORDEN:
		m.anadir(tipo)
	t.comprobar(m.widgets().size() == Esquema.ORDEN.size(), "editor: añadidos todos los tipos")
	var p := Proyecto.new()
	p.datos = m.datos
	t.comprobar(p.validar(), "editor: proyecto con todos los tipos es válido " + str(p.errores))
	var id := "indicador_1"
	t.comprobar(not m.buscar(id).is_empty() and m.buscar("valor_1").get("tipo") == "valor", "editor: identificador automático")
	# Mover con ajuste a la rejilla y límites
	m.fijar_rect(id, Rect2(13, 21, 201, 199))
	t.comprobar(m.rect_de(id) == Rect2(12, 20, 200, 200), "editor: ajuste a rejilla de 4 dp")
	m.fijar_rect(id, Rect2(300, -50, 200, 200))
	t.comprobar(m.rect_de(id).position == Vector2(184, 0), "editor: no se sale del lienzo")
	# Deshacer / rehacer
	m.deshacer()
	t.comprobar(m.rect_de(id) == Rect2(12, 20, 200, 200), "editor: deshacer")
	m.rehacer()
	t.comprobar(m.rect_de(id).position == Vector2(184, 0), "editor: rehacer")
	# Arrastre: muchos pasos = una sola entrada de historial
	var antes := m._historial.size()
	for i in 10:
		m.fijar_rect(id, Rect2(100 + i * 4, 40, 200, 200), false)
	m.registrar()
	t.comprobar(m._historial.size() == antes + 1, "editor: un arrastre ocupa un paso de deshacer")
	# Propiedades, pin, renombrar, duplicar, borrar
	m.fijar_prop(id, "unidad", "°C")
	t.comprobar(m.buscar(id).props.unidad == "°C", "editor: propiedad cambiada")
	t.comprobar(m.fijar_pin(id, "v35") and m.buscar(id).pin == "V35", "editor: pin normalizado")
	t.comprobar(not m.fijar_pin(id, "Z9"), "editor: pin no válido rechazado")
	t.comprobar(m.renombrar(id, "temperatura") and not m.buscar("temperatura").is_empty(), "editor: renombrar")
	t.comprobar(not m.renombrar("temperatura", "valor_1"), "editor: identificador repetido rechazado")
	var copia := m.duplicar("temperatura")
	t.comprobar(copia == "indicador_1" and m.buscar(copia).props.unidad == "°C", "editor: duplicar copia propiedades")
	m.borrar(copia)
	t.comprobar(m.buscar(copia).is_empty() and m.seleccion == "", "editor: borrar")
	t.comprobar(m.elemento_en(Vector2(150, 60)) == "temperatura", "editor: elemento bajo el ratón")
	# Páginas
	m.anadir_pagina("Ajustes")
	t.comprobar(m.paginas().size() == 2 and m.pagina_actual == 1 and m.widgets().is_empty(), "editor: página nueva")
	m.anadir("pulsador")
	t.comprobar(m.widgets()[0].id == "pulsador_2", "editor: ids únicos entre páginas")
	m.ir_a_pagina(0)
	t.comprobar(not m.buscar("temperatura").is_empty(), "editor: cambiar de página")
	# Cambio de dispositivo
	m.cambiar_dispositivo("generico_tablet_10", "horizontal")
	t.comprobar(m.lienzo() == Vector2(1280, 800), "editor: tablet en horizontal")
	m.cambiar_dispositivo("samsung_galaxy_a56", "vertical")
	for w in m.widgets():
		t.comprobar(float(w.x) + float(w.w) <= 384.0, "editor: elementos recolocados dentro (%s)" % w.id)
	# Guardar y abrir
	var ruta := OS.get_user_data_dir().path_join("prueba_editor.acuaris.json")
	t.comprobar(m.guardar(ruta) == "", "editor: guardar")
	t.comprobar(not m.modificado, "editor: sin cambios tras guardar")
	var m2 := ModeloEditor.new()
	t.comprobar(m2.abrir(ruta).is_empty(), "editor: abrir lo guardado")
	t.comprobar(m2.paginas().size() == 2 and not m2.buscar("temperatura").is_empty(), "editor: contenido conservado")
	DirAccess.remove_absolute(ruta)
	# El ejemplo original no se sobrescribe
	var m3 := ModeloEditor.new()
	m3.abrir("res://proyectos/acuario.acuaris.json")
	t.comprobar(m3.solo_lectura and m3.guardar() != "", "editor: el acuario original queda protegido")
