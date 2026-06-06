extends Resource
class_name SuspicionCurveResource

@export var stage_percentages: Array[int] = [10, 50, 75, 90]


func get_initial_suspicion_percent() -> int:
	return stage_percentages[0]
