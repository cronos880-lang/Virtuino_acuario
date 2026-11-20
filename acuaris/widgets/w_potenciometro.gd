class_name WPotenciometro
extends AcWidget
## Potenciómetro (rueda): arrastrar alrededor para elegir y soltar para enviar.

const A0 := deg_to_rad(135.0)
const A1 := deg_to_rad(405.0)

var _arrastrando := false
var _local := 0.0


func _init() -> void:
	interactivo = true


func _cr() -> Array:
	var lado := minf(size.x, size.y - px(16))
	return [Vector2(size.x * 0.5, lado * 0.5), lado * 0.5 - px(6)]


func _valor_en(p: Vector2) -> float:
	var c: Vector2 = _cr()[0]
	var a := fposmod((p - c).angle() - A0, TAU)
	var f := clampf(a / (A1 - A0), 0.0, 1.0) if a <= A1 - A0 else (1.0 if a < (A1 - A0) + (TAU - (A1 - A0)) * 0.5 else 0.0)
	var v := lerpf(float(prop("min", 0)), float(prop("max", 100)), f)
	var paso := float(prop("paso", 1))
	return snappedf(v, paso) if paso > 0 else v


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = e.pressed
		_local = _valor_en(e.position)
		if not e.pressed:
			solicitar_seguro(_local)
		queue_redraw()
		accept_event()
	elif e is InputEventMouseMotion and _arrastrando:
		_local = _valor_en(e.position)
		queue_redraw()
		accept_event()


func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var v := _local if _arrastrando else valor("pin", mn)
	var f := clampf((v - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0)
	var cr := _cr()
	var c: Vector2 = cr[0]
	var r: float = cr[1]
	var col := Estilo.color(prop("color"), Estilo.AGUA)
	draw_arc(c, r, A0, A1, 96, Estilo.APAGADO, px(6), true)
	if f > 0.001:
		draw_arc(c, r, A0, lerpf(A0, A1, f), 96, col, px(6), true)
	var rk := r * 0.7
	draw_circle(c + Vector2(0, px(2)), rk, Color(0, 0, 0, 0.3), true, -1, true)
	draw_circle(c, rk, Color("#1a3d55"), true, -1, true)
	var a := lerpf(A0, A1, f)
	draw_circle(c + Vector2.from_angle(a) * rk * 0.72, px(4), Color.WHITE, true, -1, true)
	var txt := (formatear(v, int(prop("decimales", 0))) + " " + str(prop("unidad", ""))).strip_edges() if (tiene_valor() or _arrastrando) else "--"
	texto(txt, Rect2(c.x - rk, c.y - px(10), rk * 2, px(20)), 14, Estilo.TEXTO, "centro", true)
	texto(str(prop("titulo", "")), Rect2(0, size.y - px(16), size.x, px(16)), 12, Estilo.TEXTO_SEC)
