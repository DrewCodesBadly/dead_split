extends DeadSplitTimer

@warning_ignore("unused_signal")
signal run_changed
signal comparison_changed

var autosplitter: Autosplitter = null

func _ready() -> void:
	new_run()
	self.hotkey_pressed.connect(_hotkey_pressed)

func _hotkey_pressed(hotkey_id: int) -> void:
	match hotkey_id:
		0:
			start_split()
		1:
			reset()
		2:
			skip_split()
		3:
			undo_split()
		4:
			pause()
		5:
			resume()
		6:
			undo_all_pauses()
		7:
			toggle_pause()
		8:
			toggle_timing_method()
		9:
			var comp_list := get_comparisons()
			TimerSettings.active_comp_idx = (TimerSettings.active_comp_idx + 1) % comp_list.size()
			var comp := comp_list[TimerSettings.active_comp_idx]
			TimerSettings.active_comparison = comp
			comparison_changed.emit(comp)
		10:
			var comp_list := get_comparisons()
			TimerSettings.active_comp_idx = (TimerSettings.active_comp_idx - 1) % comp_list.size()
			var comp := comp_list[TimerSettings.active_comp_idx]
			TimerSettings.active_comparison = comp
			comparison_changed.emit(comp)

func update_autosplitter() -> void:
	if autosplitter:
		autosplitter.update()
