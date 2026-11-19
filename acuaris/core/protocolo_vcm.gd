class_name ProtocoloVCM
extends RefCounted
## Protocolo de texto de la librería VirtuinoCM 1.0.02 (Ilias Lamprou).
##
## Comprobado contra el código fuente oficial de la librería:
##   - Cada comando empieza por '!' y termina por '$'.
##   - Lectura:   "!V05=?$"   -> respuesta "!V5=25.31$" (pin sin ceros, float con 2 decimales).
##   - Escritura: "!V15=1$"   -> la librería NO responde nada.
##   - Saludo:    "!C00=?$"   -> "!C=VirtuinoCM 1.0.02"  (sin '$' final).
##   - Errores:   "E00=7$" (comando mal formado), "E00=5$" (clave incorrecta).
##   - La librería ignora un comando si (posición '$' - posición '!') <= 5, por eso
##     "!V5=?$" NO funciona: el pin se envía siempre con dos cifras ("V05").

const INICIO := "!"
const FIN := "$"
const TIPOS_VALIDOS := "VTAQO"


## Separa "V35" en {"tipo": "V", "pin": 35}. Devuelve {} si no es válido.
static func separar_pin(texto: String) -> Dictionary:
	var t := texto.strip_edges().to_upper()
	if t.length() < 2 or not TIPOS_VALIDOS.contains(t[0]):
		return {}
	var num := t.substr(1)
	if not num.is_valid_int():
		return {}
	var pin := num.to_int()
	if pin < 0 or pin > 255:
		return {}
	return {"tipo": t[0], "pin": pin}


static func nombre_pin(tipo: String, pin: int) -> String:
	return "%s%d" % [tipo, pin]


static func peticion_lectura(tipo: String, pin: int) -> String:
	return "%s%s%02d=?%s" % [INICIO, tipo, pin, FIN]


static func peticion_escritura(tipo: String, pin: int, valor: float) -> String:
	return "%s%s%02d=%s%s" % [INICIO, tipo, pin, formatear_valor(valor), FIN]


static func peticion_saludo() -> String:
	return "!C00=?$"  # "!C=?$" sería ignorado (<= 5 caracteres)


## Número compacto: 1 -> "1", 25.5 -> "25.5", 0.125 -> "0.125".
static func formatear_valor(valor: float) -> String:
	if is_equal_approx(valor, roundf(valor)) and absf(valor) < 1.0e9:
		return str(int(roundf(valor)))
	var s := "%.3f" % valor
	while s.ends_with("0"):
		s = s.left(s.length() - 1)
	if s.ends_with("."):
		s = s.left(s.length() - 1)
	return s


## Analiza el texto recibido (puede llegar troceado o con varios mensajes juntos).
## Devuelve {"mensajes": [{tipo, pin, valor_texto, valor}], "errores": [..], "saludo": String, "resto": String}
## "resto" es el fragmento incompleto que hay que conservar para la siguiente llamada.
static func analizar(buffer: String) -> Dictionary:
	var mensajes: Array[Dictionary] = []
	var errores: Array[String] = []
	var saludo := ""
	var pos := 0
	var resto := ""
	var n := buffer.length()
	while pos < n:
		# Errores de la librería: "E00=7$" llegan sin '!'.
		var p_ini := buffer.find(INICIO, pos)
		var p_err := buffer.find("E00=", pos)
		if p_err != -1 and (p_ini == -1 or p_err < p_ini):
			var p_fin_err := buffer.find(FIN, p_err)
			if p_fin_err == -1:
				resto = buffer.substr(p_err)
				break
			errores.append(buffer.substr(p_err, p_fin_err - p_err))
			pos = p_fin_err + 1
			continue
		if p_ini == -1:
			break  # basura sin inicio: se descarta
		# El saludo "!C=VirtuinoCM x" no lleva '$'.
		if buffer.substr(p_ini, 3) == "!C=":
			var p_sig := buffer.find(INICIO, p_ini + 1)
			var p_fin_c := buffer.find(FIN, p_ini + 1)
			var corte := n
			if p_sig != -1:
				corte = p_sig
			if p_fin_c != -1 and p_fin_c < corte:
				corte = p_fin_c
			saludo = buffer.substr(p_ini + 3, corte - p_ini - 3)
			pos = corte + (1 if corte == p_fin_c else 0)
			continue
		var p_fin := buffer.find(FIN, p_ini + 1)
		if p_fin == -1:
			resto = buffer.substr(p_ini)
			break
		# Si aparece otro '!' antes del '$', el primero estaba cortado: se descarta.
		var p_otro := buffer.find(INICIO, p_ini + 1)
		if p_otro != -1 and p_otro < p_fin:
			pos = p_otro
			continue
		var cuerpo := buffer.substr(p_ini + 1, p_fin - p_ini - 1)
		var igual := cuerpo.find("=")
		if igual > 1:
			var tipo := cuerpo[0]
			var num := cuerpo.substr(1, igual - 1)
			var valor_txt := cuerpo.substr(igual + 1)
			if TIPOS_VALIDOS.contains(tipo) and num.is_valid_int():
				mensajes.append({
					"tipo": tipo,
					"pin": num.to_int(),
					"valor_texto": valor_txt,
					"valor": valor_txt.to_float() if valor_txt.is_valid_float() else 0.0,
					"numerico": valor_txt.is_valid_float(),
				})
		pos = p_fin + 1
	return {"mensajes": mensajes, "errores": errores, "saludo": saludo, "resto": resto}
