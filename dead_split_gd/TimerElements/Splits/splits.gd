extends TimerElement

@onready var split_scene := preload("res://TimerElements/Splits/split.tscn")

var current_split := -1
var shown_splits := 10
var shown_splits_after_current := 1
var last_split_pinned := true
var split_focus := 0
var seg_count: int

func run_updated() -> void:
	# Regenerate timer comparisons
	MainTimer.regenerate_comparisons()
	split_focus = 0
	seg_count = MainTimer.get_segment_count()
	update_splits(false)

func update_splits(active: bool) -> void:
	# Empty the splits container and refill it
	for child in get_children():
		child.queue_free()
	
	var split_focus_top: int = clamp(split_focus + shown_splits_after_current - shown_splits, 0, seg_count - 1)
	for i in shown_splits:
		var idx := i + split_focus_top
		if i >= seg_count:
			break
		var split := split_scene.instantiate()
		if last_split_pinned and i == shown_splits - 1:
			split.idx = MainTimer.get_segment_count() - 1
		else:
			split.idx = idx
		if split.idx == current_split:
			split.current = true
		split.update_layout(root)
		split.update_name()
		split.update(active)
		add_child(split)

# Scroll inputs
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("scroll_up") and split_focus > 0:
		split_focus -= 1
		update_splits(MainTimer.timer_phase != TimerSettings.TimerPhase.NOT_RUNNING)
	elif Input.is_action_just_pressed("scroll_down") and split_focus < seg_count - 1:
		split_focus += 1
		update_splits(MainTimer.timer_phase != TimerSettings.TimerPhase.NOT_RUNNING)

# Update current split and tell splits to self update
func timer_process() -> void:
	# Change the currently active split and set the previous split to a finished state
	if MainTimer.current_split_index != current_split:
		current_split = MainTimer.current_split_index
		# Update splits, redraw everything (i'm lazy)
		update_splits(true)
	else:
		# Update all splits without changes
		for split in get_children():
			split.update(true)

func timer_phase_change(_phase: TimerSettings.TimerPhase) -> void:
	#if phase == TimerSettings.TimerPhase.ENDED:
		#get_child(current_split).finish()
		#current_split = -1
	#elif phase == TimerSettings.TimerPhase.NOT_RUNNING:
		#reset_all_splits()
		#current_split = -1
	pass
