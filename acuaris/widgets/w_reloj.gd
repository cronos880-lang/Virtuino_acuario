class_name WReloj
extends AcWidget
## Hora del controlador a partir de tres pines (hora, minutos, segundos).

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if bool(prop("con_fondo", true)):
		caja(r, Estilo.TARJETA, Estilo.TARJETA_BORDE, 16)
	var ok := tiene_valor("pin_h") and tiene_valor("pin_m")
	var t := "--:--:--"
	if ok:
		t = "%02d:%02d" % [roundi(valor("pin_h")), roundi(valor("pin_m"))]
		if pin_de("pin_s") != "":
			t += ":%02d" % roundi(valor("pin_s"))
	var titulo := str(prop("titulo", ""))
	texto(titulo, Rect2(px(16), 0, size.x * 0.5, size.y), 13, Estilo.TEXTO_SEC, "izquierda")
	texto(t, Rect2(size.x * 0.35, 0, size.x * 0.65 - px(16), size.y), float(prop("tam", 30)), Estilo.TEXTO, "derecha", true)
