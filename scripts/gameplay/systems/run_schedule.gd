extends RefCounted
class_name RunSchedule

## Calendar helpers for effects that start "with the next customer"
## (coupons, assortment upgrades). Shared by CouponSystem and UpgradeSystem.


## Day/customer-number pair at which a purchased effect becomes active.
class Activation:
	var day: int = 1
	var customer_number: int = 1

	func _init(initial_day: int = 1, initial_customer_number: int = 1) -> void:
		day = initial_day
		customer_number = initial_customer_number


static func get_next_customer_activation(run_state: RunState, balance: GameBalanceResource) -> Activation:
	if balance == null:
		return Activation.new(run_state.current_day, run_state.current_customer_number)
	if run_state.current_customer_number >= balance.customers_per_day:
		return Activation.new(run_state.current_day + 1, 1)

	return Activation.new(run_state.current_day, run_state.current_customer_number + 1)


static func is_activation_due(
	activation_day: int,
	activation_customer_number: int,
	current_day: int,
	current_customer_number: int
) -> bool:
	if activation_day < current_day:
		return true
	if activation_day > current_day:
		return false
	return activation_customer_number <= current_customer_number
