extends Window

@export var submenus: Control
@export var menus_container: Control
@export var outer_toggle: Control
@export var menu_toggle: Control
@export var quit_index: int
@export var igt_toggle: CheckButton

var timer_window: Control
var current_menu: Control

func _ready() -> void:
	# so editor changes don't make it into runtime
	outer_toggle.show()
	menu_toggle.hide()
	
	for child in menus_container.get_children():
		child.hide()

func _on_close_requested() -> void:
	# Save settings!
	TimerSettings.reload_theme()
	TimerSettings.save()
	timer_window.update_settings()
	timer_window.settings_open = false
	MainTimer.run_changed.emit() # just assume run updated, it's easier than actually checking
	
	if TimerSettings.autosplitter_path != "" and TimerSettings.autosplitter_path.is_absolute_path():
		MainTimer.unload_autosplitter()
		print(MainTimer.load_autosplitter(TimerSettings.autosplitter_path))
		MainTimer.init_game_time()
	
	queue_free()

func _on_submenus_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if index == quit_index:
		get_tree().quit(0)
	else:
		# Show menu at that index
		outer_toggle.hide()
		if current_menu: current_menu.hide()
		
		menu_toggle.show()
		current_menu = menus_container.get_child(index)
		current_menu.show()

func _on_back_button_pressed() -> void:
	menu_toggle.hide()
	outer_toggle.show()

func _on_save_button_pressed() -> void:
	pass # Replace with function body.

func _on_use_igt_toggle_toggled(toggled_on: bool) -> void:
	TimerSettings.rta = !toggled_on


func _on_use_igt_toggle_visibility_changed() -> void:
	if igt_toggle.visible:
		igt_toggle.button_pressed = !TimerSettings.rta
