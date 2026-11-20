class_name WMapa
extends AcWidget
## Posición (latitud/longitud de dos pines) con su recorrido reciente sobre una cuadrícula.
## No dibuja calles: eso necesitaría un servicio de mapas por Internet.

func recibir(pin: String, v: float) -> void:
	super(pin, v)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	caja(r, Color("#0b2233"), Estilo.TARJETA_BORDE, 12)
	var c := size * 0.5
	var paso := px(24)
	var x := fposmod(c.x, paso)
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.05), px(1))
		x += paso
	var y := fposmod(c.y, paso)
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.05), px(1))
		y += paso
	texto("N", Rect2(size.x - px(24), px(4), px(20), px(16)), 12, Estilo.TEXTO_SEC, "centro", true)
	if not (tiene_valor("pin_lat") and tiene_valor("pin_lon")):
		texto("Sin posición", r, 12, Estilo.TEXTO_TENUE)
		return
	var lat := valor("pin_lat")
	var lon := valor("pin_lon")
	var radio_m := float(prop("radio_m", 200))
	var m_por_px := radio_m / (minf(size.x, size.y) * 0.5)
	var ser_lat := Historial.serie(pin_de("pin_lat"), 3600)
	var ser_lon := Historial.serie(pin_de("pin_lon"), 3600)
	var n := mini(ser_lat[0].size(), ser_lon[0].size())
	var pts := PackedVector2Array()
	for i in n:
		var dx: float = (ser_lon[1][i] - lon) * 111320.0 * cos(deg_to_rad(lat))
		var dy: float = (ser_lat[1][i] - lat) * 110540.0
		pts.append(c + Vector2(dx, -dy) / m_por_px)
	if pts.size() >= 2:
		draw_polyline(pts, Color(Estilo.AGUA, 0.6), px(2), true)
	draw_circle(c, px(14), Color(Estilo.ROJO, 0.2), true, -1, true)
	draw_circle(c, px(7), Estilo.ROJO, true, -1, true)
	texto("%.5f, %.5f" % [lat, lon], Rect2(px(8), size.y - px(20), size.x - px(16), px(16)), 11, Estilo.TEXTO_SEC, "izquierda")
