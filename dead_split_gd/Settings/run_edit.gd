extends VBoxContainer

@export var segment_editor: VBoxContainer
@export var comparison_remove: OptionButton
@export var comp_chooser: OptionButton
@export var igt_switch: CheckButton
@export var game_name_edit: LineEdit
@export var category_name_edit: LineEdit
@export var attempt_count_edit: LineEdit
@export var offset_edit: LineEdit
@export var add_comp_text: LineEdit
@export var segment_name_edit: LineEdit

@onready var segment_editor_scene: PackedScene = preload("res://Settings/segment_editor.tscn")
var editable_run: EditableRun

func update_custom_comparisons_list() -> void:
	comparison_remove.clear()
	comp_chooser.clear()
	for comp in editable_run.get_custom_comparisons():
		comparison_remove.add_item(comp)
	
	for comp in editable_run.get_comparisons():
		comp_chooser.add_item(comp)

func update_segment_editor() -> void:
	for child in segment_editor.get_children():
		child.queue_free()
	
	# Again, shouldn't have to do this but call_deferred won't work and i need to wait for children to be freed
	await get_tree().create_timer(0.01).timeout
	
	var active_comp: String = editable_run.get_comparisons()[comp_chooser.selected]
	var rta: bool = !igt_switch.button_pressed
	for seg_idx in editable_run.get_segment_count():
		var seg_editor: SegmentEditor = segment_editor_scene.instantiate()
		seg_editor.new_name.connect(
			func(idx: int, text: String):
				editable_run.set_segment_name(idx, text)
				update_segment_editor()
		)
		seg_editor.new_time.connect(
			func(idx: int, text: String):
				if text.is_valid_float():
					var f := text.to_float()
					if f >= 0.0:
						editable_run.set_segment_comparison(idx, active_comp, rta, f)
				update_segment_editor()
		)
		seg_editor.new_best.connect(
			func(idx: int, text: String):
				if text.is_valid_float():
					var f := text.to_float()
					if f >= 0.0:
						editable_run.set_segment_best(idx, rta, f)
				elif text == "":
					editable_run.set_segment_best(idx, rta, editable_run.get_segment_comparison(idx, "Personal Best", rta))
				update_segment_editor()
		)
		seg_editor.moved_up.connect(
			func(idx: int):
				editable_run.move_up_segment(idx)
				update_segment_editor()
		)
		seg_editor.moved_down.connect(
			func(idx: int):
				editable_run.move_down_segment(idx)
				update_segment_editor()
		)
		seg_editor.deleted.connect(
			func(idx: int):
				editable_run.remove_segment(idx)
				update_segment_editor()
		)
		segment_editor.add_child(seg_editor)
		seg_editor.setup(editable_run, active_comp, rta)

func _on_visibility_changed() -> void:
	if visible:
		editable_run = MainTimer.get_editable_run()
		game_name_edit.text = editable_run.get_game_name()
		category_name_edit.text = editable_run.get_category_name()
		attempt_count_edit.text = str(editable_run.get_attempt_count())
	
	update_custom_comparisons_list()
	update_segment_editor()

func _on_save_button_pressed() -> void:
	MainTimer.update_run(editable_run)

func _on_game_name_edit_text_changed(new_text: String) -> void:
	editable_run.set_game_name(new_text)
	game_name_edit.text = editable_run.get_game_name()

func _on_category_name_edit_text_changed(new_text: String) -> void:
	editable_run.set_category_name(new_text)
	category_name_edit.text = editable_run.get_category_name()

func _on_attempt_count_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		var n: int = new_text.to_int()
		if n >= 0:
			editable_run.set_attempt_count(n)
	
	attempt_count_edit.text = str(editable_run.get_attempt_count())

func _on_offset_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		var offset: float = new_text.to_float()
		editable_run.set_offset(offset)
	
	offset_edit.text = str(editable_run.get_offset())

func _on_add_comp_button_pressed() -> void:
	editable_run.add_custom_comparison(add_comp_text.text)
	add_comp_text.text = ""
	update_custom_comparisons_list()

func _on_remove_comp_button_pressed() -> void:
	editable_run.remove_custom_comparison(comparison_remove.selected)
	update_custom_comparisons_list()
	comparison_remove.select(-1)

func _on_comp_chooser_item_selected(_index: int) -> void:
	update_segment_editor()

func _on_add_seg_pressed() -> void:
	editable_run.add_segment(segment_name_edit.text)
	segment_name_edit.clear()
	update_segment_editor()


func _on_igt_switch_toggled(_toggled_on: bool) -> void:
	update_segment_editor()
