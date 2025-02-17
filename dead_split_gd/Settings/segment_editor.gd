extends HBoxContainer

class_name SegmentEditor

@export var seg_name: LineEdit
@export var seg_time: LineEdit
@export var seg_best: LineEdit

signal new_name
signal new_time
signal new_best
signal moved_up
signal moved_down
signal deleted

func _on_seg_name_text_changed(new_text: String) -> void:
	new_name.emit(get_index(), new_text)


func _on_seg_time_text_changed(new_text: String) -> void:
	new_time.emit(get_index(), new_text)


func _on_seg_best_text_changed(new_text: String) -> void:
	new_best.emit(get_index(), new_text)


func _on_move_up_pressed() -> void:
	moved_up.emit(get_index())


func _on_move_down_pressed() -> void:
	moved_down.emit(get_index())


func _on_delete_pressed() -> void:
	deleted.emit(get_index())

func setup(run: EditableRun, comp: String, rta: bool) -> void:
	var idx: int = get_index()
	seg_name.text = run.get_segment_name(idx)
	seg_time.text = str(run.get_segment_comparison(idx, comp, rta))
	seg_best.text = str(run.get_segment_best(idx, rta))
