class_name WValor
extends AcWidget
## Valor numérico de un pin con título y unidad. Con "editable", al tocarlo se escribe un valor nuevo.


func configurar(definicion: Dictionary, escala: float) -> void:
	interactivo = bool(definicion.get("props", {}).get("editable", false))
	super(definicion, escala)


func al_tocar() -> void:
	var titulo := str(prop("titulo", ""))
	DialogoApp.pedir_numero(self, s, titulo if titulo != "" else "Nuevo valor de %s" % pin_de(),
		formatear(valor(), int(prop("decimales", 1))) if tiene_valor() else "", func(v): solicitar_seguro(v))

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if bool(prop("con_fondo", true)):
		caja(r, Color(Estilo.APAGADO, 0.35), Color.TRANSPARENT, 12)
	var alin := str(prop("alineacion", "centro"))
	var titulo := str(prop("titulo", ""))
	var y0 := 0.0
	if titulo != "":
		texto(titulo, Rect2(px(10), px(4), size.x - px(20), px(18)), 11.5, Estilo.TEXTO_SEC, alin)
		y0 = px(16)
	var txt := "--"
	if tiene_valor():
		txt = formatear(valor() * float(prop("factor", 1.0)), int(prop("decimales", 1)))
	var unidad := str(prop("unidad", ""))
	if unidad != "":
		txt += " " + unidad
	var col := Estilo.color(prop("color"), Estilo.TEXTO)
	if tiene_valor():
		col = color_alarma(valor() * float(prop("factor", 1.0)), col)
	texto(txt, Rect2(px(6), y0, size.x - px(12), size.y - y0), float(prop("tam", 22)), col, alin, true)
	if interactivo:
		# Marca de "editable": esquina con un pequeño lápiz
		var p0 := Vector2(size.x - px(16), size.y - px(6))
		draw_line(p0, p0 + Vector2(px(9), -px(9)), Estilo.TEXTO_TENUE, px(2.0), true)
		draw_line(p0 + Vector2(-px(1), px(1)), p0 + Vector2(px(2), px(0)), Estilo.TEXTO_TENUE, px(2.0), true)
