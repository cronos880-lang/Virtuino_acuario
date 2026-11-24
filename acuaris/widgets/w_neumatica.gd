class_name WNeumatica
extends AcWidget
## Elementos neumáticos (símbolos inspirados en ISO 1219, dibujados en vectorial):
##   cilindro_de / cilindro_se: el vástago sigue al valor (entre mínimo y máximo) con movimiento suave;
##     pin_fin_a / pin_fin_b = detectores de final de carrera (se encienden en los extremos).
##   valvula_52 / valvula_32: electroválvula; con la condición cumplida cambia la casilla activa.
##   compresor_n, frl, silenciador, ventosa, pinza, detector, linea_h, linea_v.

var _pos := 0.0          # posición dibujada del vástago (0..1), se acerca al valor real
var _fase := 0.0
var _colocado := false   # con el primer valor se coloca sin animación


func _ready() -> void:
	set_process(true)


func _activo() -> bool:
	return tiene_valor() and AcWidget.cumple(str(prop("condicion", ">= 0.5")), valor())


func _objetivo() -> float:
	if not tiene_valor():
		return 0.0
	var mn := float(prop("min", 0.0))
	var mx := float(prop("max", 1.0))
	return clampf((valor() - mn) / (mx - mn), 0.0, 1.0) if mx != mn else 0.0


func _process(delta: float) -> void:
	var tipo := str(def.get("tipo"))
	if tipo.begins_with("cilindro"):
		var obj := _objetivo()
		if not _colocado and tiene_valor():
			_colocado = true
			_pos = obj
			queue_redraw()
		if absf(obj - _pos) > 0.002:
			_pos = move_toward(_pos, obj, delta / maxf(float(prop("tiempo", 0.6)), 0.05))
			queue_redraw()
	elif tipo == "compresor_n" and _activo():
		_fase = fmod(_fase + delta, 1.0)
		queue_redraw()


func _col() -> Color:
	return Estilo.color(prop("color"), Color("#4da3ff"))


func _trazo(on: bool) -> Color:
	return _col() if on else Color("#8db3ca")


func _l(a: Vector2, b: Vector2, c: Color, g := 2.0) -> void:
	draw_line(a, b, c, px(g), true)


func _caja_l(r: Rect2, c: Color, g := 2.0) -> void:
	draw_rect(r, c, false, px(g))


func _flecha(a: Vector2, b: Vector2, c: Color) -> void:
	_l(a, b, c, 1.6)
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([b, b - d * px(7) + n * px(4), b - d * px(7) - n * px(4)]), c)


func _etiqueta(r: Rect2) -> void:
	var e := str(prop("etiqueta", ""))
	if e != "":
		texto(e, r, 11, Estilo.TEXTO_SEC, "centro", true)


func _muelle(x0: float, x1: float, yc: float, h: float, c: Color) -> void:
	var n := 6
	var pts := PackedVector2Array()
	for i in n + 1:
		pts.append(Vector2(lerpf(x0, x1, float(i) / n), yc + (h if i % 2 == 1 else -h)))
	draw_polyline(pts, c, px(1.6), true)


func _solenoide(r: Rect2, c: Color, on: bool) -> void:
	if on:
		draw_rect(r, Color(c, 0.35))
	_caja_l(r, c, 1.6)
	_l(r.position + Vector2(r.size.x * 0.25, r.size.y), r.position + Vector2(r.size.x * 0.75, 0), c, 1.6)


func _draw() -> void:
	var tipo := str(def.get("tipo"))
	var on := _activo()
	var c := _col()
	var tr := _trazo(on)
	var gris := Color("#8db3ca")
	var w := size.x
	var h := size.y
	match tipo:
		"cilindro_de", "cilindro_se":
			var alto_etq := px(16) if str(prop("etiqueta", "")) != "" else 0.0
			var cuerpo := Rect2(px(4), px(8), w * 0.62, h - px(16) - alto_etq)
			var cy := cuerpo.get_center().y
			var presion := Color(c, 0.22)
			var xp := cuerpo.position.x + px(8) + (cuerpo.size.x - px(20)) * _pos
			# Cámara con presión (lado que empuja) en color
			if tiene_valor():
				if _objetivo() >= _pos - 0.01:
					draw_rect(Rect2(cuerpo.position, Vector2(xp - cuerpo.position.x, cuerpo.size.y)), presion)
				elif tipo == "cilindro_de":
					draw_rect(Rect2(Vector2(xp + px(6), cuerpo.position.y), Vector2(cuerpo.end.x - xp - px(6), cuerpo.size.y)), presion)
			_caja_l(cuerpo, gris, 2.0)
			draw_rect(Rect2(xp, cuerpo.position.y + px(2), px(6), cuerpo.size.y - px(4)), Estilo.TEXTO)
			draw_rect(Rect2(xp + px(6), cy - px(3), cuerpo.end.x - xp - px(6) + (w - cuerpo.end.x - px(10)) * _pos + px(6), px(6)), Estilo.TEXTO)
			if tipo == "cilindro_se":
				_muelle(xp + px(8), cuerpo.end.x - px(2), cy - cuerpo.size.y * 0.25, cuerpo.size.y * 0.12, gris)
			# Tomas de aire
			_l(Vector2(cuerpo.position.x + px(10), cuerpo.end.y), Vector2(cuerpo.position.x + px(10), h - alto_etq - px(2)), tr, 2.0)
			if tipo == "cilindro_de":
				_l(Vector2(cuerpo.end.x - px(10), cuerpo.end.y), Vector2(cuerpo.end.x - px(10), h - alto_etq - px(2)), tr, 2.0)
			# Detectores de final de carrera
			for par in [["pin_fin_a", cuerpo.position.x + px(14)], ["pin_fin_b", cuerpo.end.x - px(14)]]:
				var p := pin_de(par[0])
				if p != "":
					var det: bool = tiene_valor(par[0]) and valores[p] >= 0.5
					draw_circle(Vector2(par[1], cuerpo.position.y - px(3)), px(4), Estilo.VERDE if det else Estilo.APAGADO, true, -1, true)
			_etiqueta(Rect2(0, h - alto_etq, w, alto_etq))
		"valvula_52", "valvula_32":
			var cinco := tipo == "valvula_52"
			var alto_etq := px(16) if str(prop("etiqueta", "")) != "" else 0.0
			var bh := h - px(26) - alto_etq
			var bw := bh * 1.15
			var x0 := (w - bw * 2.0) * 0.5
			var y0 := px(12)
			var activa := 0 if on else 1   # casilla que conecta: 0 = izquierda (pilotada), 1 = derecha (reposo)
			for i in 2:
				var r := Rect2(x0 + bw * i, y0, bw, bh)
				if i == activa:
					draw_rect(r, Color(c, 0.18))
				_caja_l(r, tr if i == activa else gris, 1.8)
				var cc := tr if i == activa else gris
				var a := r.position.x + r.size.x * 0.3
				var b := r.position.x + r.size.x * 0.7
				if (i == 0) == cinco:
					_flecha(Vector2(a, r.end.y - px(4)), Vector2(a, r.position.y + px(4)), cc)
					_flecha(Vector2(b, r.position.y + px(4)), Vector2(b, r.end.y - px(4)), cc)
				else:
					_flecha(Vector2(a, r.end.y - px(4)), Vector2(b, r.position.y + px(4)), cc)
					if cinco:
						_flecha(Vector2(b, r.end.y - px(4)), Vector2(a, r.position.y + px(4)), cc)
					else:   # vía cerrada
						_l(Vector2(b - px(5), r.end.y - px(4)), Vector2(b + px(5), r.end.y - px(4)), cc, 1.8)
			# Mandos: solenoide a la izquierda, muelle a la derecha
			_solenoide(Rect2(x0 - px(16), y0 + bh * 0.25, px(14), bh * 0.5), c, on)
			_muelle(x0 + bw * 2.0 + px(2), x0 + bw * 2.0 + px(16), y0 + bh * 0.5, bh * 0.15, gris)
			# Vías (bajo la casilla en reposo)
			var base := x0 + bw
			for k in (3 if cinco else 2):
				var xv := base + bw * (0.3 + 0.2 * k) if cinco else base + bw * (0.3 + 0.4 * k)
				_l(Vector2(xv, y0 + bh), Vector2(xv, y0 + bh + px(10)), gris, 1.6)
			for k in 2:
				_l(Vector2(base + bw * (0.3 + 0.4 * k), y0), Vector2(base + bw * (0.3 + 0.4 * k), y0 - px(10)), gris, 1.6)
			_etiqueta(Rect2(0, h - alto_etq, w, alto_etq))
		"compresor_n":
			var d := minf(w, h) - px(8)
			var ctr := Vector2(w, h) * 0.5
			if on:
				draw_circle(ctr, d * 0.62, Color(c, 0.12), true, -1, true)
			draw_circle(ctr, d * 0.5, tr, false, px(2), true)
			var tri := PackedVector2Array([ctr + Vector2(0, -d * 0.38), ctr + Vector2(d * 0.3, d * 0.08), ctr + Vector2(-d * 0.3, d * 0.08)])
			draw_colored_polygon(tri, tr)
			if on:
				var a := _fase * TAU
				_l(ctr + Vector2(0, d * 0.25), ctr + Vector2(0, d * 0.25) + Vector2(cos(a), sin(a)) * d * 0.14, c, 2.0)
		"frl":
			var bw := minf(w / 3.0, h - px(20)) - px(4)
			var y := (h - bw) * 0.5
			for i in 3:
				var cx := px(4) + (w - px(8)) * (i + 0.5) / 3.0
				var dm := PackedVector2Array([Vector2(cx, y), Vector2(cx + bw * 0.5, y + bw * 0.5), Vector2(cx, y + bw), Vector2(cx - bw * 0.5, y + bw * 0.5), Vector2(cx, y)])
				draw_polyline(dm, tr, px(1.8), true)
				match i:
					0: draw_dashed_line(Vector2(cx - bw * 0.35, y + bw * 0.5), Vector2(cx + bw * 0.35, y + bw * 0.5), tr, px(1.4), px(3))
					1: _flecha(Vector2(cx - bw * 0.3, y + bw * 0.8), Vector2(cx + bw * 0.3, y + bw * 0.2), tr)
					2: draw_circle(Vector2(cx, y + bw * 0.5), bw * 0.1, tr, true, -1, true)
			_l(Vector2(0, h * 0.5), Vector2(px(4), h * 0.5), tr, 2.0)
			_l(Vector2(w - px(4), h * 0.5), Vector2(w, h * 0.5), tr, 2.0)
			texto("Filtro · Regulador · Lubricador", Rect2(0, h - px(14), w, px(14)), 9.5, Estilo.TEXTO_TENUE, "centro")
		"silenciador":
			var r := Rect2(w * 0.3, px(4), w * 0.4, h - px(8))
			_caja_l(r, tr, 1.8)
			for i in 3:
				for j in 2:
					draw_circle(r.position + Vector2(r.size.x * (0.3 + 0.4 * j), r.size.y * (0.25 + 0.25 * i)), px(1.8), tr, true, -1, true)
		"ventosa":
			var cx := w * 0.5
			_l(Vector2(cx, px(4)), Vector2(cx, h * 0.45), tr, 3.0)
			var copa := PackedVector2Array([Vector2(cx - w * 0.12, h * 0.45), Vector2(cx + w * 0.12, h * 0.45), Vector2(cx + w * 0.38, h * 0.78), Vector2(cx - w * 0.38, h * 0.78)])
			draw_colored_polygon(copa, Color(c, 0.45) if on else Color(gris, 0.3))
			draw_polyline(copa + PackedVector2Array([copa[0]]), tr, px(1.8), true)
			if on:
				_flecha(Vector2(cx, h * 0.72), Vector2(cx, h * 0.5), Estilo.TEXTO)
			texto("VACÍO" if on else "", Rect2(0, h * 0.8, w, h * 0.2), 10, c, "centro", true)
		"pinza":
			var abierta := 1.0 - (1.0 if on else 0.0)
			var cx := w * 0.5
			draw_rect(Rect2(cx - w * 0.3, px(4), w * 0.6, h * 0.3), Color(gris, 0.35))
			_caja_l(Rect2(cx - w * 0.3, px(4), w * 0.6, h * 0.3), tr, 1.8)
			var sep := w * (0.06 + 0.16 * abierta)
			for sgn in [-1.0, 1.0]:
				var x: float = cx + sgn * sep
				draw_rect(Rect2(x - (w * 0.1 if sgn < 0 else 0.0), h * 0.34, w * 0.1, h * 0.56), tr)
			texto("CERRADA" if on else "ABIERTA", Rect2(0, h - px(14), w, px(14)), 9.5, c if on else Estilo.TEXTO_TENUE, "centro", true)
		"detector":
			var r := Rect2(px(4), h * 0.3, w - px(8), h * 0.4)
			draw_rect(r, Color(gris, 0.25))
			_caja_l(r, gris, 1.6)
			draw_circle(Vector2(r.end.x - r.size.y * 0.5, r.get_center().y), r.size.y * 0.28, Estilo.VERDE if on else Estilo.APAGADO, true, -1, true)
			_etiqueta(Rect2(0, 0, w, h * 0.3))
		"linea_h", "linea_v":
			var g := float(prop("grosor", 3.0))
			var a := Vector2(0, h * 0.5) if tipo == "linea_h" else Vector2(w * 0.5, 0)
			var b := Vector2(w, h * 0.5) if tipo == "linea_h" else Vector2(w * 0.5, h)
			if bool(prop("pilotaje", false)):
				draw_dashed_line(a, b, tr, px(g * 0.6), px(5))
			else:
				_l(a, b, tr, g)
