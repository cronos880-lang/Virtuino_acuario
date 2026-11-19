class_name BotonUi
extends Control
## Botón/fila de lista de la propia aplicación (no del proyecto). Dibujo vectorial a escala s.

signal pulsado

var s := 1.0
var titulo := ""
var detalle := ""
var color_punto := Color.TRANSPARENT
var destacado := false
var _abajo := false
var _pos := Vector2.ZERO


func preparar(escala: float, t: String, d := "", punto := Color.TRANSPARENT, alto_dp := 60.0) -> BotonUi:
	s = escala
	titulo = t
	detalle = d
	color_punto = punto
	custom_minimum_size = Vector2(0, alto_dp * s)
	mouse_filter = Control.MOUSE_FILTER_PASS
	queue_redraw()
	return self


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_abajo = true
			_pos = e.position
		elif _abajo:
			_abajo = false
			if e.position.distance_to(_pos) < 12 * s and Rect2(Vector2.ZERO, size).has_point(e.position):
				pulsado.emit()
		queue_redraw()


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Estilo.AGUA if destacado else Estilo.TARJETA
	if _abajo:
		sb.bg_color = sb.bg_color.lightened(0.12)
	sb.border_color = Estilo.TARJETA_BORDE
	sb.set_border_width_all(maxi(1, roundi(s)))
	sb.set_corner_radius_all(roundi(14 * s))
	sb.corner_detail = 16
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var x := 16 * s
	if color_punto.a > 0:
		draw_circle(Vector2(x + 6 * s, size.y * 0.5), 6 * s, color_punto, true, -1, true)
		x += 24 * s
	var f := Estilo.fuente(true)
	var fn := Estilo.fuente(false)
	var c_txt := Estilo.FONDO_ABAJO if destacado else Estilo.TEXTO
	var fs1 := roundi(15 * s)
	var fs2 := roundi(12 * s)
	if detalle == "":
		draw_string(f, Vector2(x, roundf(size.y * 0.5 + f.get_ascent(fs1) * 0.5 - 1 * s)), titulo, HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 16 * s, fs1, c_txt)
	else:
		draw_string(f, Vector2(x, roundf(size.y * 0.5 - 2 * s)), titulo, HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 16 * s, fs1, c_txt)
		draw_string(fn, Vector2(x, roundf(size.y * 0.5 + fn.get_ascent(fs2) + 2 * s)), detalle, HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 16 * s, fs2, Estilo.FONDO_ABAJO if destacado else Estilo.TEXTO_SEC)
