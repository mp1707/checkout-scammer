extends RefCounted
class_name CustomerGenerator

const CouponSystemScript = preload("res://scripts/gameplay/systems/coupon_system.gd")

const PRODUCT_ID_APPLE: String = "apple"
const PRODUCT_ID_BANANA: String = "banana"
const PRODUCT_ID_CHIPS: String = "chips"
const PRODUCT_ID_GUM: String = "gum"
const PRODUCT_ID_WATER: String = "water"


func generate_customer(registry: ContentRegistry, run_state: RunState) -> CustomerState:
	if registry == null or registry.game_balance == null:
		push_error("CustomerGenerator needs a loaded ContentRegistry with GameBalanceResource.")
		return CustomerState.new("invalid_customer")

	return generate_customer_for_context(
		registry,
		run_state.run_seed,
		run_state.current_day,
		run_state.current_customer_number,
		run_state.assortment_level,
		run_state.active_coupons,
		registry.game_balance.products_per_customer,
		registry.game_balance.starting_assortment_level
	)


func generate_customer_for_context(
	registry: ContentRegistry,
	run_seed: int,
	day: int,
	customer_number: int,
	assortment_level: int,
	active_coupons: Array[CouponInstance],
	product_count: int,
	scripted_assortment_level: int = 1
) -> CustomerState:
	var customer: CustomerState = CustomerState.new("day_%d_customer_%d" % [day, customer_number])
	customer.total_product_count = product_count

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = _build_customer_seed(run_seed, day, customer_number, assortment_level)

	var scripted_ids: PackedStringArray = _get_scripted_first_day_product_ids(
		day,
		customer_number,
		assortment_level,
		scripted_assortment_level
	)
	if not scripted_ids.is_empty():
		_append_scripted_products(customer, scripted_ids, registry, product_count, day, customer_number)

	while customer.product_queue.size() < product_count:
		var product: ProductVariantResource = _select_weighted_product(registry, assortment_level, active_coupons, random)
		if product == null:
			push_error("CustomerGenerator could not select a product for assortment level %d." % assortment_level)
			return customer

		customer.product_queue.append(_create_product_instance(product, day, customer_number, customer.product_queue.size()))

	return customer


func _append_scripted_products(
	customer: CustomerState,
	scripted_ids: PackedStringArray,
	registry: ContentRegistry,
	product_count: int,
	day: int,
	customer_number: int
) -> void:
	var scripted_count: int = mini(scripted_ids.size(), product_count)
	for index: int in range(scripted_count):
		var product: ProductVariantResource = registry.get_product_variant(scripted_ids[index])
		if product == null:
			push_error("Scripted customer references missing product '%s'." % scripted_ids[index])
			continue

		customer.product_queue.append(_create_product_instance(product, day, customer_number, index))


func _select_weighted_product(
	registry: ContentRegistry,
	assortment_level: int,
	active_coupons: Array[CouponInstance],
	random: RandomNumberGenerator
) -> ProductVariantResource:
	var available_products: Array[ProductVariantResource] = []
	var effective_weights: Array[int] = []
	var total_weight: int = 0

	for product: ProductVariantResource in registry.product_variants:
		if not product.is_available_at_assortment_level(assortment_level):
			continue

		var effective_weight: int = _get_effective_product_weight(product, active_coupons)
		available_products.append(product)
		effective_weights.append(effective_weight)
		total_weight += effective_weight

	if available_products.is_empty() or total_weight <= 0:
		return null

	var roll: int = random.randi_range(1, total_weight)
	var running_weight: int = 0
	for index: int in range(available_products.size()):
		running_weight += effective_weights[index]
		if roll <= running_weight:
			return available_products[index]

	return available_products[available_products.size() - 1]


func _get_effective_product_weight(product: ProductVariantResource, active_coupons: Array[CouponInstance]) -> int:
	var effective_weight: int = product.generator_weight
	for coupon_instance: CouponInstance in active_coupons:
		if coupon_instance == null or coupon_instance.coupon == null:
			continue
		if CouponSystemScript.coupon_matches_product_resource(coupon_instance.coupon, product):
			effective_weight = maxi(1, floori(float(effective_weight * coupon_instance.coupon.weight_multiplier_percent) / 100.0))

	return effective_weight


func _create_product_instance(product: ProductVariantResource, day: int, customer_number: int, product_index: int) -> ProductInstance:
	var instance_id: String = "d%d_c%d_p%d_%s" % [day, customer_number, product_index + 1, product.id]
	return ProductInstance.new(product, instance_id)


func _build_customer_seed(run_seed: int, day: int, customer_number: int, assortment_level: int) -> int:
	var seed_value: int = run_seed * 73856093 + day * 19349663 + customer_number * 83492791 + assortment_level * 2654435761
	if seed_value < 0:
		seed_value = -seed_value
	return seed_value


func _get_scripted_first_day_product_ids(
	day: int,
	customer_number: int,
	assortment_level: int,
	scripted_assortment_level: int
) -> PackedStringArray:
	if day != 1 or assortment_level != scripted_assortment_level:
		return PackedStringArray()

	match customer_number:
		1:
			return PackedStringArray([
				PRODUCT_ID_GUM,
				PRODUCT_ID_GUM,
				PRODUCT_ID_CHIPS,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_WATER,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_GUM,
				PRODUCT_ID_CHIPS,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_WATER,
			])
		2:
			return PackedStringArray([
				PRODUCT_ID_BANANA,
				PRODUCT_ID_GUM,
				PRODUCT_ID_CHIPS,
				PRODUCT_ID_WATER,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_GUM,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_CHIPS,
				PRODUCT_ID_WATER,
				PRODUCT_ID_GUM,
			])
		3:
			return PackedStringArray([
				PRODUCT_ID_CHIPS,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_WATER,
				PRODUCT_ID_GUM,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_CHIPS,
				PRODUCT_ID_GUM,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_WATER,
				PRODUCT_ID_GUM,
			])
		_:
			return PackedStringArray()
