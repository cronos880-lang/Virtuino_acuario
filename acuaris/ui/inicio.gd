extends Node
## Arranque: en el móvil o tablet abre la app; en el PC abre el editor.
## En el PC, "-- --app" abre la app en lugar del editor.

func _ready() -> void:
	var app := OS.has_feature("mobile") or "--app" in OS.get_cmdline_user_args()
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	get_window().title = "Acuaris V%s %s · EXPERIMENTAL" % [version, "App" if app else "Editor"]
	if not app:
		var pantalla := DisplayServer.screen_get_usable_rect()
		var tam := Vector2i(mini(1680, pantalla.size.x - 40), mini(1000, pantalla.size.y - 60))
		get_window().size = tam
		get_window().position = pantalla.position + (pantalla.size - tam) / 2
		get_window().min_size = Vector2i(1100, 680)
	get_tree().change_scene_to_file.call_deferred("res://ui/principal.tscn" if app else "res://ui/editor/editor.tscn")
