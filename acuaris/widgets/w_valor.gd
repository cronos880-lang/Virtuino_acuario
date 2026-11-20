class_name WValor
extends AcWidget
## Valor numérico de un pin con título y unidad. Con "editable", al tocarlo se escribe un valor nuevo.


func configurar(definicion: Dictionary, escala: float) -> void:
	interactivo = bool(definicion.get("props", {}).get("editable", false))
	super(definicion, escala)


func _es_hora() -> bool:
	return str(prop("formato", "numero")) == "hora"


## HHMM (1630) -> "16:30"
static func texto_hora(v: float) -> String:
	var n := roundi(v)
	@warning_ignore("integer_division")
	return "%02d:%02d" % [n / 100, n % 100]


## "16:30", "16.30", "1630", "930" -> 1630 / 930; null si no es una hora válida
static func leer_hora(t: String):
	var limpio := t.strip_edges().replace(".", ":").replace(" ", "")
	var h := -1
	var m := -1
	if limpio.contains(":"):
		var p := limpio.split(":")
		if p.size() == 2 and p[0].is_valid_int() and p[1].is_valid_int():
			h = p[0].to_int()
			m = p[1].to_int()
	elif limpio.is_valid_int() and limpio.length() >= 3 and limpio.length() <= 4:
		@warning_ignore("integer_division")
		h = limpio.to_int() / 100
		m = limpio.to_int() % 100
	if h < 0 or h > 23 or m < 0 or m > 59:
		return null
	return h * 100 + m


func al_tocar() -> void:
	var titulo := str(prop("titulo", ""))
	titulo = titulo if titulo != "" else "Nuevo valor de %s" % pin_de()
	if _es_hora():
		DialogoApp.pedir_numero(self, s, titulo, texto_hora(valor()) if tiene_valor() else "",
			func(v): solicitar_seguro(v, "pin", "¿Poner %s a las %s?" % [titulo, texto_hora(v)]), WValor.leer_hora, "Formato HH:MM, por ejemplo 16:30")
		return
	DialogoApp.pedir_numero(self, s, titulo,
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
		txt = texto_hora(valor()) if _es_hora() else formatear(valor() * float(prop("factor", 1.0)), int(prop("decimales", 1)))
		if str(prop("texto_cero", "")) != "" and is_zero_approx(valor()):
			txt = str(prop("texto_cero"))
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
