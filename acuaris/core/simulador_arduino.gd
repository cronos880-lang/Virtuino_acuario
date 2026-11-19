class_name SimuladorArduino
extends RefCounted
## "Arduino virtual" que se comporta como el sketch Control_Acuario_01_09_2026_Final
## (Arduino Mega 2560 + VirtuinoCM) para probar interfaces sin hardware.
##
## Reproduce:
##   - La respuesta de VirtuinoCM::getResponse() (misma sintaxis, mismos silencios y errores).
##   - virtuinoRun(): por cada pasada del loop se atiende UN comando del buffer serie.
##   - Reloj (V2,V3,V4), Bomba (V8 <- V29/V15 u horario 15-22 h), Luces (V16, rampa 16:00-16:14,
##     21:45-21:59, V10 = lumen), Temperatura (V5, V35, V6, V7, histéresis 0,2 y 3 min de relé).
## No reproduce el menú bloqueante Config() (V9): se anota y se ignora.

const V_MEMORIA := 256
const MENSAJE_BIENVENIDA := "!C=VirtuinoCM 1.0.02"
const ERROR_COMANDO := "E00=7$"

# Memoria V (en el Arduino es float de 32 bits).
var V := PackedFloat32Array()

# "EEPROM"
var lumen := 125          # Valor inicial documentado en Variables.xlsx
var setpoint := 25.0      # Consigna de temperatura (supuesta para la simulación)
var hismax := 0.2
var hismin := 0.2

# Estado físico simulado
var temperatura_agua := 24.6
var temperatura_ambiente := 21.0
var luz_pwm := 0              # Valor que iría a analogWrite(3/6)
var rele_calentador := false  # pin 2
var rele_bomba := false       # pin 4

# Tiempo simulado
var segundos_del_dia := 15.0 * 3600.0 + 58.0 * 60.0  # 15:58:00 por defecto
var millis_sim := 0.0
var _ultimo_cambio_rele := 0.0
var _t_ultima_temp := -1000.0

var _buffer_serie := ""
var avisos: Array[String] = []

const TIEMPO_MINIMO_RELE_MS := 180000.0
const CONSTANTE_PERDIDA_S := 3600.0      # el agua tiende al ambiente con tau = 1 h
const POTENCIA_CALENTADOR_C_S := 8.0 / 3600.0


func _init() -> void:
	V.resize(V_MEMORIA)
	V.fill(0.0)
	# setup()
	V[27] = setpoint
	V[28] = lumen


func fijar_hora(h: int, m: int, s: int = 0) -> void:
	segundos_del_dia = float(h * 3600 + m * 60 + s)


func hora() -> int:
	return int(segundos_del_dia / 3600.0) % 24


func minuto() -> int:
	return int(segundos_del_dia / 60.0) % 60


func segundo() -> int:
	return int(segundos_del_dia) % 60


## Llega texto por el "puerto serie" (Serial1).
func recibir(texto: String) -> void:
	_buffer_serie += texto
	if _buffer_serie.length() > 4096:
		_buffer_serie = _buffer_serie.right(4096)


## Avanza la simulación. Devuelve el texto que el Arduino "escribe" por Serial1.
func avanzar(delta_s: float) -> String:
	segundos_del_dia = fmod(segundos_del_dia + delta_s, 86400.0)
	millis_sim += delta_s * 1000.0
	_fisica(delta_s)
	var salida := ""
	# loop(): virtuinoRun() + subprogramas (cada uno vuelve a llamar a virtuinoRun vía vDelay)
	salida += _virtuino_run()
	if V[9] == 1.0:
		avisos.append("Menú de configuración (V9) no simulado")
		V[9] = 0.0
	if millis_sim - _t_ultima_temp >= 1000.0:
		_t_ultima_temp = millis_sim
		_temperatura()
		salida += _virtuino_run()
	_reloj()
	salida += _virtuino_run()
	_bomba()
	_luces()
	V[10] = lumen
	return salida


# --------------------------------------------------------------- lógica del sketch
func _reloj() -> void:
	V[2] = hora()
	V[3] = minuto()
	V[4] = segundo()


func _bomba() -> void:
	var estado: bool
	if V[29] == 1.0:
		estado = V[15] == 1.0
	else:
		var h := hora()
		estado = h >= 15 and h < 22
	rele_bomba = estado
	V[8] = 1.0 if estado else 0.0


func _luces() -> void:
	var h := hora()
	var m := minuto()
	var nivel := 0
	if V[16] == 1.0:
		nivel = lumen
	elif h == 16 and m < 15:
		nivel = _map(m, 0, 14, 0, lumen)
	elif (h > 16 and h < 21) or (h == 16 and m >= 15) or (h == 21 and m < 45):
		nivel = lumen
	elif h == 21 and m >= 45:
		nivel = _map(m, 45, 59, lumen, 0)
	luz_pwm = nivel


func _temperatura() -> void:
	# DS18B20 a 0,0625 ºC de resolución (12 bits)
	var temp := snappedf(temperatura_agua, 0.0625)
	if temp < 0.0 or temp > 40.0:
		return
	V[5] = temp
	V[35] = temp
	if millis_sim - _ultimo_cambio_rele >= TIEMPO_MINIMO_RELE_MS:
		if temp >= setpoint + hismax and rele_calentador:
			rele_calentador = false
			_ultimo_cambio_rele = millis_sim
		elif temp <= setpoint - hismin and not rele_calentador:
			rele_calentador = true
			_ultimo_cambio_rele = millis_sim
	V[6] = 1.0 if rele_calentador else 0.0
	V[7] = 0.0 if rele_calentador else 1.0


func _fisica(delta_s: float) -> void:
	var d := -(temperatura_agua - temperatura_ambiente) / CONSTANTE_PERDIDA_S
	if rele_calentador:
		d += POTENCIA_CALENTADOR_C_S
	temperatura_agua += d * delta_s


static func _map(x: int, in_min: int, in_max: int, out_min: int, out_max: int) -> int:
	# map() de Arduino (aritmética entera)
	@warning_ignore("integer_division")
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min


# --------------------------------------------------------------- VirtuinoCM
## virtuinoRun(): busca un '!' en el buffer, lee hasta '$' y responde a ESE comando.
func _virtuino_run() -> String:
	while _buffer_serie.length() > 0:
		var c := _buffer_serie[0]
		_buffer_serie = _buffer_serie.substr(1)
		if c == "!":
			var fin := _buffer_serie.find("$")
			var cmd := "!"
			if fin == -1:
				# readStringUntil con timeout: se consume lo que haya
				cmd += _buffer_serie + "$"
				_buffer_serie = ""
			else:
				cmd += _buffer_serie.substr(0, fin + 1)
				_buffer_serie = _buffer_serie.substr(fin + 1)
			return obtener_respuesta(cmd)
	return ""


## Traducción de VirtuinoCM::getResponse() (clave vacía).
func obtener_respuesta(read_buffer: String) -> String:
	var write_buffer := ""
	var start_pos := read_buffer.find("!")
	if start_pos == -1:
		return ERROR_COMANDO
	while start_pos != -1:
		var last_pos := read_buffer.find("$", start_pos + 1)
		if last_pos - start_pos > 5:
			var one := read_buffer.substr(start_pos + 1, last_pos - start_pos - 1)
			var tipo := one[0]
			if tipo == "C":
				return MENSAJE_BIENVENIDA
			var equal_pos := one.find("=")
			if equal_pos > 1:
				var pin := _to_int(one.substr(1, equal_pos - 1))
				var valor := one.substr(equal_pos + 1)
				if valor == "?":
					var resp := "_NR_"
					match tipo:
						"V":
							if pin >= 0 and pin < V_MEMORIA:
								resp = "%.2f" % V[pin]
						"A", "Q", "O":
							resp = "0"
					if resp != "_NR_":
						write_buffer += "!%s%d=%s$" % [tipo, pin, resp]
				elif tipo == "V":
					if pin >= 0 and pin < V_MEMORIA:
						V[pin] = _to_float(valor)
		if last_pos == -1:
			break
		start_pos = read_buffer.find("!", last_pos)
	return write_buffer


## String::toInt() de Arduino (atol: dígitos iniciales).
static func _to_int(t: String) -> int:
	var i := 0
	var signo := 1
	var r := 0
	t = t.strip_edges()
	if i < t.length() and (t[i] == "-" or t[i] == "+"):
		signo = -1 if t[i] == "-" else 1
		i += 1
	while i < t.length() and t[i] >= "0" and t[i] <= "9":
		r = r * 10 + t[i].to_int()
		i += 1
	return r * signo


static func _to_float(t: String) -> float:
	t = t.strip_edges()
	if t.is_valid_float():
		return t.to_float()
	# atof: prefijo numérico
	var fin := 0
	while fin < t.length() and "+-.0123456789eE".contains(t[fin]):
		fin += 1
	var pref := t.substr(0, fin)
	return pref.to_float() if pref.is_valid_float() else 0.0
