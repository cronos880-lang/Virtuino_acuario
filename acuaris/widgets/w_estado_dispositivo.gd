class_name WEstadoDispositivo
extends AcWidget
## Indica si el controlador responde y avisa cuando deja de hacerlo.

var _t := 0.0


func _ready() -> void:
	set_process(true)


func _process(d: float) -> void:
	_t += d
	if _t > 1.0:
		_t = 0.0
		queue_redraw()


func _draw() -> void:
	var ultima := Comunicador.ultima_respuesta_unix
	var hace := Time.get_unix_time_from_system() - ultima if ultima > 0 else -1.0
	var limite := float(prop("segundos", 10))
	var en_linea := hace >= 0 and hace <= limite
	var col := Estilo.VERDE if en_linea else (Estilo.ROJO if ultima > 0 else Estilo.TEXTO_TENUE)
	caja(Rect2(Vector2.ZERO, size), Color(col, 0.10), Color(col, 0.55), 12)
	var c := Vector2(px(22), size.y * 0.5)
	if en_linea:
		draw_circle(c, px(12), Color(col, 0.2), true, -1, true)
	draw_circle(c, px(7), col, true, -1, true)
	texto(str(prop("titulo", "Controlador")), Rect2(px(40), px(4), size.x - px(46), size.y * 0.5), 13, Estilo.TEXTO, "izquierda", true)
	var det := "Sin datos todavía"
	if en_linea:
		det = "En línea · respuesta hace %d s" % roundi(hace)
	elif ultima > 0:
		det = "SIN RESPUESTA desde las %s" % Time.get_time_string_from_unix_time(int(ultima + Time.get_time_zone_from_system().bias * 60)).substr(0, 5)
	texto(det, Rect2(px(40), size.y * 0.45, size.x - px(46), size.y * 0.5), 11.5, col if not en_linea else Estilo.TEXTO_SEC, "izquierda", not en_linea and ultima > 0)
