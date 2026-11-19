class_name Perfiles
extends RefCounted
## Perfiles de teléfono: tamaño en píxeles reales, densidad (px por dp) y márgenes del sistema.

const RUTA := "res://data/perfiles_moviles.json"


static func cargar_todos() -> Array:
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		return []
	var datos = JSON.parse_string(f.get_as_text())
	if datos is Dictionary and datos.get("perfiles") is Array:
		return datos.perfiles
	return []


static func buscar(id: String) -> Dictionary:
	for p in cargar_todos():
		if p.get("id") == id:
			return p
	return {}


## Tamaño de la pantalla en dp: px / densidad.
static func tamano_dp(perfil: Dictionary) -> Vector2:
	var px: Array = perfil.get("pantalla_px", [1080, 2340])
	var d: float = perfil.get("densidad", 1.0)
	return Vector2(px[0] / d, px[1] / d)


## Mide el dispositivo en el que se ejecuta Acuaris y devuelve un perfil.
static func medir_este_dispositivo() -> Dictionary:
	var pantalla := DisplayServer.window_get_current_screen()
	var tam := DisplayServer.screen_get_size(pantalla)
	var dpi := DisplayServer.screen_get_dpi(pantalla)
	var escala := DisplayServer.screen_get_scale(pantalla)
	var seguro := DisplayServer.get_display_safe_area()
	var ventana := DisplayServer.window_get_size()
	var es_movil := OS.has_feature("mobile")
	var densidad := float(dpi) / 160.0 if es_movil else escala
	var perfil := {
		"id": "medido_%s" % OS.get_model_name().to_snake_case().replace(" ", "_"),
		"nombre": "%s (medido)" % OS.get_model_name(),
		"pantalla_px": [tam.x, tam.y],
		"densidad": snappedf(densidad, 0.0001),
		"densidad_verificado": es_movil,
		"dpi_sistema": dpi,
		"escala_sistema": escala,
		"ventana_px": [ventana.x, ventana.y],
		"zona_segura_px": [seguro.position.x, seguro.position.y, seguro.size.x, seguro.size.y],
		"margen_superior_dp": roundi(seguro.position.y / densidad) if densidad > 0 else 0,
		"margen_inferior_dp": roundi((tam.y - seguro.end.y) / densidad) if densidad > 0 else 0,
		"margenes_verificado": es_movil,
		"sistema": "%s %s" % [OS.get_name(), OS.get_version()],
	}
	return perfil
