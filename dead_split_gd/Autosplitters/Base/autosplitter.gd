extends RefCounted

class_name Autosplitter

var process_name: String = ""
var settings: Dictionary[String, Variant] = {}

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
		process_update()
	else:
		print("No process")
		MainTimer.try_attach_process(process_name)

# Called every tick when there is a valid process handle. Override this to provide autosplitter functionality.
func process_update() -> void:
	pass

func start_split() -> void:
	MainTimer.start_split()

func skip_split() -> void:
	MainTimer.skip_split()

func undo_split() -> void:
	MainTimer.undo_split()

func reset() -> void:
	MainTimer.reset()

func pause_game_time() -> void:
	MainTimer.pause_game_time()

func resume_game_time() -> void:
	MainTimer.resume_game_time()

func read_pointer_path(offsets: PackedInt64Array, pointer_size_32: bool, data_type: int):
	return MainTimer.read_pointer_path(offsets, pointer_size_32, data_type)
