class_name Estilo
extends RefCounted
## Paleta y tipografía comunes. Todo se dibuja con primitivas vectoriales a la resolución real.

const FONDO_ARRIBA := Color("#0d2a3f")
const FONDO_ABAJO := Color("#06131d")
const TARJETA := Color("#10314a")
const TARJETA_BORDE := Color("#1d4a68")
const TEXTO := Color("#e8f3fa")
const TEXTO_SEC := Color("#8db3ca")
const TEXTO_TENUE := Color("#5d8299")
const AGUA := Color("#2ec4d6")
const CALOR := Color("#ff8a3d")
const VERDE := Color("#3ddc84")
const ROJO := Color("#ff5a5f")
const AMBAR := Color("#ffc145")
const LUZ := Color("#ffd166")
const APAGADO := Color("#26465c")

static var _normal: Font
static var _negrita: Font


static func fuente(negrita := false) -> Font:
	if _normal == null:
		_normal = ThemeDB.fallback_font
		var fv := FontVariation.new()
		fv.base_font = _normal
		fv.variation_embolden = 0.55
		_negrita = fv
	return _negrita if negrita else _normal


static func color(valor, defecto: Color) -> Color:
	if valor is String and valor != "":
		return Color.from_string(valor, defecto)
	return defecto
