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
		var zip := ZIPReader.new()
		var err := zip.open(timer_theme_path)
		if err != OK:
			theme = load("res://DefaultTheming/DefaultTimerTheme.tres")
		else:
			var new_theme := TimerTheme.new()
			# jank here because actually saving TimerTheme would save a script -
			# this causes the script to load twice and break :(
			for property in new_theme.get_property_list():
				# once again using temp files due to jank zip interface
				# thankfully the filenames are the same as the properties so we can for loop this
				var file_name: String = property["name"] + ".tres"
				if zip.file_exists(file_name):
					var temp_file := FileAccess.create_temp(
						FileAccess.READ_WRITE, "resource_load_temp", ".tres", false)
					temp_file.store_string(zip.read_file(file_name).get_string_from_utf8()) # copy
					temp_file.close()
					var resource: Resource = ResourceLoader.load(temp_file.get_path_absolute())
					new_theme.set(property["name"], resource)
			
			theme = new_theme
	else:
		theme = load("res://DefaultTheming/DefaultTimerTheme.tres")
