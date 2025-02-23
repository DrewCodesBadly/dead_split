extends TimerElement

@export var game_name: Label
@export var cat_name: Label
@export var attempts: Label

func run_updated() -> void:
	update_text()

func update_text() -> void:
	if TimerSettings.title_one_line:
		game_name.text = MainTimer.get_game_name() + " - " + MainTimer.get_category_name()
	else:
		game_name.text = MainTimer.get_game_name()
		cat_name.text = MainTimer.get_category_name()
	
	attempts.visible = TimerSettings.show_attempt_count
	if TimerSettings.show_finished_runs:
		attempts.text = str(MainTimer.get_finished_run_count()) + "/" + str(MainTimer.get_attempt_count())
	else:
		attempts.text = str(MainTimer.get_attempt_count())

func layout_updated() -> void:
	pass # theme will automatically override

func timer_phase_change(_phase: TimerSettings.TimerPhase) -> void:
	update_text()
