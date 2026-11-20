class_name WSegmentos
extends AcWidget
## Indicador por segmentos (tipo batería o cobertura): se iluminan más barras al subir el valor.

func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var n := clampi(int(prop("segmentos", 5)), 2, 20)
	var f := clampf((valor() - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0) if tiene_valor() else 0.0
	var encendidos := roundi(f * n)
	var bueno := Estilo.VERDE
	var regular := Estilo.AMBAR
	var malo := Estilo.ROJO
	var pobre := float(prop("umbral_malo", mn + (mx - mn) * 0.25))
	var justo := float(prop("umbral_regular", mn + (mx - mn) * 0.5))
	var col := bueno
	if tiene_valor():
		if pobre <= justo:
			col = malo if valor() <= pobre else (regular if valor() <= justo else bueno)
		else:
			col = malo if valor() >= pobre else (regular if valor() >= justo else bueno)
	var titulo := str(prop("titulo", ""))
	var y0 := px(18) if titulo != "" else 0.0
	texto(titulo, Rect2(0, 0, size.x * 0.6, px(16)), 11.5, Estilo.TEXTO_SEC, "izquierda")
	if tiene_valor():
		texto((formatear(valor(), int(prop("decimales", 0))) + " " + str(prop("unidad", ""))).strip_edges(), Rect2(size.x * 0.4, 0, size.x * 0.6, px(16)), 12, Estilo.TEXTO, "derecha", true)
	var hueco := px(3)
	var ancho := (size.x - hueco * (n - 1)) / n
	var alto := size.y - y0
	for i in n:
		var h := alto if not bool(prop("escalera", true)) else alto * (0.35 + 0.65 * (i + 1) / n)
		var r := Rect2(i * (ancho + hueco), y0 + alto - h, ancho, h)
		caja(r, col if i < encendidos else Estilo.APAGADO, Color.TRANSPARENT, 3)
