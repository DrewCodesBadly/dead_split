extends TimerElement

@export var game_name: Label
@export var cat_name: Label

func run_updated() -> void:
	game_name.text = MainTimer.get_game_name()
	cat_name.text = MainTimer.get_category_name()

func layout_updated() -> void:
	pass # theme will automatically override
