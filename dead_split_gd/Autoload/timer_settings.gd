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
var show_title := true
var show_splits := true
var show_attempt_count := true
var show_finished_runs := true
var title_one_line := false
var shown_splits := 10
var shown_upcoming_splits := 1
var last_split_pinned := true
var time_rounding := 0.01

var active_comparison: String = "Personal Best"
var active_comp_idx: int = 0

var working_directory_path: String = ""
var current_file_path: String = "None"
var autosplitter_path: String = ""
var autosplitter_settings_dict: Dictionary[String, Variant] = {}

var timer_theme_path: String = ""

var window_size: Vector2i = Vector2i(750, 750)

# DO NOT SERIALIZE THIS
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
	
	var decimal: float = snapped(fmod(val, 60.0), time_rounding)
	var decimal_str := str(decimal)
	var expected_chars := str(time_rounding).length() + (1 if decimal < 0.0 else 0)
	while decimal_str.length() < expected_chars:
		decimal_str += "0"
	out_string += decimal_str
	
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

func save() -> void:
	var settings := TimerSettingsSerializable.new()
	
	settings.rta = rta
	settings.show_title = show_title
	settings.show_splits = show_splits
	settings.show_attempt_count = show_attempt_count
	settings.show_finished_runs = show_finished_runs
	settings.title_one_line = title_one_line
	settings.shown_splits = shown_splits
	settings.shown_upcoming_splits = shown_upcoming_splits
	settings.last_split_pinned = last_split_pinned
	settings.time_rounding = time_rounding
	settings.active_comparison = active_comparison
	settings.active_comp_idx = active_comp_idx
	settings.working_directory_path = working_directory_path
	settings.current_file_path = current_file_path
	settings.timer_theme_path = timer_theme_path
	settings.autosplitter_path = autosplitter_path
	settings.autosplitter_settings_dict = autosplitter_settings_dict
	settings.window_size = window_size
	
	# Finally, we save hotkeys
	settings.hotkeys_dict = MainTimer.get_hotkeys_dict()
	
	# Debug
	#print("Saving!")
	#for property in settings.get_property_list():
			#print(property["name"] + ": " + str(settings.get(property["name"])))
	
	ResourceSaver.save(settings, "user://deadsplit_settings.tres")

func try_load() -> void:
	if ResourceLoader.exists("user://deadsplit_settings.tres", "TimerSettingsSerializable"):
		var settings = ResourceLoader.load("user://deadsplit_settings.tres")
		
		# Debug
		#print("Loading!")
		#for property in settings.get_property_list():
			#print(property["name"] + ": " + str(settings.get(property["name"])))
		
		rta = settings.rta 
		show_title = settings.show_title 
		show_splits = settings.show_splits
		show_attempt_count = settings.show_attempt_count
		show_finished_runs = settings.show_finished_runs
		title_one_line = settings.title_one_line
		shown_splits = settings.shown_splits
		shown_upcoming_splits = settings.shown_upcoming_splits
		last_split_pinned = settings.last_split_pinned
		time_rounding = settings.time_rounding
		active_comparison = settings.active_comparison
		active_comp_idx = settings.active_comp_idx
		working_directory_path = settings.working_directory_path
		current_file_path = settings.current_file_path
		timer_theme_path = settings.timer_theme_path
		autosplitter_path = settings.autosplitter_path
		autosplitter_settings_dict = settings.autosplitter_settings_dict
		window_size = settings.window_size
		
		# Load hotkeys
		for k in settings.hotkeys_dict:
			MainTimer.add_hotkey(settings.hotkeys_dict[k], k)

func reload_autosplitter() -> void:
	if autosplitter_path == "" or !autosplitter_path.is_absolute_path(): return
	var autosplitter := Autosplitter.new()
	var script = ResourceLoader.load(autosplitter_path, "Script")
	if script and autosplitter:
		autosplitter.set_script(script)
		MainTimer.autosplitter = autosplitter
		autosplitter.setup()
		
		# Handle settings
		for setting in autosplitter_settings_dict:
			if autosplitter.settings.has(setting):
				autosplitter.settings[setting] = autosplitter_settings_dict[setting]
			else:
				autosplitter_settings_dict.erase(setting)
		for setting in autosplitter.settings:
			if !autosplitter_settings_dict.has(setting):
				autosplitter_settings_dict[setting] = autosplitter.settings[setting]
		
		autosplitter.read_settings()
