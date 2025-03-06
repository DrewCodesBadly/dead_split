extends Button

@export var file_chooser: FileDialog
@export var file_label: Label
@export var run_saved_label: Label
@export var save_failed_label: Label
@export var window: Window

func _ready() -> void:
	file_label.text = "Current Splits File: " + TimerSettings.current_file_path
	run_saved_label.hide()
	save_failed_label.hide()

func _on_pressed() -> void:
	disabled = true
	text = "Waiting..."
	file_chooser.show()


func _on_run_file_chooser_file_selected(path: String) -> void:
	TimerSettings.current_file_path = path
	file_label.text = "Current Splits File: " + path
	disabled = false
	text = "Open"
	MainTimer.try_load_run(TimerSettings.current_file_path)

func _on_save_run_to_file_pressed() -> void:
	var success := MainTimer.try_save_run(TimerSettings.current_file_path)
	run_saved_label.text = "Run saved!" if success else "Failed to save run - check your path is valid"
	run_saved_label.show()

func _on_run_file_chooser_canceled() -> void:
	disabled = false
	text = "Open"
