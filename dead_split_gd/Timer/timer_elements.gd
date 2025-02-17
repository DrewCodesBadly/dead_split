extends VBoxContainer

func _ready() -> void:
	var title = load("res://TimerElements/title.tscn")
	add_element(title.instantiate())
	
	var splits = load("res://TimerElements/splits.tscn")
	add_element(splits.instantiate())
	
	var timer_e = load("res://TimerElements/timer.tscn")
	add_element(timer_e.instantiate())

func add_element(element: TimerElement) -> void:
	pass
