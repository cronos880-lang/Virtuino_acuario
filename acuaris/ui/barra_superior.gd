class_name BarraSuperior
extends Control
## Cabecera: nombre de la app, proyecto y estado de la conexión (pulsar para cambiar).

signal pulsado_estado

var s := 1.0
var subtitulo := ""
var estado_txt := "Sin conexión"
var estado_color := Estilo.ROJO
var _rect_estado := Rect2()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		if _rect_estado.grow(6 * s).has_point(e.position):
			pulsado_estado.emit()


func _draw() -> void:
	var fb := Estilo.fuente(true)
	var fn := Estilo.fuente(false)
	draw_string(fb, Vector2(16 * s, roundf(28 * s)), "Acuaris", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(22 * s), Estilo.TEXTO)
	draw_string(fn, Vector2(16 * s, roundf(46 * s)), subtitulo, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.5, roundi(12 * s), Estilo.TEXTO_SEC)
	var fs := roundi(12.5 * s)
	var ancho := fb.get_string_size(estado_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 40 * s
	_rect_estado = Rect2(size.x - ancho - 16 * s, 14 * s, ancho, 30 * s)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(estado_color, 0.14)
	sb.border_color = Color(estado_color, 0.55)
	sb.set_border_width_all(maxi(1, roundi(s)))
	sb.set_corner_radius_all(roundi(15 * s))
	sb.corner_detail = 16
	draw_style_box(sb, _rect_estado)
	draw_circle(_rect_estado.position + Vector2(15 * s, 15 * s), 4.5 * s, estado_color, true, -1, true)
	draw_string(fb, _rect_estado.position + Vector2(26 * s, roundf(15 * s + fb.get_ascent(fs) * 0.5 - s)), estado_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Estilo.TEXTO)
	draw_line(Vector2(0, size.y - s), Vector2(size.x, size.y - s), Color(Estilo.TARJETA_BORDE, 0.6), maxf(1.0, s * 0.75))
