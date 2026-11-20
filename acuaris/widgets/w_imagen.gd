class_name WImagen
extends AcWidget
## Imagen propia (PNG/JPG incrustada en el proyecto). Con "imagen_activa", cambia cuando
## el valor del pin cumple la condición (por defecto ">= 0.5").

static var _cache: Dictionary = {}


static func textura(b64: String) -> Texture2D:
	if b64 == "":
		return null
	var clave := b64.md5_text()
	if _cache.has(clave):
		return _cache[clave]
	var datos := Marshalls.base64_to_raw(b64)
	var img := Image.new()
	var e := img.load_png_from_buffer(datos)
	if e != OK:
		e = img.load_jpg_from_buffer(datos)
	if e != OK:
		e = img.load_webp_from_buffer(datos)
	if e != OK:
		return null
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t


func _draw() -> void:
	var b64 := str(prop("imagen", ""))
	var alt := str(prop("imagen_activa", ""))
	if alt != "" and tiene_valor() and AcWidget.cumple(str(prop("condicion", ">=0.5")), valor()):
		b64 = alt
	var t := textura(b64)
	if t == null:
		caja(Rect2(Vector2.ZERO, size), Color(Estilo.APAGADO, 0.3), Estilo.TARJETA_BORDE, 10)
		texto("Imagen\n(elígela en propiedades)", Rect2(Vector2.ZERO, size), 11, Estilo.TEXTO_TENUE)
		return
	var tam := Vector2(t.get_size())
	var esc := minf(size.x / tam.x, size.y / tam.y) if str(prop("ajuste", "contener")) == "contener" else maxf(size.x / tam.x, size.y / tam.y)
	var dib := tam * esc
	draw_texture_rect(t, Rect2((size - dib) * 0.5, dib), false)
