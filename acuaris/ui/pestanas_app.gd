class_name PestanasApp
extends Control
## Pestañas de páginas de la app (solo aparecen si el proyecto tiene más de una página).

signal elegida(indice: int)

var s := 1.0
var nombres: Array[String] = []
var actual := 0
var _rects: Array[Rect2] = []


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		for i in _rects.size():
			if _rects[i].has_point(e.position):
				actual = i
				queue_redraw()
				elegida.emit(i)


func _draw() -> void:
	_rects.clear()
	var f := Estilo.fuente(true)
	var fs := roundi(13 * s)
	var x := 16 * s
	for i in nombres.size():
		var ancho := f.get_string_size(nombres[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28 * s
		var r := Rect2(x, 6 * s, ancho, size.y - 12 * s)
		_rects.append(r)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Estilo.AGUA if i == actual else Color(Estilo.TARJETA, 0.9)
		sb.border_color = Estilo.TARJETA_BORDE
		sb.set_border_width_all(maxi(1, roundi(s)))
		sb.set_corner_radius_all(roundi(r.size.y * 0.5))
		sb.corner_detail = 16
		draw_style_box(sb, r)
		draw_string(f, Vector2(r.position.x + 14 * s, roundf(r.get_center().y + f.get_ascent(fs) * 0.5 - s)), nombres[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Estilo.FONDO_ABAJO if i == actual else Estilo.TEXTO)
		x += ancho + 8 * s
