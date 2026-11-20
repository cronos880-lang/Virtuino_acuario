class_name WPulsador
extends AcWidget
## Botón. modo: "conmutado" (alterna 1/0), "momentaneo" (1 al pulsar, 0 al soltar), "valor" (escribe props.valor).

func _init() -> void:
	interactivo = true


func al_presionar(presionado: bool) -> void:
	if str(prop("modo", "conmutado")) == "momentaneo":
		solicitar(1.0 if presionado else 0.0)


func al_tocar() -> void:
	match str(prop("modo", "conmutado")):
		"conmutado":
			solicitar_seguro(0.0 if valor() >= 0.5 else 1.0, "pin", "¿Pulsar «%s»?" % str(prop("texto", "")))
		"valor":
			solicitar_seguro(float(prop("valor", 1.0)), "pin", "¿Pulsar «%s»?" % str(prop("texto", "")))


func _draw() -> void:
	var activo := tiene_valor() and valor() >= 0.5 and str(prop("modo", "conmutado")) == "conmutado"
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	var fondo := c if activo else Color(c, 0.16)
	if _pulsado:
		fondo = fondo.lightened(0.15)
	caja(Rect2(Vector2.ZERO, size), fondo, c, float(prop("radio", 14)), 1.5)
	texto(str(prop("texto", "")), Rect2(Vector2.ZERO, size), float(prop("tam", 15)),
		Estilo.FONDO_ABAJO if activo else Estilo.TEXTO, "centro", true)
