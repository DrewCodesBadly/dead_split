extends RefCounted

class_name Autosplitter

var process_name: String = ""
var settings: Dictionary[String, Variant] = {}
var was_loading := false
var pointer_paths: Array[PointerPath] = []

# Use this enum when calling read_pointer_path
enum {
	TYPE_I32,
	TYPE_I64,
	TYPE_U32,
	TYPE_U64,
	TYPE_F32,
	TYPE_F64
}

# Override to do any needed initialization (settings, name, etc)
func setup() -> void:
	pass

# Called after the user's settings have been loaded.
func read_settings() -> void:
	pass

# Called internally. Do not override.
func update() -> void:
	if MainTimer.has_valid_process():
		
		for path in pointer_paths:
			path.update()
		
		match MainTimer.timer_phase:
			TimerSettings.TimerPhase.NOT_RUNNING:
				if start():
					MainTimer.start_split()
			TimerSettings.TimerPhase.RUNNING:
				if split():
					MainTimer.start_split()
				if reset():
					MainTimer.reset()
				var loading := is_loading()
				if loading and !was_loading:
					MainTimer.pause_game_time()
				elif !loading and was_loading:
					MainTimer.resume_game_time()
				was_loading = loading
			_:
				pass
	else:
		MainTimer.try_attach_process(process_name)

# These functions are called by update(). They work similarly to ASL's scripts.
# Returning true in start() starts the timer
# Returning true in split() makes the timer split
# Returning true in reset() makes the timer reset
# is_loading() changing will cause the game time to pause and resume
func start() -> bool:
	return false

func split() -> bool:
	return false

func reset() -> bool:
	return false

func is_loading() -> bool:
	return false

func start_split() -> void:
	MainTimer.start_split()

func skip_split() -> void:
	MainTimer.skip_split()

func undo_split() -> void:
	MainTimer.undo_split()

func pause_game_time() -> void:
	MainTimer.pause_game_time()

func resume_game_time() -> void:
	MainTimer.resume_game_time()

func read_pointer_path(offsets: PackedInt64Array, pointer_size_32: bool, data_type: int):
	return MainTimer.read_pointer_path(offsets, pointer_size_32, data_type)
