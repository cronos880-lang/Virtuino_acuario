class_name WEstado
extends AcWidget
## Texto de estado elegido por reglas: "==0|Apagado|#5d8299; >80|Alarma|#ff5a5f".
## Se comprueban en orden y gana la primera que se cumple.

func _regla_activa() -> Array:
	if not tiene_valor():
		return ["--", Estilo.TEXTO_TENUE]
	for r in str(prop("reglas", "")).split(";", false):
		var partes := r.split("|")
		if partes.size() >= 2 and AcWidget.cumple(partes[0], valor()):
			return [partes[1].strip_edges(), Estilo.color(partes[2].strip_edges() if partes.size() > 2 else "", Estilo.TEXTO)]
	return [str(prop("defecto", "")), Estilo.TEXTO_SEC]


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var act := _regla_activa()
	var col: Color = act[1]
	if bool(prop("con_fondo", true)):
		caja(r, Color(col, 0.14), Color(col, 0.55), 12)
	var titulo := str(prop("titulo", ""))
	var y0 := 0.0
	if titulo != "":
		texto(titulo, Rect2(px(10), px(4), size.x - px(20), px(16)), 11.5, Estilo.TEXTO_SEC, "izquierda")
		y0 = px(14)
	texto(str(act[0]), Rect2(px(10), y0, size.x - px(20), size.y - y0), float(prop("tam", 18)), col, str(prop("alineacion", "centro")), true)
