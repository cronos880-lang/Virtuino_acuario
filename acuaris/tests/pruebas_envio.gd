extends RefCounted
## Pruebas del envío PC -> app por la red (en 127.0.0.1, puertos de prueba).

var t
var recibidos: Array = []


func _init(ejecutor) -> void:
	t = ejecutor


func _esperar(srv: ServidorEnvio, rec: ReceptorEnvio, cond: Callable, max_ms := 3000) -> bool:
	var fin := Time.get_ticks_msec() + max_ms
	while Time.get_ticks_msec() < fin:
		srv.sondear()
		rec.sondear()
		if cond.call():
			return true
		OS.delay_msec(5)
	return false


func ejecutar() -> void:
	var datos1: Dictionary = Proyecto.desde_archivo("res://proyectos/acuario.acuaris.json").datos
	var datos2 := datos1.duplicate(true)
	datos2["nombre"] = "Acuario modificado"
	var srv := ServidorEnvio.new()
	srv.archivo = "user://prueba_emparejados.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(srv.archivo))
	t.comprobar(srv.iniciar(47900, 47901) == "", "envío: el editor abre los puertos")
	t.comprobar(srv.codigo.length() == 6, "envío: código de 6 cifras")
	srv.publicar(datos1)
	var rec := ReceptorEnvio.new()
	rec.archivo = "user://prueba_receptor.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(rec.archivo))
	rec._ready()
	rec.proyecto_recibido.connect(func(d, r): recibidos.append([d, r]))
	# Búsqueda
	rec.buscar(["127.0.0.1"], 47901)
	t.comprobar(_esperar(srv, rec, func(): return rec.pcs.size() > 0), "envío: la app encuentra el editor")
	var pc: Dictionary = rec.pcs[0] if rec.pcs.size() > 0 else {"ip": "127.0.0.1", "puerto": 47900}
	t.comprobar(int(pc.get("puerto", 0)) == 47900, "envío: el editor anuncia su puerto")
	# Sin código y sin emparejar: lo pide
	rec.conectar(pc)
	t.comprobar(rec.estado == "necesita_codigo", "envío: pide código la primera vez")
	# Código incorrecto
	var malo := "000000" if srv.codigo != "000000" else "111111"
	rec.conectar(pc, malo)
	t.comprobar(_esperar(srv, rec, func(): return rec.estado == "necesita_codigo"), "envío: código incorrecto rechazado")
	t.comprobar(recibidos.is_empty(), "envío: nada recibido sin emparejar")
	# Código correcto
	rec.conectar(pc, srv.codigo)
	t.comprobar(_esperar(srv, rec, func(): return recibidos.size() == 1), "envío: interfaz recibida tras el código")
	t.comprobar(recibidos.size() > 0 and recibidos[0][0].get("nombre") == "Acuario", "envío: contenido correcto")
	t.comprobar(rec.conectado(), "envío: conexión activa")
	# Cambio en vivo
	srv.publicar(datos2)
	t.comprobar(_esperar(srv, rec, func(): return recibidos.size() == 2), "envío: cambio en vivo recibido")
	t.comprobar(_esperar(srv, rec, func(): return srv.clientes().size() == 1 and srv.clientes()[0].revision == 2), "envío: el editor sabe qué versión tiene el móvil")
	# Reconexión ya emparejado, sin código
	rec.desconectar()
	rec.conectar(pc)
	t.comprobar(rec.estado == "conectando", "envío: emparejado no pide código")
	t.comprobar(_esperar(srv, rec, func(): return recibidos.size() == 3), "envío: reconecta y recibe la última versión")
	# Bloqueo
	rec.fijar_bloqueado(true)
	srv.publicar(datos1)
	t.comprobar(_esperar(srv, rec, func(): return srv.clientes().size() == 1 and srv.clientes()[0].rechazado), "envío: app bloqueada rechaza cambios")
	t.comprobar(recibidos.size() == 3, "envío: bloqueada no aplica cambios")
	rec.fijar_bloqueado(false)
	# El PC olvida los dispositivos: el token deja de valer
	srv.olvidar_emparejados()
	rec.desconectar()
	rec.conectar(pc)
	t.comprobar(_esperar(srv, rec, func(): return rec.estado == "necesita_codigo"), "envío: tras olvidar, vuelve a pedir código")
	rec.desconectar()
	srv.detener()
	rec.free()
	srv.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://prueba_emparejados.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://prueba_receptor.cfg"))
