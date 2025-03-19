extends TimerElement

@onready var split_scene := preload("res://TimerElements/Splits/split.tscn")

var current_split := -1
var shown_splits := 10
var shown_splits_after_current := 1
var last_split_pinned := true
var split_focus := 0
var seg_count: int
var splits_array: Array[SplitData] = []

func _ready() -> void:
	MainTimer.comparison_changed.connect(func(_comp: String): update_splits())

func run_updated() -> void:
	# Regenerate timer comparisons
	MainTimer.regenerate_comparisons()
	split_focus = 0
	seg_count = MainTimer.get_segment_count()
	
	# Create new array of split data, accounting for subsplits
	# jank iterator
	splits_array.clear()
	var i: int = 0
	while i < seg_count:
		var split_name := MainTimer.get_segment_name(i)
		if split_name.left(1) == "-":
			# We have found the start of a subsplit
			var subsplit_data := SubsplitData.new()
			subsplit_data.start_index = i
			var init_split_data := SplitData.new()
			init_split_data.index = i
			init_split_data.split_name = "\t" + split_name.substr(1)
			subsplit_data.subsplits.append(init_split_data)
			
			i += 1
			
			# Loop through and add all subsplits
			while i < seg_count and MainTimer.get_segment_name(i).left(1) == "-":
				var split_data := SplitData.new()
				split_data.index = i
				split_data.split_name = "\t" + MainTimer.get_segment_name(i).substr(1)
				subsplit_data.subsplits.append(split_data)
				i += 1
			
			# Final split here should have form {subsplit} split
			var end_name := MainTimer.get_segment_name(i)
			subsplit_data.index = i
			var name_end := end_name.find("}")
			subsplit_data.split_name = end_name.substr(1, name_end - 1)
			var last_split_data := SplitData.new()
			last_split_data.index = i
			last_split_data.split_name = "\t" + end_name.substr(name_end + 1).strip_edges(true, false)
			subsplit_data.subsplits.append(last_split_data)
			
			splits_array.append(subsplit_data)
		else:
			var split_data := SplitData.new()
			split_data.index = i
			split_data.split_name = split_name
			splits_array.append(split_data)
		
		i += 1
	
	# Debug: print out the splits array
	#for data in splits_array:
		#if data is SubsplitData:
			#print("Subsplit: named " + data.split_name + " starting/ending at " \
				#+ str(data.start_index) + " " + str(data.index) + " containing the following:")
			#for split in data.subsplits:
				#print("\t" + split.split_name)
		#else:
			#print("Split: named " + data.split_name)
	
	update_splits()

func update_splits() -> void:
	# Empty the splits container and refill it
	for child in get_children():
		child.queue_free()
	
	# Find current position of the timer and render starting there
	var rendered_splits: int = 0
	var current_array_idx := 0
	var render_final_split := last_split_pinned
	while current_array_idx < splits_array.size() and splits_array[current_array_idx].index < split_focus:
		current_array_idx += 1
	
	var current_split_data := splits_array[current_array_idx]
	
	# Find the point where we will start rendering splits
	var needed_shown_splits := shown_splits - (0 if !last_split_pinned or current_array_idx == splits_array.size() - 1 else 1)
	var iterate_idx := 0
	if current_split_data is SubsplitData:
		# it's gonna take up all the space anyway so we can just start here
		if current_split_data.subsplits.size() >= needed_shown_splits - shown_splits_after_current - 1: # -1 for header
			iterate_idx = current_array_idx
		elif current_array_idx == 0:
			pass # we just go from the start until we can't render any more
		# We need to calculate based on how much space is left after rendering the whole subsplit
		else:
			# too lazy to even try to explain this
			var after_current_offset: int = max(0, shown_splits_after_current - current_split_data.index + split_focus)
			iterate_idx = max(0, current_array_idx - (needed_shown_splits - current_split_data.subsplits.size() - 1) \
				+ after_current_offset)
			# Means final split will be rendered w/o pinning
			if current_array_idx + after_current_offset >= splits_array.size() - 1 and iterate_idx > 0:
				iterate_idx -= 1
		
		
	else:
		iterate_idx = max(0, current_array_idx - needed_shown_splits + shown_splits_after_current)
	
	# Render splits starting from the start pos until we've rendered as many as we need
	while iterate_idx < splits_array.size() and rendered_splits < needed_shown_splits:
		var splits := splits_array[iterate_idx].generate(split_focus, needed_shown_splits, shown_splits_after_current)
		for split in splits:
			add_child(split)
			rendered_splits += 1
		
		if iterate_idx == splits_array.size() - 1:
			render_final_split = false
			needed_shown_splits = shown_splits
		
		iterate_idx += 1
	
	# Render the last split, if it's pinned and needed
	if render_final_split:
		var final_split := splits_array[splits_array.size() - 1].generate()
		rendered_splits += 1
		add_child(final_split[0])

# Scroll inputs
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("scroll_up") and split_focus > 0:
		split_focus -= 1
		update_splits()
	elif Input.is_action_just_pressed("scroll_down") and split_focus < seg_count - 1:
		split_focus += 1
		update_splits()

# Update current split and tell splits to self update
func timer_process() -> void:
	# Change the currently active split and set the previous split to a finished state
	if MainTimer.current_split_index != current_split:
		current_split = MainTimer.current_split_index
		split_focus = clamp(current_split + shown_splits_after_current, 0, seg_count - 1)
		# Update splits, redraw everything (i'm lazy)
		update_splits()
	else:
		# Update all splits without changes
		for split in get_children():
			split.update()

func timer_phase_change(phase: TimerSettings.TimerPhase) -> void:
	if phase == TimerSettings.TimerPhase.NOT_RUNNING:
		current_split = -1
		split_focus = 0
		update_splits()
	elif phase == TimerSettings.TimerPhase.ENDED:
		split_focus = MainTimer.get_segment_count() - 1
		current_split = -1
		update_splits()

func update_settings() -> void:
	shown_splits = TimerSettings.shown_splits
	shown_splits_after_current = TimerSettings.shown_upcoming_splits
	last_split_pinned = TimerSettings.last_split_pinned
