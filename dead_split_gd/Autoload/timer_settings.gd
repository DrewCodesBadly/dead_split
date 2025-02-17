extends Node

enum ComparisonType {
	COMPARISON_TYPE_NONE,
	COMPARISON_TYPE_TIME,
	COMPARISON_TYPE_SEGMENT_DELTA,
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

var active_comparisons: Array[String] = ["Personal Best", "Personal Best"]
var active_comp_types: Array[ComparisonType] = [ComparisonType.COMPARISON_TYPE_DELTA, ComparisonType.COMPARISON_TYPE_TIME]

var working_directory_path: String = ""
var current_file_path: String = "None"

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
	
	out_string += str(floori(val) % 60)
	
	return out_string
