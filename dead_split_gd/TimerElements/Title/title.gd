extends TimerElement

func run_updated() -> void:
	$GameName.text = MainTimer.get_game_name()
	$CategoryName.text = MainTimer.get_category_name()
