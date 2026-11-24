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
##
## Con modelo = "acuario_v2" se comporta como arduino/Control_Acuario_V2 (ajustes escritos desde la
## app con validación, horarios configurables, rampas por segundos, alarmas y diagnóstico).

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

## "acuario_v1" (sketch original) o "acuario_v2" (Control_Acuario_V2)
var modelo := "acuario_v1"
## Pruebas: simular la sonda desconectada (solo modelo V2)
var sonda_conectada := true

# --- Estado del modelo V2
var aj := {}                 # ajustes (como la EEPROM del V2)
var _publicado := {}
var _t_ultima_valida := 0.0
var _rele_libre := true
var _temperatura_v2 := NAN
var _ms_calentador_hoy := 0.0
var _dia_v2 := 0
# V2 2.1.0: intensidad temporal, resumen del día y vigilancia del calentador
var _intensidad_actual := 125
var _estaba_en_horario := false
var _primera_vez_luces := true
var _seg_anterior := -1.0
var _ms_luz_hoy := 0.0
var _ms_bomba_hoy := 0.0
var _encendidos_hoy := 0
var _t_calentador_on := 0.0
var _temp_al_encender := NAN
var _min_hoy := NAN
var _max_hoy := NAN

const TIEMPO_MINIMO_RELE_MS := 180000.0
const CONSTANTE_PERDIDA_S := 3600.0      # el agua tiende al ambiente con tau = 1 h
const POTENCIA_CALENTADOR_C_S := 8.0 / 3600.0


func _init() -> void:
	V.resize(V_MEMORIA)
	V.fill(0.0)
	# setup()
	V[27] = setpoint
	V[28] = lumen


func configurar_modelo(m: String) -> void:
	modelo = m
	if modelo != "acuario_v2":
		return
	aj = {"consigna": 25.0, "histeresis": 0.2, "alarma_alta": 29.0, "alarma_baja": 21.0, "intensidad": 125,
		"luz_on": 1600, "luz_off": 2200, "rampa": 15, "bomba_on": 1500, "bomba_off": 2200}
	V.fill(0.0)
	_publicado.clear()
	for par in [[27, "consigna"], [28, "intensidad"], [50, "luz_on"], [51, "luz_off"], [52, "rampa"], [53, "bomba_on"],
			[54, "bomba_off"], [55, "histeresis"], [57, "alarma_alta"], [58, "alarma_baja"]]:
		_publicar(par[0], aj[par[1]])
	_publicar(44, 0)
	V[10] = aj.intensidad
	V[70] = 210
	_intensidad_actual = aj.intensidad
	_publicar(12, _intensidad_actual)
	_primera_vez_luces = true
	_min_hoy = NAN
	_max_hoy = NAN
	V[71] = 1
	V[72] = 1
	_t_ultima_valida = millis_sim
	_rele_libre = true
	rele_calentador = false


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
	if modelo == "acuario_v2":
		return _avanzar_v2(delta_s)
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


# =============================================================================== modelo V2
static func hhmm_valido(v: int) -> bool:
	return v >= 0 and v <= 2359 and v % 100 < 60


static func segundos_de(hhmm: int) -> int:
	@warning_ignore("integer_division")
	return (hhmm / 100) * 3600 + (hhmm % 100) * 60


static func en_horario(seg: int, inicio: int, fin: int) -> bool:
	var a := segundos_de(inicio)
	var b := segundos_de(fin)
	if a == b:
		return false
	if a < b:
		return seg >= a and seg < b
	return seg >= a or seg < b


## Misma fórmula que Logica::nivel_luz del sketch V2 (aritmética entera).
static func nivel_luz(seg: int, on: int, off: int, rampa_min: int, maximo: int) -> int:
	if not en_horario(seg, on, off):
		return 0
	var dia := 86400
	var a := segundos_de(on)
	var b := segundos_de(off)
	var desde_on := posmod(seg - a, dia)
	var hasta_off := posmod(b - seg, dia)
	var rampa := rampa_min * 60
	var duracion := posmod(b - a, dia)
	if rampa * 2 > duracion:
		@warning_ignore("integer_division")
		rampa = duracion / 2
	if rampa <= 0:
		return maximo
	var nivel := maximo
	if desde_on < rampa:
		@warning_ignore("integer_division")
		nivel = maximo * desde_on / rampa
	if hasta_off < rampa:
		@warning_ignore("integer_division")
		nivel = mini(nivel, maximo * hasta_off / rampa)
	return clampi(nivel, 0, maximo)


func _publicar(v: int, valor: float) -> void:
	V[v] = valor
	_publicado[v] = valor


func _escrito(v: int) -> bool:
	return absf(V[v] - float(_publicado.get(v, 0.0))) > 0.001


func _tomar_real(v: int, clave: String, mn: float, mx: float) -> void:
	if not _escrito(v):
		return
	var x := V[v]
	if x >= mn and x <= mx:
		aj[clave] = x
	_publicar(v, aj[clave])


func _tomar_hhmm(v: int, clave: String) -> void:
	if not _escrito(v):
		return
	var x := roundi(V[v])
	if hhmm_valido(x):
		aj[clave] = x
	_publicar(v, aj[clave])


func _ajustes_v2() -> void:
	_tomar_real(27, "consigna", 18.0, 32.0)
	_tomar_real(55, "histeresis", 0.1, 2.0)
	var alta: float = aj.alarma_alta
	var baja: float = aj.alarma_baja
	if _escrito(57) or _escrito(58):
		var na := V[57] if (V[57] >= 5.0 and V[57] <= 40.0) else alta
		var nb := V[58] if (V[58] >= 5.0 and V[58] <= 40.0) else baja
		if nb < na:
			aj.alarma_alta = na
			aj.alarma_baja = nb
		_publicar(57, aj.alarma_alta)
		_publicar(58, aj.alarma_baja)
	if _escrito(28):
		var n := roundi(V[28])
		if n >= 0 and n <= 255:
			aj.intensidad = n
			_volver_a_referencia()
		_publicar(28, aj.intensidad)
	if _escrito(52):
		var n := roundi(V[52])
		if n >= 0 and n <= 60:
			aj.rampa = n
		_publicar(52, aj.rampa)
	for par in [[50, "luz_on"], [51, "luz_off"], [53, "bomba_on"], [54, "bomba_off"]]:
		_tomar_hhmm(par[0], par[1])
	V[10] = aj.intensidad
	if _escrito(44):
		var hhmm := roundi(V[44])
		if hhmm_valido(hhmm):
			@warning_ignore("integer_division")
			fijar_hora(hhmm / 100, hhmm % 100, 0)
			V[62] = 0
		_publicar(44, 0)


func _volver_a_referencia() -> void:
	_intensidad_actual = aj.intensidad
	_publicar(12, _intensidad_actual)


func _hhmm_ahora() -> int:
	return hora() * 100 + minuto()


func _resumen_temperatura(t: float) -> void:
	if is_nan(_min_hoy) or t < _min_hoy:
		_min_hoy = t
		V[76] = t
		V[77] = _hhmm_ahora()
	if is_nan(_max_hoy) or t > _max_hoy:
		_max_hoy = t
		V[78] = t
		V[79] = _hhmm_ahora()


func _nuevo_dia_v2() -> void:
	_ms_calentador_hoy = 0.0
	_ms_luz_hoy = 0.0
	_ms_bomba_hoy = 0.0
	_encendidos_hoy = 0
	_min_hoy = NAN
	_max_hoy = NAN
	if not is_nan(_temperatura_v2):
		_resumen_temperatura(_temperatura_v2)


func _avanzar_v2(delta_s: float) -> String:
	segundos_del_dia = fmod(segundos_del_dia + delta_s, 86400.0)
	if _seg_anterior >= 0.0 and segundos_del_dia < _seg_anterior:
		_nuevo_dia_v2()
	_seg_anterior = segundos_del_dia
	millis_sim += delta_s * 1000.0
	_fisica(delta_s)
	var salida := _virtuino_run()
	_ajustes_v2()
	# Temperatura sin bloqueo: una lectura por segundo
	if millis_sim - _t_ultima_temp >= 1000.0:
		_t_ultima_temp = millis_sim
		if sonda_conectada:
			_temperatura_v2 = snappedf(temperatura_agua, 0.0625)
			_t_ultima_valida = millis_sim
			V[5] = _temperatura_v2
			V[35] = _temperatura_v2
			_resumen_temperatura(_temperatura_v2)
			if rele_calentador and is_nan(_temp_al_encender):
				_temp_al_encender = _temperatura_v2
	var fallo := millis_sim - _t_ultima_valida > 15000.0
	if (fallo or is_nan(_temperatura_v2)) and rele_calentador:
		rele_calentador = false
		_ultimo_cambio_rele = millis_sim
		_rele_libre = false
	if not fallo and not is_nan(_temperatura_v2):
		if _rele_libre or millis_sim - _ultimo_cambio_rele >= TIEMPO_MINIMO_RELE_MS:
			var nuevo := rele_calentador
			if rele_calentador and _temperatura_v2 >= aj.consigna + aj.histeresis:
				nuevo = false
			elif not rele_calentador and _temperatura_v2 <= aj.consigna - aj.histeresis:
				nuevo = true
			if nuevo != rele_calentador:
				if nuevo:
					_t_calentador_on = millis_sim
					_temp_al_encender = _temperatura_v2
					_encendidos_hoy += 1
				rele_calentador = nuevo
				_ultimo_cambio_rele = millis_sim
				_rele_libre = false
	V[6] = 1.0 if rele_calentador else 0.0
	V[7] = 0.0 if rele_calentador else 1.0
	var alta: bool = not fallo and not is_nan(_temperatura_v2) and _temperatura_v2 > aj.alarma_alta
	var baja: bool = not fallo and not is_nan(_temperatura_v2) and _temperatura_v2 < aj.alarma_baja
	V[60] = 1.0 if fallo else 0.0
	V[61] = 1.0 if alta else 0.0
	V[65] = 1.0 if baja else 0.0
	var sin_efecto: bool = rele_calentador and not is_nan(_temp_al_encender) and not is_nan(_temperatura_v2) \
			and millis_sim - _t_calentador_on >= 3600000.0 and _temperatura_v2 - _temp_al_encender < 0.2
	V[64] = 1.0 if sin_efecto else 0.0
	V[63] = 3.0 if fallo else (1.0 if alta else (2.0 if baja else (5.0 if sin_efecto else (4.0 if V[62] == 1.0 else 0.0))))
	# Reloj
	V[2] = hora()
	V[3] = minuto()
	V[4] = segundo()
	salida += _virtuino_run()
	# Bomba y luces
	var seg := int(segundos_del_dia)
	rele_bomba = (V[15] == 1.0) if V[29] == 1.0 else en_horario(seg, aj.bomba_on, aj.bomba_off)
	V[8] = 1.0 if rele_bomba else 0.0
	if _escrito(12):
		var n := roundi(V[12])
		if n >= 0 and n <= 255:
			_intensidad_actual = n
		_publicar(12, _intensidad_actual)
	if V[13] == 1.0:
		_volver_a_referencia()
		V[13] = 0.0
	var en_h := en_horario(seg, aj.luz_on, aj.luz_off)
	if en_h and not _estaba_en_horario and not _primera_vez_luces:
		_volver_a_referencia()
	_estaba_en_horario = en_h
	_primera_vez_luces = false
	luz_pwm = _intensidad_actual if V[16] == 1.0 else nivel_luz(seg, aj.luz_on, aj.luz_off, aj.rampa, _intensidad_actual)
	V[11] = luz_pwm
	# Diagnóstico
	if rele_calentador:
		_ms_calentador_hoy += delta_s * 1000.0
	if luz_pwm > 0:
		_ms_luz_hoy += delta_s * 1000.0
	if rele_bomba:
		_ms_bomba_hoy += delta_s * 1000.0
	V[73] = floorf(_ms_calentador_hoy / 60000.0)
	V[90] = _encendidos_hoy
	V[91] = floorf(_ms_luz_hoy / 60000.0)
	V[92] = floorf(_ms_bomba_hoy / 60000.0)
	V[74] = 5480
	V[75] = floorf(millis_sim / 60000.0)
	return salida
