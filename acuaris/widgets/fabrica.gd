class_name FabricaWidgets
extends RefCounted
## Crea el elemento adecuado para cada "tipo" del proyecto (el script lo indica Esquema).

const SCRIPTS := {
	"w_valor": preload("res://widgets/w_valor.gd"),
	"w_led": preload("res://widgets/w_led.gd"),
	"w_estado": preload("res://widgets/w_estado.gd"),
	"w_indicador": preload("res://widgets/w_indicador.gd"),
	"w_manometro": preload("res://widgets/w_manometro.gd"),
	"w_barra": preload("res://widgets/w_barra.gd"),
	"w_barra_vertical": preload("res://widgets/w_barra_vertical.gd"),
	"w_giratorio": preload("res://widgets/w_giratorio.gd"),
	"w_segmentos": preload("res://widgets/w_segmentos.gd"),
	"w_imagen": preload("res://widgets/w_imagen.gd"),
	"w_reloj": preload("res://widgets/w_reloj.gd"),
	"w_etiqueta": preload("res://widgets/w_etiqueta.gd"),
	"w_panel": preload("res://widgets/w_panel.gd"),
	"w_interruptor": preload("res://widgets/w_interruptor.gd"),
	"w_pulsador": preload("res://widgets/w_pulsador.gd"),
	"w_casilla": preload("res://widgets/w_casilla.gd"),
	"w_opciones": preload("res://widgets/w_opciones.gd"),
	"w_selector": preload("res://widgets/w_selector.gd"),
	"w_potenciometro": preload("res://widgets/w_potenciometro.gd"),
	"w_deslizador": preload("res://widgets/w_deslizador.gd"),
	"w_grafica": preload("res://widgets/w_grafica.gd"),
	"w_grafica_emergente": preload("res://widgets/w_grafica_emergente.gd"),
	"w_historial_tabla": preload("res://widgets/w_historial_tabla.gd"),
	"w_tabla": preload("res://widgets/w_tabla.gd"),
	"w_estado_dispositivo": preload("res://widgets/w_estado_dispositivo.gd"),
	"w_regla": preload("res://widgets/w_regla.gd"),
	"w_programador": preload("res://widgets/w_programador.gd"),
	"w_mapa": preload("res://widgets/w_mapa.gd"),
	"w_hidraulica": preload("res://widgets/w_hidraulica.gd"),
}


static func crear(definicion: Dictionary, escala: float) -> AcWidget:
	var info := Esquema.info(str(definicion.get("tipo", "")))
	var clase = SCRIPTS.get(str(info.get("script", "")))
	if clase == null:
		return null
	var w: AcWidget = clase.new()
	w.name = str(definicion.get("id", "w"))
	w.configurar(definicion, escala)
	return w
