extends Control

class_name TimerElement

# Called only while the timer is running
func timer_process() -> void:
	pass

# Called when the timer changes phase
func timer_phase_change(_phase: TimerSettings.TimerPhase) -> void:
	pass

# Called when the Run used by the timer changes
func run_updated() -> void:
	pass
