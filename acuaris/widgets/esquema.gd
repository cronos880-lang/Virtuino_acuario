class_name Esquema
extends RefCounted
## Catálogo de elementos: nombre visible, tamaño inicial (dp), script y propiedades editables.
## Lo usan la paleta, el inspector, la fábrica y la creación de elementos nuevos.
## ARCHIVO GENERADO: se edita herramientas/generar_esquema.py y se ejecuta
##   python3 herramientas/generar_esquema.py acuaris/widgets/esquema.gd
##
## Tipos de propiedad: "texto", "numero", "entero", "color", "bool", "opcion", "pin", "imagen".

const GRUPOS := [
	[
		"Visualización",
		[
			"valor",
			"valor_editable",
			"led",
			"estado",
			"indicador",
			"manometro",
			"barra",
			"barra_escala",
			"barra_vertical",
			"giratorio",
			"segmentos",
			"imagen",
			"reloj",
			"etiqueta",
			"panel"
		]
	],
	[
		"Control",
		[
			"interruptor",
			"interruptor_seguro",
			"pulsador",
			"pulsador_seguro",
			"casilla",
			"opciones",
			"grupo_botones",
			"selector",
			"potenciometro",
			"deslizador",
			"deslizador_v"
		]
	],
	[
		"Gráficas y especiales",
		[
			"grafica",
			"grafica_avanzada",
			"grafica_emergente",
			"historial_tabla",
			"tabla",
			"estado_dispositivo",
			"regla",
			"programador",
			"mapa"
		]
	],
	[
		"Hidráulica",
		[
			"deposito",
			"tuberia_h",
			"tuberia_v",
			"acoplamiento",
			"codo",
			"te",
			"cruz",
			"reduccion",
			"valvula_2v",
			"valvula_3v",
			"acoplamiento_eje",
			"bomba_h",
			"antirretorno",
			"caudalimetro",
			"volante",
			"maneta",
			"motor",
			"solenoide",
			"manometro_peq",
			"sensor",
			"agitador",
			"chorro"
		]
	]
]

const ORDEN := [
	"valor",
	"valor_editable",
	"led",
	"estado",
	"indicador",
	"manometro",
	"barra",
	"barra_escala",
	"barra_vertical",
	"giratorio",
	"segmentos",
	"imagen",
	"reloj",
	"etiqueta",
	"panel",
	"interruptor",
	"interruptor_seguro",
	"pulsador",
	"pulsador_seguro",
	"casilla",
	"opciones",
	"grupo_botones",
	"selector",
	"potenciometro",
	"deslizador",
	"deslizador_v",
	"grafica",
	"grafica_avanzada",
	"grafica_emergente",
	"historial_tabla",
	"tabla",
	"estado_dispositivo",
	"regla",
	"programador",
	"mapa",
	"deposito",
	"tuberia_h",
	"tuberia_v",
	"acoplamiento",
	"codo",
	"te",
	"cruz",
	"reduccion",
	"valvula_2v",
	"valvula_3v",
	"acoplamiento_eje",
	"bomba_h",
	"antirretorno",
	"caudalimetro",
	"volante",
	"maneta",
	"motor",
	"solenoide",
	"manometro_peq",
	"sensor",
	"agitador",
	"chorro"
]

const TIPOS := {
	"valor": {
		"nombre": "Valor",
		"w": 128,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Valor"
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "factor",
				"nombre": "Factor",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 22
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#e8f3fa"
			},
			{
				"clave": "alineacion",
				"nombre": "Alineación",
				"tipo": "opcion",
				"defecto": "centro",
				"opciones": [
					"izquierda",
					"centro",
					"derecha"
				]
			},
			{
				"clave": "con_fondo",
				"nombre": "Con fondo",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "editable",
				"nombre": "Editable al tocar",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "formato",
				"nombre": "Formato",
				"tipo": "opcion",
				"defecto": "numero",
				"opciones": [
					"numero",
					"hora"
				]
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_valor"
	},
	"valor_editable": {
		"nombre": "Valor editable",
		"w": 128,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Consigna"
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 22
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#ffc145"
			},
			{
				"clave": "alineacion",
				"nombre": "Alineación",
				"tipo": "opcion",
				"defecto": "centro",
				"opciones": [
					"izquierda",
					"centro",
					"derecha"
				]
			},
			{
				"clave": "con_fondo",
				"nombre": "Con fondo",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "editable",
				"nombre": "Editable al tocar",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "formato",
				"nombre": "Formato",
				"tipo": "opcion",
				"defecto": "numero",
				"opciones": [
					"numero",
					"hora"
				]
			},
			{
				"clave": "texto_cero",
				"nombre": "Texto si vale 0 (vacío = mostrar 0)",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_valor"
	},
	"led": {
		"nombre": "LED",
		"w": 200,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Piloto"
			},
			{
				"clave": "texto_on",
				"nombre": "Texto encendido",
				"tipo": "texto",
				"defecto": "ON"
			},
			{
				"clave": "texto_off",
				"nombre": "Texto apagado",
				"tipo": "texto",
				"defecto": "OFF"
			},
			{
				"clave": "color_on",
				"nombre": "Color encendido",
				"tipo": "color",
				"defecto": "#3ddc84"
			},
			{
				"clave": "color_off",
				"nombre": "Color apagado",
				"tipo": "color",
				"defecto": "#26465c"
			},
			{
				"clave": "umbral",
				"nombre": "Umbral",
				"tipo": "numero",
				"defecto": 0.5
			},
			{
				"clave": "radio",
				"nombre": "Radio (dp)",
				"tipo": "numero",
				"defecto": 11
			},
			{
				"clave": "vertical",
				"nombre": "Texto en dos líneas",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "con_fondo",
				"nombre": "Con fondo",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_led"
	},
	"estado": {
		"nombre": "Texto de estado",
		"w": 200,
		"h": 56,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Estado"
			},
			{
				"clave": "reglas",
				"nombre": "Reglas (cond|texto|color; ...)",
				"tipo": "texto",
				"defecto": "==0|Apagado|#5d8299; ==1|En marcha|#3ddc84; >1|Alarma|#ff5a5f"
			},
			{
				"clave": "defecto",
				"nombre": "Texto si no se cumple",
				"tipo": "texto",
				"defecto": "?"
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "alineacion",
				"nombre": "Alineación",
				"tipo": "opcion",
				"defecto": "centro",
				"opciones": [
					"izquierda",
					"centro",
					"derecha"
				]
			},
			{
				"clave": "con_fondo",
				"nombre": "Con fondo",
				"tipo": "bool",
				"defecto": true
			}
		],
		"script": "w_estado"
	},
	"indicador": {
		"nombre": "Indicador",
		"w": 200,
		"h": 200,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "pin_consigna",
				"nombre": "Pin consigna",
				"tipo": "pin",
				"defecto": ""
			},
			{
				"clave": "tolerancia",
				"nombre": "Tolerancia",
				"tipo": "numero",
				"defecto": 0.5
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 34
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_indicador"
	},
	"manometro": {
		"nombre": "Manómetro (aguja)",
		"w": 200,
		"h": 200,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": "bar"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 10
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "decimales_escala",
				"nombre": "Decimales escala",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "divisiones",
				"nombre": "Divisiones",
				"tipo": "entero",
				"defecto": 10
			},
			{
				"clave": "zona_verde",
				"nombre": "Verde hasta",
				"tipo": "numero",
				"defecto": 6
			},
			{
				"clave": "zona_ambar",
				"nombre": "Ámbar hasta",
				"tipo": "numero",
				"defecto": 8
			},
			{
				"clave": "sin_zonas",
				"nombre": "Sin zonas de color",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "color_aguja",
				"nombre": "Color aguja",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_manometro"
	},
	"barra": {
		"nombre": "Barra",
		"w": 240,
		"h": 48,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Nivel"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "mostrar",
				"nombre": "Mostrar",
				"tipo": "opcion",
				"defecto": "valor",
				"opciones": [
					"valor",
					"porcentaje"
				]
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#ffd166"
			},
			{
				"clave": "escala",
				"nombre": "Con escala",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_barra"
	},
	"barra_escala": {
		"nombre": "Barra con escala",
		"w": 240,
		"h": 64,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Nivel"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "mostrar",
				"nombre": "Mostrar",
				"tipo": "opcion",
				"defecto": "valor",
				"opciones": [
					"valor",
					"porcentaje"
				]
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "escala",
				"nombre": "Con escala",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_barra"
	},
	"barra_vertical": {
		"nombre": "Barra vertical",
		"w": 80,
		"h": 220,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Temp."
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": "°C"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 40
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "decimales_escala",
				"nombre": "Decimales escala",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "degradado",
				"nombre": "Degradado",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "color_inicio",
				"nombre": "Color abajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "color_fin",
				"nombre": "Color arriba",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color",
				"nombre": "Color fijo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_barra_vertical"
	},
	"giratorio": {
		"nombre": "Icono giratorio",
		"w": 100,
		"h": 116,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Bomba"
			},
			{
				"clave": "icono",
				"nombre": "Icono",
				"tipo": "opcion",
				"defecto": "bomba",
				"opciones": [
					"bomba",
					"ventilador",
					"rueda"
				]
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máxima velocidad en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "limite_alto",
				"nombre": "Límite alto",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "limite_bajo",
				"nombre": "Límite bajo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_alto",
				"nombre": "Color si alto",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "color_bajo",
				"nombre": "Color si bajo",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_giratorio"
	},
	"segmentos": {
		"nombre": "Segmentos",
		"w": 160,
		"h": 64,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Señal"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "segmentos",
				"nombre": "Segmentos",
				"tipo": "entero",
				"defecto": 5
			},
			{
				"clave": "umbral_malo",
				"nombre": "Umbral malo",
				"tipo": "numero",
				"defecto": 25
			},
			{
				"clave": "umbral_regular",
				"nombre": "Umbral regular",
				"tipo": "numero",
				"defecto": 50
			},
			{
				"clave": "escalera",
				"nombre": "Forma de escalera",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": "%"
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			}
		],
		"script": "w_segmentos"
	},
	"imagen": {
		"nombre": "Imagen",
		"w": 160,
		"h": 120,
		"pin": "V1",
		"props": [
			{
				"clave": "imagen",
				"nombre": "Imagen",
				"tipo": "imagen",
				"defecto": ""
			},
			{
				"clave": "imagen_activa",
				"nombre": "Imagen si se cumple",
				"tipo": "imagen",
				"defecto": ""
			},
			{
				"clave": "condicion",
				"nombre": "Condición",
				"tipo": "texto",
				"defecto": ">= 0.5"
			},
			{
				"clave": "ajuste",
				"nombre": "Ajuste",
				"tipo": "opcion",
				"defecto": "contener",
				"opciones": [
					"contener",
					"cubrir"
				]
			}
		],
		"script": "w_imagen"
	},
	"reloj": {
		"nombre": "Reloj",
		"w": 280,
		"h": 60,
		"pin": "",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Hora"
			},
			{
				"clave": "pin_h",
				"nombre": "Pin horas",
				"tipo": "pin",
				"defecto": "V2"
			},
			{
				"clave": "pin_m",
				"nombre": "Pin minutos",
				"tipo": "pin",
				"defecto": "V3"
			},
			{
				"clave": "pin_s",
				"nombre": "Pin segundos",
				"tipo": "pin",
				"defecto": "V4"
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 28
			},
			{
				"clave": "con_fondo",
				"nombre": "Con fondo",
				"tipo": "bool",
				"defecto": true
			}
		],
		"script": "w_reloj"
	},
	"etiqueta": {
		"nombre": "Texto",
		"w": 200,
		"h": 28,
		"pin": "",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Texto"
			},
			{
				"clave": "tam",
				"nombre": "Tamaño",
				"tipo": "numero",
				"defecto": 14
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#e8f3fa"
			},
			{
				"clave": "alineacion",
				"nombre": "Alineación",
				"tipo": "opcion",
				"defecto": "izquierda",
				"opciones": [
					"izquierda",
					"centro",
					"derecha"
				]
			},
			{
				"clave": "negrita",
				"nombre": "Negrita",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_etiqueta"
	},
	"panel": {
		"nombre": "Panel",
		"w": 352,
		"h": 160,
		"pin": "",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Panel"
			},
			{
				"clave": "subtitulo",
				"nombre": "Subtítulo",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "fondo",
				"nombre": "Color fondo",
				"tipo": "color",
				"defecto": "#10314a"
			},
			{
				"clave": "borde",
				"nombre": "Color borde",
				"tipo": "color",
				"defecto": "#1d4a68"
			},
			{
				"clave": "radio",
				"nombre": "Radio esquinas",
				"tipo": "numero",
				"defecto": 16
			}
		],
		"script": "w_panel"
	},
	"interruptor": {
		"nombre": "Interruptor",
		"w": 240,
		"h": 36,
		"pin": "V1",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Interruptor"
			},
			{
				"clave": "texto_on",
				"nombre": "Detalle activado",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "texto_off",
				"nombre": "Detalle desactivado",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_on",
				"nombre": "Color activado",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_interruptor"
	},
	"interruptor_seguro": {
		"nombre": "Interruptor seguro",
		"w": 240,
		"h": 36,
		"pin": "V1",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Calentador"
			},
			{
				"clave": "texto_on",
				"nombre": "Detalle activado",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "texto_off",
				"nombre": "Detalle desactivado",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "color_on",
				"nombre": "Color activado",
				"tipo": "color",
				"defecto": "#ff8a3d"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_interruptor"
	},
	"pulsador": {
		"nombre": "Pulsador",
		"w": 120,
		"h": 48,
		"pin": "V1",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Pulsar"
			},
			{
				"clave": "modo",
				"nombre": "Modo",
				"tipo": "opcion",
				"defecto": "conmutado",
				"opciones": [
					"conmutado",
					"momentaneo",
					"valor"
				]
			},
			{
				"clave": "valor",
				"nombre": "Valor a enviar",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 15
			},
			{
				"clave": "radio",
				"nombre": "Radio esquinas",
				"tipo": "numero",
				"defecto": 14
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_pulsador"
	},
	"pulsador_seguro": {
		"nombre": "Pulsador seguro",
		"w": 120,
		"h": 48,
		"pin": "V1",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Reset"
			},
			{
				"clave": "modo",
				"nombre": "Modo",
				"tipo": "opcion",
				"defecto": "valor",
				"opciones": [
					"conmutado",
					"momentaneo",
					"valor"
				]
			},
			{
				"clave": "valor",
				"nombre": "Valor a enviar",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#ff5a5f"
			},
			{
				"clave": "tam",
				"nombre": "Tamaño texto",
				"tipo": "numero",
				"defecto": 15
			},
			{
				"clave": "radio",
				"nombre": "Radio esquinas",
				"tipo": "numero",
				"defecto": 14
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": "1234"
			}
		],
		"script": "w_pulsador"
	},
	"casilla": {
		"nombre": "Casilla",
		"w": 200,
		"h": 36,
		"pin": "V1",
		"props": [
			{
				"clave": "texto",
				"nombre": "Texto",
				"tipo": "texto",
				"defecto": "Activar"
			},
			{
				"clave": "valor_on",
				"nombre": "Valor marcada",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "valor_off",
				"nombre": "Valor desmarcada",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_casilla"
	},
	"opciones": {
		"nombre": "Opciones",
		"w": 180,
		"h": 108,
		"pin": "V1",
		"props": [
			{
				"clave": "opciones",
				"nombre": "Opciones (texto:valor, ...)",
				"tipo": "texto",
				"defecto": "Apagado:0, Auto:1, Manual:2"
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_opciones"
	},
	"grupo_botones": {
		"nombre": "Grupo de botones",
		"w": 300,
		"h": 44,
		"pin": "V1",
		"props": [
			{
				"clave": "opciones",
				"nombre": "Opciones (texto:valor, ...)",
				"tipo": "texto",
				"defecto": "Off:0, Auto:1, Manual:2"
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_opciones"
	},
	"selector": {
		"nombre": "Selector giratorio",
		"w": 150,
		"h": 160,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Velocidad"
			},
			{
				"clave": "opciones",
				"nombre": "Posiciones (texto:valor, ...)",
				"tipo": "texto",
				"defecto": "Off:0, 1:1, 2:2, 3:3"
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_selector"
	},
	"potenciometro": {
		"nombre": "Potenciómetro",
		"w": 150,
		"h": 166,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Intensidad"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 255
			},
			{
				"clave": "paso",
				"nombre": "Paso",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#ffd166"
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_potenciometro"
	},
	"deslizador": {
		"nombre": "Deslizador",
		"w": 240,
		"h": 56,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Ajuste"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "paso",
				"nombre": "Paso",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "vertical",
				"nombre": "Vertical",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_deslizador"
	},
	"deslizador_v": {
		"nombre": "Deslizador vertical",
		"w": 72,
		"h": 220,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Nivel"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "paso",
				"nombre": "Paso",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "vertical",
				"nombre": "Vertical",
				"tipo": "bool",
				"defecto": true
			},
			{
				"clave": "confirmar",
				"nombre": "Pedir confirmación",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "clave",
				"nombre": "PIN (vacío = sin PIN)",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_deslizador"
	},
	"grafica": {
		"nombre": "Gráfica",
		"w": 352,
		"h": 200,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Temperatura"
			},
			{
				"clave": "rango",
				"nombre": "Rango inicial",
				"tipo": "opcion",
				"defecto": "1 h",
				"opciones": [
					"15 min",
					"1 h",
					"6 h",
					"24 h",
					"7 d"
				]
			},
			{
				"clave": "min",
				"nombre": "Mínimo (vacío = auto)",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "max",
				"nombre": "Máximo (vacío = auto)",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_grafica"
	},
	"grafica_avanzada": {
		"nombre": "Gráfica avanzada",
		"w": 352,
		"h": 220,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Comparativa"
			},
			{
				"clave": "pin_2",
				"nombre": "Pin 2",
				"tipo": "pin",
				"defecto": ""
			},
			{
				"clave": "pin_3",
				"nombre": "Pin 3",
				"tipo": "pin",
				"defecto": ""
			},
			{
				"clave": "rango",
				"nombre": "Rango inicial",
				"tipo": "opcion",
				"defecto": "6 h",
				"opciones": [
					"15 min",
					"1 h",
					"6 h",
					"24 h",
					"7 d"
				]
			},
			{
				"clave": "min",
				"nombre": "Mínimo (vacío = auto)",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "max",
				"nombre": "Máximo (vacío = auto)",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "color",
				"nombre": "Color 1",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "color_2",
				"nombre": "Color 2",
				"tipo": "color",
				"defecto": "#ffc145"
			},
			{
				"clave": "color_3",
				"nombre": "Color 3",
				"tipo": "color",
				"defecto": "#3ddc84"
			}
		],
		"script": "w_grafica"
	},
	"grafica_emergente": {
		"nombre": "Gráfica emergente",
		"w": 220,
		"h": 56,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Historial"
			},
			{
				"clave": "pin_2",
				"nombre": "Pin 2",
				"tipo": "pin",
				"defecto": ""
			},
			{
				"clave": "pin_3",
				"nombre": "Pin 3",
				"tipo": "pin",
				"defecto": ""
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "rango",
				"nombre": "Rango inicial",
				"tipo": "opcion",
				"defecto": "6 h",
				"opciones": [
					"15 min",
					"1 h",
					"6 h",
					"24 h",
					"7 d"
				]
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_grafica_emergente"
	},
	"historial_tabla": {
		"nombre": "Historial (tabla)",
		"w": 220,
		"h": 56,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Datos guardados"
			},
			{
				"clave": "dias",
				"nombre": "Días a mostrar",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			},
			{
				"clave": "color",
				"nombre": "Color",
				"tipo": "color",
				"defecto": "#2ec4d6"
			}
		],
		"script": "w_historial_tabla"
	},
	"tabla": {
		"nombre": "Tabla de valores",
		"w": 300,
		"h": 140,
		"pin": "",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Resumen"
			},
			{
				"clave": "filas",
				"nombre": "Filas (texto|pin|unidad|decimales; ...)",
				"tipo": "texto",
				"defecto": "Temperatura|V35|°C|1; Consigna|V27|°C|1; Bomba|V8||0"
			}
		],
		"script": "w_tabla"
	},
	"estado_dispositivo": {
		"nombre": "Estado del controlador",
		"w": 240,
		"h": 52,
		"pin": "",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Controlador"
			},
			{
				"clave": "segundos",
				"nombre": "Sin respuesta tras (s)",
				"tipo": "numero",
				"defecto": 10
			}
		],
		"script": "w_estado_dispositivo"
	},
	"regla": {
		"nombre": "Regla automática",
		"w": 300,
		"h": 52,
		"pin": "V1",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Regla"
			},
			{
				"clave": "condicion",
				"nombre": "Condición",
				"tipo": "texto",
				"defecto": "> 28"
			},
			{
				"clave": "pin_destino",
				"nombre": "Pin destino",
				"tipo": "pin",
				"defecto": "V16"
			},
			{
				"clave": "valor",
				"nombre": "Valor si se cumple",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "valor_si_no",
				"nombre": "Valor si deja de cumplirse (vacío = nada)",
				"tipo": "texto",
				"defecto": ""
			},
			{
				"clave": "al_iniciar",
				"nombre": "Actuar también al abrir",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_regla"
	},
	"programador": {
		"nombre": "Programador horario",
		"w": 300,
		"h": 110,
		"pin": "V16",
		"props": [
			{
				"clave": "titulo",
				"nombre": "Título",
				"tipo": "texto",
				"defecto": "Horario"
			},
			{
				"clave": "eventos",
				"nombre": "Eventos (HH:MM|días|valor; ...)",
				"tipo": "texto",
				"defecto": "08:00|LMXJV|1; 22:00|*|0"
			}
		],
		"script": "w_programador"
	},
	"mapa": {
		"nombre": "Mapa (posición)",
		"w": 300,
		"h": 200,
		"pin": "",
		"props": [
			{
				"clave": "pin_lat",
				"nombre": "Pin latitud",
				"tipo": "pin",
				"defecto": "V50"
			},
			{
				"clave": "pin_lon",
				"nombre": "Pin longitud",
				"tipo": "pin",
				"defecto": "V51"
			},
			{
				"clave": "radio_m",
				"nombre": "Radio visible (m)",
				"tipo": "numero",
				"defecto": 200
			}
		],
		"script": "w_mapa"
	},
	"deposito": {
		"nombre": "Depósito",
		"w": 140,
		"h": 180,
		"pin": "V1",
		"props": [
			{
				"clave": "forma",
				"nombre": "Forma",
				"tipo": "opcion",
				"defecto": "redondeado",
				"opciones": [
					"redondeado",
					"caja",
					"cilindro",
					"barril",
					"conico"
				]
			},
			{
				"clave": "min",
				"nombre": "Vacío en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Lleno en",
				"tipo": "numero",
				"defecto": 100
			},
			{
				"clave": "mostrar",
				"nombre": "Mostrar",
				"tipo": "opcion",
				"defecto": "porcentaje",
				"opciones": [
					"porcentaje",
					"valor"
				]
			},
			{
				"clave": "unidad",
				"nombre": "Unidad",
				"tipo": "texto",
				"defecto": "L"
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "etiqueta",
				"nombre": "Etiqueta",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_hidraulica"
	},
	"tuberia_h": {
		"nombre": "Tubería horizontal",
		"w": 120,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"tuberia_v": {
		"nombre": "Tubería vertical",
		"w": 40,
		"h": 120,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"acoplamiento": {
		"nombre": "Acoplamiento",
		"w": 60,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"codo": {
		"nombre": "Codo",
		"w": 40,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "orientacion",
				"nombre": "Orientación (0-3)",
				"tipo": "entero",
				"defecto": 0
			}
		],
		"script": "w_hidraulica"
	},
	"te": {
		"nombre": "Te",
		"w": 60,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "orientacion",
				"nombre": "Orientación (0-3)",
				"tipo": "entero",
				"defecto": 0
			}
		],
		"script": "w_hidraulica"
	},
	"cruz": {
		"nombre": "Cruz",
		"w": 40,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"reduccion": {
		"nombre": "Reducción",
		"w": 60,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "tubo_2",
				"nombre": "Grosor salida (dp)",
				"tipo": "numero",
				"defecto": 10
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"valvula_2v": {
		"nombre": "Válvula 2 vías",
		"w": 80,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			},
			{
				"clave": "etiqueta",
				"nombre": "Etiqueta",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_hidraulica"
	},
	"valvula_3v": {
		"nombre": "Válvula 3 vías",
		"w": 80,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "orientacion",
				"nombre": "Orientación (0-3)",
				"tipo": "entero",
				"defecto": 0
			},
			{
				"clave": "etiqueta",
				"nombre": "Etiqueta",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_hidraulica"
	},
	"acoplamiento_eje": {
		"nombre": "Acoplamiento con eje",
		"w": 60,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"bomba_h": {
		"nombre": "Bomba",
		"w": 100,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "etiqueta",
				"nombre": "Etiqueta",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_hidraulica"
	},
	"antirretorno": {
		"nombre": "Válvula antirretorno",
		"w": 80,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			}
		],
		"script": "w_hidraulica"
	},
	"caudalimetro": {
		"nombre": "Caudalímetro",
		"w": 80,
		"h": 60,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Parado en",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo en",
				"tipo": "numero",
				"defecto": 1
			},
			{
				"clave": "invertir",
				"nombre": "Invertir sentido",
				"tipo": "bool",
				"defecto": false
			},
			{
				"clave": "etiqueta",
				"nombre": "Etiqueta",
				"tipo": "texto",
				"defecto": ""
			}
		],
		"script": "w_hidraulica"
	},
	"volante": {
		"nombre": "Volante",
		"w": 40,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			}
		],
		"script": "w_hidraulica"
	},
	"maneta": {
		"nombre": "Maneta",
		"w": 40,
		"h": 40,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			}
		],
		"script": "w_hidraulica"
	},
	"motor": {
		"nombre": "Motor",
		"w": 40,
		"h": 48,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			}
		],
		"script": "w_hidraulica"
	},
	"solenoide": {
		"nombre": "Solenoide",
		"w": 32,
		"h": 44,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			}
		],
		"script": "w_hidraulica"
	},
	"manometro_peq": {
		"nombre": "Manómetro de línea",
		"w": 44,
		"h": 52,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "min",
				"nombre": "Mínimo",
				"tipo": "numero",
				"defecto": 0
			},
			{
				"clave": "max",
				"nombre": "Máximo",
				"tipo": "numero",
				"defecto": 10
			},
			{
				"clave": "decimales",
				"nombre": "Decimales",
				"tipo": "entero",
				"defecto": 1
			}
		],
		"script": "w_hidraulica"
	},
	"sensor": {
		"nombre": "Sensor",
		"w": 40,
		"h": 48,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "etiqueta",
				"nombre": "Etiqueta",
				"tipo": "texto",
				"defecto": "TT"
			}
		],
		"script": "w_hidraulica"
	},
	"agitador": {
		"nombre": "Agitador",
		"w": 60,
		"h": 100,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			}
		],
		"script": "w_hidraulica"
	},
	"chorro": {
		"nombre": "Chorro de salida",
		"w": 30,
		"h": 80,
		"pin": "V1",
		"props": [
			{
				"clave": "tubo",
				"nombre": "Grosor tubo (dp)",
				"tipo": "numero",
				"defecto": 18
			},
			{
				"clave": "color_tubo",
				"nombre": "Color tubo",
				"tipo": "color",
				"defecto": "#5f7c8e"
			},
			{
				"clave": "color_liquido",
				"nombre": "Color líquido",
				"tipo": "color",
				"defecto": "#2ec4d6"
			},
			{
				"clave": "condicion",
				"nombre": "Activo si",
				"tipo": "texto",
				"defecto": ">= 0.5"
			}
		],
		"script": "w_hidraulica"
	}
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
