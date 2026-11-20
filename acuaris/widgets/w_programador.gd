class_name WProgramador
extends AcWidget
## Programador horario: escribe valores a horas fijas. Funciona mientras la app está abierta.
## props.eventos = "07:30|LMXJV|1; 22:00|*|0"   (días: L M X J V S D, o * para todos)

const DIAS := "DLMXJVS"   # índice = weekday de Godot (0 = domingo)

var _ultimo := ""
var _t := 0.0


func _ready() -> void:
	set_process(true)


static func eventos_de(texto: String) -> Array:
	var r := []
	for e in texto.split(";", false):
		var c := e.split("|")
		if c.size() >= 3 and c[0].strip_edges().length() >= 4:
			var hm := c[0].strip_edges().split(":")
			if hm.size() == 2 and hm[0].is_valid_int() and hm[1].is_valid_int():
				r.append({"h": hm[0].to_int(), "m": hm[1].to_int(), "dias": c[1].strip_edges().to_upper(), "valor": c[2].strip_edges().replace(",", ".").to_float()})
	return r


static func toca(ev: Dictionary, fecha: Dictionary) -> bool:
	if int(fecha.hour) != ev.h or int(fecha.minute) != ev.m:
		return false
	return ev.dias == "*" or ev.dias.contains(DIAS[int(fecha.weekday)])


func _process(d: float) -> void:
	_t += d
	if _t < 1.0:
		return
	_t = 0.0
	var f := Time.get_datetime_dict_from_system()
	var clave := "%d-%d-%d %d:%d" % [f.year, f.month, f.day, f.hour, f.minute]
	if clave == _ultimo:
		return
	for ev in eventos_de(str(prop("eventos", ""))):
		if toca(ev, f):
			_ultimo = clave
			solicitar(ev.valor)
			queue_redraw()


func _draw() -> void:
	caja(Rect2(Vector2.ZERO, size), Estilo.TARJETA, Estilo.TARJETA_BORDE, 14)
	texto(str(prop("titulo", "Programador")), Rect2(px(12), px(6), size.x - px(24), px(18)), 13, Estilo.TEXTO, "izquierda", true)
	var evs := eventos_de(str(prop("eventos", "")))
	var y := px(28)
	if evs.is_empty():
		texto("Sin eventos (defínelos en propiedades)", Rect2(px(12), y, size.x - px(24), px(16)), 11, Estilo.TEXTO_TENUE, "izquierda")
	for ev in evs:
		if y > size.y - px(16):
			break
		texto("%02d:%02d   %s   →  %s = %s" % [ev.h, ev.m, "todos" if ev.dias == "*" else ev.dias, pin_de(), ProtocoloVCM.formatear_valor(ev.valor)], Rect2(px(12), y, size.x - px(24), px(16)), 11.5, Estilo.TEXTO_SEC, "izquierda")
		y += px(17)
