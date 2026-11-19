class_name VistaPagina
extends Control
## Dibuja una página del proyecto a escala s (px por dp) y reparte los valores a sus elementos.
## En el editor (modo_editor) los elementos no reciben pulsaciones y se puede mostrar la rejilla.

signal escritura_solicitada(pin: String, valor: float)

var s := 1.0
var ancho_dp := 384.0
var alto_dp := 832.0
var modo_editor := false
var rejilla_dp := 0.0
var _widgets: Array[AcWidget] = []
var _valores: Dictionary = {}


func construir(pagina: Dictionary, escala: float, ancho: float, alto: float) -> void:
	s = escala
	ancho_dp = ancho
	alto_dp = alto
	for w in _widgets:
		w.queue_free()
	_widgets.clear()
	var max_y := 0.0
	for d in pagina.get("widgets", []):
		var w := FabricaWidgets.crear(d, s)
		if w == null:
			push_warning("Tipo no soportado: %s" % d.get("tipo"))
			continue
		w.escritura_solicitada.connect(func(p, v): escritura_solicitada.emit(p, v))
		if modo_editor:
			w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(w)
		_widgets.append(w)
		max_y = maxf(max_y, float(d.y) + float(d.h))
		for p in _valores:
			w.recibir(p, _valores[p])
	if modo_editor:
		custom_minimum_size = Vector2(ancho_dp, alto_dp) * s
	else:
		custom_minimum_size = Vector2(ancho_dp, max_y + 16.0) * s
	size = custom_minimum_size
	queue_redraw()


func widget(id: String) -> AcWidget:
	for w in _widgets:
		if w.def.get("id") == id:
			return w
	return null


## Recoloca/redibuja un único elemento (durante un arrastre en el editor).
func actualizar(def: Dictionary) -> void:
	var w := widget(str(def.get("id")))
	if w:
		w.configurar(def, s)
		if modo_editor:
			w.mouse_filter = Control.MOUSE_FILTER_IGNORE


func recibir(pin: String, v: float) -> void:
	_valores[pin] = v
	for w in _widgets:
		w.recibir(pin, v)


func _draw() -> void:
	if rejilla_dp <= 0.0 or not modo_editor:
		return
	var paso := rejilla_dp * s
	while paso < 10.0:
		paso *= 2.0
	var col := Color(1, 1, 1, 0.07)
	var x := 0.0
	while x <= size.x:
		var y := 0.0
		while y <= size.y:
			draw_rect(Rect2(x - 0.5, y - 0.5, 1.5, 1.5), col)
			y += paso
		x += paso
