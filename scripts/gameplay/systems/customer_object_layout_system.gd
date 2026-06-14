extends RefCounted
class_name CustomerObjectLayoutSystem


func start_customer(customer: CustomerState, coupon_instance: CouponInstance = null) -> void:
	if customer == null:
		return

	customer.visible_slots.clear()
	customer.coupon_instance = coupon_instance
	customer.processed_product_count = 0
	customer.processed_product_instance_ids.clear()
	customer.total_product_count = customer.product_queue.size()
	customer.is_complete = false

	var slot_index: int = 0
	if coupon_instance != null:
		var coupon_slot: VisibleObjectSlot = VisibleObjectSlot.new(slot_index)
		coupon_slot.set_coupon(coupon_instance)
		customer.visible_slots.append(coupon_slot)
		slot_index += 1

	for product_instance: ProductInstance in customer.product_queue:
		var product_slot: VisibleObjectSlot = VisibleObjectSlot.new(slot_index)
		product_slot.set_product(product_instance)
		customer.visible_slots.append(product_slot)
		slot_index += 1

	customer.product_queue.clear()
	_update_customer_completion(customer)


func mark_product_processed(customer: CustomerState, product_instance: ProductInstance) -> void:
	if customer == null or product_instance == null:
		return

	if not customer.processed_product_instance_ids.has(product_instance.instance_id):
		product_instance.is_processed = true
		customer.processed_product_instance_ids.append(product_instance.instance_id)
		customer.processed_product_count += 1

	var slot: VisibleObjectSlot = _find_product_slot(customer, product_instance)
	if slot != null:
		slot.clear_object()
	_update_customer_completion(customer)


func mark_coupon_processed(customer: CustomerState, coupon_instance: CouponInstance, was_trashed: bool) -> void:
	if customer == null or coupon_instance == null:
		return

	coupon_instance.was_trashed = was_trashed
	coupon_instance.was_activated_honestly = not was_trashed
	var slot: VisibleObjectSlot = _find_coupon_slot(customer, coupon_instance)
	if slot != null:
		slot.clear_object()
	_update_customer_completion(customer)


func mark_all_visible_objects_processed(customer: CustomerState) -> void:
	if customer == null:
		return

	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot == null or not slot.has_object():
			continue
		match slot.slot_kind:
			VisibleObjectSlot.SlotKind.PRODUCT:
				if slot.product_instance != null:
					mark_product_processed(customer, slot.product_instance)
			VisibleObjectSlot.SlotKind.COUPON:
				if slot.coupon_instance != null:
					mark_coupon_processed(customer, slot.coupon_instance, not slot.coupon_instance.was_activated_honestly)
			_:
				pass
	_update_customer_completion(customer)


func get_visible_product_count(customer: CustomerState) -> int:
	var count: int = 0
	if customer == null:
		return count
	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot != null and slot.slot_kind == VisibleObjectSlot.SlotKind.PRODUCT:
			count += 1
	return count


func get_visible_object_count(customer: CustomerState) -> int:
	var count: int = 0
	if customer == null:
		return count
	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot != null and slot.has_object():
			count += 1
	return count


func get_first_occupied_slot_index(customer: CustomerState) -> int:
	if customer == null:
		return -1
	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot != null and slot.has_object():
			return slot.slot_index
	return -1


func _update_customer_completion(customer: CustomerState) -> void:
	customer.is_complete = (
		customer.processed_product_count >= customer.total_product_count
		and get_visible_object_count(customer) == 0
	)


func _find_product_slot(customer: CustomerState, product_instance: ProductInstance) -> VisibleObjectSlot:
	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot != null and slot.slot_kind == VisibleObjectSlot.SlotKind.PRODUCT and slot.product_instance == product_instance:
			return slot
	return null


func _find_coupon_slot(customer: CustomerState, coupon_instance: CouponInstance) -> VisibleObjectSlot:
	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot != null and slot.slot_kind == VisibleObjectSlot.SlotKind.COUPON and slot.coupon_instance == coupon_instance:
			return slot
	return null
