class_name VistaPagina
extends Control
## Dibuja una página del proyecto a escala s (px por dp) y reparte los valores a sus elementos.

signal escritura_solicitada(pin: String, valor: float)

var s := 1.0
var ancho_dp := 384.0
var alto_dp := 832.0
var _widgets: Array[AcWidget] = []


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
		add_child(w)
		_widgets.append(w)
		max_y = maxf(max_y, float(d.y) + float(d.h))
	custom_minimum_size = Vector2(ancho_dp, max_y + 16.0) * s
	size = custom_minimum_size
	queue_redraw()


func recibir(pin: String, v: float) -> void:
	for w in _widgets:
		w.recibir(pin, v)
