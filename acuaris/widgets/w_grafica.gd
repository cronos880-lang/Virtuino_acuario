class_name WGrafica
extends AcWidget
## Gráfica de historial. "grafica" = un valor con botones de rango; "grafica_avanzada" = hasta 3 valores.
## Los datos se registran mientras la app (o el editor) está abierta (core/historial.gd).
##
## Opciones de la avanzada (todas opcionales, vacías = desactivadas):
##   viva: curva suave con relleno degradado y punto final que late con el valor actual.
##   pin_franja ± pin_franja_ancho: franja verde de confort (p. ej. consigna ± histéresis).
##   pin_actividad: zonas sombreadas cuando el valor es 1 (p. ej. calentador encendido).
##   pin_limite_alto / pin_limite_bajo: líneas punteadas de alarma.
## Al tocar o arrastrar sobre la gráfica se muestran la hora y los valores de ese momento.

const RANGOS := [["15 min", 900], ["1 h", 3600], ["6 h", 21600], ["24 h", 86400], ["7 d", 604800]]
const FRANJA := Color("#3ddc84")

var _rango := -1
var _t := 0.0
var _fase := 0.0
var _rects_rango: Array[Rect2] = []
var _cursor_x := -1.0       # posición del dedo sobre la gráfica (-1 = sin cursor)
var _area := Rect2()


func _init() -> void:
	interactivo = true


func _ready() -> void:
	set_process(true)


func _viva() -> bool:
	return str(def.get("tipo")) == "grafica_avanzada" and bool(prop("viva", false))


func _process(delta: float) -> void:
	_t += delta
	_fase = fmod(_fase + delta, 1.6)
	# Con el punto vivo se redibuja a ~20 imágenes/s para la animación; sin él, cada 2 s.
	if _t > (0.05 if _viva() else 2.0):
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
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if not e.pressed:
			for i in _rects_rango.size():
				if _rects_rango[i].has_point(e.position):
					_rango = i
					_cursor_x = -1.0
					queue_redraw()
					accept_event()
					return
			_cursor_x = -1.0
			queue_redraw()
		elif _area.has_point(e.position):
			_cursor_x = e.position.x
			queue_redraw()
			accept_event()
	elif e is InputEventMouseMotion and _cursor_x >= 0.0 and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_cursor_x = clampf(e.position.x, _area.position.x, _area.end.x)
		queue_redraw()
		accept_event()


## Reduce la serie a como mucho `n` puntos (media por tramos): 7 días son ~120 000 muestras.
static func reducir(datos: Array, n: int) -> Array:
	var ts: PackedFloat64Array = datos[0]
	var vs: PackedFloat32Array = datos[1]
	if ts.size() <= n or n < 2:
		return datos
	var rt := PackedFloat64Array()
	var rv := PackedFloat32Array()
	var paso := float(ts.size()) / n
	for k in n:
		var a := int(k * paso)
		var b := maxi(a + 1, int((k + 1) * paso))
		var st := 0.0
		var sv := 0.0
		for i in range(a, b):
			st += ts[i]
			sv += vs[i]
		rt.append(st / (b - a))
		rv.append(sv / (b - a))
	return [rt, rv]


## Curva suave (Catmull-Rom) que pasa por todos los puntos.
static func suavizar(pts: PackedVector2Array, sub: int = 4) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var r := PackedVector2Array()
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		for s in sub:
			var t := float(s) / sub
			var t2 := t * t
			var t3 := t2 * t
			var p := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			p.y = clampf(p.y, minf(p1.y, p2.y), maxf(p1.y, p2.y))   # sin picos inventados
			r.append(p)
	r.append(pts[pts.size() - 1])
	return r


func _series() -> Array:
	var r := []
	var claves := ["pin", "pin_2", "pin_3"] if str(def.get("tipo")) != "grafica" else ["pin"]
	var nombres := ["nombre", "nombre_2", "nombre_3"]
	var colores := [Estilo.color(prop("color"), Estilo.AGUA), Estilo.color(prop("color_2"), Estilo.AMBAR), Estilo.color(prop("color_3"), Estilo.VERDE)]
	for i in claves.size():
		var p := pin_de(claves[i])
		if p != "":
			var nombre := str(prop(nombres[i], ""))
			r.append({"pin": p, "nombre": nombre if nombre != "" else p, "color": colores[i],
				"datos": reducir(Historial.serie(p, _segundos()), 400)})
	return r


## Valor actual de un pin de las opciones (NAN si no se usa o aún no ha llegado).
func _valor_pin(clave: String) -> float:
	var p := pin_de(clave)
	if p == "" or not valores.has(p):
		return NAN
	return float(valores[p])


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
	var viva := _viva()
	var area := Rect2(px(44), px(32), size.x - px(56) - (px(46) if viva else 0.0), size.y - px(52))
	_area = area
	var series := _series()
	var centro := _valor_pin("pin_franja")
	var ancho := _valor_pin("pin_franja_ancho")
	var hay_franja := not is_nan(centro) and not is_nan(ancho) and ancho > 0.0
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
		if hay_franja:   # la franja de confort siempre a la vista
			mn = minf(mn, centro - ancho)
			mx = maxf(mx, centro + ancho)
		var margen := maxf((mx - mn) * 0.1, 0.05)
		mn -= margen
		mx += margen
		if hay_franja and mx - mn < ancho * 6.0:   # la franja ocupa como mucho un tercio del alto
			var c := (mn + mx) / 2.0
			mn = c - ancho * 3.0
			mx = c + ancho * 3.0
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
	var a_y := func(v: float) -> float: return area.end.y - area.size.y * clampf((v - mn) / (mx - mn), 0, 1)
	var ahora := Historial.ahora()
	var desde := ahora - segundos
	var a_x := func(t: float) -> float: return area.position.x + area.size.x * (t - desde) / segundos
	# Zonas de actividad (p. ej. calentador encendido): columnas suaves y una tira abajo
	var pin_act := pin_de("pin_actividad")
	if pin_act != "":
		var col_act := Estilo.color(prop("color_actividad"), Color("#ff8a3d"))
		var act: Array = Historial.serie(pin_act, segundos)
		var ts: PackedFloat64Array = act[0]
		var vs: PackedFloat32Array = act[1]
		var i := 0
		while i < ts.size():
			if vs[i] >= 0.5:
				var j := i
				while j + 1 < ts.size() and vs[j + 1] >= 0.5:
					j += 1
				var x0: float = a_x.call(ts[i])
				var x1: float = a_x.call(ts[j + 1]) if j + 1 < ts.size() else a_x.call(ahora)
				x1 = maxf(x1, x0 + px(2))
				draw_rect(Rect2(x0, area.position.y, x1 - x0, area.size.y), Color(col_act, 0.10))
				draw_rect(Rect2(x0, area.end.y - px(4), x1 - x0, px(4)), Color(col_act, 0.85))
				i = j + 1
			else:
				i += 1
	# Franja de confort
	if hay_franja:
		var y0: float = a_y.call(centro + ancho)
		var y1: float = a_y.call(centro - ancho)
		draw_rect(Rect2(area.position.x, y0, area.size.x, y1 - y0), Color(FRANJA, 0.12))
		draw_line(Vector2(area.position.x, y0), Vector2(area.end.x, y0), Color(FRANJA, 0.35), px(1))
		draw_line(Vector2(area.position.x, y1), Vector2(area.end.x, y1), Color(FRANJA, 0.35), px(1))
	# Rejilla
	var dec := int(prop("decimales", 1))
	for i in 5:
		var y := area.end.y - area.size.y * i / 4.0
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(1, 1, 1, 0.06), px(1))
		texto(formatear(lerpf(mn, mx, i / 4.0), dec), Rect2(0, y - px(7), area.position.x - px(4), px(14)), 9.5, Estilo.TEXTO_TENUE, "derecha")
	# Líneas de alarma (punteadas), solo si caen dentro de la escala
	for par in [["pin_limite_alto", Estilo.ROJO], ["pin_limite_bajo", Estilo.AGUA]]:
		var lv := _valor_pin(par[0])
		if not is_nan(lv) and lv >= mn and lv <= mx:
			var yl: float = a_y.call(lv)
			draw_dashed_line(Vector2(area.position.x, yl), Vector2(area.end.x, yl), Color(par[1], 0.75), px(1.5), px(5))
	texto(Time.get_time_string_from_unix_time(int(desde + Time.get_time_zone_from_system().bias * 60)).substr(0, 5), Rect2(area.position.x, area.end.y + px(2), px(60), px(14)), 9.5, Estilo.TEXTO_TENUE, "izquierda")
	texto("ahora", Rect2(area.end.x - px(60), area.end.y + px(2), px(60), px(14)), 9.5, Estilo.TEXTO_TENUE, "derecha")
	# Curvas
	var ley_x := area.position.x
	var puntos_finales := []
	for k in series.size():
		var s_: Dictionary = series[k]
		var ts: PackedFloat64Array = s_.datos[0]
		var vs: PackedFloat32Array = s_.datos[1]
		var pts := PackedVector2Array()
		for i in ts.size():
			pts.append(Vector2(a_x.call(ts[i]), a_y.call(vs[i])))
		if viva and k == 0:
			pts = suavizar(pts)
			if pts.size() >= 2:
				# Relleno degradado bajo la curva principal
				var poli := PackedVector2Array(pts)
				poli.append(Vector2(pts[pts.size() - 1].x, area.end.y))
				poli.append(Vector2(pts[0].x, area.end.y))
				var cols := PackedColorArray()
				for p in poli:
					cols.append(Color(s_.color, lerpf(0.32, 0.0, clampf((p.y - area.position.y) / area.size.y, 0, 1))))
				draw_polygon(poli, cols)
		if pts.size() >= 2:
			draw_polyline(pts, s_.color, px(2.5 if viva and k == 0 else 2.0), true)
		elif pts.size() == 1:
			draw_circle(pts[0], px(3), s_.color, true, -1, true)
		if pts.size() >= 1:
			puntos_finales.append([pts[pts.size() - 1], s_, vs[vs.size() - 1]])
		if series.size() > 1:
			draw_circle(Vector2(ley_x + px(5), size.y - px(9)), px(4), s_.color, true, -1, true)
			texto(s_.nombre, Rect2(ley_x + px(12), size.y - px(16), px(70), px(14)), 10, Estilo.TEXTO_SEC, "izquierda")
			ley_x += px(78)
	# Punto vivo y valor actual de la curva principal
	if viva and not puntos_finales.is_empty():
		var pf: Vector2 = puntos_finales[0][0]
		var col: Color = puntos_finales[0][1].color
		var f := _fase / 1.6
		draw_circle(pf, px(4 + 9 * f), Color(col, 0.45 * (1.0 - f)), true, -1, true)
		draw_circle(pf, px(4.5), col, true, -1, true)
		draw_circle(pf, px(2), Estilo.FONDO_ABAJO, true, -1, true)
		var vtxt := formatear(puntos_finales[0][2], dec)
		var caja_v := Rect2(area.end.x + px(4), clampf(pf.y - px(14), area.position.y, area.end.y - px(28)), px(48), px(28))
		texto(vtxt, Rect2(caja_v.position, Vector2(caja_v.size.x, px(18))), 15, col, "centro", true)
		texto(str(prop("unidad", "")), Rect2(caja_v.position + Vector2(0, px(17)), Vector2(caja_v.size.x, px(12))), 9.5, Estilo.TEXTO_TENUE, "centro")
	# Cursor: hora y valores en el punto tocado
	if _cursor_x >= area.position.x and _cursor_x <= area.end.x and not series.is_empty():
		var tc := desde + segundos * (_cursor_x - area.position.x) / area.size.x
		draw_line(Vector2(_cursor_x, area.position.y), Vector2(_cursor_x, area.end.y), Color(1, 1, 1, 0.5), px(1))
		var lineas := [Time.get_time_string_from_unix_time(int(tc + Time.get_time_zone_from_system().bias * 60)).substr(0, 5)]
		for s_ in series:
			var ts: PackedFloat64Array = s_.datos[0]
			if ts.is_empty():
				continue
			var i := clampi(ts.bsearch(tc), 0, ts.size() - 1)
			if i > 0 and absf(ts[i - 1] - tc) < absf(ts[i] - tc):
				i -= 1
			var v: float = s_.datos[1][i]
			draw_circle(Vector2(_cursor_x, a_y.call(v)), px(4), s_.color, true, -1, true)
			lineas.append("%s  %s %s" % [s_.nombre, formatear(v, dec), str(prop("unidad", ""))])
		var wcaja := px(118)
		var hcaja := px(8) + lineas.size() * px(15)
		var xc := _cursor_x + px(8) if _cursor_x + px(8) + wcaja < size.x else _cursor_x - px(8) - wcaja
		var rc := Rect2(xc, area.position.y + px(2), wcaja, hcaja)
		caja(rc, Color(Estilo.FONDO_ABAJO, 0.92), Estilo.TARJETA_BORDE, 8)
		for i in lineas.size():
			texto(lineas[i], Rect2(rc.position.x + px(8), rc.position.y + px(4) + i * px(15), wcaja - px(12), px(15)), 10.5, Estilo.TEXTO if i == 0 else Estilo.TEXTO_SEC, "izquierda", i == 0)
