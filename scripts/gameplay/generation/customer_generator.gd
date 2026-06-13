extends RefCounted
class_name CustomerGenerator

const FIRST_CUSTOMER_TYPE_ID: String = "jimmy"


func generate_customer(registry: ContentRegistry, run_state: RunState) -> CustomerState:
	if registry == null or registry.game_balance == null or run_state == null:
		push_error("CustomerGenerator needs a loaded ContentRegistry, GameBalanceResource and RunState.")
		return CustomerState.new("invalid_customer")

	var customer: CustomerState = generate_customer_for_context(
		registry,
		run_state.run_seed,
		run_state.current_day,
		run_state.current_customer_number,
		run_state.assortment_level,
		run_state.active_coupons,
		registry.game_balance.products_per_customer,
		run_state.last_customer_type_id
	)
	if customer.customer_type != null:
		run_state.last_customer_type_id = customer.customer_type.id

	return customer


func generate_customer_for_context(
	registry: ContentRegistry,
	run_seed: int,
	day: int,
	customer_number: int,
	assortment_level: int,
	active_coupons: Array[CouponInstance],
	product_count: int,
	last_customer_type_id: String = ""
) -> CustomerState:
	var customer: CustomerState = CustomerState.new("day_%d_customer_%d" % [day, customer_number])
	customer.total_product_count = product_count

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = _build_customer_seed(run_seed, day, customer_number, assortment_level)

	var customer_type: CustomerTypeResource = _select_customer_type(registry, day, customer_number, last_customer_type_id, random)
	if customer_type == null:
		push_error("CustomerGenerator could not select a customer type.")
		return customer

	customer.customer_type = customer_type

	while customer.product_queue.size() < product_count:
		var product: ProductVariantResource = _select_weighted_product(
			registry,
			assortment_level,
			active_coupons,
			customer_type,
			random
		)
		if product == null:
			push_error("CustomerGenerator could not select a product for customer type '%s' at assortment level %d." % [customer_type.id, assortment_level])
			return customer

		customer.product_queue.append(_create_product_instance(product, run_seed, day, customer_number, customer.product_queue.size()))

	return customer


static func get_products_for_customer_type(
	available_products: Array[ProductVariantResource],
	customer_type: CustomerTypeResource
) -> Array[ProductVariantResource]:
	var sorted_products: Array[ProductVariantResource] = []
	for product: ProductVariantResource in available_products:
		if product != null:
			sorted_products.append(product)

	if sorted_products.is_empty() or customer_type == null:
		return sorted_products

	_sort_products_by_expected_unit_value(sorted_products)

	var product_count: int = sorted_products.size()
	var start_index: int = floori(float(product_count * customer_type.price_percentile_min) / 100.0)
	var end_index: int = ceili(float(product_count * customer_type.price_percentile_max) / 100.0)
	start_index = clampi(start_index, 0, product_count - 1)
	end_index = clampi(end_index, start_index + 1, product_count)

	var filtered_products: Array[ProductVariantResource] = []
	for index: int in range(start_index, end_index):
		filtered_products.append(sorted_products[index])
	return filtered_products


func _select_weighted_product(
	registry: ContentRegistry,
	assortment_level: int,
	active_coupons: Array[CouponInstance],
	customer_type: CustomerTypeResource,
	random: RandomNumberGenerator
) -> ProductVariantResource:
	var available_products: Array[ProductVariantResource] = []
	for product: ProductVariantResource in registry.product_variants:
		if product.is_available_at_assortment_level(assortment_level):
			available_products.append(product)

	var customer_products: Array[ProductVariantResource] = get_products_for_customer_type(available_products, customer_type)
	var effective_weights: Array[int] = []
	var total_weight: int = 0

	for product: ProductVariantResource in customer_products:
		var effective_weight: int = _get_effective_product_weight(product, active_coupons)
		effective_weights.append(effective_weight)
		total_weight += effective_weight

	if customer_products.is_empty() or total_weight <= 0:
		return null

	var roll: int = random.randi_range(1, total_weight)
	var running_weight: int = 0
	for index: int in range(customer_products.size()):
		running_weight += effective_weights[index]
		if roll <= running_weight:
			return customer_products[index]

	return customer_products[customer_products.size() - 1]


func _select_customer_type(
	registry: ContentRegistry,
	day: int,
	customer_number: int,
	last_customer_type_id: String,
	random: RandomNumberGenerator
) -> CustomerTypeResource:
	if day == 1 and customer_number == 1:
		return registry.get_customer_type(FIRST_CUSTOMER_TYPE_ID)

	var candidates: Array[CustomerTypeResource] = []
	for customer_type: CustomerTypeResource in registry.customer_types:
		if customer_type != null and customer_type.id != last_customer_type_id:
			candidates.append(customer_type)

	if candidates.is_empty():
		for customer_type: CustomerTypeResource in registry.customer_types:
			if customer_type != null:
				candidates.append(customer_type)

	if candidates.is_empty():
		return null

	return candidates[random.randi_range(0, candidates.size() - 1)]


static func _sort_products_by_expected_unit_value(products: Array[ProductVariantResource]) -> void:
	for index: int in range(1, products.size()):
		var current_product: ProductVariantResource = products[index]
		var previous_index: int = index - 1
		while previous_index >= 0 and _is_product_before(current_product, products[previous_index]):
			products[previous_index + 1] = products[previous_index]
			previous_index -= 1
		products[previous_index + 1] = current_product


static func _is_product_before(left: ProductVariantResource, right: ProductVariantResource) -> bool:
	var left_value: int = left.get_expected_unit_value_cents()
	var right_value: int = right.get_expected_unit_value_cents()
	if left_value != right_value:
		return left_value < right_value
	return left.id.naturalnocasecmp_to(right.id) < 0


func _get_effective_product_weight(product: ProductVariantResource, active_coupons: Array[CouponInstance]) -> int:
	var effective_weight: int = product.generator_weight
	for coupon_instance: CouponInstance in active_coupons:
		if coupon_instance == null or coupon_instance.coupon == null:
			continue
		if CouponSystem.coupon_matches_product_resource(coupon_instance.coupon, product):
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
	if product.is_weighable():
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
