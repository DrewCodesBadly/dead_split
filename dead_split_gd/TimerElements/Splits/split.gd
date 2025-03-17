extends PanelContainer

class_name Split

@export var name_label: Label
@export var comp_label: Label
@export var time_label: Label
var idx: int
var current := false

# This will perform like shit but its so much easier to code and I don't think it matters
func update() -> void:
	time_label.text = TimerSettings.round_off_no_decimal(MainTimer.get_segment_comparison(
		idx, TimerSettings.active_comparison, TimerSettings.rta))
	
	var comp := MainTimer.get_segment_comparison(idx, TimerSettings.active_comparison, TimerSettings.rta)
	if MainTimer.timer_phase != TimerSettings.TimerPhase.NOT_RUNNING and \
	MainTimer.current_split_index >= idx and \
	comp != 0.0: # Ignore all updating if there is no valid comparison
		# Current split should only conditionally update, using current time
		if current:
			var t := MainTimer.current_time if TimerSettings.rta else MainTimer.current_game_time
			var delta := t - comp
			var best := MainTimer.get_segment_best(idx, TimerSettings.rta)
			# Only starts showing the time change when this split is slower than the best segment
			# Bit jank since the effective split time has to be reconstructed manually
			# Additionally, the comparison is always shown when you are behind (to mirror livesplit)
			if delta >= 0.0 or (idx == 0 and t >= best) or \
			(idx > 0 and t >= MainTimer.get_segment_time(idx - 1, TimerSettings.rta) + best):
				var string := ""
				if delta >= 0.0:
					string += "+"
				string += str(TimerSettings.round_off(delta))
				comp_label.text = string
		
		# Other splits should update using segment times and set their label settings.
		else:
			# Comparison calculation
			var t := MainTimer.get_segment_time(idx, TimerSettings.rta)
			if t != 0.0:
				var delta := t - comp
				var string := ""
				if delta >= 0.0:
					string += "+"
				string += str(TimerSettings.round_off(delta))
				comp_label.text = string
				
				# Label settings
				if t <= MainTimer.get_segment_best(idx, TimerSettings.rta):
					comp_label.label_settings = TimerSettings.theme.split_best_segment_label
				else:
					# We need to check with the last split to see whether we are gaining or losing
					if idx > 0:
						var last_delta = \
						MainTimer.get_segment_time(idx - 1, TimerSettings.rta) - \
						MainTimer.get_segment_comparison(idx - 1, TimerSettings.active_comparison, TimerSettings.rta)
						if delta > 0.0:
							if last_delta > delta:
								comp_label.label_settings = TimerSettings.theme.split_behind_gaining_label
							else:
								comp_label.label_settings = TimerSettings.theme.split_behind_losing_label
						elif last_delta > delta:
							comp_label.label_settings = TimerSettings.theme.split_ahead_gaining_label
						else:
							comp_label.label_settings = TimerSettings.theme.split_ahead_losing_label
					
					# No such check needed
					else:
						if delta > 0.0:
							comp_label.label_settings = TimerSettings.theme.split_behind_losing_label
						else:
							comp_label.label_settings = TimerSettings.theme.split_ahead_gaining_label
			# t == 0.0 so the last split was skipped.
			else:
				comp_label.text = "-"
	
	# Timer isn't running or the split is upcoming and should be blank.
	else:
		comp_label.text = ""
		comp_label.label_settings = null
	
	# set StyleBox depending on if this is the current split or not
	if current:
		add_theme_stylebox_override("panel", TimerSettings.theme.active_split_bg_stylebox)
	else:
		add_theme_stylebox_override("panel", TimerSettings.theme.inactive_split_bg_stylebox)

func update_name() -> void:
	var text := MainTimer.get_segment_name(idx)
	if text.left(1) == "-": # this is a subsplit
		name_label.text = "\t" + text.substr(1)
	elif text.left(1) == "{" and text.find("}") != -1: # this is a subsplit, but the end one
		name_label.text = "\t" + text.substr(text.find("}"))

# Uses the name of a subsplit header, making this a header split
func update_subsplit_name() -> void:
	# Assume this is actually a header
	var text := MainTimer.get_segment_name(idx)
	name_label.text = text.substr(1, text.find("}"))

func set_split_name(text: String) -> void:
	name_label.text = text
