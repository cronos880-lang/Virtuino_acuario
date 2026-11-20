class_name WGiratorio
extends AcWidget
## Icono que gira más rápido cuanto mayor es el valor (bomba, ventilador, rueda).

var _angulo := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 1))
	var f := clampf((valor() - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0) if tiene_valor() else 0.0
	if f > 0.0:
		_angulo = fmod(_angulo + delta * TAU * 1.5 * f, TAU)
		queue_redraw()


func _draw() -> void:
	var lado := minf(size.x, size.y - px(18))
	var c := Vector2(size.x * 0.5, lado * 0.5)
	var r := lado * 0.5 - px(4)
	var activo := tiene_valor() and valor() > float(prop("min", 0))
	var col := color_alarma(valor(), Estilo.color(prop("color"), Estilo.AGUA)) if activo else Estilo.APAGADO
	draw_circle(c, r, Color(col, 0.12), true, -1, true)
	draw_circle(c, r, Color(col, 0.6), false, px(2), true)
	match str(prop("icono", "ventilador")):
		"bomba":
			for i in 6:
				var a := _angulo + TAU * i / 6.0
				var p1 := c + Vector2.from_angle(a) * r * 0.2
				var p2 := c + Vector2.from_angle(a + 0.6) * r * 0.82
				draw_line(p1, p2, col, px(4), true)
		"rueda":
			draw_circle(c, r * 0.75, col, false, px(4), true)
			for i in 8:
				var a := _angulo + TAU * i / 8.0
				draw_line(c, c + Vector2.from_angle(a) * r * 0.75, col, px(3), true)
		_:
			for i in 3:
				var a := _angulo + TAU * i / 3.0
				var pts := PackedVector2Array([c, c + Vector2.from_angle(a - 0.35) * r * 0.85, c + Vector2.from_angle(a + 0.25) * r * 0.85])
				draw_colored_polygon(pts, col)
	draw_circle(c, r * 0.16, Color("#dfe9ef"), true, -1, true)
	texto(str(prop("titulo", "")), Rect2(0, size.y - px(18), size.x, px(18)), 12, Estilo.TEXTO_SEC)
