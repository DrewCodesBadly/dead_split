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

const timer_theme_path_default: String = "res://DefaultTheming/TimerTheme.tres"
const timer_stopped_label_path_default: String = "res://DefaultTheming/TimerStopped.tres"
const timer_running_label_path_default: String = "res://DefaultTheming/TimerRunning.tres"
const timer_finished_label_path_default: String = "res://DefaultTheming/TimerFinished.tres"
const timer_finished_pb_label_path_default: String = "res://DefaultTheming/TimerFinishedPB.tres"
const split_ahead_gaining_label_path_default: String = "res://DefaultTheming/SplitAheadGaining.tres"
const split_ahead_losing_label_path_default: String = "res://DefaultTheming/SplitAheadLosing.tres"
const split_behind_gaining_label_path_default: String = "res://DefaultTheming/SplitBehindGaining.tres"
const split_behind_losing_label_path_default: String = "res://DefaultTheming/SplitBehindLosing.tres"
const split_best_segment_label_path_default: String = "res://DefaultTheming/SplitBestSegment.tres"
const timer_background_stylebox_path_default: String = "res://DefaultTheming/TimerBackgroundStyleBox.tres"
const active_split_bg_stylebox_path_default: String = "res://DefaultTheming/ActiveSplitStyleBox.tres"
const inactive_split_bg_stylebox_path_default: String = "res://DefaultTheming/InactiveSplitStyleBox.tres"

var timer_theme_path: String = "res://DefaultTheming/TimerTheme.tres"
var timer_stopped_label_path: String = "res://DefaultTheming/TimerStopped.tres"
var timer_running_label_path: String = "res://DefaultTheming/TimerRunning.tres"
var timer_finished_label_path: String = "res://DefaultTheming/TimerFinished.tres"
var timer_finished_pb_label_path: String = "res://DefaultTheming/TimerFinishedPB.tres"
var split_ahead_gaining_label_path: String = "res://DefaultTheming/SplitAheadGaining.tres"
var split_ahead_losing_label_path: String = "res://DefaultTheming/SplitAheadLosing.tres"
var split_behind_gaining_label_path: String = "res://DefaultTheming/SplitBehindGaining.tres"
var split_behind_losing_label_path: String = "res://DefaultTheming/SplitBehindLosing.tres"
var split_best_segment_label_path: String = "res://DefaultTheming/SplitBestSegment.tres"
var timer_background_stylebox_path: String = "res://DefaultTheming/TimerBackgroundStyleBox.tres"
var active_split_bg_stylebox_path: String = "res://DefaultTheming/ActiveSplitStyleBox.tres"
var inactive_split_bg_stylebox_path: String = "res://DefaultTheming/InactiveSplitStyleBox.tres"


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
