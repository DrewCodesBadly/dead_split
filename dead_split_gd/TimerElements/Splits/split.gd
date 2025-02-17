extends PanelContainer

@export var name_label: Label
@export var comparisons: HBoxContainer
@export var inactive_box: StyleBox
@export var active_box: StyleBox

func set_split_name(n: String) -> void:
	name_label.text = n

func add_comparison() -> void:
	var comp_label := Label.new()
	comparisons.add_child(comp_label)

func start() -> void:
	update(true)
	add_theme_stylebox_override("panel", active_box)
	grab_focus()

func finish() -> void:
	update(true)
	add_theme_stylebox_override("panel", inactive_box)

func update(active: bool) -> void:
	for comp_idx in comparisons.get_children().size():
		var idx := get_index()
		var label := comparisons.get_child(comp_idx)
		
		match TimerSettings.active_comp_types[comp_idx]:
			TimerSettings.ComparisonType.COMPARISON_TYPE_NONE:
				label.text = "-"
			
			TimerSettings.ComparisonType.COMPARISON_TYPE_TIME:
				var t := MainTimer.get_segment_comparison(idx, TimerSettings.active_comparisons[comp_idx], TimerSettings.rta)
				if t != 0.0:
					label.text = TimerSettings.round_off(t)
				else:
					label.text = "-"
			
			TimerSettings.ComparisonType.COMPARISON_TYPE_SEGMENT_DELTA:
				var t := MainTimer.get_segment_comparison(idx, TimerSettings.active_comparisons[comp_idx], TimerSettings.rta)
				if t != 0.0 and active:
					var delta := (MainTimer.current_time if TimerSettings.rta else MainTimer.current_game_time) - t
					label.text = ("+" if delta > 0 else "") + TimerSettings.round_off(delta)
				else:
					label.text = ""
			
			TimerSettings.ComparisonType.COMPARISON_TYPE_DELTA:
				var t := MainTimer.get_segment_comparison(idx, TimerSettings.active_comparisons[comp_idx], TimerSettings.rta)
				if t != 0.0 and active:
					var delta := (MainTimer.current_time if TimerSettings.rta else MainTimer.current_game_time) - t
					label.text = ("+" if delta > 0 else "") + TimerSettings.round_off(delta)
				else:
					label.text = ""

func reset() -> void:
	for comp_idx in comparisons.get_children().size():
		var idx := get_index()
		var label := comparisons.get_child(comp_idx)
		
		match TimerSettings.active_comp_types[comp_idx]:
			TimerSettings.ComparisonType.COMPARISON_TYPE_NONE:
				label.text = "-"
			TimerSettings.ComparisonType.COMPARISON_TYPE_TIME:
				var t := MainTimer.get_segment_comparison(idx, TimerSettings.active_comparisons[comp_idx], TimerSettings.rta)
				if t != 0.0:
					label.text = TimerSettings.round_off(t)
				else:
					label.text = "-"
			TimerSettings.ComparisonType.COMPARISON_TYPE_DELTA:
				label.text = ""
			TimerSettings.ComparisonType.COMPARISON_TYPE_SEGMENT_DELTA:
				label.text = ""
