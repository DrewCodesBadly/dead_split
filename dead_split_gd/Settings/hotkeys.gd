extends ScrollContainer

@export var window: Window
@export var hotkeys_container: VBoxContainer

func _on_visibility_changed() -> void:
	if visible:
		for i in hotkeys_container.get_children().size():
			hotkeys_container.get_child(i).set_button_text(get_key_string(i))

func get_key_string(idx: int) -> String:
	return MainTimer.get_hotkey_string(idx)
