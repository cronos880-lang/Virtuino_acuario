class_name WPulsador
extends AcWidget
## Botón. modo: "conmutado" (alterna 1/0), "momentaneo" (1 al pulsar, 0 al soltar), "valor" (escribe props.valor).
## "boton" = botón personalizable: forma, colores de fondo, letra y borde (normal y activo),
## icono de Pictos e imagen propia de fondo.

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
	if str(def.get("tipo")) == "boton":
		_dibujar_personalizado()
		return
	var activo := tiene_valor() and valor() >= 0.5 and str(prop("modo", "conmutado")) == "conmutado"
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	var fondo := c if activo else Color(c, 0.16)
	if _pulsado:
		fondo = fondo.lightened(0.15)
	caja(Rect2(Vector2.ZERO, size), fondo, c, float(prop("radio", 14)), 1.5)
	texto(str(prop("texto", "")), Rect2(Vector2.ZERO, size), float(prop("tam", 15)),
		Estilo.FONDO_ABAJO if activo else Estilo.TEXTO, "centro", true)


var _textura: Texture2D = null
var _b64 := ""


func _dibujar_personalizado() -> void:
	var activo := tiene_valor() and valor() >= 0.5 and str(prop("modo", "conmutado")) == "conmutado"
	activo = activo or _pulsado
	var fondo := Estilo.color(prop("color_activo" if activo else "color_fondo"), Estilo.AGUA if activo else Color("#10314a"))
	var c_txt := Estilo.color(prop("color_texto_activo" if activo else "color_texto"), Estilo.FONDO_ABAJO if activo else Estilo.TEXTO)
	var borde := Estilo.color(prop("color_borde"), Estilo.AGUA)
	var ancho_b := float(prop("ancho_borde", 1.5))
	var r := Rect2(Vector2.ZERO, size)
	var forma := str(prop("forma", "redondeado"))
	if forma == "circulo":
		var d := minf(size.x, size.y)
		r = Rect2((size - Vector2(d, d)) * 0.5, Vector2(d, d))
	var radio: float = {"rectangulo": 0.0, "redondeado": float(prop("radio", 14)), "pildora": 999.0, "circulo": 999.0}.get(forma, 14.0)
	if forma in ["pildora", "circulo"]:
		radio = minf(r.size.x, r.size.y) * 0.5 / s
	if _pulsado:
		fondo = fondo.lightened(0.12)
	caja(r, fondo, borde if ancho_b > 0 else Color.TRANSPARENT, radio, ancho_b)
	# Imagen propia de fondo (PNG/JPG incrustada)
	var b64 := str(prop("imagen", ""))
	if b64 != _b64:
		_b64 = b64
		_textura = null
		if b64 != "":
			var img := Image.new()
			if img.load_png_from_buffer(Marshalls.base64_to_raw(b64)) == OK or img.load_jpg_from_buffer(Marshalls.base64_to_raw(b64)) == OK:
				_textura = ImageTexture.create_from_image(img)
	if _textura != null:
		var ts := _textura.get_size()
		var esc := minf(r.size.x / ts.x, r.size.y / ts.y) * 0.9
		draw_texture_rect(_textura, Rect2(r.get_center() - ts * esc * 0.5, ts * esc), false)
	var icono := str(prop("icono", "ninguno"))
	var t := str(prop("texto", ""))
	var tam := float(prop("tam", 15))
	if icono != "ninguno" and icono != "":
		var lado := minf(r.size.y * 0.62, px(tam * 1.9))
		if t == "":
			Pictos.dibujar(self, icono, Rect2(r.get_center() - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), c_txt, true, 0.0, c_txt)
		else:
			var ancho_t := ancho_texto(t, tam, bool(prop("negrita", true)))
			var x0 := r.get_center().x - (lado + px(6) + ancho_t) * 0.5
			Pictos.dibujar(self, icono, Rect2(x0, r.get_center().y - lado * 0.5, lado, lado), c_txt, true, 0.0, c_txt)
			texto(t, Rect2(x0 + lado + px(6), r.position.y, ancho_t + px(4), r.size.y), tam, c_txt, "izquierda", bool(prop("negrita", true)))
	elif t != "":
		texto(t, r, tam, c_txt, "centro", bool(prop("negrita", true)))
