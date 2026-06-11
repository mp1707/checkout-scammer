extends RefCounted
class_name CustomerGenerator

const CouponSystemScript = preload("res://scripts/gameplay/systems/coupon_system.gd")

const PRODUCT_ID_APPLE: String = "apple"
const PRODUCT_ID_BANANA: String = "banana"
const PRODUCT_ID_CANDY: String = "candy"
const PRODUCT_ID_CHEWING_GUM: String = "chewing_gum"
const PRODUCT_ID_ORANGE: String = "orange"
const PRODUCT_ID_TISSUE: String = "tissue"


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
		_append_scripted_products(customer, scripted_ids, registry, product_count, run_seed, day, customer_number)

	while customer.product_queue.size() < product_count:
		var product: ProductVariantResource = _select_weighted_product(registry, assortment_level, active_coupons, random)
		if product == null:
			push_error("CustomerGenerator could not select a product for assortment level %d." % assortment_level)
			return customer

		customer.product_queue.append(_create_product_instance(product, run_seed, day, customer_number, customer.product_queue.size()))

	return customer


func _append_scripted_products(
	customer: CustomerState,
	scripted_ids: PackedStringArray,
	registry: ContentRegistry,
	product_count: int,
	run_seed: int,
	day: int,
	customer_number: int
) -> void:
	var scripted_count: int = mini(scripted_ids.size(), product_count)
	for index: int in range(scripted_count):
		var product: ProductVariantResource = registry.get_product_variant(scripted_ids[index])
		if product == null:
			push_error("Scripted customer references missing product '%s'." % scripted_ids[index])
			continue

		customer.product_queue.append(_create_product_instance(product, run_seed, day, customer_number, index))


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


func _create_product_instance(
	product: ProductVariantResource,
	run_seed: int,
	day: int,
	customer_number: int,
	product_index: int
) -> ProductInstance:
	var instance_id: String = "d%d_c%d_p%d_%s" % [day, customer_number, product_index + 1, product.id]
	var product_instance: ProductInstance = ProductInstance.new(product, instance_id)
	if product != null and product.is_weighable():
		product_instance.weight_grams = _generate_weight_grams(product, run_seed, day, customer_number, product_index)
	return product_instance


func _generate_weight_grams(
	product: ProductVariantResource,
	run_seed: int,
	day: int,
	customer_number: int,
	product_index: int
) -> int:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = _build_weight_seed(run_seed, day, customer_number, product_index, product.id)

	var normalized_roll: float = pow(random.randf(), product.weight_distribution_power)
	var raw_weight: float = float(product.min_weight_grams) + float(product.max_weight_grams - product.min_weight_grams) * normalized_roll
	var weight_step: int = maxi(1, product.weight_step_grams)
	var rounded_weight: int = roundi(raw_weight / float(weight_step)) * weight_step
	return clampi(rounded_weight, product.min_weight_grams, product.max_weight_grams)


func _build_customer_seed(run_seed: int, day: int, customer_number: int, assortment_level: int) -> int:
	var seed_value: int = run_seed * 73856093 + day * 19349663 + customer_number * 83492791 + assortment_level * 2654435761
	if seed_value < 0:
		seed_value = -seed_value
	return seed_value


func _build_weight_seed(run_seed: int, day: int, customer_number: int, product_index: int, product_id: String) -> int:
	var seed_value: int = (
		run_seed * 92837111
		+ day * 689287499
		+ customer_number * 283923481
		+ (product_index + 1) * 97531
		+ _stable_string_hash(product_id)
	)
	if seed_value < 0:
		seed_value = -seed_value
	return seed_value


func _stable_string_hash(text: String) -> int:
	var hash_value: int = 17
	for index: int in range(text.length()):
		hash_value = hash_value * 31 + text.unicode_at(index)
	if hash_value < 0:
		hash_value = -hash_value
	return hash_value


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
				PRODUCT_ID_APPLE,
				PRODUCT_ID_CHEWING_GUM,
				PRODUCT_ID_ORANGE,
				PRODUCT_ID_CANDY,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_TISSUE,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_ORANGE,
				PRODUCT_ID_CHEWING_GUM,
			])
		2:
			return PackedStringArray([
				PRODUCT_ID_BANANA,
				PRODUCT_ID_ORANGE,
				PRODUCT_ID_TISSUE,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_CANDY,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_ORANGE,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_CHEWING_GUM,
				PRODUCT_ID_TISSUE,
			])
		3:
			return PackedStringArray([
				PRODUCT_ID_APPLE,
				PRODUCT_ID_CANDY,
				PRODUCT_ID_ORANGE,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_CHEWING_GUM,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_TISSUE,
				PRODUCT_ID_BANANA,
				PRODUCT_ID_APPLE,
				PRODUCT_ID_ORANGE,
			])
		_:
			return PackedStringArray()
