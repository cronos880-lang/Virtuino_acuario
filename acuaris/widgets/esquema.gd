class_name Esquema
extends RefCounted
## Catálogo de elementos: nombre visible, tamaño inicial (dp) y propiedades editables.
## Lo usan la paleta, el inspector de propiedades y la creación de elementos nuevos.
##
## Tipos de propiedad: "texto", "numero", "entero", "color", "bool", "opcion", "pin".

const ORDEN := ["indicador", "valor", "led", "interruptor", "pulsador", "barra", "deslizador", "reloj", "etiqueta", "panel"]

const TIPOS := {
	"indicador": {
		"nombre": "Indicador", "w": 200, "h": 200, "pin": "V1",
		"props": [
			{"clave": "titulo", "nombre": "Título", "tipo": "texto", "defecto": ""},
			{"clave": "unidad", "nombre": "Unidad", "tipo": "texto", "defecto": ""},
			{"clave": "min", "nombre": "Mínimo", "tipo": "numero", "defecto": 0},
			{"clave": "max", "nombre": "Máximo", "tipo": "numero", "defecto": 100},
			{"clave": "decimales", "nombre": "Decimales", "tipo": "entero", "defecto": 1},
			{"clave": "pin_consigna", "nombre": "Pin consigna", "tipo": "pin", "defecto": ""},
			{"clave": "tolerancia", "nombre": "Tolerancia", "tipo": "numero", "defecto": 0.5},
			{"clave": "color", "nombre": "Color", "tipo": "color", "defecto": "#2ec4d6"},
			{"clave": "tam", "nombre": "Tamaño texto", "tipo": "numero", "defecto": 34},
		],
	},
	"valor": {
		"nombre": "Valor", "w": 128, "h": 60, "pin": "V1",
		"props": [
			{"clave": "titulo", "nombre": "Título", "tipo": "texto", "defecto": "Valor"},
			{"clave": "unidad", "nombre": "Unidad", "tipo": "texto", "defecto": ""},
			{"clave": "decimales", "nombre": "Decimales", "tipo": "entero", "defecto": 1},
			{"clave": "factor", "nombre": "Factor", "tipo": "numero", "defecto": 1},
			{"clave": "tam", "nombre": "Tamaño texto", "tipo": "numero", "defecto": 22},
			{"clave": "color", "nombre": "Color", "tipo": "color", "defecto": "#e8f3fa"},
			{"clave": "alineacion", "nombre": "Alineación", "tipo": "opcion", "defecto": "centro", "opciones": ["izquierda", "centro", "derecha"]},
			{"clave": "con_fondo", "nombre": "Con fondo", "tipo": "bool", "defecto": true},
		],
	},
	"led": {
		"nombre": "LED", "w": 200, "h": 40, "pin": "V1",
		"props": [
			{"clave": "texto", "nombre": "Texto", "tipo": "texto", "defecto": "Piloto"},
			{"clave": "texto_on", "nombre": "Texto encendido", "tipo": "texto", "defecto": "ON"},
			{"clave": "texto_off", "nombre": "Texto apagado", "tipo": "texto", "defecto": "OFF"},
			{"clave": "color_on", "nombre": "Color encendido", "tipo": "color", "defecto": "#3ddc84"},
			{"clave": "color_off", "nombre": "Color apagado", "tipo": "color", "defecto": "#26465c"},
			{"clave": "umbral", "nombre": "Umbral", "tipo": "numero", "defecto": 0.5},
			{"clave": "radio", "nombre": "Radio (dp)", "tipo": "numero", "defecto": 11},
			{"clave": "vertical", "nombre": "Texto en dos líneas", "tipo": "bool", "defecto": false},
			{"clave": "con_fondo", "nombre": "Con fondo", "tipo": "bool", "defecto": false},
		],
	},
	"interruptor": {
		"nombre": "Interruptor", "w": 240, "h": 36, "pin": "V1",
		"props": [
			{"clave": "texto", "nombre": "Texto", "tipo": "texto", "defecto": "Interruptor"},
			{"clave": "texto_on", "nombre": "Detalle activado", "tipo": "texto", "defecto": ""},
			{"clave": "texto_off", "nombre": "Detalle desactivado", "tipo": "texto", "defecto": ""},
			{"clave": "color_on", "nombre": "Color activado", "tipo": "color", "defecto": "#2ec4d6"},
		],
	},
	"pulsador": {
		"nombre": "Pulsador", "w": 120, "h": 48, "pin": "V1",
		"props": [
			{"clave": "texto", "nombre": "Texto", "tipo": "texto", "defecto": "Pulsar"},
			{"clave": "modo", "nombre": "Modo", "tipo": "opcion", "defecto": "conmutado", "opciones": ["conmutado", "momentaneo", "valor"]},
			{"clave": "valor", "nombre": "Valor a enviar", "tipo": "numero", "defecto": 1},
			{"clave": "color", "nombre": "Color", "tipo": "color", "defecto": "#2ec4d6"},
			{"clave": "tam", "nombre": "Tamaño texto", "tipo": "numero", "defecto": 15},
			{"clave": "radio", "nombre": "Radio esquinas", "tipo": "numero", "defecto": 14},
		],
	},
	"barra": {
		"nombre": "Barra", "w": 240, "h": 48, "pin": "V1",
		"props": [
			{"clave": "titulo", "nombre": "Título", "tipo": "texto", "defecto": "Nivel"},
			{"clave": "min", "nombre": "Mínimo", "tipo": "numero", "defecto": 0},
			{"clave": "max", "nombre": "Máximo", "tipo": "numero", "defecto": 100},
			{"clave": "mostrar", "nombre": "Mostrar", "tipo": "opcion", "defecto": "valor", "opciones": ["valor", "porcentaje"]},
			{"clave": "unidad", "nombre": "Unidad", "tipo": "texto", "defecto": ""},
			{"clave": "decimales", "nombre": "Decimales", "tipo": "entero", "defecto": 0},
			{"clave": "color", "nombre": "Color", "tipo": "color", "defecto": "#ffd166"},
		],
	},
	"deslizador": {
		"nombre": "Deslizador", "w": 240, "h": 56, "pin": "V1",
		"props": [
			{"clave": "titulo", "nombre": "Título", "tipo": "texto", "defecto": "Ajuste"},
			{"clave": "min", "nombre": "Mínimo", "tipo": "numero", "defecto": 0},
			{"clave": "max", "nombre": "Máximo", "tipo": "numero", "defecto": 100},
			{"clave": "paso", "nombre": "Paso", "tipo": "numero", "defecto": 1},
			{"clave": "unidad", "nombre": "Unidad", "tipo": "texto", "defecto": ""},
			{"clave": "decimales", "nombre": "Decimales", "tipo": "entero", "defecto": 0},
			{"clave": "color", "nombre": "Color", "tipo": "color", "defecto": "#2ec4d6"},
		],
	},
	"reloj": {
		"nombre": "Reloj", "w": 280, "h": 60, "pin": "",
		"props": [
			{"clave": "titulo", "nombre": "Título", "tipo": "texto", "defecto": "Hora"},
			{"clave": "pin_h", "nombre": "Pin horas", "tipo": "pin", "defecto": "V2"},
			{"clave": "pin_m", "nombre": "Pin minutos", "tipo": "pin", "defecto": "V3"},
			{"clave": "pin_s", "nombre": "Pin segundos", "tipo": "pin", "defecto": "V4"},
			{"clave": "tam", "nombre": "Tamaño texto", "tipo": "numero", "defecto": 28},
			{"clave": "con_fondo", "nombre": "Con fondo", "tipo": "bool", "defecto": true},
		],
	},
	"etiqueta": {
		"nombre": "Texto", "w": 200, "h": 28, "pin": "",
		"props": [
			{"clave": "texto", "nombre": "Texto", "tipo": "texto", "defecto": "Texto"},
			{"clave": "tam", "nombre": "Tamaño", "tipo": "numero", "defecto": 14},
			{"clave": "color", "nombre": "Color", "tipo": "color", "defecto": "#e8f3fa"},
			{"clave": "alineacion", "nombre": "Alineación", "tipo": "opcion", "defecto": "izquierda", "opciones": ["izquierda", "centro", "derecha"]},
			{"clave": "negrita", "nombre": "Negrita", "tipo": "bool", "defecto": false},
		],
	},
	"panel": {
		"nombre": "Panel", "w": 352, "h": 160, "pin": "",
		"props": [
			{"clave": "titulo", "nombre": "Título", "tipo": "texto", "defecto": "Panel"},
			{"clave": "subtitulo", "nombre": "Subtítulo", "tipo": "texto", "defecto": ""},
			{"clave": "fondo", "nombre": "Color fondo", "tipo": "color", "defecto": "#10314a"},
			{"clave": "borde", "nombre": "Color borde", "tipo": "color", "defecto": "#1d4a68"},
			{"clave": "radio", "nombre": "Radio esquinas", "tipo": "numero", "defecto": 16},
		],
	},
}


static func info(tipo: String) -> Dictionary:
	return TIPOS.get(tipo, {})


static func usa_pin(tipo: String) -> bool:
	return info(tipo).get("pin", "") != ""


## Definición nueva de un elemento con sus valores por defecto.
static func crear(tipo: String, id: String, x: float, y: float) -> Dictionary:
	var i := info(tipo)
	var props := {}
	for p in i.get("props", []):
		if str(p.defecto) != "" or p.tipo == "texto":
			props[p.clave] = p.defecto
	var d := {"id": id, "tipo": tipo, "x": x, "y": y, "w": i.get("w", 100), "h": i.get("h", 40), "props": props}
	if usa_pin(tipo):
		d["pin"] = i.pin
	return d
