extends Resource

class_name SplitData

const split_scene := preload("res://TimerElements/Splits/split.tscn")

var split_name: String
var index: int

func generate(_focus_index: int = -1, _shown_splits: int = 0, _shown_splits_after_current: int = 0) -> Array[Node]:
	var arr: Array[Node] = []
	var split := split_scene.instantiate()
	if MainTimer.current_split_index == index:
		split.current = true
	split.idx = index
	split.set_split_name(split_name)
	split.update()
	arr.append(split)
	return arr
