extends ScrollContainer

@export var no_dir_label: Label
@export var file_list: ItemList
@export var window: Window
@export var file_ending: String

func _on_item_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if file_list.get_item_metadata(index):
		TimerSettings.autosplitter_path = "res://Autosplitters/" + file_list.get_item_text(index)
	else:
		TimerSettings.autosplitter_path = TimerSettings.working_directory_path + "/" + file_list.get_item_text(index)
	window._on_close_requested()

func _on_visibility_changed() -> void:
	if visible:
		no_dir_label.hide()
		
		file_list.show()
		file_list.clear()
		
		var default_dir = DirAccess.open("res://Autosplitters")
		for file in default_dir.get_files():
			print("adding mayb")
			if file.ends_with(file_ending):
				print("adding")
				file_list.add_item(file)
				file_list.set_item_metadata(file_list.item_count - 1, true)
		
		var dir = DirAccess.open(TimerSettings.working_directory_path)
		if dir == null or TimerSettings.working_directory_path == "":
			no_dir_label.show()
		
		for file in dir.get_files():
			if file.ends_with(file_ending):
				file_list.add_item(file)
				file_list.set_item_metadata(file_list.item_count - 1, false)
