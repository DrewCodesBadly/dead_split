extends CenterContainer

@export var label: Label
var t: Tween

func _ready() -> void:
	visible = false

func set_text(text: String) -> void:
	label.text = text

func flash() -> void:
	if t: t.kill()
	visible = true
	modulate.a = 1.0
	t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	t.tween_callback(hide)
