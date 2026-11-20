class_name WGraficaEmergente
extends AcWidget
## Casilla pequeña que abre la gráfica completa en una ventana.

func _init() -> void:
	interactivo = true


func al_tocar() -> void:
	var g := WGrafica.new()
	var d := def.duplicate(true)
	d["tipo"] = "grafica_avanzada"
	d["x"] = 0
	d["y"] = 0
	var ancho := minf(get_viewport_rect().size.x / s - 80, 460)
	d["w"] = ancho
	d["h"] = ancho * 0.62
	g.configurar(d, s)
	g.custom_minimum_size = g.size
	for p in valores:
		g.recibir(p, valores[p])
	DialogoApp.mostrar(self, s, str(prop("titulo", "Gráfica")), g)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	caja(r, Estilo.TARJETA, Estilo.TARJETA_BORDE, 14)
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	var ic := Rect2(px(10), size.y * 0.5 - px(14), px(36), px(28))
	draw_polyline(PackedVector2Array([ic.position + Vector2(0, ic.size.y), ic.position + Vector2(ic.size.x * 0.3, ic.size.y * 0.45), ic.position + Vector2(ic.size.x * 0.6, ic.size.y * 0.7), ic.position + Vector2(ic.size.x, 0)]), c, px(2.5), true)
	texto(str(prop("titulo", "Gráfica")), Rect2(px(54), px(4), size.x - px(60), size.y * 0.5), 13, Estilo.TEXTO, "izquierda", true)
	var txt := (formatear(valor(), int(prop("decimales", 1))) + " " + str(prop("unidad", ""))).strip_edges() if tiene_valor() else "--"
	texto(txt + "   ·   ver gráfica", Rect2(px(54), size.y * 0.45, size.x - px(60), size.y * 0.5), 11.5, Estilo.TEXTO_SEC, "izquierda")
