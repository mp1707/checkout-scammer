extends SceneTree
class_name Phase2SimulationTest

const CustomerGeneratorScript = preload("res://scripts/gameplay/generation/customer_generator.gd")
const BeltSystemScript = preload("res://scripts/gameplay/systems/belt_system.gd")
const ScanSystemScript = preload("res://scripts/gameplay/systems/scan_system.gd")
const SuspicionSystemScript = preload("res://scripts/gameplay/systems/suspicion_system.gd")
const EconomySystemScript = preload("res://scripts/gameplay/systems/economy_system.gd")
const CouponSystemScript = preload("res://scripts/gameplay/systems/coupon_system.gd")
const UpgradeSystemScript = preload("res://scripts/gameplay/systems/upgrade_system.gd")

var _failure_count: int = 0
var _registry: ContentRegistry
var _generator: CustomerGeneratorScript
var _belt_system: BeltSystemScript
var _scan_system: ScanSystemScript
var _suspicion_system: SuspicionSystemScript
var _economy_system: EconomySystemScript
var _coupon_system: CouponSystemScript
var _upgrade_system: UpgradeSystemScript


func _initialize() -> void:
	_registry = ContentRegistry.new()
	var content_errors: PackedStringArray = _registry.load_all()
	for message: String in content_errors:
		_fail("content validation", message)

	_generator = CustomerGeneratorScript.new()
	_belt_system = BeltSystemScript.new()
	_scan_system = ScanSystemScript.new()
	_suspicion_system = SuspicionSystemScript.new()
	_economy_system = EconomySystemScript.new()
	_coupon_system = CouponSystemScript.new()
	_upgrade_system = UpgradeSystemScript.new()

	_test_customer_generator()
	_test_belt_system()
	_test_scan_system()
	_test_suspicion_system()
	_test_economy_system()
	_test_coupon_system()
	_test_upgrade_system()
	_test_complete_customer_flow_without_scenes()

	if _failure_count > 0:
		push_error("Phase 2 simulation tests failed: %d failure(s)." % _failure_count)
		quit(1)
		return

	print("Phase 2 simulation tests passed.")
	quit(0)


func _test_customer_generator() -> void:
	var run_a: RunState = _create_run_state(77)
	run_a.current_day = 2
	run_a.current_customer_number = 1
	var run_b: RunState = _create_run_state(77)
	run_b.current_day = 2
	run_b.current_customer_number = 1

	var customer_a: CustomerState = _generator.generate_customer(_registry, run_a)
	var customer_b: CustomerState = _generator.generate_customer(_registry, run_b)
	_expect_string_arrays_equal(
		_product_ids(customer_a.product_queue),
		_product_ids(customer_b.product_queue),
		"CustomerGenerator keeps equal seeds deterministic"
	)

	run_b.run_seed = 78
	var customer_c: CustomerState = _generator.generate_customer(_registry, run_b)
	_expect_true(
		_product_ids(customer_a.product_queue) != _product_ids(customer_c.product_queue),
		"CustomerGenerator changes generated customers when seed changes"
	)

	var scripted_run: RunState = _create_run_state(77)
	scripted_run.current_day = 1
	scripted_run.current_customer_number = 1
	var scripted_customer: CustomerState = _generator.generate_customer(_registry, scripted_run)
	_expect_string_arrays_equal(
		PackedStringArray(["gum", "gum", "chips", "apple", "water", "banana", "gum", "chips", "apple", "water"]),
		_product_ids(scripted_customer.product_queue),
		"CustomerGenerator models scripted first customer"
	)

	var no_active_coupons_for_upgrade: Array[CouponInstance] = []
	var upgraded_first_day_customer: CustomerState = _generator.generate_customer_for_context(
		_registry,
		_registry.game_balance.default_run_seed,
		1,
		2,
		2,
		no_active_coupons_for_upgrade,
		_registry.game_balance.products_per_customer,
		_registry.game_balance.starting_assortment_level
	)
	_expect_true(
		_has_product_at_assortment_level(upgraded_first_day_customer, 2),
		"CustomerGenerator uses expanded assortment once a level-up is active"
	)

	var apple_coupon: CouponInstance = CouponInstance.new(_registry.get_coupon("apple_20_discount"), "test_coupon")
	var no_coupons: Array[CouponInstance] = []
	var weighted_count_without_coupon: int = _count_generated_product("apple", 400, no_coupons)
	var active_coupons: Array[CouponInstance] = [apple_coupon]
	var weighted_count_with_coupon: int = _count_generated_product("apple", 400, active_coupons)
	_expect_true(
		weighted_count_with_coupon > weighted_count_without_coupon,
		"CustomerGenerator applies coupon weight multipliers without mutating resources"
	)
	_expect_equal_int(10, _registry.get_product_variant("apple").generator_weight, "Product resource weight remains immutable")


func _test_belt_system() -> void:
	var customer: CustomerState = _create_customer_with_products(10)
	var coupon_instance: CouponInstance = CouponInstance.new(_registry.get_coupon("apple_20_discount"), "belt_coupon")
	_belt_system.start_customer(customer, 4, coupon_instance)

	_expect_equal_int(4, customer.visible_slots.size(), "BeltSystem creates visible slot records")
	_expect_equal_int(BeltSlot.SlotKind.COUPON, customer.visible_slots[0].slot_kind, "BeltSystem puts coupon first")
	_expect_equal_int(3, _belt_system.get_visible_product_count(customer), "BeltSystem fills remaining slots with products")
	_expect_equal_int(7, customer.product_queue.size(), "BeltSystem keeps hidden queue after visible fill")

	var taken_product_slot: BeltSlot = _belt_system.take_slot_object(customer, 2)
	_expect_equal_int(BeltSlot.SlotKind.PRODUCT, taken_product_slot.slot_kind, "BeltSystem allows free product slot selection")
	_expect_equal_int(BeltSlot.SlotKind.PRODUCT, customer.visible_slots[2].slot_kind, "BeltSystem refills selected product slot")
	_expect_equal_int(6, customer.product_queue.size(), "BeltSystem advances queue after taking product")

	var taken_coupon_slot: BeltSlot = _belt_system.take_slot_object(customer, 0)
	_expect_equal_int(BeltSlot.SlotKind.COUPON, taken_coupon_slot.slot_kind, "BeltSystem allows coupon processing")
	_expect_equal_int(BeltSlot.SlotKind.PRODUCT, customer.visible_slots[0].slot_kind, "BeltSystem refills coupon slot with product")
	_expect_equal_int(5, customer.product_queue.size(), "BeltSystem refills coupon slot from product queue")
	_expect_equal_int(10, customer.total_product_count, "BeltSystem coupon does not count against total product count")

	_belt_system.mark_product_processed(customer, taken_product_slot.product_instance)
	_expect_equal_int(1, customer.processed_product_count, "BeltSystem counts processed products")


func _test_scan_system() -> void:
	var customer: CustomerState = CustomerState.new("scan_customer")
	_suspicion_system.setup_customer(customer, _registry.suspicion_curve)
	var product: ProductInstance = ProductInstance.new(_registry.get_product_variant("gum"), "scan_product")
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 10

	var valid_request: ScanRequest = _create_scan_request(product, true, true, Vector2.LEFT)
	var valid_result: ScanResult = _scan_system.evaluate_scan(valid_request, customer, _suspicion_system, _registry.suspicion_curve, random)
	_expect_true(valid_result.is_valid_scan, "ScanSystem accepts held right-to-left scanner contact")
	_expect_true(valid_result.is_first_scan, "ScanSystem marks first scan")

	var wrong_direction: ScanResult = _scan_system.evaluate_scan(
		_create_scan_request(product, true, true, Vector2.RIGHT),
		customer,
		_suspicion_system,
		_registry.suspicion_curve,
		random
	)
	_expect_equal_string(ScanSystemScript.FAILURE_WRONG_DIRECTION, wrong_direction.failure_reason, "ScanSystem rejects left-to-right movement")

	var not_touching: ScanResult = _scan_system.evaluate_scan(
		_create_scan_request(product, true, false, Vector2.LEFT),
		customer,
		_suspicion_system,
		_registry.suspicion_curve,
		random
	)
	_expect_equal_string(ScanSystemScript.FAILURE_NOT_TOUCHING_SCANNER, not_touching.failure_reason, "ScanSystem rejects missing scanner contact")

	var not_held: ScanResult = _scan_system.evaluate_scan(
		_create_scan_request(product, false, true, Vector2.LEFT),
		customer,
		_suspicion_system,
		_registry.suspicion_curve,
		random
	)
	_expect_equal_string(ScanSystemScript.FAILURE_NOT_HELD, not_held.failure_reason, "ScanSystem rejects products that are not held")


func _test_suspicion_system() -> void:
	var customer: CustomerState = CustomerState.new("suspicion_customer")
	_suspicion_system.setup_customer(customer, _registry.suspicion_curve)
	_expect_equal_int(10, customer.current_suspicion_percent, "SuspicionSystem starts customer at 10 percent")

	var was_caught: bool = _suspicion_system.roll_for_duplicate_scan_with_value(customer, _registry.suspicion_curve, 11)
	_expect_false(was_caught, "SuspicionSystem does not catch rolls above current suspicion")
	_expect_equal_int(50, customer.current_suspicion_percent, "SuspicionSystem raises double-scan suspicion to 50")

	_suspicion_system.roll_for_duplicate_scan_with_value(customer, _registry.suspicion_curve, 51)
	_expect_equal_int(75, customer.current_suspicion_percent, "SuspicionSystem raises next stage to 75")
	_suspicion_system.roll_for_duplicate_scan_with_value(customer, _registry.suspicion_curve, 76)
	_expect_equal_int(90, customer.current_suspicion_percent, "SuspicionSystem raises next stage to 90")
	_suspicion_system.roll_for_duplicate_scan_with_value(customer, _registry.suspicion_curve, 91)
	_expect_equal_int(90, customer.current_suspicion_percent, "SuspicionSystem caps at 90")

	_suspicion_system.setup_customer(customer, _registry.suspicion_curve)
	was_caught = _suspicion_system.roll_for_duplicate_scan_with_value(customer, _registry.suspicion_curve, 10)
	_expect_true(was_caught, "SuspicionSystem catches rolls at or below current suspicion")
	_expect_equal_int(10, customer.current_suspicion_percent, "SuspicionSystem does not advance suspicion after caught roll")
	_expect_equal_int(0, _suspicion_system.get_mood_ring_stage_index(10, _registry.suspicion_curve), "SuspicionSystem maps green mood-ring stage")
	_expect_equal_int(3, _suspicion_system.get_mood_ring_stage_index(90, _registry.suspicion_curve), "SuspicionSystem maps red mood-ring stage")


func _test_economy_system() -> void:
	var run_state: RunState = _create_run_state(1)
	var apple: ProductInstance = ProductInstance.new(_registry.get_product_variant("apple"), "apple_economy")
	var apple_coupon: CouponInstance = CouponInstance.new(_registry.get_coupon("apple_20_discount"), "apple_coupon")
	_coupon_system.mark_coupon_honestly_activated(apple_coupon)
	var honest_coupons: Array[CouponInstance] = [apple_coupon]

	_expect_equal_int(48, _economy_system.calculate_scan_amount_cents(apple, honest_coupons), "EconomySystem applies honest coupon discount")
	_coupon_system.mark_coupon_trashed(apple_coupon)
	_expect_equal_int(60, _economy_system.calculate_scan_amount_cents(apple, honest_coupons), "EconomySystem ignores trashed coupon discount")

	var result: ScanResult = ScanResult.new()
	result.product_instance = apple
	result.is_valid_scan = true
	var no_coupons: Array[CouponInstance] = []
	_economy_system.apply_successful_scan(result, no_coupons)
	_expect_equal_int(1, apple.scan_count, "EconomySystem increases scan count")
	_expect_equal_int(60, apple.open_amount_cents, "EconomySystem increases open amount")

	var payout: PayoutOutcome = _economy_system.payout_product(run_state, apple)
	_expect_equal_int(60, payout.payout_cents, "EconomySystem pays out open product amount")
	_expect_equal_int(1060, run_state.cash_cents, "EconomySystem credits cash only on payout")
	_expect_true(apple.is_processed, "EconomySystem marks paid product processed")

	var trash_product: ProductInstance = ProductInstance.new(_registry.get_product_variant("chips"), "trash_product")
	trash_product.open_amount_cents = 160
	var trash_outcome: PayoutOutcome = _economy_system.trash_product(run_state, trash_product)
	_expect_equal_int(0, trash_outcome.payout_cents, "EconomySystem trash pays no money")
	_expect_equal_int(1060, run_state.cash_cents, "EconomySystem trash leaves cash unchanged")
	_expect_equal_int(0, trash_product.open_amount_cents, "EconomySystem trash clears open amount")
	_expect_equal_string("$10.60", _economy_system.format_cents(run_state.cash_cents), "EconomySystem formats cents for display")


func _test_coupon_system() -> void:
	var run_state: RunState = _create_run_state(2)
	var apple_coupon: CouponResource = _registry.get_coupon("apple_20_discount")
	var energy_coupon: CouponResource = _registry.get_coupon("energy_25_discount")

	_expect_true(_coupon_system.can_purchase_coupon(run_state, apple_coupon, _registry), "CouponSystem allows coupons for current assortment")
	_expect_false(_coupon_system.can_purchase_coupon(run_state, energy_coupon, _registry), "CouponSystem hides coupons for locked products")

	var purchased_coupon: CouponInstance = _coupon_system.purchase_coupon(run_state, apple_coupon, _registry, _registry.game_balance)
	_expect_true(purchased_coupon != null, "CouponSystem purchases affordable coupon")
	_expect_equal_int(800, run_state.cash_cents, "CouponSystem deducts coupon price")
	_expect_equal_int(1, purchased_coupon.activates_on_day, "CouponSystem activates mid-day purchase on next customer day")
	_expect_equal_int(2, purchased_coupon.activates_on_customer_number, "CouponSystem activates mid-day purchase on next customer number")
	_expect_equal_int(1, run_state.pending_coupons.size(), "CouponSystem stores purchased coupon as pending")

	_coupon_system.apply_pending_coupons_for_customer(run_state)
	_expect_equal_int(0, run_state.active_coupons.size(), "CouponSystem does not activate coupon during same customer")
	_expect_equal_int(1, run_state.pending_coupons.size(), "CouponSystem keeps same-customer coupon pending")

	run_state.current_customer_number = 2
	_coupon_system.apply_pending_coupons_for_customer(run_state)
	_expect_equal_int(1, run_state.active_coupons.size(), "CouponSystem activates due pending coupons")
	_expect_equal_int(0, run_state.pending_coupons.size(), "CouponSystem removes activated pending coupons")

	var customer_coupon: CouponInstance = _coupon_system.create_customer_belt_coupon(run_state)
	_expect_true(customer_coupon != null and customer_coupon.instance_id != purchased_coupon.instance_id, "CouponSystem creates customer-scoped belt coupon")
	_coupon_system.mark_coupon_trashed(customer_coupon)
	_expect_true(customer_coupon.was_trashed, "CouponSystem records coupon scam")
	_expect_false(customer_coupon.was_activated_honestly, "CouponSystem keeps trashed coupon from discounting products")

	_coupon_system.expire_coupons_after_day(run_state, 1)
	_expect_equal_int(0, run_state.active_coupons.size(), "CouponSystem expires day coupons at day end")

	var last_customer_run: RunState = _create_run_state(3)
	last_customer_run.current_customer_number = _registry.game_balance.customers_per_day
	var last_customer_coupon: CouponInstance = _coupon_system.purchase_coupon(last_customer_run, apple_coupon, _registry, _registry.game_balance)
	_expect_equal_int(2, last_customer_coupon.activates_on_day, "CouponSystem delays last-customer purchase to next day")
	_expect_equal_int(1, last_customer_coupon.activates_on_customer_number, "CouponSystem delays last-customer purchase to first customer")


func _test_upgrade_system() -> void:
	var run_state: RunState = _create_run_state(4)
	var next_upgrade: UpgradeResource = _upgrade_system.get_next_assortment_upgrade(run_state, _registry.upgrades)
	_expect_true(next_upgrade != null, "UpgradeSystem finds next assortment upgrade")
	_expect_equal_int(2, next_upgrade.target_assortment_level, "UpgradeSystem picks level 2 first")
	_expect_true(_upgrade_system.can_purchase_assortment_upgrade(run_state, next_upgrade), "UpgradeSystem enables affordable next upgrade")

	var was_purchased: bool = _upgrade_system.purchase_assortment_upgrade(run_state, next_upgrade, _registry.game_balance)
	_expect_true(was_purchased, "UpgradeSystem purchases assortment level-up")
	_expect_equal_int(400, run_state.cash_cents, "UpgradeSystem deducts upgrade cost")
	_expect_equal_int(1, run_state.assortment_level, "UpgradeSystem does not apply upgrade during active customer")
	_expect_equal_int(2, run_state.pending_assortment_level, "UpgradeSystem stores pending assortment level")

	_upgrade_system.apply_pending_assortment_for_customer(run_state)
	_expect_equal_int(1, run_state.assortment_level, "UpgradeSystem keeps level pending for same customer")

	run_state.current_customer_number = 2
	_upgrade_system.apply_pending_assortment_for_customer(run_state)
	_expect_equal_int(2, run_state.assortment_level, "UpgradeSystem applies pending level for next customer")

	var level_three_upgrade: UpgradeResource = _upgrade_system.get_next_assortment_upgrade(run_state, _registry.upgrades)
	_expect_false(_upgrade_system.can_purchase_assortment_upgrade(run_state, level_three_upgrade), "UpgradeSystem disables unaffordable next upgrade")


func _test_complete_customer_flow_without_scenes() -> void:
	var run_state: RunState = _create_run_state(5)
	var customer: CustomerState = _generator.generate_customer(_registry, run_state)
	_suspicion_system.setup_customer(customer, _registry.suspicion_curve)
	_belt_system.start_customer(customer, _registry.game_balance.visible_belt_slots)

	while not customer.is_complete:
		var slot_index: int = _belt_system.get_first_occupied_slot_index(customer)
		if slot_index < 0:
			_fail("complete customer flow", "No visible object remained before customer completion.")
			return

		var taken_slot: BeltSlot = _belt_system.take_slot_object(customer, slot_index)
		if taken_slot.slot_kind == BeltSlot.SlotKind.COUPON:
			_coupon_system.mark_coupon_honestly_activated(taken_slot.coupon_instance)
			_belt_system.mark_coupon_processed(customer, taken_slot.coupon_instance, false)
			continue

		var product: ProductInstance = taken_slot.product_instance
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 99
		var scan_result: ScanResult = _scan_system.evaluate_scan(
			_create_scan_request(product, true, true, Vector2.LEFT),
			customer,
			_suspicion_system,
			_registry.suspicion_curve,
			random
		)
		_economy_system.apply_successful_scan(scan_result, _coupon_system.get_honest_customer_coupons(customer))
		_economy_system.payout_product(run_state, product)
		_belt_system.mark_product_processed(customer, product)

	_expect_true(customer.is_complete, "Complete customer flow reaches completion without loading scenes")
	_expect_equal_int(10, customer.processed_product_count, "Complete customer flow processes every product")
	_expect_true(run_state.cash_cents > _registry.game_balance.start_money_cents, "Complete customer flow increases cash through payouts")


func _create_run_state(seed: int) -> RunState:
	var run_state: RunState = RunState.new()
	run_state.apply_balance(_registry.game_balance)
	run_state.run_seed = seed
	return run_state


func _create_customer_with_products(product_count: int) -> CustomerState:
	var customer: CustomerState = CustomerState.new("manual_customer")
	var variants: Array[ProductVariantResource] = [
		_registry.get_product_variant("gum"),
		_registry.get_product_variant("chips"),
		_registry.get_product_variant("apple"),
		_registry.get_product_variant("water"),
	]
	for index: int in range(product_count):
		var variant: ProductVariantResource = variants[index % variants.size()]
		customer.product_queue.append(ProductInstance.new(variant, "manual_p%d_%s" % [index + 1, variant.id]))
	customer.total_product_count = product_count
	return customer


func _create_scan_request(product: ProductInstance, is_held: bool, is_touching_scanner: bool, direction: Vector2) -> ScanRequest:
	var request: ScanRequest = ScanRequest.new()
	request.product_instance = product
	request.is_held = is_held
	request.is_touching_scanner = is_touching_scanner
	request.movement_direction = direction
	return request


func _product_ids(products: Array[ProductInstance]) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for product: ProductInstance in products:
		ids.append(product.variant.id)
	return ids


func _count_generated_product(product_id: String, sample_count: int, active_coupons: Array[CouponInstance]) -> int:
	var count: int = 0
	for index: int in range(sample_count):
		var customer: CustomerState = _generator.generate_customer_for_context(
			_registry,
			9000 + index,
			2,
			1,
			1,
			active_coupons,
			_registry.game_balance.products_per_customer
		)
		for product: ProductInstance in customer.product_queue:
			if product.variant.id == product_id:
				count += 1

	return count


func _has_product_at_assortment_level(customer: CustomerState, assortment_level: int) -> bool:
	for product: ProductInstance in customer.product_queue:
		if product.variant != null and product.variant.assortment_level == assortment_level:
			return true
	return false


func _expect_true(value: bool, label: String) -> void:
	if not value:
		_fail(label, "Expected true.")


func _expect_false(value: bool, label: String) -> void:
	if value:
		_fail(label, "Expected false.")


func _expect_equal_int(expected: int, actual: int, label: String) -> void:
	if expected != actual:
		_fail(label, "Expected %d, got %d." % [expected, actual])


func _expect_equal_string(expected: String, actual: String, label: String) -> void:
	if expected != actual:
		_fail(label, "Expected '%s', got '%s'." % [expected, actual])


func _expect_string_arrays_equal(expected: PackedStringArray, actual: PackedStringArray, label: String) -> void:
	if expected.size() != actual.size():
		_fail(label, "Expected %s, got %s." % [str(expected), str(actual)])
		return

	for index: int in range(expected.size()):
		if expected[index] != actual[index]:
			_fail(label, "Expected %s, got %s." % [str(expected), str(actual)])
			return


func _fail(label: String, message: String) -> void:
	_failure_count += 1
	push_error("%s: %s" % [label, message])
