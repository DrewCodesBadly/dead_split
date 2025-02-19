extends Control

@export var timer_elements: VBoxContainer
@export var timer_label: Label
@export var notification_popup: CenterContainer

@export_subgroup("Theme files")
var timer_theme: Theme
var timer_stopped_label: LabelSettings
var timer_running_label: LabelSettings
var timer_finished_label: LabelSettings
var timer_finished_pb_label: LabelSettings
var split_ahead_gaining_label: LabelSettings
var split_ahead_losing_label: LabelSettings
var split_behind_gaining_label: LabelSettings
var split_behind_losing_label: LabelSettings
var split_best_segment_label: LabelSettings
var timer_background_stylebox: StyleBox
var active_split_bg_stylebox: StyleBox
var inactive_split_bg_stylebox: StyleBox

@onready var settings_window_scene := preload("res://Settings/settings.tscn")

var old_timer_phase: int
var settings_open := false

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
	MainTimer.comparison_changed.connect(comp_changed)
	
	refresh_layout()
	var title = load("res://TimerElements/Title/title.tscn")
	add_element(title.instantiate())
	
	var splits = load("res://TimerElements/Splits/splits.tscn")
	add_element(splits.instantiate())
	
	MainTimer.run_changed.emit()

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
	MainTimer.run_changed.emit() # lazy and unnecessarily slow but no one will notice :3

# horror show. I could've made this arrays with an enum. Too late now.
func refresh_layout() -> void:
	# timer_theme
	var r = ResourceLoader.load(TimerSettings.timer_theme_path)
	if r is Theme:
		timer_theme = r
	else:
		timer_theme = ResourceLoader.load(TimerSettings.timer_theme_path_default)
	# timer_stopped
	r = ResourceLoader.load(TimerSettings.timer_stopped_label_path)
	if r is LabelSettings:
		timer_stopped_label = r
	else:
		timer_stopped_label = ResourceLoader.load(TimerSettings.timer_stopped_label_path_default)
	# timer_running
	r = ResourceLoader.load(TimerSettings.timer_running_label_path)
	if r is LabelSettings:
		timer_running_label = r
	else:
		timer_running_label = ResourceLoader.load(TimerSettings.timer_running_label_path_default)
	# timer_finished
	r = ResourceLoader.load(TimerSettings.timer_finished_label_path)
	if r is LabelSettings:
		timer_finished_label = r
	else:
		timer_finished_label = ResourceLoader.load(TimerSettings.timer_finished_label_path_default)
	# timer_finished_pb
	r = ResourceLoader.load(TimerSettings.timer_finished_pb_label_path)
	if r is LabelSettings:
		timer_finished_pb_label = r
	else:
		timer_finished_pb_label = ResourceLoader.load(TimerSettings.timer_finished_pb_label_path_default)
	# split_ahead_gaining
	r = ResourceLoader.load(TimerSettings.split_ahead_gaining_label_path)
	if r is LabelSettings:
		split_ahead_gaining_label = r
	else:
		split_ahead_gaining_label = ResourceLoader.load(TimerSettings.split_ahead_gaining_label_path_default)
	# split_ahead_losing
	r = ResourceLoader.load(TimerSettings.split_ahead_losing_label_path)
	if r is LabelSettings:
		split_ahead_losing_label = r
	else:
		split_ahead_losing_label = ResourceLoader.load(TimerSettings.split_ahead_losing_label_path_default)
	# split_behind_gaining
	r = ResourceLoader.load(TimerSettings.split_behind_gaining_label_path)
	if r is LabelSettings:
		split_behind_gaining_label = r
	else:
		split_behind_gaining_label = ResourceLoader.load(TimerSettings.split_behind_gaining_label_path_default)
	# split_behing_losing
	r = ResourceLoader.load(TimerSettings.split_behind_losing_label_path)
	if r is LabelSettings:
		split_behind_losing_label = r
	else:
		split_behind_losing_label = ResourceLoader.load(TimerSettings.split_behind_losing_label_path)
	# split_best
	r = ResourceLoader.load(TimerSettings.split_best_segment_label_path)
	if r is LabelSettings:
		split_best_segment_label = r
	else:
		split_best_segment_label = ResourceLoader.load(TimerSettings.split_best_segment_label_path_default)
	# timer_bg
	r = ResourceLoader.load(TimerSettings.timer_background_stylebox_path)
	if r is StyleBox:
		timer_background_stylebox = r
	else:
		timer_background_stylebox = ResourceLoader.load(TimerSettings.timer_background_stylebox_path_default)
	# active_split_bg
	r = ResourceLoader.load(TimerSettings.active_split_bg_stylebox_path)
	if r is StyleBox:
		active_split_bg_stylebox = r
	else:
		active_split_bg_stylebox = ResourceLoader.load(TimerSettings.active_split_bg_stylebox_path_default)
	# inactive_split_bg
	r = ResourceLoader.load(TimerSettings.inactive_split_bg_stylebox_path)
	if r is StyleBox:
		inactive_split_bg_stylebox = r
	else:
		inactive_split_bg_stylebox = ResourceLoader.load(TimerSettings.inactive_split_bg_stylebox_path_default)
	
	theme = timer_theme
	layout_changed.emit()
