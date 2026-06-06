extends RefCounted
class_name CouponSystem


func can_purchase_coupon(run_state: RunState, coupon: CouponResource, registry: ContentRegistry) -> bool:
	if run_state == null or coupon == null or registry == null:
		return false
	if run_state.cash_cents < coupon.purchase_price_cents:
		return false
	if _has_coupon_with_id(run_state.active_coupons, coupon.id) or _has_coupon_with_id(run_state.pending_coupons, coupon.id):
		return false

	return coupon_is_available_for_assortment(coupon, registry.product_variants, run_state.assortment_level)


func purchase_coupon(
	run_state: RunState,
	coupon: CouponResource,
	registry: ContentRegistry,
	balance: GameBalanceResource
) -> CouponInstance:
	if not can_purchase_coupon(run_state, coupon, registry):
		return null

	var activation_context: Vector2i = _get_next_customer_context(run_state, balance)
	var coupon_instance: CouponInstance = CouponInstance.new(coupon, "coupon_%s_d%d_c%d" % [
		coupon.id,
		run_state.current_day,
		run_state.current_customer_number,
	])
	coupon_instance.activates_on_day = activation_context.x
	coupon_instance.activates_on_customer_number = activation_context.y
	coupon_instance.expires_after_day = activation_context.x + coupon.duration_days - 1
	coupon_instance.is_active = false

	run_state.cash_cents -= coupon.purchase_price_cents
	run_state.pending_coupons.append(coupon_instance)
	return coupon_instance


func apply_pending_coupons_for_customer(run_state: RunState) -> void:
	if run_state == null:
		return

	_filter_active_coupons_for_day(run_state, run_state.current_day)

	var still_pending: Array[CouponInstance] = []
	for coupon_instance: CouponInstance in run_state.pending_coupons:
		if _is_activation_due(
			coupon_instance.activates_on_day,
			coupon_instance.activates_on_customer_number,
			run_state.current_day,
			run_state.current_customer_number
		):
			coupon_instance.is_active = true
			run_state.active_coupons.append(coupon_instance)
		else:
			still_pending.append(coupon_instance)

	run_state.pending_coupons = still_pending


func expire_coupons_after_day(run_state: RunState, completed_day: int) -> void:
	if run_state == null:
		return

	var still_active: Array[CouponInstance] = []
	for coupon_instance: CouponInstance in run_state.active_coupons:
		if coupon_instance.expires_after_day > completed_day:
			still_active.append(coupon_instance)
		else:
			coupon_instance.is_active = false

	run_state.active_coupons = still_active


func create_customer_visible_coupon(run_state: RunState) -> CouponInstance:
	if run_state == null:
		return null

	_filter_active_coupons_for_day(run_state, run_state.current_day)
	if run_state.active_coupons.is_empty():
		return null

	var active_coupon: CouponInstance = run_state.active_coupons[0]
	var customer_coupon: CouponInstance = CouponInstance.new(active_coupon.coupon, "%s_for_d%d_c%d" % [
		active_coupon.instance_id,
		run_state.current_day,
		run_state.current_customer_number,
	])
	customer_coupon.is_active = true
	customer_coupon.activates_on_day = active_coupon.activates_on_day
	customer_coupon.activates_on_customer_number = active_coupon.activates_on_customer_number
	customer_coupon.expires_after_day = active_coupon.expires_after_day
	return customer_coupon


func mark_coupon_honestly_activated(coupon_instance: CouponInstance) -> void:
	if coupon_instance == null:
		return

	coupon_instance.was_activated_honestly = true
	coupon_instance.was_trashed = false


func mark_coupon_trashed(coupon_instance: CouponInstance) -> void:
	if coupon_instance == null:
		return

	coupon_instance.was_activated_honestly = false
	coupon_instance.was_trashed = true


func get_honest_customer_coupons(customer: CustomerState) -> Array[CouponInstance]:
	var honest_coupons: Array[CouponInstance] = []
	if customer != null and customer.coupon_instance != null and customer.coupon_instance.was_activated_honestly:
		honest_coupons.append(customer.coupon_instance)

	return honest_coupons


func coupon_is_available_for_assortment(
	coupon: CouponResource,
	products: Array[ProductVariantResource],
	assortment_level: int
) -> bool:
	if coupon == null:
		return false

	if coupon.targets_product():
		return coupon.target_product != null and coupon.target_product.is_available_at_assortment_level(assortment_level)

	if coupon.targets_line():
		for product: ProductVariantResource in products:
			if product.product_line != null and coupon.target_line != null:
				if product.product_line.id == coupon.target_line.id and product.is_available_at_assortment_level(assortment_level):
					return true

	return false


static func coupon_matches_product_resource(coupon: CouponResource, product: ProductVariantResource) -> bool:
	if coupon == null or product == null:
		return false

	if coupon.targets_product():
		return coupon.target_product != null and coupon.target_product.id == product.id

	if coupon.targets_line():
		return (
			coupon.target_line != null
			and product.product_line != null
			and coupon.target_line.id == product.product_line.id
		)

	return false


func _get_next_customer_context(run_state: RunState, balance: GameBalanceResource) -> Vector2i:
	if balance == null:
		return Vector2i(run_state.current_day, run_state.current_customer_number)
	if run_state.current_customer_number >= balance.customers_per_day:
		return Vector2i(run_state.current_day + 1, 1)

	return Vector2i(run_state.current_day, run_state.current_customer_number + 1)


func _is_activation_due(activation_day: int, activation_customer_number: int, current_day: int, current_customer_number: int) -> bool:
	if activation_day < current_day:
		return true
	if activation_day > current_day:
		return false
	return activation_customer_number <= current_customer_number


func _filter_active_coupons_for_day(run_state: RunState, day: int) -> void:
	var still_active: Array[CouponInstance] = []
	for coupon_instance: CouponInstance in run_state.active_coupons:
		if coupon_instance.expires_after_day >= day:
			still_active.append(coupon_instance)
		else:
			coupon_instance.is_active = false

	run_state.active_coupons = still_active


func _has_coupon_with_id(coupon_instances: Array[CouponInstance], coupon_id: String) -> bool:
	for coupon_instance: CouponInstance in coupon_instances:
		if coupon_instance != null and coupon_instance.coupon != null and coupon_instance.coupon.id == coupon_id:
			return true

	return false
