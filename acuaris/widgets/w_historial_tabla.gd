class_name WHistorialTabla
extends AcWidget
## Casilla que abre los valores guardados de un pin en una tabla (más recientes primero),
## con opción de copiar en formato CSV (para pegarlos en una hoja de cálculo).

func _init() -> void:
	interactivo = true


func al_tocar() -> void:
	var p := pin_de()
	var segundos := 86400.0 * float(prop("dias", 1))
	var serie := Historial.serie(p, segundos)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(get_viewport_rect().size.y * 0.5, 420 * s))
	var v := VBoxContainer.new()
	sc.add_child(v)
	var dec := int(prop("decimales", 1))
	var n: int = serie[0].size()
	if n == 0:
		var l := Label.new()
		l.text = "Sin datos todavía."
		v.add_child(l)
	for k in mini(n, 500):
		var i: int = n - 1 - k
		var l := Label.new()
		l.text = "%s     %s %s" % [Time.get_datetime_string_from_unix_time(int(serie[0][i] + Time.get_time_zone_from_system().bias * 60), true), formatear(serie[1][i], dec), str(prop("unidad", ""))]
		l.add_theme_font_size_override("font_size", roundi(13 * s))
		l.add_theme_color_override("font_color", Estilo.TEXTO)
		v.add_child(l)
	DialogoApp.mostrar(self, s, "%s · %d valores" % [str(prop("titulo", p)), n], sc,
		[["Copiar CSV", false, func(): DisplayServer.clipboard_set(Historial.csv(p, segundos))]])


func _draw() -> void:
	caja(Rect2(Vector2.ZERO, size), Estilo.TARJETA, Estilo.TARJETA_BORDE, 14)
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	for i in 4:
		draw_line(Vector2(px(12), size.y * 0.5 - px(10) + i * px(7)), Vector2(px(40), size.y * 0.5 - px(10) + i * px(7)), c, px(2), true)
	texto(str(prop("titulo", "Historial")), Rect2(px(52), px(4), size.x - px(58), size.y * 0.5), 13, Estilo.TEXTO, "izquierda", true)
	texto("%s · ver y exportar datos" % pin_de(), Rect2(px(52), size.y * 0.45, size.x - px(58), size.y * 0.5), 11.5, Estilo.TEXTO_SEC, "izquierda")
