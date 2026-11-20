extends SceneTree
## Pruebas automáticas sin pantalla:
##   godot --headless --path acuaris -s res://tests/ejecutar_pruebas.gd
## Sale con código 0 si todo pasa y 1 si algo falla.

var _ok := 0
var _fallos: Array[String] = []


func comprobar(cond: bool, nombre: String) -> void:
	if cond:
		_ok += 1
	else:
		_fallos.append(nombre)
		printerr("FALLO: ", nombre)


func _initialize() -> void:
	prueba_protocolo()
	prueba_simulador_respuestas()
	prueba_simulador_logica()
	prueba_proyecto()
	prueba_perfiles()
	prueba_comunicador()
	load("res://tests/pruebas_editor.gd").new(self).ejecutar()
	load("res://tests/pruebas_envio.gd").new(self).ejecutar()
	load("res://tests/pruebas_elementos.gd").new(self).ejecutar()
	# Prueba de la aplicación completa: se termina en _process tras unos fotogramas.
	_app = load("res://ui/principal.tscn").instantiate()
	root.add_child(_app)
	_t_inicio = Time.get_ticks_msec()


var _app: Node = null
var _t_inicio := 0
var _fase := 0
var _editor: Node = null
var _srv: ServidorEnvio = null
var _enlace_antes: Object = null


func _process(_delta: float) -> bool:
	var t := Time.get_ticks_msec() - _t_inicio
	if _fase == 0 and t > 300:
		# Cambiar de conexión: la nueva debe sobrevivir al redibujado de la pantalla.
		_app.conectar_simulador()
		_fase = 1
		_t_inicio = Time.get_ticks_msec()
		return false
	if _fase == 1 and t > 3000:
		# El editor también debe cargar sin errores.
		_editor = load("res://ui/editor/editor.tscn").instantiate()
		root.add_child(_editor)
		_fase = 3
		return false
	if _fase == 3:
		_fase = 4
		return false
	if _fase == 4 and _srv == null:
		# Extremo a extremo: el editor envía una interfaz y la app la aplica sin perder la conexión.
		_srv = ServidorEnvio.new()
		_srv.archivo = "user://prueba_e2e_emparejados.cfg"
		root.add_child(_srv)
		_srv.iniciar(47910, 47911)
		var d: Dictionary = Proyecto.desde_archivo("res://proyectos/acuario.acuaris.json").datos.duplicate(true)
		d["nombre"] = "Prueba envío"
		_srv.publicar(d)
		_app.receptor.archivo = "user://prueba_e2e_receptor.cfg"
		_app.receptor._ready()
		_app.receptor.conectar({"pc": "PC-PRUEBA", "ip": "127.0.0.1", "puerto": 47910}, _srv.codigo)
		_enlace_antes = _app.enlace
		_t_inicio = Time.get_ticks_msec()
		return false
	if _fase == 4 and _srv != null and _app.proyecto.nombre() != "Prueba envío" and t < 4000:
		return false
	if _fase == 4:
		comprobar(_app.proyecto.nombre() == "Prueba envío", "e2e: la app aplica la interfaz enviada por el editor")
		comprobar(is_instance_valid(_enlace_antes) and _app.enlace == _enlace_antes and _app.enlace.esta_conectado(), "e2e: la conexión con el controlador no se corta")
		comprobar(FileAccess.file_exists(_app.PROYECTO_RECIBIDO), "e2e: la interfaz recibida se guarda en la app")
		_app.volver_a_original()
		comprobar(_app.proyecto.nombre() == "Acuario" and not FileAccess.file_exists(_app.PROYECTO_RECIBIDO), "e2e: volver a la interfaz original")
		_srv.detener()
		for f in ["user://prueba_e2e_emparejados.cfg", "user://prueba_e2e_receptor.cfg"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
		comprobar(_editor.modelo.paginas().size() == 1 and _editor.modelo.widgets().size() > 10, "app editor: abre el acuario")
		comprobar(_editor.lienzo.zoom >= 0.1 and _editor.lienzo.modelo != null, "app editor: lienzo preparado")
		comprobar(is_instance_valid(_app.enlace), "app: la conexión sobrevive al redibujado")
		comprobar(is_instance_valid(_app.enlace) and _app.enlace.esta_conectado(), "app: conexión activa")
		comprobar(_app.comunicador.valores.has("V35"), "app: llegan valores a la pantalla")
		comprobar(_app.comunicador.respuestas > 3, "app: el sondeo funciona")
		print("Pruebas superadas: %d  ·  fallos: %d" % [_ok, _fallos.size()])
		quit(0 if _fallos.is_empty() else 1)
		_fase = 2
	return false


func prueba_protocolo() -> void:
	comprobar(ProtocoloVCM.peticion_lectura("V", 5) == "!V05=?$", "lectura con dos cifras")
	comprobar(ProtocoloVCM.peticion_lectura("V", 35) == "!V35=?$", "lectura V35")
	comprobar(ProtocoloVCM.peticion_escritura("V", 15, 1.0) == "!V15=1$", "escritura entera")
	comprobar(ProtocoloVCM.peticion_escritura("V", 27, 25.5) == "!V27=25.5$", "escritura decimal")
	comprobar(ProtocoloVCM.separar_pin("v35") == {"tipo": "V", "pin": 35}, "separar pin")
	comprobar(ProtocoloVCM.separar_pin("X1").is_empty(), "pin no válido")
	comprobar(ProtocoloVCM.separar_pin("V256").is_empty(), "pin fuera de rango")
	var r := ProtocoloVCM.analizar("!V5=25.31$!V8=1.00$!V3")
	comprobar(r.mensajes.size() == 2, "dos mensajes")
	comprobar(r.mensajes[0].pin == 5 and is_equal_approx(r.mensajes[0].valor, 25.31), "valor V5")
	comprobar(r.resto == "!V3", "resto incompleto conservado")
	r = ProtocoloVCM.analizar(r.resto + "=12.00$")
	comprobar(r.mensajes.size() == 1 and r.mensajes[0].pin == 3, "mensaje recompuesto")
	r = ProtocoloVCM.analizar("basura!V2=1.00$E00=7$")
	comprobar(r.mensajes.size() == 1 and r.errores == ["E00=7"], "basura y error")
	r = ProtocoloVCM.analizar("!C=VirtuinoCM 1.0.02")
	comprobar(r.saludo == "VirtuinoCM 1.0.02", "saludo")
	r = ProtocoloVCM.analizar("!V1=2.0!V4=5.00$")
	comprobar(r.mensajes.size() == 1 and r.mensajes[0].pin == 4, "mensaje cortado descartado")


func prueba_simulador_respuestas() -> void:
	var sim := SimuladorArduino.new()
	sim.V[35] = 25.3125
	comprobar(sim.obtener_respuesta("!V35=?$") == "!V35=25.31$", "respuesta como String(float)")
	comprobar(sim.obtener_respuesta("!V05=?$") == "!V5=0.00$", "pin sin ceros en la respuesta")
	comprobar(sim.obtener_respuesta("!V5=?$") == "", "comando corto ignorado como en VirtuinoCM")
	comprobar(sim.obtener_respuesta("!V15=1$") == "", "escritura sin respuesta")
	comprobar(sim.V[15] == 1.0, "escritura aplicada")
	comprobar(sim.obtener_respuesta("sin inicio") == "E00=7$", "error sin '!'")
	comprobar(sim.obtener_respuesta(ProtocoloVCM.peticion_saludo()) == "!C=VirtuinoCM 1.0.02", "saludo")
	comprobar(sim.obtener_respuesta("!V300=?$") == "", "pin fuera de memoria sin respuesta")
	# Un comando por pasada del loop
	sim.recibir("!V02=?$!V03=?$")
	var primera := sim._virtuino_run()
	var segunda := sim._virtuino_run()
	comprobar(primera.begins_with("!V2=") and segunda.begins_with("!V3="), "un comando por pasada")


func prueba_simulador_logica() -> void:
	var sim := SimuladorArduino.new()
	sim.fijar_hora(16, 7)
	sim.avanzar(0.2)
	comprobar(sim.V[8] == 1.0, "bomba en marcha a las 16:07")
	comprobar(sim.luz_pwm == SimuladorArduino._map(7, 0, 14, 0, 125), "rampa de amanecer")
	comprobar(sim.V[10] == 125.0, "V10 = lumen")
	sim.fijar_hora(23, 0)
	sim.avanzar(0.2)
	comprobar(sim.V[8] == 0.0 and sim.luz_pwm == 0, "noche: bomba y luces apagadas")
	sim.V[29] = 1.0
	sim.V[15] = 1.0
	sim.V[16] = 1.0
	sim.avanzar(0.2)
	comprobar(sim.V[8] == 1.0 and sim.luz_pwm == 125, "modo manual")
	comprobar(sim.V[2] == 23.0, "V2 = hora")
	# Termostato: agua fría -> enciende tras los 3 min de protección del relé
	sim.temperatura_agua = 23.0
	sim.temperatura_ambiente = 23.0
	for i in 50:
		sim.avanzar(1.0)
	comprobar(sim.V[6] == 0.0, "relé protegido los primeros 3 min")
	for i in 200:
		sim.avanzar(1.0)
	comprobar(sim.V[6] == 1.0 and sim.V[7] == 0.0, "calentador encendido por debajo de consigna")
	sim.temperatura_agua = 26.0
	for i in 200:
		sim.avanzar(1.0)
	comprobar(sim.V[6] == 0.0, "calentador apagado por encima de consigna + histéresis")


func prueba_proyecto() -> void:
	var p := Proyecto.desde_archivo("res://proyectos/acuario.acuaris.json")
	comprobar(p.errores.is_empty(), "proyecto de ejemplo válido " + str(p.errores))
	var pines := p.todos_los_pines()
	for esperado in ["V35", "V27", "V6", "V8", "V29", "V15", "V16", "V10", "V2", "V3", "V4"]:
		comprobar(pines.has(esperado), "pin usado " + esperado)
	var malo := Proyecto.new()
	comprobar(not malo.cargar_texto('{"formato":"acuaris-proyecto","version":1,"paginas":[{"widgets":[{"id":"a","tipo":"nave","x":0,"y":0,"w":1,"h":1,"pin":"Z9"}]}]}'), "proyecto inválido detectado")
	comprobar(malo.errores.size() == 2, "dos errores (tipo y pin)")


func prueba_perfiles() -> void:
	var a56 := Perfiles.buscar("samsung_galaxy_a56")
	var px: Array = a56.get("pantalla_px", [])
	comprobar(px.size() == 2 and int(px[0]) == 1080 and int(px[1]) == 2340, "A56 1080x2340")
	var dp := Perfiles.tamano_dp(a56)
	comprobar(is_equal_approx(dp.x, 384.0) and is_equal_approx(dp.y, 832.0), "A56 384x832 dp con densidad estimada")


func prueba_comunicador() -> void:
	var enlace := EnlaceSimulado.new()
	enlace.simulador.fijar_hora(16, 30)
	var com := Comunicador.new()
	root.add_child(enlace)
	root.add_child(com)
	enlace.set_process(false)
	com.set_process(false)
	com.fijar_enlace(enlace)
	com.fijar_pines(["V35", "V8", "V02", "V27"])
	enlace.conectar()
	var t := 0
	for i in 60:
		t += 100
		enlace.paso(0.1)
		com.tick(t)
	comprobar(com.valores.has("V8") and com.valores.V8 == 1.0, "comunicador lee V8")
	comprobar(com.valores.has("V2") and com.valores.V2 == 16.0, "comunicador lee V2 (pedido como V02)")
	comprobar(com.valores.has("V27") and com.valores.V27 == 25.0, "comunicador lee consigna")
	comprobar(com.sin_respuesta == 0, "sin peticiones perdidas")
	com.escribir("V29", 1.0)
	com.escribir("V15", 0.0)
	for i in 30:
		t += 100
		enlace.paso(0.1)
		com.tick(t)
	comprobar(enlace.simulador.V[29] == 1.0, "escritura llega al Arduino")
	comprobar(com.valores.V8 == 0.0, "bomba parada en manual tras escribir")
	enlace.free()
	com.free()
