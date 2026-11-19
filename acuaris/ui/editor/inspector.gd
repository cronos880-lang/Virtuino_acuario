class_name Inspector
extends VBoxContainer
## Panel de propiedades del elemento seleccionado (o del proyecto si no hay selección).

signal mensaje(texto: String)

var modelo: ModeloEditor
var u := 1.0
var _propio := false
var _campos_rect: Dictionary = {}


func fijar_modelo(m: ModeloEditor) -> void:
	modelo = m
	modelo.seleccion_cambiada.connect(reconstruir)
	modelo.cambiado.connect(_al_cambiar)
	reconstruir()


func _al_cambiar() -> void:
	if _propio:
		return
	var w := modelo.buscar(modelo.seleccion)
	if w.is_empty() or _campos_rect.is_empty():
		reconstruir()
		return
	for k in _campos_rect:
		var sb: SpinBox = _campos_rect[k]
		if is_instance_valid(sb):
			sb.set_value_no_signal(float(w.get(k, 0)))


func _cambiar(f: Callable) -> void:
	_propio = true
	f.call()
	_propio = false


func reconstruir() -> void:
	for h in get_children():
		h.queue_free()
	_campos_rect.clear()
	if modelo == null:
		return
	add_theme_constant_override("separation", roundi(6 * u))
	var w := modelo.buscar(modelo.seleccion)
	if w.is_empty():
		_proyecto()
	else:
		_elemento(w)


func _titulo(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", Estilo.fuente(true))
	l.add_theme_font_size_override("font_size", roundi(17 * u))
	add_child(l)


func _seccion(t: String) -> void:
	var l := Label.new()
	l.text = t.to_upper()
	l.add_theme_font_override("font", Estilo.fuente(true))
	l.add_theme_font_size_override("font_size", roundi(11 * u))
	l.add_theme_color_override("font_color", Estilo.TEXTO_TENUE)
	add_child(l)


func _fila(nombre: String, control: Control) -> void:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = nombre
	l.custom_minimum_size.x = 118 * u
	l.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
	l.clip_text = true
	h.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(control)
	add_child(h)


func _texto(valor: String, al_confirmar: Callable) -> LineEdit:
	var le := LineEdit.new()
	le.text = valor
	le.select_all_on_focus = true
	var confirmar := func():
		if le.text != valor:
			al_confirmar.call(le.text)
	le.text_submitted.connect(func(_t): confirmar.call())
	le.focus_exited.connect(confirmar)
	return le


func _numero(valor: float, paso: float, al_cambiar: Callable, minimo := -100000.0, maximo := 100000.0) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = minimo
	sb.max_value = maximo
	sb.step = paso
	sb.allow_greater = true
	sb.allow_lesser = minimo < 0
	sb.value = valor
	sb.select_all_on_focus = true
	sb.value_changed.connect(al_cambiar)
	return sb


func _boton(t: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(f)
	return b


# ------------------------------------------------------------------ elemento
func _elemento(w: Dictionary) -> void:
	var id := str(w.id)
	var info := Esquema.info(str(w.tipo))
	_titulo(info.get("nombre", str(w.tipo)))
	_seccion("Identificación")
	_fila("Identificador", _texto(id, func(t):
		_cambiar(func():
			if not modelo.renombrar(id, t):
				mensaje.emit("Identificador vacío o repetido: '%s'" % t))
		reconstruir()))
	if Esquema.usa_pin(str(w.tipo)) or w.has("pin"):
		var le := _texto(str(w.get("pin", "")), func(t):
			_cambiar(func():
				if not modelo.fijar_pin(id, t):
					mensaje.emit("Pin no válido: '%s' (ejemplo: V35)" % t))
			reconstruir())
		le.tooltip_text = "Variable del Arduino: V0 a V255"
		_fila("Pin", le)
	_seccion("Posición y tamaño (dp)")
	for k in ["x", "y", "w", "h"]:
		var nombre: String = {"x": "X", "y": "Y", "w": "Ancho", "h": "Alto"}[k]
		var clave: String = k
		var sb := _numero(float(w.get(k, 0)), modelo.rejilla, func(v):
			_cambiar(func():
				var r := modelo.rect_de(id)
				match clave:
					"x": r.position.x = v
					"y": r.position.y = v
					"w": r.size.x = v
					"h": r.size.y = v
				modelo.fijar_rect(id, r)), 0.0)
		_campos_rect[k] = sb
		_fila(nombre, sb)
	_seccion("Aspecto y comportamiento")
	var props: Dictionary = w.get("props", {})
	for p in info.get("props", []):
		var clave: String = p.clave
		var actual = props.get(clave, p.defecto)
		var control: Control
		match str(p.tipo):
			"texto", "pin":
				control = _texto(str(actual), func(t):
					if p.tipo == "pin" and t.strip_edges() != "" and ProtocoloVCM.separar_pin(t).is_empty():
						mensaje.emit("Pin no válido: '%s'" % t)
						return
					_cambiar(func(): modelo.fijar_prop(id, clave, t.strip_edges().to_upper() if p.tipo == "pin" else t)))
			"numero":
				control = _numero(float(actual), 0.1, func(v): _cambiar(func(): modelo.fijar_prop(id, clave, v)))
			"entero":
				control = _numero(float(actual), 1.0, func(v): _cambiar(func(): modelo.fijar_prop(id, clave, int(v))), 0.0)
			"color":
				var cp := ColorPickerButton.new()
				cp.color = Color.from_string(str(actual), Color.WHITE)
				cp.custom_minimum_size.y = 30 * u
				cp.popup_closed.connect(func():
					var hex := "#" + cp.color.to_html(false)
					if hex != str(props.get(clave, "")):
						_cambiar(func(): modelo.fijar_prop(id, clave, hex)))
				control = cp
			"bool":
				var cb := CheckBox.new()
				cb.button_pressed = bool(actual)
				cb.toggled.connect(func(v): _cambiar(func(): modelo.fijar_prop(id, clave, v)))
				control = cb
			"opcion":
				var ob := OptionButton.new()
				for o in p.opciones:
					ob.add_item(o)
					if o == str(actual):
						ob.select(ob.item_count - 1)
				ob.item_selected.connect(func(i): _cambiar(func(): modelo.fijar_prop(id, clave, p.opciones[i])))
				control = ob
		_fila(p.nombre, control)
	_seccion("Acciones")
	var h := HFlowContainer.new()
	h.add_child(_boton("Duplicar", func(): modelo.duplicar(id)))
	h.add_child(_boton("Delante", func(): modelo.traer_delante(id)))
	h.add_child(_boton("Detrás", func(): modelo.enviar_atras(id)))
	var b_borrar := _boton("Borrar", func(): modelo.borrar(id))
	b_borrar.add_theme_color_override("font_color", Estilo.ROJO)
	h.add_child(b_borrar)
	add_child(h)


# ------------------------------------------------------------------ proyecto
func _proyecto() -> void:
	_titulo("Proyecto")
	_fila("Nombre", _texto(str(modelo.datos.get("nombre", "")), func(t):
		_cambiar(func():
			modelo.datos["nombre"] = t
			modelo.registrar())))
	_fila("Página", _texto(str(modelo.pagina().get("nombre", "")), func(t):
		_cambiar(func(): modelo.renombrar_pagina(t))))
	_seccion("Dispositivo")
	var p := modelo.perfil()
	var l := modelo.lienzo()
	var info := Label.new()
	info.text = "%s\n%d × %d dp · %s" % [p.get("nombre", "?"), l.x, l.y, str(modelo.datos.get("orientacion", "vertical"))]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
	add_child(info)
	_seccion("Conexión Bluetooth")
	var con: Dictionary = modelo.datos.get("conexion", {})
	_fila("Módulo", _texto(str(con.get("nombre_dispositivo", "")), func(t):
		_cambiar(func():
			modelo.datos.get_or_add("conexion", {})["nombre_dispositivo"] = t
			modelo.registrar())))
	_fila("Sondeo (ms)", _numero(float(con.get("intervalo_ms", 400)), 50, func(v):
		_cambiar(func():
			modelo.datos.get_or_add("conexion", {})["intervalo_ms"] = int(v)
			modelo.registrar()), 100.0, 10000.0))
	_seccion("Ayuda")
	var ayuda := Label.new()
	ayuda.text = "Pulsa un elemento de la izquierda para añadirlo, o arrástralo al dispositivo.\n\nRatón: mover y estirar por los tiradores.\nFlechas: mover (Mayús ×4).\nSupr: borrar · Ctrl+D: duplicar\nCtrl+Z / Ctrl+Y: deshacer / rehacer\nCtrl+S: guardar"
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.add_theme_color_override("font_color", Estilo.TEXTO_TENUE)
	add_child(ayuda)
