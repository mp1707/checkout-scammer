extends RefCounted
class_name SuspicionSystem

const GREEN_HAND_MAX_SUSPICION_PERCENT: int = 30
const YELLOW_HAND_MAX_SUSPICION_PERCENT: int = 60


func setup_customer(customer: CustomerState, run_state: RunState = null) -> void:
	if customer == null or customer.customer_type == null:
		return

	var bonus_percent: int = run_state.next_customer_suspicion_bonus_percent if run_state != null else 0
	customer.current_suspicion_percent = clampi(
		customer.customer_type.get_initial_suspicion_percent() + bonus_percent,
		0,
		100
	)
	if run_state != null:
		run_state.next_customer_suspicion_bonus_percent = 0


func roll_for_duplicate_scan(
	customer: CustomerState,
	random: RandomNumberGenerator
) -> bool:
	var roll_percent: int = random.randi_range(1, 100)
	return roll_for_duplicate_scan_with_value(customer, roll_percent)


func roll_for_duplicate_scan_with_value(
	customer: CustomerState,
	roll_percent: int
) -> bool:
	if customer == null or customer.customer_type == null:
		return false

	var was_caught: bool = roll_percent <= customer.current_suspicion_percent
	customer.current_suspicion_percent = get_next_suspicion_percent(
		customer.current_suspicion_percent,
		customer.customer_type
	)

	return was_caught


func get_next_suspicion_percent(current_percent: int, customer_type: CustomerTypeResource) -> int:
	if customer_type == null or customer_type.suspicion_stage_percentages.is_empty():
		return current_percent

	for stage_percent: int in customer_type.suspicion_stage_percentages:
		if stage_percent > current_percent:
			return stage_percent

	return customer_type.suspicion_stage_percentages[customer_type.suspicion_stage_percentages.size() - 1]


func get_customer_hand_stage_index(current_percent: int, _customer_type: CustomerTypeResource) -> int:
	if current_percent <= GREEN_HAND_MAX_SUSPICION_PERCENT:
		return 0
	if current_percent <= YELLOW_HAND_MAX_SUSPICION_PERCENT:
		return 1
	return 2


func apply_next_customer_suspicion_bonus(customer: CustomerState, run_state: RunState) -> void:
	if customer == null or customer.customer_type == null or run_state == null:
		return
	if customer.customer_type.caught_penalty_kind != CustomerTypeResource.CaughtPenaltyKind.NEXT_CUSTOMER_SUSPICION_BONUS:
		return

	run_state.next_customer_suspicion_bonus_percent += customer.customer_type.next_customer_suspicion_bonus_percent
