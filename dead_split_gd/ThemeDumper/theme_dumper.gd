extends FileDialog

func _ready() -> void:
	canceled.connect(get_tree().quit)
	TimerSettings.reload_theme()
	var path: String = await file_selected
	var attempt = ResourceSaver.save(TimerSettings.theme, path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
	if attempt != OK:
		printerr(error_string(attempt))
	await get_tree().create_timer(0.1).timeout # just in case, give error time to print
	get_tree().quit()
