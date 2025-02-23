extends ScrollContainer

@export var no_dir_label: Label
@export var file_list: ItemList
@export var window: Window

func _on_item_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	TimerSettings.timer_theme_path = TimerSettings.working_directory_path + "/" + file_list.get_item_text(index)
	window.timer_window.reload_theme()
	window._on_close_requested()

func _on_visibility_changed() -> void:
	if visible:
		no_dir_label.hide()
		file_list.hide()
		
		var dir = DirAccess.open(TimerSettings.working_directory_path)
		if dir == null or TimerSettings.working_directory_path == "":
			no_dir_label.show()
			return
		
		file_list.show()
		file_list.clear()
		for file in dir.get_files():
			if file.ends_with(".zip"):
				file_list.add_item(file)
