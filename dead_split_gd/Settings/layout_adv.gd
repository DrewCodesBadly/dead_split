extends ScrollContainer

@export var chooser: FileDialog
@export var load_theme_button: Button
@export var path_label: Label

func _on_visibility_changed() -> void:
	if visible:
		update_label()

func _on_load_theme_pressed() -> void:
	chooser.show()
	load_theme_button.disabled = true


func _on_resource_chooser_file_selected(path: String) -> void:
	load_theme_button.disabled = false
	TimerSettings.timer_theme_path = path
	get_window().timer_window.reload_theme()
	update_label()


func _on_resource_chooser_canceled() -> void:
	load_theme_button.disabled = false


func update_label() -> void:
	if TimerSettings.timer_theme_path != "":
		path_label.text = "Current theme file: " + TimerSettings.timer_theme_path
	else:
		path_label.text = "No theme file selected."


func _on_reset_default_pressed() -> void:
	TimerSettings.timer_theme_path = ""
	get_window().timer_window.reload_theme()
	update_label()
