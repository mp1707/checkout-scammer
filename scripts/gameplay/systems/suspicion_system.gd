extends RefCounted
class_name SuspicionSystem


func setup_customer(customer: CustomerState, curve: SuspicionCurveResource) -> void:
	if customer == null or curve == null:
		return

	customer.current_suspicion_percent = curve.get_initial_suspicion_percent()


func roll_for_duplicate_scan(
	customer: CustomerState,
	curve: SuspicionCurveResource,
	random: RandomNumberGenerator
) -> bool:
	var roll_percent: int = random.randi_range(1, 100)
	return roll_for_duplicate_scan_with_value(customer, curve, roll_percent)


func roll_for_duplicate_scan_with_value(
	customer: CustomerState,
	curve: SuspicionCurveResource,
	roll_percent: int
) -> bool:
	if customer == null or curve == null:
		return false

	var was_caught: bool = roll_percent <= customer.current_suspicion_percent
	if not was_caught:
		customer.current_suspicion_percent = get_next_suspicion_percent(customer.current_suspicion_percent, curve)

	return was_caught


func get_next_suspicion_percent(current_percent: int, curve: SuspicionCurveResource) -> int:
	if curve == null or curve.stage_percentages.is_empty():
		return current_percent

	for stage_percent: int in curve.stage_percentages:
		if stage_percent > current_percent:
			return stage_percent

	return curve.stage_percentages[curve.stage_percentages.size() - 1]


func get_customer_hand_stage_index(current_percent: int, curve: SuspicionCurveResource) -> int:
	if curve == null or curve.stage_percentages.is_empty():
		return 0

	if curve.stage_percentages.size() < 3:
		return 0
	if current_percent < curve.stage_percentages[1]:
		return 0
	if current_percent < curve.stage_percentages[2]:
		return 1
	return 2
