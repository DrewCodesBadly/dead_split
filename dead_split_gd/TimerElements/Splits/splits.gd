extends TimerElement

@onready var split_scene := preload("res://TimerElements/Splits/split.tscn")

@export var splits_container: VBoxContainer
var current_split := -1

func run_updated() -> void:
	# Regenerate timer comparisons
	MainTimer.regenerate_comparisons()
	
	# Empty the splits container and refill it
	for child in splits_container.get_children():
		child.queue_free()
	
	# stupid, but call_deferred isn't saving me for some reason. Need to wait for old splits to be freed.
	await get_tree().create_timer(0.01).timeout
	for split_idx in MainTimer.get_segment_count():
		var split := split_scene.instantiate()
		splits_container.add_child(split)
		for c in TimerSettings.active_comparisons.size():
			split.add_comparison()
		
		split.set_split_name(MainTimer.get_segment_name(split_idx))
	
	update_all_splits()

# Update current split and tell splits to self update
func timer_process() -> void:
	# Change the currently active split and set the previous split to a finished state
	if MainTimer.current_split_index != current_split:
		if current_split >= 0:
			splits_container.get_child(current_split).old_split.finish()
		
		if MainTimer.timer_phase == TimerSettings.TimerPhase.RUNNING:
			current_split = MainTimer.current_split_index
			splits_container.get_child(current_split).start()
	
	# Update the current split
	splits_container.get_child(current_split).update()

func update_all_splits() -> void:
	for split in splits_container.get_children():
		split.update(false)

func reset_all_splits() -> void:
	for split in splits_container.get_children():
		split.reset()

func timer_phase_change(phase: TimerSettings.TimerPhase) -> void:
	if phase == TimerSettings.TimerPhase.ENDED:
		splits_container.get_child(current_split).finish()
		current_split = -1
	elif phase == TimerSettings.TimerPhase.NOT_RUNNING:
		reset_all_splits()
		current_split = -1
