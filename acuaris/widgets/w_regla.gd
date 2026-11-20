class_name WRegla
extends AcWidget
## Regla automática: cuando el pin cumple la condición, escribe un valor en otro pin.
## Funciona mientras la app está abierta. props: condicion, pin_destino, valor, valor_si_no

var _estado := -1   # -1 desconocido, 0 no se cumple, 1 se cumple
var disparos := 0


func recibir(pin: String, v: float) -> void:
	super(pin, v)
	if pin != pin_de():
		return
	var ahora := 1 if AcWidget.cumple(str(prop("condicion", "> 0")), v) else 0
	if ahora != _estado:
		var antes := _estado
		_estado = ahora
		if antes == -1 and not bool(prop("al_iniciar", false)):
			queue_redraw()
			return
		if ahora == 1:
			solicitar(float(prop("valor", 1)), "pin_destino")
			disparos += 1
		elif str(prop("valor_si_no", "")) != "":
			solicitar(float(prop("valor_si_no")), "pin_destino")
			disparos += 1
	queue_redraw()


func _draw() -> void:
	var col := Estilo.VERDE if _estado == 1 else Estilo.TEXTO_TENUE
	caja(Rect2(Vector2.ZERO, size), Color(col, 0.10), Color(col, 0.5), 12)
	var t := str(prop("titulo", "Regla"))
	texto(t, Rect2(px(12), px(4), size.x - px(24), size.y * 0.5), 13, Estilo.TEXTO, "izquierda", true)
	var desc := "Si %s %s → %s = %s" % [pin_de(), str(prop("condicion", "> 0")), pin_de("pin_destino"), str(prop("valor", 1))]
	texto(desc, Rect2(px(12), size.y * 0.45, size.x - px(24), size.y * 0.5), 11, Estilo.TEXTO_SEC, "izquierda")
