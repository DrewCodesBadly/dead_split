extends ScrollContainer

@export var title_check_box: CheckBox
@export var attempt_count_check_box: CheckBox
@export var finished_runs_check_box: CheckBox
@export var show_splits_check_box: CheckBox
@export var one_line_check_box: CheckBox
@export var pin_last_check_box: CheckBox
@export var shown_splits_num: SpinBox
@export var upcoming_splits_num: SpinBox
@export var window_x_num: SpinBox
@export var window_y_num: SpinBox
@export var decimals_shown: SpinBox
@export var split_min_size: SpinBox

func _on_visibility_changed() -> void:
	if visible:
		title_check_box.button_pressed = TimerSettings.show_title
		attempt_count_check_box.button_pressed = TimerSettings.show_attempt_count
		finished_runs_check_box.button_pressed = TimerSettings.show_finished_runs
		show_splits_check_box.button_pressed = TimerSettings.show_splits
		one_line_check_box.button_pressed = TimerSettings.title_one_line
		pin_last_check_box.button_pressed = TimerSettings.last_split_pinned
		window_x_num.value = TimerSettings.window_size.x
		window_y_num.value = TimerSettings.window_size.y
		upcoming_splits_num.value = TimerSettings.shown_upcoming_splits
		shown_splits_num.value = TimerSettings.shown_splits
		decimals_shown.value = TimerSettings.time_rounding
		split_min_size.value = TimerSettings.split_time_min_size

func _on_title_check_box_toggled(toggled_on: bool) -> void:
	TimerSettings.show_title = toggled_on

func _on_attempt_count_check_box_toggled(toggled_on: bool) -> void:
	TimerSettings.show_attempt_count = toggled_on

func _on_finished_runs_check_box_toggled(toggled_on: bool) -> void:
	TimerSettings.show_finished_runs = toggled_on

func _on_show_splits_check_box_toggled(toggled_on: bool) -> void:
	TimerSettings.show_splits = toggled_on

func _on_last_pinned_check_box_toggled(toggled_on: bool) -> void:
	TimerSettings.last_split_pinned = toggled_on

func _on_shown_splits_num_value_changed(value: float) -> void:
	TimerSettings.shown_splits = floori(value)

func _on_upcoming_splits_num_value_changed(value: float) -> void:
	TimerSettings.shown_upcoming_splits = floori(value)

func _on_one_line_check_box_toggled(toggled_on: bool) -> void:
	TimerSettings.title_one_line = toggled_on

func _on_win_size_x_value_changed(value: float) -> void:
	TimerSettings.window_size.x = floori(value)
	DisplayServer.window_set_size(TimerSettings.window_size, 0)

func _on_win_size_y_value_changed(value: float) -> void:
	TimerSettings.window_size.y = floori(value)
	DisplayServer.window_set_size(TimerSettings.window_size, 0)

func _on_decimal_prec_value_changed(value: float) -> void:
	TimerSettings.time_rounding = floori(value)

func _on_split_min_size_value_changed(value: float) -> void:
	TimerSettings.split_time_min_size = floori(value)
