extends Autosplitter

# Declaring pointer paths as packed arrays
var room_id: PointerPath
var game_is_loading: PointerPath
var game_state: PointerPath
var module_toggle: PointerPath
var horde_end: PointerPath
var is_paused: PointerPath

var mre_triggered := false

# Make sure to set process_name and add any desired settings to the `settings` dictionary.
func setup() -> void:
	process_name = "HyperLightDrift" # Preferably short, as long as it's identifiable
	
	# Check the current platform and adjust pointer paths as needed
	# In this case, only windows and linux under proton are supported.
	# This will either use the windows pointer paths or linux pointer paths.
	if OS.get_name().begins_with("Wi"):
		room_id = PointerPath.new([0x255B1F10], 0, TYPE_U32, true)
		game_is_loading = PointerPath.new([0x255A7E24, 0x0, 0x0, 0x10, 0x0, 0xC, 0x28, 0x370], 0.0, TYPE_F64, true)
		game_state = PointerPath.new([0x255A7E0C, 0xAC, 0xC, 0xC], 0, TYPE_U32, true)
		module_toggle = PointerPath.new([0x255B2648, 0xA5C, 0x18, 0x24], 0, TYPE_U32, true)
		horde_end = PointerPath.new([0x255B2648, 0xA60, 0x18, 0x24], 0, TYPE_U32, true)
		is_paused = PointerPath.new([0x255AF150, 0x0, 0x144, 0x3C, 0xD8], 0, TYPE_U32, true)
	# Assume linux. Other platforms are not supported.
	else:
		room_id = PointerPath.new([0x259B1F10], 0, TYPE_U32, true)
		game_is_loading = PointerPath.new([0x259A7E24, 0x0, 0x0, 0x10, 0x0, 0xC, 0x28, 0x370], 0.0, TYPE_F64, true)
		game_state = PointerPath.new([0x259A7E0C, 0xAC, 0xC, 0xC], 0, TYPE_U32, true)
		module_toggle = PointerPath.new([0x259B2648, 0xA5C, 0x18, 0x24], 0, TYPE_U32, true)
		horde_end = PointerPath.new([0x259B2648, 0xA60, 0x18, 0x24], 0, TYPE_U32, true)
		is_paused = PointerPath.new([0x259AF150, 0x0, 0x144, 0x3C, 0xD8], 0, TYPE_U32, true)
	
	# Adding settings, with provided default values
	settings["ng_start"] = true
	settings["alt_end"] = true
	settings["horde_finish"] = false
	settings["horde_start"] = false
	settings["room_transitions"] = false
	settings["intro"] = true
	settings["mre"] = false
	settings["modules"] = true
	settings["town_warp"] = true
	settings["north_warp"] = true
	settings["south_warp"] = true
	settings["east_warp"] = true
	settings["west_warp"] = true
	
	# Add the pointers to pointer_paths
	# This makes them automatically get updated when the autosplitter updates.
	pointer_paths.append(room_id)
	pointer_paths.append(game_is_loading)
	pointer_paths.append(game_state)
	pointer_paths.append(module_toggle)
	pointer_paths.append(horde_end)
	pointer_paths.append(is_paused)

# Called after the user's settings are loaded. You can use this if you want.
# You can also just not override this method.
func read_settings() -> void:
	pass

# All of the below methods are called automatically by the super class.
# You can optionally just not override them if they aren't needed.
# They are meant to mimic ASL
# And they are mostly copied from HLD's ASL autosplitter, just adapted to GDScript
# In the future, this process could probably be automated pretty easily.

# This function will be called repeatedly before the timer starts
# If it returns true, the run starts.
func start() -> bool:
	# NG start
	if game_state.last == 0 and game_state.current == 5:
		if settings["ng_start"]:
			mre_triggered = false
			return true
	
	if room_id.current >= 73 and room_id.last <= 77 and room_id.last != room_id.current \
	and settings["horde_start"]:
		mre_triggered = false
		return true
	
	return false

# This function will be called repeatedly while the timer is running. 
# If it returns true, the timer splits.
func split() -> bool:
	# horde mode
	if room_id.current >= 73 and room_id.current <= 77 \
	and horde_end.current == 1 and horde_end.last == 0 and is_paused.current == 0:
		if settings["horde_finish"]:
			return true
	
	# Modules
	if module_toggle.current != module_toggle.last and module_toggle.current == 1:
		# TODO: Individual module support
		if settings["modules"]:
			return true
	
	# All room transition based splits
	if room_id.current != room_id.last:
		# All transitions
		if settings["room_transitions"]:
			return true
		
		# Town warp
		if room_id.current == 61 and (room_id.last < 60 or room_id.current > 80):
			if settings["town_warp"]:
				return true
		
		# East warp
		if room_id.current == 175 and (room_id.last < 172 or room_id.last > 200):
			if settings["east_warp"]:
				return true
		
		# North warp
		if room_id.current == 94 and (room_id.last < 93 or room_id.last > 124):
			if settings["north_warp"]:
				return true
		
		# West warp
		if room_id.current == 219 and (room_id.last < 218 or room_id.last > 253):
			if settings["west_warp"]:
				return true
		
		# South warp
		if room_id.current == 130 and (room_id.last < 128 or room_id.last > 165):
			if settings["south_warp"]:
				return true
		
		# Alt drifter ending
		if room_id.current == 8 and room_id.last == 262:
			if settings["alt_end"]:
				return true
		
		# MRE
		if room_id.current == 53:
			if !mre_triggered and settings["mre"]:
				mre_triggered = true
				return true
		
		# Intro
		if room_id.current == 51 and room_id.last == 50:
			if settings["intro"]:
				return true
		
		# TODO: Other transitions in the HLD autosplitter
	
	return false

# This function will be called repeatedly while the timer is running.
# The timer will pause when it first returns true and resume when it later returns false.
func is_loading() -> bool:
	return game_is_loading.current > 0.5

# This function will be called repeatedly while the timer is running.
# If it returns true, the timer resets.
func reset() -> bool:
	return false
