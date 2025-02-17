extends Button

@export var dir_chooser: FileDialog
@export var dir_label: Label
@export var no_dir_warning: Label
@export var dir_changed_warning: Label

func _ready() -> void:
	dir_label.text = "DeadSplit directory: " + TimerSettings.working_directory_path
	if TimerSettings.working_directory_path == "":
		no_dir_warning.show()

func _on_pressed() -> void:
	disabled = true
	text = "Waiting..."
	dir_chooser.show()

func _on_directory_chooser_dir_selected(dir: String) -> void:
	TimerSettings.working_directory_path = dir
	dir_label.text = "DeadSplit directory: " + dir
	disabled = false
	text = "Change"
	no_dir_warning.hide()
	dir_changed_warning.show()

func _on_directory_chooser_canceled() -> void:
	text = "Change"
	disabled = false
