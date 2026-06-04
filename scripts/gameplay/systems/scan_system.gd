extends RefCounted
class_name ScanSystem

const SuspicionSystemScript = preload("res://scripts/gameplay/systems/suspicion_system.gd")

const FAILURE_NOT_HELD: String = "not_held"
const FAILURE_NOT_TOUCHING_SCANNER: String = "not_touching_scanner"
const FAILURE_WRONG_DIRECTION: String = "wrong_direction"
const FAILURE_NO_PRODUCT: String = "no_product"
const FAILURE_PRODUCT_PROCESSED: String = "product_processed"
const FAILURE_CAUGHT: String = "caught"


func evaluate_scan(
	request: ScanRequest,
	customer: CustomerState,
	suspicion_system: SuspicionSystemScript,
	curve: SuspicionCurveResource,
	random: RandomNumberGenerator
) -> ScanResult:
	var result: ScanResult = ScanResult.new()
	if customer != null:
		result.suspicion_percent_after = customer.current_suspicion_percent

	if request == null or request.product_instance == null:
		result.failure_reason = FAILURE_NO_PRODUCT
		return result

	result.product_instance = request.product_instance

	if request.product_instance.is_processed:
		result.failure_reason = FAILURE_PRODUCT_PROCESSED
		return result
	if not request.is_held:
		result.failure_reason = FAILURE_NOT_HELD
		return result
	if not request.is_touching_scanner:
		result.failure_reason = FAILURE_NOT_TOUCHING_SCANNER
		return result
	if request.movement_direction.x >= 0.0:
		result.failure_reason = FAILURE_WRONG_DIRECTION
		return result

	result.is_first_scan = request.product_instance.scan_count == 0
	result.is_duplicate_scan = request.product_instance.scan_count > 0

	if result.is_duplicate_scan:
		result.was_caught = suspicion_system.roll_for_duplicate_scan(customer, curve, random)
		result.suspicion_percent_after = customer.current_suspicion_percent
		if result.was_caught:
			result.failure_reason = FAILURE_CAUGHT
			return result

	result.is_valid_scan = true
	result.suspicion_percent_after = customer.current_suspicion_percent
	return result
