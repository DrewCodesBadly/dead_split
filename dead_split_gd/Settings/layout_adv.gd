extends ScrollContainer

@export var chooser: FileDialog

var setting: String = ""

func _on_resource_chooser_file_selected(path: String) -> void:
	TimerSettings.set(setting, path)
	update_labels()

func _on_visibility_changed() -> void:
	if visible:
		update_labels()

func update_labels() -> void:
	pass

func _on_timer_theme_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "timer_theme_path"

func _on_timer_stopped_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "timer_stopped_label_path"

func _on_timer_running_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "timer_running_label_path"

func _on_timer_finished_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "timer_finished_label_path"

func _on_timer_finished_pb_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "timer_finished_pb_label_path"

func _on_split_ahead_gaining_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "split_ahead_gaining_label_path"

func _on_split_ahead_losing_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "split_ahead_losing_label_path"

func _on_split_behind_gaining_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "split_behind_gaining_label_path"

func _on_split_behind_losing_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "split_behind_losing_label_path"

func _on_timer_bg_style_box_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "timer_background_stylebox_path"

func _on_active_split_style_box_btn_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "active_split_bg_stylebox_path"

func _on_inactive_split_style_box_btn_2_pressed() -> void:
	if !chooser.visible:
		chooser.show()
		setting = "inactive_split_bg_stylebox_path"
