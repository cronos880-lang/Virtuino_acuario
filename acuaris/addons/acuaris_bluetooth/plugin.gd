@tool
extends EditorPlugin
## Añade la librería Android (AAR) del complemento Bluetooth al exportar a Android.

var _exportador: ExportadorAndroid


func _enter_tree() -> void:
	_exportador = ExportadorAndroid.new()
	add_export_plugin(_exportador)


func _exit_tree() -> void:
	remove_export_plugin(_exportador)
	_exportador = null


class ExportadorAndroid extends EditorExportPlugin:
	const AAR := "acuaris_bluetooth/bin/AcuarisBluetooth-release.aar"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([AAR])

	func _get_name() -> String:
		return "AcuarisBluetooth"
