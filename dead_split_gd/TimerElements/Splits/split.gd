extends PanelContainer

class_name Split

@export var name_label: Label
@export var comp_label: Label
@export var time_label: Label
var inactive_box: StyleBox
var active_box: StyleBox
var ahead_gaining: LabelSettings
var ahead_losing: LabelSettings
var behind_gaining: LabelSettings
var behind_losing: LabelSettings
var best_segment: LabelSettings
var idx: int
var current := false

# This will perform like shit but its so much easier to code and I don't think it matters
func update(active: bool) -> void:
	time_label.text = TimerSettings.round_off_no_decimal(MainTimer.get_segment_comparison(
		idx, TimerSettings.active_comparison, TimerSettings.rta))
	if active:
		var t := MainTimer.current_time if TimerSettings.rta else MainTimer.current_game_time
		var comp := MainTimer.get_segment_comparison(idx, TimerSettings.active_comparison, TimerSettings.rta)
		var delta := t - comp
		var string := ""
		if delta >= 0.0:
			string += "+"
		string += str(TimerSettings.round_off(delta))
		comp_label.text = string
		
		# handle label settings
		if !current:
			var last_delta := 0.0
			if idx > 0:
				last_delta = MainTimer.get_segment_comparison(idx - 1, TimerSettings.active_comparison, TimerSettings.rta)
			
			if delta > 0.0:
				comp_label.label_settings = ahead_gaining if delta < last_delta else ahead_losing
			else:
				comp_label.label_settings = behind_gaining if delta > last_delta else behind_gaining
		else:
			comp_label.label_settings = null
	
	else:
		comp_label.text = ""
	
	# set StyleBox depending on if this is the current split or not
	if current:
		add_theme_stylebox_override("panel", active_box)
	else:
		add_theme_stylebox_override("panel", inactive_box)

func update_name() -> void:
	name_label.text = MainTimer.get_segment_name(idx)

func update_layout(root: Control) -> void:
	inactive_box = root.inactive_split_bg_stylebox
	active_box = root.active_split_bg_stylebox
	ahead_gaining = root.split_ahead_gaining_label
	ahead_losing = root.split_ahead_losing_label
	behind_gaining = root.split_behind_gaining_label
	behind_losing = root.split_behind_losing_label
	best_segment = root.split_best_segment_label
