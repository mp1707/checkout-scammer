extends "res://tests/checkout_test_base.gd"
class_name SimulationSystemsTest

var _registry: ContentRegistry
var _generator: CustomerGenerator
var _visible_object_queue_system: VisibleObjectQueueSystem
var _scan_system: ScanSystem
var _suspicion_system: SuspicionSystem
var _economy_system: EconomySystem
var _coupon_system: CouponSystem
var _upgrade_system: UpgradeSystem
var _sticker_system: StickerSystem


func _initialize() -> void:
	_registry = ContentRegistry.new()
	var content_errors: PackedStringArray = _registry.load_all()
	for message: String in content_errors:
		_fail("content validation", message)

	_generator = CustomerGenerator.new()
	_visible_object_queue_system = VisibleObjectQueueSystem.new()
	_scan_system = ScanSystem.new()
	_suspicion_system = SuspicionSystem.new()
	_economy_system = EconomySystem.new()
	_coupon_system = CouponSystem.new()
	_upgrade_system = UpgradeSystem.new()
	_sticker_system = StickerSystem.new()

	_test_customer_generator()
	_test_visible_object_queue_system()
	_test_scan_system()
	_test_suspicion_system()
	_test_economy_system()
	_test_coupon_system()
	_test_upgrade_system()
	_test_sticker_system()
	_test_complete_customer_flow_without_scenes()

	_finish_suite("Simulation system tests")


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
		PackedStringArray(["apple", "chewing_gum", "orange", "candy", "banana", "tissue", "apple", "banana", "orange", "chewing_gum"]),
		_product_ids(scripted_customer.product_queue),
		"CustomerGenerator models scripted first customer"
	)
	_expect_true(_all_weighed_products_have_valid_weights(scripted_customer.product_queue), "CustomerGenerator assigns valid fruit weights")

	var no_active_coupons_for_upgrade: Array[CouponInstance] = []
	var upgraded_first_day_customer: CustomerState = _generator.generate_customer_for_context(
		_registry,
		_registry.game_balance.default_run_seed,
		1,
		2,
		2,
		no_active_coupons_for_upgrade,
		_registry.game_balance.products_per_customer
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


func _test_visible_object_queue_system() -> void:
	var customer: CustomerState = _create_customer_with_products(10)
	var coupon_instance: CouponInstance = CouponInstance.new(_registry.get_coupon("apple_20_discount"), "visible_coupon")
	_visible_object_queue_system.start_customer(customer, 4, coupon_instance)

	_expect_equal_int(4, customer.visible_slots.size(), "VisibleObjectQueueSystem creates visible slot records")
	_expect_equal_int(VisibleObjectSlot.SlotKind.COUPON, customer.visible_slots[0].slot_kind, "VisibleObjectQueueSystem puts coupon first")
	_expect_equal_int(3, _visible_object_queue_system.get_visible_product_count(customer), "VisibleObjectQueueSystem fills remaining slots with products")
	_expect_equal_int(7, customer.product_queue.size(), "VisibleObjectQueueSystem keeps hidden queue after visible fill")

	var taken_product_slot: VisibleObjectSlot = _visible_object_queue_system.take_slot_object(customer, 2)
	_expect_equal_int(VisibleObjectSlot.SlotKind.PRODUCT, taken_product_slot.slot_kind, "VisibleObjectQueueSystem allows free product slot selection")
	_expect_true(customer.visible_slots[2].is_taken, "VisibleObjectQueueSystem keeps taken product slot reserved")
	_expect_equal_int(7, customer.product_queue.size(), "VisibleObjectQueueSystem waits to advance queue until product is processed")

	_visible_object_queue_system.mark_product_processed(customer, taken_product_slot.product_instance)
	_expect_equal_int(VisibleObjectSlot.SlotKind.PRODUCT, customer.visible_slots[2].slot_kind, "VisibleObjectQueueSystem refills selected product slot after processing")
	_expect_equal_int(6, customer.product_queue.size(), "VisibleObjectQueueSystem advances queue after product processing")

	var taken_coupon_slot: VisibleObjectSlot = _visible_object_queue_system.take_slot_object(customer, 0)
	_expect_equal_int(VisibleObjectSlot.SlotKind.COUPON, taken_coupon_slot.slot_kind, "VisibleObjectQueueSystem allows coupon processing")
	_expect_true(customer.visible_slots[0].is_taken, "VisibleObjectQueueSystem keeps taken coupon slot reserved")
	_expect_equal_int(6, customer.product_queue.size(), "VisibleObjectQueueSystem waits to refill coupon slot until processed")

	_visible_object_queue_system.mark_coupon_processed(customer, taken_coupon_slot.coupon_instance, false)
	_expect_equal_int(VisibleObjectSlot.SlotKind.PRODUCT, customer.visible_slots[0].slot_kind, "VisibleObjectQueueSystem refills coupon slot with product after processing")
	_expect_equal_int(5, customer.product_queue.size(), "VisibleObjectQueueSystem refills coupon slot from product queue")
	_expect_equal_int(10, customer.total_product_count, "VisibleObjectQueueSystem coupon does not count against total product count")
	_expect_equal_int(1, customer.processed_product_count, "VisibleObjectQueueSystem counts processed products")


func _test_scan_system() -> void:
	var customer: CustomerState = CustomerState.new("scan_customer")
	_suspicion_system.setup_customer(customer, _registry.suspicion_curve)
	var product: ProductInstance = ProductInstance.new(_registry.get_product_variant("chewing_gum"), "scan_product")
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
	_expect_equal_int(ScanResult.FailureReason.WRONG_DIRECTION, wrong_direction.failure_reason, "ScanSystem rejects left-to-right movement")

	var not_touching: ScanResult = _scan_system.evaluate_scan(
		_create_scan_request(product, true, false, Vector2.LEFT),
		customer,
		_suspicion_system,
		_registry.suspicion_curve,
		random
	)
	_expect_equal_int(ScanResult.FailureReason.NOT_TOUCHING_SCANNER, not_touching.failure_reason, "ScanSystem rejects missing scanner contact")

	var not_held: ScanResult = _scan_system.evaluate_scan(
		_create_scan_request(product, false, true, Vector2.LEFT),
		customer,
		_suspicion_system,
		_registry.suspicion_curve,
		random
	)
	_expect_equal_int(ScanResult.FailureReason.NOT_HELD, not_held.failure_reason, "ScanSystem rejects products that are not held")

	var apple: ProductInstance = ProductInstance.new(_registry.get_product_variant("apple"), "weighable_scan_product")
	var weighed_scan: ScanResult = _scan_system.evaluate_scan(
		_create_scan_request(apple, true, true, Vector2.LEFT),
		customer,
		_suspicion_system,
		_registry.suspicion_curve,
		random
	)
	_expect_equal_int(ScanResult.FailureReason.PRODUCT_WEIGHABLE, weighed_scan.failure_reason, "ScanSystem rejects fruit scanner sales")


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
	_expect_equal_int(0, _suspicion_system.get_customer_hand_stage_index(10, _registry.suspicion_curve), "SuspicionSystem maps green hand stage")
	_expect_equal_int(1, _suspicion_system.get_customer_hand_stage_index(50, _registry.suspicion_curve), "SuspicionSystem maps yellow hand stage")
	_expect_equal_int(2, _suspicion_system.get_customer_hand_stage_index(75, _registry.suspicion_curve), "SuspicionSystem maps red hand stage")


func _test_economy_system() -> void:
	var run_state: RunState = _create_run_state(1)
	var apple: ProductInstance = ProductInstance.new(_registry.get_product_variant("apple"), "apple_economy")
	apple.weight_grams = 200
	var apple_coupon: CouponInstance = CouponInstance.new(_registry.get_coupon("apple_20_discount"), "apple_coupon")
	_coupon_system.mark_coupon_honestly_activated(apple_coupon)
	var honest_coupons: Array[CouponInstance] = [apple_coupon]

	_expect_equal_int(48, _economy_system.calculate_weighed_amount_cents(apple, honest_coupons), "EconomySystem applies honest coupon discount to weighed fruit")
	_coupon_system.mark_coupon_trashed(apple_coupon)
	_expect_equal_int(60, _economy_system.calculate_weighed_amount_cents(apple, honest_coupons), "EconomySystem ignores trashed coupon discount on weighed fruit")

	var bio_sticker: StickerResource = _registry.get_sticker("bio_sticker")
	apple.add_sticker(StickerInstance.new(bio_sticker, "apple_bio"))
	_expect_equal_int(180, _economy_system.calculate_weighed_amount_cents(apple, honest_coupons), "EconomySystem applies sticker multipliers to weighed charges")
	apple.scan_count = 1
	apple.open_amount_cents = 60
	_expect_equal_int(180, _economy_system.refresh_weighed_open_amount(apple, honest_coupons), "EconomySystem refreshes open weighed amount after sticker changes")

	var fixed_product: ProductInstance = ProductInstance.new(_registry.get_product_variant("chewing_gum"), "gum_economy")

	var result: ScanResult = ScanResult.new()
	result.product_instance = fixed_product
	result.is_valid_scan = true
	var no_coupons: Array[CouponInstance] = []
	_economy_system.apply_successful_scan(result, no_coupons)
	_expect_equal_int(1, fixed_product.scan_count, "EconomySystem increases scan count")
	_expect_equal_int(95, fixed_product.open_amount_cents, "EconomySystem increases fixed product open amount")

	var payout: PayoutOutcome = _economy_system.payout_product(run_state, fixed_product)
	_expect_equal_int(95, payout.payout_cents, "EconomySystem pays out open product amount")
	_expect_equal_int(1095, run_state.cash_cents, "EconomySystem credits cash only on payout")
	_expect_true(fixed_product.is_processed, "EconomySystem marks paid product processed")

	var trash_product: ProductInstance = ProductInstance.new(_registry.get_product_variant("orange"), "trash_product")
	trash_product.open_amount_cents = 160
	var trash_outcome: PayoutOutcome = _economy_system.trash_product(run_state, trash_product)
	_expect_equal_int(0, trash_outcome.payout_cents, "EconomySystem trash pays no money")
	_expect_equal_int(1095, run_state.cash_cents, "EconomySystem trash leaves cash unchanged")
	_expect_equal_int(0, trash_product.open_amount_cents, "EconomySystem trash clears open amount")
	_expect_equal_string("$10.95", _economy_system.format_cents(run_state.cash_cents), "EconomySystem formats cents for display")


func _test_coupon_system() -> void:
	var run_state: RunState = _create_run_state(2)
	var apple_coupon: CouponResource = _registry.get_coupon("apple_20_discount")
	var brown_snackbar_coupon: CouponResource = _registry.get_coupon("brown_snackbar_15_discount")

	_expect_true(_coupon_system.can_purchase_coupon(run_state, apple_coupon, _registry), "CouponSystem allows coupons for current assortment")
	_expect_false(_coupon_system.can_purchase_coupon(run_state, brown_snackbar_coupon, _registry), "CouponSystem hides coupons for locked products")

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

	var customer_coupon: CouponInstance = _coupon_system.create_customer_visible_coupon(run_state)
	_expect_true(customer_coupon != null and customer_coupon.instance_id != purchased_coupon.instance_id, "CouponSystem creates customer-scoped visible coupon")
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

	var further_upgrade: UpgradeResource = _upgrade_system.get_next_assortment_upgrade(run_state, _registry.upgrades)
	_expect_true(further_upgrade == null, "UpgradeSystem has no further assortment level without new product art")


func _test_sticker_system() -> void:
	var run_state: RunState = _create_run_state(6)
	_sticker_system.setup_run_inventory(run_state, _registry.stickers)
	_expect_equal_int(3, _sticker_system.get_sticker_count(run_state, "bio_sticker"), "StickerSystem starts day with three bio stickers")

	var apple: ProductInstance = ProductInstance.new(_registry.get_product_variant("apple"), "sticker_apple")
	var sticker_instance: StickerInstance = _sticker_system.apply_sticker(run_state, "bio_sticker", apple)
	_expect_true(sticker_instance != null, "StickerSystem applies bio sticker to fruit")
	_expect_equal_int(2, _sticker_system.get_sticker_count(run_state, "bio_sticker"), "StickerSystem consumes applied sticker")
	_expect_equal_int(300, apple.get_price_multiplier_percent(), "StickerSystem stores sticker multiplier on product")

	var second_same_sticker: StickerInstance = _sticker_system.apply_sticker(run_state, "bio_sticker", apple)
	_expect_true(second_same_sticker == null, "StickerSystem rejects duplicate bio sticker on one fruit")
	_expect_equal_int(2, _sticker_system.get_sticker_count(run_state, "bio_sticker"), "StickerSystem does not consume rejected duplicate")

	var gum: ProductInstance = ProductInstance.new(_registry.get_product_variant("chewing_gum"), "sticker_gum")
	var rejected_sticker: StickerInstance = _sticker_system.apply_sticker(run_state, "bio_sticker", gum)
	_expect_true(rejected_sticker == null, "StickerSystem rejects bio sticker on fixed-price products")

	_sticker_system.refill_daily(run_state)
	_expect_equal_int(3, _sticker_system.get_sticker_count(run_state, "bio_sticker"), "StickerSystem refills bio stickers each day")


func _test_complete_customer_flow_without_scenes() -> void:
	var run_state: RunState = _create_run_state(5)
	var customer: CustomerState = _generator.generate_customer(_registry, run_state)
	_suspicion_system.setup_customer(customer, _registry.suspicion_curve)
	_visible_object_queue_system.start_customer(customer, _registry.game_balance.visible_object_slots)

	while not customer.is_complete:
		var slot_index: int = _visible_object_queue_system.get_first_occupied_slot_index(customer)
		if slot_index < 0:
			_fail("complete customer flow", "No visible object remained before customer completion.")
			return

		var taken_slot: VisibleObjectSlot = _visible_object_queue_system.take_slot_object(customer, slot_index)
		if taken_slot.slot_kind == VisibleObjectSlot.SlotKind.COUPON:
			_coupon_system.mark_coupon_honestly_activated(taken_slot.coupon_instance)
			_visible_object_queue_system.mark_coupon_processed(customer, taken_slot.coupon_instance, false)
			continue

		var product: ProductInstance = taken_slot.product_instance
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 99
		if product.is_weighable():
			var weigh_result: ScanResult = _scan_system.evaluate_product_charge_attempt(
				product,
				customer,
				_suspicion_system,
				_registry.suspicion_curve,
				random
			)
			_economy_system.apply_successful_weighing(weigh_result, _coupon_system.get_honest_customer_coupons(customer))
		else:
			var scan_result: ScanResult = _scan_system.evaluate_scan(
				_create_scan_request(product, true, true, Vector2.LEFT),
				customer,
				_suspicion_system,
				_registry.suspicion_curve,
				random
			)
			_economy_system.apply_successful_scan(scan_result, _coupon_system.get_honest_customer_coupons(customer))
		_economy_system.payout_product(run_state, product)
		_visible_object_queue_system.mark_product_processed(customer, product)

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
		_registry.get_product_variant("apple"),
		_registry.get_product_variant("orange"),
		_registry.get_product_variant("banana"),
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


func _all_weighed_products_have_valid_weights(products: Array[ProductInstance]) -> bool:
	for product: ProductInstance in products:
		if product == null or product.variant == null or not product.variant.is_weighable():
			continue
		if product.weight_grams < product.variant.min_weight_grams:
			return false
		if product.weight_grams > product.variant.max_weight_grams:
			return false
		if product.weight_grams % product.variant.weight_step_grams != 0:
			return false
	return true


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

