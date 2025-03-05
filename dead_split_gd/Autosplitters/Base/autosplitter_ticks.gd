extends Timer

# just calls 120hz autosplitter updates
func _ready() -> void:
	wait_time = 1 / 120.0
	timeout.connect(MainTimer.update_autosplitter)
	start()
