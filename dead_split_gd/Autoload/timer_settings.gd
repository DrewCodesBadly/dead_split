extends Node

enum ComparisonType {
	COMPARISON_TYPE_NONE,
	COMPARISON_TYPE_TIME,
	COMPARISON_TYPE_DELTA
}

enum TimerPhase {
	NOT_RUNNING,
	RUNNING,
	ENDED,
	PAUSED
}

var rta := true
var time_rounding := 0.01

var active_comparison: String = "Personal Best"
var active_comp_idx: int = 0

var working_directory_path: String = ""
var current_file_path: String = "None"

var timer_theme_path: String = ""
var theme: TimerTheme = null

func round_off(val: float) -> String:
	var out_string := ""
	if val > 3600.0:
		out_string += str(floori(val / 3600)) + ":"
		if fmod(val, 3600) < 600.0:
			out_string += "0"
	if val > 60.0:
		out_string += str(floori(val / 60) % 60) + ":"
		if fmod(val, 60.0) < 10.0:
			out_string += "0"
	
	out_string += str(snapped(fmod(val, 60.0), time_rounding))
	if fmod(val, 1.0) < 0.1:
		out_string += "0"
	
	return out_string

func round_off_no_decimal(val: float) -> String:
	var out_string := ""
	if val > 3600.0:
		out_string += str(floori(val / 3600)) + ":"
		if fmod(val, 3600) < 600.0:
			out_string += "0"
	if val > 60.0:
		out_string += str(floori(val / 60) % 60) + ":"
		if fmod(val, 60.0) < 10.0:
			out_string += "0"
	else:
		out_string += "0:"
		if val < 10.0:
			out_string += "0"
	
	out_string += str(floori(val) % 60)
	
	return out_string

func reload_theme() -> void:
	if timer_theme_path != "" and timer_theme_path.is_absolute_path():
		var theme_try = load(timer_theme_path)
		if theme_try is TimerTheme:
			theme = theme_try
	else:
		theme = load("res://DefaultTheming/DefaultTimerTheme.tres")
