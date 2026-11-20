class_name DialogoApp
extends Control
## Ventanas emergentes de la app con el estilo de Acuaris (confirmar, PIN, número, contenido libre).
## Se colocan encima de todo, en la raíz de la ventana.

signal cerrado

var s := 1.0
var _caja: VBoxContainer


static func _nuevo(origen: Node, escala: float, titulo: String) -> DialogoApp:
	var d := DialogoApp.new()
	d.s = escala
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	origen.get_tree().root.add_child(d)
	d._montar(titulo)
	return d


func _montar(titulo: String) -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Estilo.TARJETA
	sb.border_color = Estilo.TARJETA_BORDE
	sb.set_border_width_all(maxi(1, roundi(s)))
	sb.set_corner_radius_all(roundi(18 * s))
	for lado in ["left", "right", "top", "bottom"]:
		sb.set("content_margin_" + lado, 18 * s)
	panel.add_theme_stylebox_override("panel", sb)
	var ancho := minf(get_viewport_rect().size.x - 32 * s, 520 * s)
	panel.custom_minimum_size.x = ancho
	centro.add_child(panel)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", roundi(12 * s))
	panel.add_child(_caja)
	if titulo != "":
		_caja.add_child(etiqueta(titulo, 18, Estilo.TEXTO, true))


func etiqueta(t: String, tam: float, col: Color, negrita := false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200 * s
	l.add_theme_font_override("font", Estilo.fuente(negrita))
	l.add_theme_font_size_override("font_size", roundi(tam * s))
	l.add_theme_color_override("font_color", col)
	return l


func campo(marcador: String, secreto := false) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = marcador
	le.secret = secreto
	le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	le.add_theme_font_size_override("font_size", roundi(18 * s))
	le.add_theme_color_override("font_color", Estilo.TEXTO)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0a1c28")
	sb.border_color = Estilo.AGUA
	sb.set_border_width_all(maxi(1, roundi(s)))
	sb.set_corner_radius_all(roundi(10 * s))
	for lado in ["left", "right", "top", "bottom"]:
		sb.set("content_margin_" + lado, 12 * s)
	le.add_theme_stylebox_override("normal", sb)
	le.add_theme_stylebox_override("focus", sb)
	return le


func botones(lista: Array) -> void:
	# lista de [texto, destacado, callable]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", roundi(10 * s))
	h.alignment = BoxContainer.ALIGNMENT_END
	for b in lista:
		var bt := Button.new()
		bt.text = b[0]
		bt.custom_minimum_size = Vector2(110, 46) * s
		bt.add_theme_font_size_override("font_size", roundi(15 * s))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Estilo.AGUA if b[1] else Color("#143247")
		sb.set_corner_radius_all(roundi(12 * s))
		bt.add_theme_stylebox_override("normal", sb)
		bt.add_theme_stylebox_override("hover", sb)
		bt.add_theme_stylebox_override("pressed", sb)
		bt.add_theme_color_override("font_color", Estilo.FONDO_ABAJO if b[1] else Estilo.TEXTO)
		bt.add_theme_color_override("font_hover_color", Estilo.FONDO_ABAJO if b[1] else Estilo.TEXTO)
		bt.add_theme_color_override("font_pressed_color", Estilo.FONDO_ABAJO if b[1] else Estilo.TEXTO)
		var f: Callable = b[2]
		bt.pressed.connect(func(): f.call())
		h.add_child(bt)
	_caja.add_child(h)


func anadir(c: Control) -> void:
	_caja.add_child(c)


func cerrar() -> void:
	cerrado.emit()
	queue_free()


## ¿Seguro? (y PIN opcional). Llama a al_aceptar solo si se confirma y el PIN es correcto.
static func confirmar(origen: Node, escala: float, texto: String, clave: String, al_aceptar: Callable) -> DialogoApp:
	var d := _nuevo(origen, escala, "Confirmar")
	d.anadir(d.etiqueta(texto, 15, Estilo.TEXTO_SEC))
	var le: LineEdit = null
	var aviso := d.etiqueta("", 13, Estilo.ROJO)
	if clave != "":
		le = d.campo("PIN", true)
		d.anadir(le)
		d.anadir(aviso)
	d.botones([["Cancelar", false, d.cerrar], ["Aceptar", true, func():
		if le != null and le.text.strip_edges() != clave:
			aviso.text = "PIN incorrecto"
			return
		d.cerrar()
		al_aceptar.call()]])
	return d


## Pide un número y lo devuelve a al_aceptar(valor).
## "convertir" (opcional) recibe el texto y devuelve un número o null si no es válido.
static func pedir_numero(origen: Node, escala: float, titulo: String, actual: String, al_aceptar: Callable, convertir := Callable(), ayuda := "") -> DialogoApp:
	var d := _nuevo(origen, escala, titulo)
	var le := d.campo("Valor")
	le.text = actual
	if convertir.is_valid():
		le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_URL   # admite ":" y "."
	d.anadir(le)
	if ayuda != "":
		d.anadir(d.etiqueta(ayuda, 12, Estilo.TEXTO_SEC))
	var aviso := d.etiqueta("", 13, Estilo.ROJO)
	d.anadir(aviso)
	d.botones([["Cancelar", false, d.cerrar], ["Enviar", true, func():
		var t := le.text.strip_edges().replace(",", ".")
		if convertir.is_valid():
			var v = convertir.call(t)
			if v == null:
				aviso.text = "Valor no válido"
				return
			d.cerrar()
			al_aceptar.call(float(v))
			return
		if not t.is_valid_float():
			aviso.text = "Escribe un número"
			return
		d.cerrar()
		al_aceptar.call(t.to_float())]])
	le.grab_focus.call_deferred()
	return d


## Ventana con un contenido libre (gráfica, tabla...) y botón Cerrar.
static func mostrar(origen: Node, escala: float, titulo: String, contenido: Control, extra: Array = []) -> DialogoApp:
	var d := _nuevo(origen, escala, titulo)
	d.anadir(contenido)
	var lista := extra.duplicate()
	lista.append(["Cerrar", true, d.cerrar])
	d.botones(lista)
	return d
