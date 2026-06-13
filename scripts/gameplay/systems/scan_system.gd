extends RefCounted
class_name ScanSystem


func evaluate_scan(
	request: ScanRequest,
	customer: CustomerState,
	suspicion_system: SuspicionSystem,
	random: RandomNumberGenerator
) -> ScanResult:
	var result: ScanResult = ScanResult.new()
	if customer != null:
		result.suspicion_percent_after = customer.current_suspicion_percent

	if request == null or request.product_instance == null:
		result.failure_reason = ScanResult.FailureReason.NO_PRODUCT
		return result

	result.product_instance = request.product_instance

	if request.product_instance.is_processed:
		result.failure_reason = ScanResult.FailureReason.PRODUCT_PROCESSED
		return result
	if not request.is_held:
		result.failure_reason = ScanResult.FailureReason.NOT_HELD
		return result
	if not request.is_touching_scanner:
		result.failure_reason = ScanResult.FailureReason.NOT_TOUCHING_SCANNER
		return result
	if request.movement_direction.x >= 0.0:
		result.failure_reason = ScanResult.FailureReason.WRONG_DIRECTION
		return result
	if request.product_instance.is_weighable():
		result.failure_reason = ScanResult.FailureReason.PRODUCT_WEIGHABLE
		return result

	return evaluate_product_charge_attempt(request.product_instance, customer, suspicion_system, random)


func evaluate_product_charge_attempt(
	product_instance: ProductInstance,
	customer: CustomerState,
	suspicion_system: SuspicionSystem,
	random: RandomNumberGenerator
) -> ScanResult:
	var result: ScanResult = ScanResult.new()
	if customer != null:
		result.suspicion_percent_after = customer.current_suspicion_percent

	if product_instance == null:
		result.failure_reason = ScanResult.FailureReason.NO_PRODUCT
		return result

	result.product_instance = product_instance
	if product_instance.is_processed:
		result.failure_reason = ScanResult.FailureReason.PRODUCT_PROCESSED
		return result
	result.is_first_scan = product_instance.scan_count == 0
	result.is_duplicate_scan = product_instance.scan_count > 0

	if result.is_duplicate_scan:
		result.was_caught = suspicion_system.roll_for_duplicate_scan(customer, random)
		result.suspicion_percent_after = customer.current_suspicion_percent
		if result.was_caught:
			result.failure_reason = ScanResult.FailureReason.CAUGHT
			return result

	result.is_valid_scan = true
	result.suspicion_percent_after = customer.current_suspicion_percent
	return result
