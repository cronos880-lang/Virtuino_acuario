class_name WDibujo
extends AcWidget
## Indicador con dibujo (bombilla, ventilador, bomba...). Encendido si el valor cumple la
## condición. Depósito y termómetro muestran el valor entre mínimo y máximo.

var _fase := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	var anima := str(prop("dibujo", "bombilla")) in ["ventilador", "bomba", "compresor", "campana"]
	if anima and _encendido():
		_fase = fmod(_fase + delta * float(prop("velocidad", 1.0)), 1.0)
		queue_redraw()


func _encendido() -> bool:
	return tiene_valor() and AcWidget.cumple(str(prop("condicion", ">= 0.5")), valor())


func _draw() -> void:
	var dib := str(prop("dibujo", "bombilla"))
	var on := _encendido()
	var c_on := Estilo.color(prop("color_on"), Estilo.AMBAR)
	var c_off := Estilo.color(prop("color_off"), Color("#4a6a80"))
	if bool(prop("con_fondo", false)):
		caja(Rect2(Vector2.ZERO, size), Color(Estilo.APAGADO, 0.35), Color.TRANSPARENT, 12)
	var t_etq := str(prop("texto", ""))
	var t_est := ""
	if str(prop("texto_on", "")) != "" or str(prop("texto_off", "")) != "":
		t_est = "--" if not tiene_valor() else (str(prop("texto_on", "")) if on else str(prop("texto_off", "")))
	var alto_txt := (px(16) if t_etq != "" else 0.0) + (px(15) if t_est != "" else 0.0)
	var area := Rect2(px(4), px(4), size.x - px(8), size.y - px(8) - alto_txt)
	var fase := _fase
	if dib in ["deposito", "termometro"]:
		var mn := float(prop("min", 0.0))
		var mx := float(prop("max", 100.0))
		fase = clampf((valor() - mn) / (mx - mn), 0.0, 1.0) if tiene_valor() and mx != mn else 0.0
		on = true
	Pictos.dibujar(self, dib, area, c_on, on, fase, c_off)
	var y := area.end.y + px(2)
	if t_etq != "":
		texto(t_etq, Rect2(0, y, size.x, px(16)), 12, Estilo.TEXTO, "centro", true)
		y += px(16)
	if t_est != "":
		texto(t_est, Rect2(0, y, size.x, px(15)), 11, c_on if on else Estilo.TEXTO_TENUE, "centro", true)
