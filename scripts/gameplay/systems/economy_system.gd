extends RefCounted
class_name EconomySystem

const CouponSystemScript = preload("res://scripts/gameplay/systems/coupon_system.gd")


func calculate_scan_amount_cents(product_instance: ProductInstance, honest_coupons: Array[CouponInstance]) -> int:
	if product_instance == null or product_instance.variant == null:
		return 0
	if product_instance.variant.is_weighable():
		return 0

	var base_cents: int = product_instance.variant.price_cents
	var discount_percent: int = get_best_discount_percent(product_instance.variant, honest_coupons)
	return floori(float(base_cents * (100 - discount_percent)) / 100.0)


func calculate_weighed_amount_cents(product_instance: ProductInstance, honest_coupons: Array[CouponInstance]) -> int:
	if product_instance == null or product_instance.variant == null or not product_instance.variant.is_weighable():
		return 0

	var base_cents: int = roundi(
		float(product_instance.weight_grams * product_instance.variant.price_per_kg_cents) / 1000.0
	)
	var discount_percent: int = get_best_discount_percent(product_instance.variant, honest_coupons)
	var discounted_cents: int = floori(float(base_cents * (100 - discount_percent)) / 100.0)
	var multiplier_percent: int = product_instance.get_price_multiplier_percent()
	return floori(float(discounted_cents * multiplier_percent) / 100.0)


func apply_successful_scan(result: ScanResult, honest_coupons: Array[CouponInstance]) -> void:
	if result == null or not result.is_valid_scan or result.was_caught or result.product_instance == null:
		return

	var added_amount_cents: int = calculate_scan_amount_cents(result.product_instance, honest_coupons)
	result.product_instance.scan_count += 1
	result.product_instance.open_amount_cents += added_amount_cents
	result.added_amount_cents = added_amount_cents
	result.resulting_open_amount_cents = result.product_instance.open_amount_cents


func apply_successful_weighing(result: ScanResult, honest_coupons: Array[CouponInstance]) -> void:
	if result == null or not result.is_valid_scan or result.was_caught or result.product_instance == null:
		return

	var added_amount_cents: int = calculate_weighed_amount_cents(result.product_instance, honest_coupons)
	result.product_instance.scan_count += 1
	result.product_instance.open_amount_cents += added_amount_cents
	result.added_amount_cents = added_amount_cents
	result.resulting_open_amount_cents = result.product_instance.open_amount_cents


func payout_product(run_state: RunState, product_instance: ProductInstance) -> PayoutOutcome:
	var outcome: PayoutOutcome = PayoutOutcome.new()
	outcome.product_instance = product_instance
	outcome.cash_before_cents = run_state.cash_cents

	if product_instance != null:
		outcome.payout_cents = product_instance.open_amount_cents
		product_instance.open_amount_cents = 0
		product_instance.is_processed = true

	run_state.cash_cents += outcome.payout_cents
	outcome.cash_after_cents = run_state.cash_cents
	outcome.was_trashed = false
	return outcome


func trash_product(run_state: RunState, product_instance: ProductInstance) -> PayoutOutcome:
	var outcome: PayoutOutcome = PayoutOutcome.new()
	outcome.product_instance = product_instance
	outcome.cash_before_cents = run_state.cash_cents
	outcome.cash_after_cents = run_state.cash_cents
	outcome.was_trashed = true

	if product_instance != null:
		product_instance.open_amount_cents = 0
		product_instance.is_processed = true

	return outcome


func get_best_discount_percent(product: ProductVariantResource, honest_coupons: Array[CouponInstance]) -> int:
	var best_discount_percent: int = 0
	for coupon_instance: CouponInstance in honest_coupons:
		if coupon_instance == null or coupon_instance.coupon == null:
			continue
		if not coupon_instance.was_activated_honestly:
			continue
		if CouponSystemScript.coupon_matches_product_resource(coupon_instance.coupon, product):
			best_discount_percent = maxi(best_discount_percent, coupon_instance.coupon.discount_percent)

	return best_discount_percent


func format_cents(cents: int) -> String:
	var sign_prefix: String = ""
	var absolute_cents: int = cents
	if cents < 0:
		sign_prefix = "-"
		absolute_cents = -cents

	var dollars: int = floori(float(absolute_cents) / 100.0)
	return "%s$%d.%02d" % [sign_prefix, dollars, absolute_cents % 100]
