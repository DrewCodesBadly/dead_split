extends Autosplitter

# Declaring pointer paths as packed arrays
var room_id := PointerPath.new([0x259B1F10], 0, TYPE_U32, true)
var is_loading := PointerPath.new([0x259A7E24, 0x0, 0x0, 0x10, 0x0, 0xC, 0x28, 0x370], 0.0, TYPE_F64, true)
var game_state := PointerPath.new([0x259A7E0C, 0xAC, 0xC, 0xC], 0, TYPE_U32, true)
var module_toggle := PointerPath.new([0x259B2648, 0xA5C, 0x18, 0x24], 0, TYPE_U32, true)
var horde_end := PointerPath.new([0x259B2648, 0xA60, 0x18, 0x24], 0, TYPE_U32, true)
var is_paused := PointerPath.new([0x259AF150, 0x0, 0x144, 0x3C, 0xD8], 0, TYPE_U32, true)
var activated_modules: Array[Callable]

var mre_triggered := false

# Make sure to set process_name and add any desired settings to the `settings` dictionary.
func setup() -> void:
	process_name = "HyperLightDrift" # Preferably short, as long as it's identifiable
	
	# Adding settings
	settings["ng_start"] = true
	settings["alt_end"] = true
	settings["horde_finish"] = false
	settings["horde_start"] = false
	settings["room_transitions"] = false
	settings["intro"] = true
	settings["mre"] = false
	settings["modules"] = true
	settings["warps"] = true

# Called after the user's settings are loaded.
# This is mainly to avoid a billion dictionary checks. Instead, we can use an array of Callables.
# Leads to some overlap which you could implement at your discretion but I prefer it seperate.
# (e.x. a lot of splits rely on room_id changing that could be put under 1 if condition)
func read_settings() -> void:
	activated_modules = []
	if settings["ng_start"]:
		activated_modules.append(ng_start)
	if settings["alt_end"]:
		activated_modules.append(alt_end)
	if settings["horde_finish"]:
		activated_modules.append(horde_finish)
	if settings["horde_start"]:
		activated_modules.append(horde_start)
	if settings["room_transitions"]:
		activated_modules.append(room_transitions)
	if settings["intro"]:
		activated_modules.append(intro)
	if settings["mre"]:
		activated_modules.append(mre)
	if settings["modules"]:
		activated_modules.append(modules)
	if settings["warps"]:
		activated_modules.append(warps)

func process_update() -> void:
	# Update all pointer paths (if this is too much of a pain I guess you could put them in a dict)
	room_id.update()
	is_loading.update()
	game_state.update()
	module_toggle.update()
	horde_end.update()
	is_paused.update()
	
	# Now run autosplitter code
	# Load removal
	if is_loading.current > 0.5:
		pause_game_time()
	else:
		resume_game_time()
	
	for module in activated_modules:
		module.call()

func ng_start() -> void:
	if game_state.last == 0 and game_state.current == 5:
		mre_triggered = false
		start_split()

func alt_end() -> void:
	if room_id.current == 8 and room_id.last == 262:
		start_split()

func horde_finish() -> void:
	if horde_end.current == 1 and horde_end.last == 0 and is_paused.current == 0 \
	and room_id.current >= 73 and room_id.current <= 77:
		start_split()

func horde_start() -> void:
	if room_id.current >= 73 and room_id.current <= 77 and room_id.last != room_id.current:
		mre_triggered = false
		start_split()

func room_transitions() -> void:
	if room_id.current != room_id.last and room_id.current > 5 and room_id.last > 5:
		start_split()

func intro() -> void:
	if room_id.current == 51 and room_id.last == 50:
		start_split()

func mre() -> void:
	if !mre_triggered and room_id.current == 53:
		start_split()
		mre_triggered = true

func modules() -> void:
	if module_toggle.last != module_toggle.current and module_toggle.current == 1:
		start_split()

func warps() -> void:
	# Town
	if room_id.current == 61 and (room_id.last < 60 or room_id.last > 80):
		start_split()
	# East
	elif room_id.current == 175 and (room_id.last < 172 or room_id.last > 200):
		start_split()
	# North
	elif room_id.current == 94 and (room_id.last < 93 or room_id.last > 124):
		start_split()
	# West
	elif room_id.current == 219 and (room_id.last < 218 or room_id.last > 253):
		start_split()
	# South
	elif room_id.current == 130 and (room_id.last < 128 or room_id.last > 165):
		start_split()
