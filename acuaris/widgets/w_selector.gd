class_name WSelector
extends AcWidget
## Selector giratorio de varias posiciones: tocar una posición envía su valor.
## props.opciones = "Off:0, 1:1, 2:2, 3:3"

const A0 := deg_to_rad(150.0)
const A1 := deg_to_rad(390.0)


func _init() -> void:
	interactivo = true


func _angulo(i: int, n: int) -> float:
	return lerpf(A0, A1, float(i) / maxf(n - 1, 1))


func _centro_radio() -> Array:
	var lado := minf(size.x, size.y - px(16))
	return [Vector2(size.x * 0.5, lado * 0.5 + px(2)), lado * 0.5 - px(4)]


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		var ops := opciones_prop()
		var cr := _centro_radio()
		var mejor := -1
		var dist := INF
		for i in ops.size():
			var p: Vector2 = cr[0] + Vector2.from_angle(_angulo(i, ops.size())) * cr[1] * 0.8
			var d := p.distance_to(e.position)
			if d < dist:
				dist = d
				mejor = i
		if mejor >= 0 and dist < cr[1] * 0.6:
			solicitar_seguro(ops[mejor][1], "pin", "¿Poner el selector en «%s»?" % ops[mejor][0])
			accept_event()


func _draw() -> void:
	var ops := opciones_prop()
	var cr := _centro_radio()
	var c: Vector2 = cr[0]
	var r: float = cr[1]
	var col := Estilo.color(prop("color"), Estilo.AGUA)
	var activo := -1
	for i in ops.size():
		if tiene_valor() and is_equal_approx(valor(), ops[i][1]):
			activo = i
	for i in ops.size():
		var p := c + Vector2.from_angle(_angulo(i, ops.size())) * r * 0.86
		draw_circle(p, px(4), col if i == activo else Estilo.TEXTO_TENUE, true, -1, true)
		texto(str(ops[i][0]), Rect2(p - Vector2(px(22), px(19)) + Vector2.from_angle(_angulo(i, ops.size())) * px(2), Vector2(px(44), px(14))), 10, col if i == activo else Estilo.TEXTO_SEC)
	var rk := r * 0.58
	draw_circle(c + Vector2(0, px(2)), rk, Color(0, 0, 0, 0.3), true, -1, true)
	draw_circle(c, rk, Color("#1a3d55"), true, -1, true)
	draw_circle(c, rk, Estilo.TARJETA_BORDE, false, px(2), true)
	if activo >= 0:
		var a := _angulo(activo, ops.size())
		draw_line(c + Vector2.from_angle(a) * rk * 0.25, c + Vector2.from_angle(a) * rk * 0.9, col, px(5), true)
	texto(str(prop("titulo", "")), Rect2(0, size.y - px(16), size.x, px(16)), 12, Estilo.TEXTO_SEC)
