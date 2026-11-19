class_name FabricaWidgets
extends RefCounted
## Crea el elemento adecuado para cada "tipo" del proyecto.

const CLASES := {
	"panel": preload("res://widgets/w_panel.gd"),
	"etiqueta": preload("res://widgets/w_etiqueta.gd"),
	"valor": preload("res://widgets/w_valor.gd"),
	"led": preload("res://widgets/w_led.gd"),
	"interruptor": preload("res://widgets/w_interruptor.gd"),
	"pulsador": preload("res://widgets/w_pulsador.gd"),
	"indicador": preload("res://widgets/w_indicador.gd"),
	"barra": preload("res://widgets/w_barra.gd"),
	"reloj": preload("res://widgets/w_reloj.gd"),
	"deslizador": preload("res://widgets/w_deslizador.gd"),
}


static func crear(definicion: Dictionary, escala: float) -> AcWidget:
	var clase = CLASES.get(str(definicion.get("tipo", "")))
	if clase == null:
		return null
	var w: AcWidget = clase.new()
	w.name = str(definicion.get("id", "w"))
	w.configurar(definicion, escala)
	return w
