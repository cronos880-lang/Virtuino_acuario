class_name WHidraulica
extends AcWidget
## Piezas para dibujar un esquema hidráulico animado (depósito, tuberías, válvulas, bomba...).
## Tuberías y accesorios se unen borde con borde: usa el mismo "tubo" (grosor en dp) en las piezas
## que se tocan. Tuberías/bomba/caudalímetro siguen un número (caudal o velocidad); válvulas y
## actuadores siguen una condición (props.condicion, por defecto ">= 0.5").

const TIPOS := ["deposito", "tuberia_h", "tuberia_v", "acoplamiento", "codo", "te", "cruz", "reduccion",
	"valvula_2v", "valvula_3v", "acoplamiento_eje", "bomba_h", "antirretorno", "caudalimetro",
	"volante", "maneta", "motor", "solenoide", "manometro_peq", "sensor", "agitador", "chorro"]

var _fase := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	var v := _velocidad()
	if v > 0.0:
		_fase = fmod(_fase + delta * v, 1000.0)
		queue_redraw()


func tipo() -> String:
	return str(def.get("tipo", ""))


func _activo() -> bool:
	return tiene_valor() and AcWidget.cumple(str(prop("condicion", ">= 0.5")), valor())


## 0..1 según el valor entre min y max (para caudal y velocidad).
func _fraccion() -> float:
	if not tiene_valor():
		return 0.0
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 1))
	return clampf((valor() - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0)


func _velocidad() -> float:
	match tipo():
		"deposito":
			return 0.6 if _fraccion() > 0.0 else 0.0
		"volante", "maneta", "solenoide", "sensor", "manometro_peq", "valvula_2v", "valvula_3v", "antirretorno":
			return 0.0
		"motor", "agitador", "chorro":
			return 1.5 if _activo() else 0.0
	return 3.0 * _fraccion()


func _t() -> float:
	return px(float(prop("tubo", 18)))


func _c_tubo() -> Color:
	return Estilo.color(prop("color_tubo"), Color("#5f7c8e"))


func _c_liquido() -> Color:
	return Estilo.color(prop("color_liquido"), Estilo.AGUA)


func _brazos() -> Array:
	var o := int(prop("orientacion", 0)) % 4
	match tipo():
		"tuberia_v":
			return ["N", "S"]
		"codo":
			return [["E", "S"], ["S", "W"], ["W", "N"], ["N", "E"]][o]
		"te", "valvula_3v":
			return [["E", "W", "S"], ["N", "S", "W"], ["E", "W", "N"], ["N", "S", "E"]][o]
		"cruz":
			return ["N", "S", "E", "W"]
	return ["E", "W"]


func _dibujar_brazo(c: Vector2, lado: String, t: float, fluye: bool) -> void:
	var r: Rect2
	match lado:
		"E": r = Rect2(c.x, c.y - t * 0.5, size.x - c.x, t)
		"W": r = Rect2(0, c.y - t * 0.5, c.x, t)
		"N": r = Rect2(c.x - t * 0.5, 0, t, c.y)
		"S": r = Rect2(c.x - t * 0.5, c.y, t, size.y - c.y)
	_tubo_recto(r, lado in ["E", "W"], fluye, 1.0 if lado in ["E", "S"] else -1.0)


func _tubo_recto(r: Rect2, horizontal: bool, fluye: bool, sentido := 1.0) -> void:
	var col := _c_tubo()
	draw_rect(r, col)
	# brillo
	if horizontal:
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.15, r.size.x, r.size.y * 0.18), Color(1, 1, 1, 0.18))
		draw_line(r.position, Vector2(r.end.x, r.position.y), col.darkened(0.35), px(1))
		draw_line(Vector2(r.position.x, r.end.y), r.end, col.darkened(0.35), px(1))
	else:
		draw_rect(Rect2(r.position.x + r.size.x * 0.15, r.position.y, r.size.x * 0.18, r.size.y), Color(1, 1, 1, 0.18))
		draw_line(r.position, Vector2(r.position.x, r.end.y), col.darkened(0.35), px(1))
		draw_line(Vector2(r.end.x, r.position.y), r.end, col.darkened(0.35), px(1))
	if not fluye:
		return
	# Líquido y trazos que avanzan
	var liq := _c_liquido()
	var inner := r.grow_individual(0, -r.size.y * 0.3, 0, -r.size.y * 0.3) if horizontal else r.grow_individual(-r.size.x * 0.3, 0, -r.size.x * 0.3, 0)
	draw_rect(inner, Color(liq, 0.55))
	var paso := px(16)
	var largo := px(7)
	var desp := fposmod(_fase * px(30) * sentido * (-1.0 if bool(prop("invertir", false)) else 1.0), paso)
	if horizontal:
		var x := r.position.x - paso + desp
		while x < r.end.x:
			var a := maxf(x, r.position.x)
			var b := minf(x + largo, r.end.x)
			if b > a:
				draw_rect(Rect2(a, inner.position.y, b - a, inner.size.y), Color(1, 1, 1, 0.55))
			x += paso
	else:
		var y := r.position.y - paso + desp
		while y < r.end.y:
			var a := maxf(y, r.position.y)
			var b := minf(y + largo, r.end.y)
			if b > a:
				draw_rect(Rect2(inner.position.x, a, inner.size.x, b - a), Color(1, 1, 1, 0.55))
			y += paso


func _draw() -> void:
	match tipo():
		"deposito":
			_deposito()
		"volante", "maneta", "motor", "solenoide", "manometro_peq", "sensor", "agitador", "chorro":
			_accesorio()
		_:
			_linea()
	var et := str(prop("etiqueta", ""))
	if et != "" and tipo() != "sensor":
		texto(et, Rect2(0, size.y - px(14), size.x, px(14)), 10, Estilo.TEXTO_SEC)


func _linea() -> void:
	var t := _t()
	var c := size * 0.5
	var fluye := _fraccion() > 0.0
	match tipo():
		"valvula_2v", "antirretorno":
			fluye = _activo() if tipo() == "valvula_2v" else _fraccion() > 0.0 or _activo()
		"valvula_3v":
			fluye = tiene_valor()
	if tipo() == "reduccion":
		var t2 := px(float(prop("tubo_2", 10)))
		_tubo_recto(Rect2(0, c.y - t * 0.5, c.x, t), true, fluye)
		_tubo_recto(Rect2(c.x, c.y - t2 * 0.5, size.x - c.x, t2), true, fluye)
		draw_colored_polygon(PackedVector2Array([Vector2(c.x - px(4), c.y - t * 0.5), Vector2(c.x + px(6), c.y - t2 * 0.5), Vector2(c.x + px(6), c.y + t2 * 0.5), Vector2(c.x - px(4), c.y + t * 0.5)]), _c_tubo().darkened(0.15))
		return
	var brazos := _brazos()
	if tipo() == "valvula_3v":
		# 0 -> paso recto (primeros dos brazos), otro valor -> hacia la derivación
		var recto := tiene_valor() and is_zero_approx(valor())
		for i in brazos.size():
			var con_flujo := fluye and (i < 2 if recto else i != 1)
			_dibujar_brazo(c, brazos[i], t, con_flujo)
	else:
		for b in brazos:
			_dibujar_brazo(c, b, t, fluye)
	draw_rect(Rect2(c - Vector2(t, t) * 0.5, Vector2(t, t)), _c_tubo().darkened(0.1))
	match tipo():
		"acoplamiento":
			for dx in [-t * 0.6, t * 0.6]:
				draw_rect(Rect2(c.x + dx - px(3), c.y - t * 0.75, px(6), t * 1.5), _c_tubo().lightened(0.15))
		"acoplamiento_eje":
			draw_rect(Rect2(c.x - t * 0.35, 0, t * 0.7, c.y - t * 0.5), _c_tubo().darkened(0.2))
			draw_rect(Rect2(c.x - t * 0.6, c.y - t * 0.75, t * 1.2, px(5)), _c_tubo().lightened(0.15))
		"valvula_2v", "valvula_3v":
			var col := Estilo.VERDE if (_activo() if tipo() == "valvula_2v" else tiene_valor()) else Estilo.ROJO
			var h := t * 0.95
			draw_colored_polygon(PackedVector2Array([c + Vector2(-h, -h), c, c + Vector2(-h, h)]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(h, -h), c, c + Vector2(h, h)]), col)
			draw_rect(Rect2(c.x - px(2), c.y - h * 1.6, px(4), h * 1.6), _c_tubo().darkened(0.3))
			draw_rect(Rect2(c.x - h * 0.5, c.y - h * 1.6 - px(4), h, px(5)), _c_tubo().lightened(0.1))
		"antirretorno":
			var h := t * 0.8
			draw_circle(c, h, Color("#24485e"), true, -1, true)
			var dir := -1.0 if bool(prop("invertir", false)) else 1.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.5 * dir, -h * 0.6), c + Vector2(h * 0.6 * dir, 0), c + Vector2(-h * 0.5 * dir, h * 0.6)]), Estilo.VERDE if fluye else Estilo.TEXTO_TENUE)
		"bomba_h":
			var rr := minf(size.y * 0.42, t * 1.6)
			draw_circle(c, rr, Color("#24485e"), true, -1, true)
			draw_circle(c, rr, _c_tubo().lightened(0.2), false, px(2), true)
			var col := Estilo.VERDE if _fraccion() > 0 else Estilo.TEXTO_TENUE
			for i in 5:
				var a := _fase * 2.0 + TAU * i / 5.0
				draw_line(c + Vector2.from_angle(a) * rr * 0.15, c + Vector2.from_angle(a + 0.5) * rr * 0.8, col, px(3), true)
			draw_circle(c, rr * 0.15, Color("#dfe9ef"), true, -1, true)
		"caudalimetro":
			var rr := minf(size.y * 0.42, t * 1.5)
			draw_circle(c, rr, Color("#e9f1f5"), true, -1, true)
			draw_circle(c, rr, _c_tubo().darkened(0.2), false, px(2), true)
			var a := lerpf(deg_to_rad(135), deg_to_rad(405), _fraccion())
			draw_line(c, c + Vector2.from_angle(a) * rr * 0.8, Estilo.ROJO, px(2), true)
			draw_circle(c, px(2.5), Color("#123247"), true, -1, true)


func _accesorio() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.45
	var on := _activo()
	var col := Estilo.VERDE if on else Estilo.ROJO
	match tipo():
		"volante":
			draw_line(Vector2(c.x, c.y), Vector2(c.x, size.y), _c_tubo().darkened(0.3), px(4), true)
			draw_circle(c, r * 0.9, col, false, px(4), true)
			for i in 3:
				draw_line(c, c + Vector2.from_angle(TAU * i / 3.0 - PI / 2) * r * 0.9, col, px(3), true)
			draw_circle(c, px(4), Color("#dfe9ef"), true, -1, true)
		"maneta":
			var base := Vector2(c.x, size.y - px(4))
			draw_circle(base, px(5), _c_tubo().darkened(0.2), true, -1, true)
			var a := deg_to_rad(-90.0 if on else -10.0)
			draw_line(base, base + Vector2.from_angle(a) * r * 1.6, col, px(6), true)
		"motor":
			var caja_r := Rect2(c.x - r, c.y - r * 0.8, r * 2, r * 1.6)
			caja(caja_r, Color("#24485e"), _c_tubo().lightened(0.2), 6)
			for i in 4:
				var a := _fase * 3.0 + TAU * i / 4.0
				draw_line(c, c + Vector2.from_angle(a) * r * 0.6, Estilo.VERDE if on else Estilo.TEXTO_TENUE, px(3), true)
			draw_line(Vector2(c.x, caja_r.end.y), Vector2(c.x, size.y), _c_tubo().darkened(0.3), px(4), true)
		"solenoide":
			var rr := Rect2(c.x - r * 0.7, c.y - r, r * 1.4, r * 1.6)
			if on:
				draw_rect(rr.grow(px(4)), Color(Estilo.AMBAR, 0.3))
			caja(rr, Estilo.AMBAR if on else Color("#24485e"), _c_tubo().lightened(0.2), 4)
			for i in 4:
				var y := rr.position.y + rr.size.y * (i + 1) / 5.0
				draw_line(Vector2(rr.position.x, y), Vector2(rr.end.x, y), Color(0, 0, 0, 0.3), px(1))
			draw_line(Vector2(c.x, rr.end.y), Vector2(c.x, size.y), _c_tubo().darkened(0.3), px(4), true)
		"manometro_peq":
			draw_line(Vector2(c.x, c.y + r * 0.8), Vector2(c.x, size.y), _c_tubo().darkened(0.3), px(4), true)
			draw_circle(c, r * 0.85, Color("#e9f1f5"), true, -1, true)
			draw_circle(c, r * 0.85, _c_tubo().darkened(0.2), false, px(2), true)
			var a := lerpf(deg_to_rad(135), deg_to_rad(405), _fraccion())
			draw_line(c, c + Vector2.from_angle(a) * r * 0.7, Estilo.ROJO, px(2), true)
			if tiene_valor():
				texto(formatear(valor(), int(prop("decimales", 1))), Rect2(0, c.y + r * 0.25, size.x, px(12)), 9, Color("#123247"), "centro", true)
		"sensor":
			draw_line(Vector2(c.x, c.y + r * 0.7), Vector2(c.x, size.y), _c_tubo().darkened(0.3), px(4), true)
			draw_circle(c, r * 0.75, Color("#24485e"), true, -1, true)
			draw_circle(c, r * 0.75, Estilo.AGUA if tiene_valor() else Estilo.TEXTO_TENUE, false, px(2), true)
			texto(str(prop("etiqueta", "TT")), Rect2(c - Vector2(r, r * 0.4), Vector2(r * 2, r * 0.8)), 11, Estilo.TEXTO, "centro", true)
		"agitador":
			draw_line(Vector2(c.x, 0), Vector2(c.x, size.y * 0.85), _c_tubo().lightened(0.1), px(3), true)
			var y := size.y * 0.85
			var ang := _fase * 4.0
			var w := r * absf(cos(ang))
			draw_line(Vector2(c.x - w, y), Vector2(c.x + w, y), Estilo.VERDE if on else Estilo.TEXTO_TENUE, px(6), true)
		"chorro":
			if not on:
				return
			var liq := _c_liquido()
			var pts := PackedVector2Array()
			var ancho := minf(size.x * 0.5, px(float(prop("tubo", 18)) * 0.6))
			var n := 12
			for i in n + 1:
				var y := size.y * i / n
				pts.append(Vector2(c.x - ancho * 0.5 + sin(_fase * 6.0 + i) * px(1.5), y))
			for i in range(n, -1, -1):
				var y := size.y * i / n
				pts.append(Vector2(c.x + ancho * 0.5 + sin(_fase * 6.0 + i + 1.3) * px(1.5), y))
			draw_colored_polygon(pts, Color(liq, 0.75))
			draw_circle(Vector2(c.x, size.y - px(3)), ancho * 0.9, Color(liq, 0.35), true, -1, true)


func _forma_deposito() -> PackedVector2Array:
	var m := px(4)
	var r := Rect2(m, m, size.x - m * 2, size.y - m * 2 - px(14))
	var p := PackedVector2Array()
	match str(prop("forma", "redondeado")):
		"caja":
			p = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		"cilindro", "barril":
			var k := r.size.y * 0.08
			var barril := str(prop("forma")) == "barril"
			for i in 13:
				var a := PI + PI * i / 12.0
				p.append(Vector2(r.get_center().x + cos(a) * r.size.x * 0.5, r.position.y + k + sin(a) * k))
			if barril:
				p.append(Vector2(r.end.x + px(4), r.get_center().y))
			for i in 13:
				var a := PI * i / 12.0
				p.append(Vector2(r.get_center().x + cos(a) * r.size.x * 0.5, r.end.y - k + sin(a) * k))
			if barril:
				p.append(Vector2(r.position.x - px(4), r.get_center().y))
		"conico":
			var cono := r.size.y * 0.25
			p = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y - cono), Vector2(r.get_center().x + px(8), r.end.y), Vector2(r.get_center().x - px(8), r.end.y), Vector2(r.position.x, r.end.y - cono)])
		_:
			var rad := minf(px(18), minf(r.size.x, r.size.y) * 0.2)
			for esq in [[r.end - Vector2(rad, rad), 0.0], [Vector2(r.position.x + rad, r.end.y - rad), PI * 0.5], [r.position + Vector2(rad, rad), PI], [Vector2(r.end.x - rad, r.position.y + rad), PI * 1.5]]:
				for i in 7:
					var a: float = esq[1] + PI * 0.5 * i / 6.0
					p.append(esq[0] + Vector2.from_angle(a) * rad)
	return p


func _deposito() -> void:
	var forma := _forma_deposito()
	draw_colored_polygon(forma, Color("#0b2233"))
	var f := _fraccion() if tiene_valor() else 0.0
	if f > 0.0:
		var arriba := INF
		var abajo := -INF
		for q in forma:
			arriba = minf(arriba, q.y)
			abajo = maxf(abajo, q.y)
		var nivel := lerpf(abajo, arriba, f)
		var ola := PackedVector2Array()
		var n := 24
		for i in n + 1:
			var x := -px(10) + (size.x + px(20)) * i / n
			ola.append(Vector2(x, nivel + sin(i * 0.9 + _fase * 2.0) * px(2.5)))
		ola.append(Vector2(size.x + px(10), abajo + px(10)))
		ola.append(Vector2(-px(10), abajo + px(10)))
		for poligono in Geometry2D.intersect_polygons(forma, ola):
			draw_colored_polygon(poligono, Color(_c_liquido(), 0.85))
	var cerrado := forma.duplicate()
	cerrado.append(forma[0])
	draw_polyline(cerrado, _c_tubo().lightened(0.25), px(2.5), true)
	var txt := "%d %%" % roundi(f * 100.0) if tiene_valor() else "--"
	if str(prop("mostrar", "porcentaje")) == "valor" and tiene_valor():
		txt = (formatear(valor(), int(prop("decimales", 0))) + " " + str(prop("unidad", ""))).strip_edges()
	texto(txt, Rect2(0, size.y * 0.35, size.x, px(20)), 15, Estilo.TEXTO, "centro", true)
