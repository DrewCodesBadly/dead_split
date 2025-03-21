extends Control

@export var timer_elements: VBoxContainer
@export var timer_label: Label
@export var notification_popup: CenterContainer
@export var panel: PanelContainer

@onready var settings_window_scene := preload("res://Settings/settings.tscn")

var old_timer_phase: int
var settings_open := false
var title: TimerElement
var splits: TimerElement

signal timer_phase_changed
signal timer_running
signal layout_changed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		get_window().position += Vector2i(event.relative.x * 1.5, event.relative.y * 1.5)

func _process(_delta: float) -> void:
	# Mimic livesplit's floating window system
	if Input.is_action_just_pressed("move_window") and DisplayServer.window_is_focused(0):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_just_released("move_window"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Open settings when settings key (default right mouse) is pressed
	if Input.is_action_just_pressed("open_settings") and !settings_open \
	and MainTimer.timer_phase == TimerSettings.TimerPhase.NOT_RUNNING:
		var settings := settings_window_scene.instantiate()
		add_child(settings)
		settings.timer_window = self
		settings_open = true
	
	# Send appropriate signals based on timer phase
	var new_phase := MainTimer.timer_phase
	if new_phase != old_timer_phase:
		timer_phase_changed.emit(new_phase as TimerSettings.TimerPhase)
	if new_phase == 1:
		timer_running.emit()
	
	old_timer_phase = new_phase
	
	timer_label.text = TimerSettings.round_off(MainTimer.current_time if TimerSettings.rta else MainTimer.current_game_time)

func _ready() -> void:
	title = load("res://TimerElements/Title/title.tscn").instantiate()
	add_element(title)
	
	splits = load("res://TimerElements/Splits/splits.tscn").instantiate()
	add_element(splits)
	
	# Try to load in any settings
	TimerSettings.try_load()
	MainTimer.try_load_run(TimerSettings.current_file_path)
	update_settings()
	reload_theme()
	
	TimerSettings.reload_autosplitter()
	get_viewport().get_window().size = TimerSettings.window_size
	
	MainTimer.comparison_changed.connect(comp_changed)
	
	MainTimer.run_changed.emit()
	timer_phase_changed.connect(func(phase: TimerSettings.TimerPhase):
		if phase == TimerSettings.TimerPhase.RUNNING:
			MainTimer.init_game_time()
		# On reset, save run (make this an optional feature later?)
		elif phase == TimerSettings.TimerPhase.NOT_RUNNING:
			MainTimer.try_save_run(TimerSettings.current_file_path)
	)

func add_element(element: TimerElement) -> void:
	element.root = self
	timer_elements.add_child(element)
	MainTimer.run_changed.connect(element.run_updated)
	timer_running.connect(element.timer_process)
	timer_phase_changed.connect(element.timer_phase_change)
	layout_changed.connect(element.layout_updated)

func comp_changed(comp: String) -> void:
	notification_popup.set_text(comp)
	notification_popup.flash()
	#MainTimer.run_changed.emit() # lazy and unnecessarily slow but no one will notice :3
	# Update: This broke things. Not very :3 unfortunately :(
	# Now it just calls update_splits in the splits module.

func reload_theme() -> void:
	TimerSettings.reload_theme()
	theme = TimerSettings.theme.timer_theme
	layout_changed.emit()
	panel.add_theme_stylebox_override("panel", TimerSettings.theme.timer_background_stylebox)
	panel.material = TimerSettings.theme.timer_background_material

func update_settings() -> void:
	title.visible = TimerSettings.show_title
	splits.visible = TimerSettings.show_splits
	splits.update_settings()
