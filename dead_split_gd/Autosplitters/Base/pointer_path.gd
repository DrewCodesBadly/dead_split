extends Resource

## Class to make reading pointer paths easier. Stores both the last read value and current value.
class_name PointerPath

var path: PackedInt64Array
var last
var current
var small_pointers: bool
var type: int

func _init(p_path: Array[int], last_val, p_type: int, pointer_size_32: bool) -> void:
	last = last_val
	current = last
	path = PackedInt64Array(p_path)
	small_pointers = pointer_size_32
	type = p_type

func update() -> void:
	var new_val = MainTimer.read_pointer_path(path, small_pointers, type)
	if new_val != null:
		last = current
		current = new_val
