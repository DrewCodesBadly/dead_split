extends ScrollContainer

@export var load_button: Button
@export var autosplit_picker: FileDialog

func _on_load_button_pressed() -> void:
	load_button.disabled = true
	load_button.text = "Waiting..."
	autosplit_picker.show()

func _on_autosplit_picker_file_selected(path: String) -> void:
	TimerSettings.autosplitter_path = path

func _on_autosplit_picker_canceled() -> void:
	load_button.disabled = false
	load_button.text = "Open..."
