extends Resource
class_name SuspicionCurveResource

@export var stage_percentages: Array[int] = [10, 50, 75, 90]
@export var mood_ring_colors: Array[Color] = [
	Color(0.20, 0.78, 0.32, 1.0),
	Color(0.94, 0.84, 0.24, 1.0),
	Color(0.95, 0.48, 0.18, 1.0),
	Color(0.88, 0.16, 0.16, 1.0),
]


func get_initial_suspicion_percent() -> int:
	return stage_percentages[0]
