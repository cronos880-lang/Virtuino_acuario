class_name WGrafica
extends AcWidget
## Gráfica de historial. "grafica" = un valor con botones de rango; "grafica_avanzada" = hasta 3 valores.
## Los datos se registran mientras la app (o el editor) está abierta (core/historial.gd).

const RANGOS := [["15 min", 900], ["1 h", 3600], ["6 h", 21600], ["24 h", 86400], ["7 d", 604800]]

var _rango := -1
var _t := 0.0
var _rects_rango: Array[Rect2] = []


func _init() -> void:
	interactivo = true


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _t > 2.0:
		_t = 0.0
		queue_redraw()


func _segundos() -> float:
	if _rango < 0:
		var txt := str(prop("rango", "1 h"))
		for i in RANGOS.size():
			if RANGOS[i][0] == txt:
				_rango = i
		if _rango < 0:
			_rango = 1
	return float(RANGOS[_rango][1])


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		for i in _rects_rango.size():
			if _rects_rango[i].has_point(e.position):
				_rango = i
				queue_redraw()
				accept_event()


func _series() -> Array:
	var r := []
	var claves := ["pin", "pin_2", "pin_3"] if str(def.get("tipo")) != "grafica" else ["pin"]
	var colores := [Estilo.color(prop("color"), Estilo.AGUA), Estilo.color(prop("color_2"), Estilo.AMBAR), Estilo.color(prop("color_3"), Estilo.VERDE)]
	for i in claves.size():
		var p := pin_de(claves[i])
		if p != "":
			r.append({"pin": p, "color": colores[i], "datos": Historial.serie(p, _segundos())})
	return r


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if bool(prop("con_fondo", true)):
		caja(r, Estilo.TARJETA, Estilo.TARJETA_BORDE, 14)
	texto(str(prop("titulo", "")), Rect2(px(12), px(6), size.x * 0.5, px(18)), 13, Estilo.TEXTO, "izquierda", true)
	# Botones de rango
	_rects_rango.clear()
	var x := size.x - px(10)
	for i in range(RANGOS.size() - 1, -1, -1):
		var t: String = RANGOS[i][0]
		var w := ancho_texto(t, 10.5, true) + px(12)
		x -= w
		var rr := Rect2(x, px(6), w, px(18))
		_rects_rango.push_front(rr)
		var sel := i == _rango or (_rango < 0 and t == str(prop("rango", "1 h")))
		caja(rr, Estilo.AGUA if sel else Color(Estilo.APAGADO, 0.5), Color.TRANSPARENT, 9)
		texto(t, rr, 10.5, Estilo.FONDO_ABAJO if sel else Estilo.TEXTO_SEC, "centro", true)
		x -= px(4)
	var segundos := _segundos()
	var area := Rect2(px(44), px(32), size.x - px(56), size.y - px(52))
	var series := _series()
	# Rango vertical
	# Escala automática robusta: percentiles 2 % y 98 % (un valor suelto, como el 0 inicial
	# antes de la primera lectura, no aplasta la curva). Los valores fuera se dibujan en el borde.
	var todos := PackedFloat32Array()
	for s_ in series:
		todos.append_array(s_.datos[1])
	var mn := INF
	var mx := -INF
	if not todos.is_empty():
		todos.sort()
		mn = todos[int((todos.size() - 1) * 0.02)]
		mx = todos[int(ceil((todos.size() - 1) * 0.98))]
		var margen := (mx - mn) * 0.1
		mn -= margen
		mx += margen
	if str(prop("min", "")) != "":
		mn = float(prop("min"))
	if str(prop("max", "")) != "":
		mx = float(prop("max"))
	if mn == INF:
		texto("Sin datos todavía.\nSe registran mientras la app está abierta.", area, 11.5, Estilo.TEXTO_TENUE)
		return
	if is_equal_approx(mn, mx):
		mn -= 1.0
		mx += 1.0
	# Rejilla
	var dec := int(prop("decimales", 1))
	for i in 5:
		var y := area.end.y - area.size.y * i / 4.0
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(1, 1, 1, 0.06), px(1))
		texto(formatear(lerpf(mn, mx, i / 4.0), dec), Rect2(0, y - px(7), area.position.x - px(4), px(14)), 9.5, Estilo.TEXTO_TENUE, "derecha")
	var ahora := Historial.ahora()
	var desde := ahora - segundos
	texto(Time.get_time_string_from_unix_time(int(desde + Time.get_time_zone_from_system().bias * 60)).substr(0, 5), Rect2(area.position.x, area.end.y + px(2), px(60), px(14)), 9.5, Estilo.TEXTO_TENUE, "izquierda")
	texto("ahora", Rect2(area.end.x - px(60), area.end.y + px(2), px(60), px(14)), 9.5, Estilo.TEXTO_TENUE, "derecha")
	# Líneas
	var ley_x := area.position.x
	for s_ in series:
		var ts: PackedFloat64Array = s_.datos[0]
		var vs: PackedFloat32Array = s_.datos[1]
		var pts := PackedVector2Array()
		for i in ts.size():
			pts.append(Vector2(area.position.x + area.size.x * (ts[i] - desde) / segundos, area.end.y - area.size.y * clampf((vs[i] - mn) / (mx - mn), 0, 1)))
		if pts.size() >= 2:
			draw_polyline(pts, s_.color, px(2), true)
		elif pts.size() == 1:
			draw_circle(pts[0], px(3), s_.color, true, -1, true)
		if series.size() > 1:
			draw_circle(Vector2(ley_x + px(5), size.y - px(9)), px(4), s_.color, true, -1, true)
			texto(s_.pin, Rect2(ley_x + px(12), size.y - px(16), px(50), px(14)), 10, Estilo.TEXTO_SEC, "izquierda")
			ley_x += px(64)
