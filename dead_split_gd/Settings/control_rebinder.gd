extends SplitContainer

@export var button: Button
@onready var hotkeys: ScrollContainer = $"../.."

var waiting_new_key := false

func set_button_text(t: String) -> void:
	button.text = t


func _on_button_pressed() -> void:
	waiting_new_key = true
	button.disabled = true
	button.text = "Waiting..."

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and waiting_new_key:
		waiting_new_key = false
		var idx := get_index()
		MainTimer.add_hotkey(event.as_text_keycode(), idx) # could throw error w/bool here
		
		button.text = hotkeys.get_key_string(idx)
		button.disabled = false
