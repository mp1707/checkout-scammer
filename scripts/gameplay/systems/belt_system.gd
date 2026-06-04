extends RefCounted
class_name BeltSystem


func start_customer(customer: CustomerState, visible_slot_count: int, coupon_instance: CouponInstance = null) -> void:
	customer.visible_slots.clear()
	customer.coupon_instance = coupon_instance
	customer.processed_product_count = 0
	customer.processed_product_instance_ids.clear()
	customer.total_product_count = customer.product_queue.size()
	customer.is_complete = false

	for slot_index: int in range(visible_slot_count):
		customer.visible_slots.append(BeltSlot.new(slot_index))

	var fill_start_index: int = 0
	if coupon_instance != null and not customer.visible_slots.is_empty():
		customer.visible_slots[0].set_coupon(coupon_instance)
		fill_start_index = 1

	for slot_index: int in range(fill_start_index, customer.visible_slots.size()):
		_refill_slot_from_queue(customer, customer.visible_slots[slot_index])

	_update_customer_completion(customer)


func take_slot_object(customer: CustomerState, slot_index: int) -> BeltSlot:
	var slot: BeltSlot = _find_slot(customer, slot_index)
	if slot == null or not slot.has_object():
		return BeltSlot.new(slot_index)

	var taken_slot: BeltSlot = _copy_slot(slot)
	_refill_slot_from_queue(customer, slot)
	_update_customer_completion(customer)
	return taken_slot


func mark_product_processed(customer: CustomerState, product_instance: ProductInstance) -> void:
	if product_instance == null:
		return
	if customer.processed_product_instance_ids.has(product_instance.instance_id):
		return

	product_instance.is_processed = true
	customer.processed_product_instance_ids.append(product_instance.instance_id)
	customer.processed_product_count += 1
	_update_customer_completion(customer)


func mark_coupon_processed(customer: CustomerState, coupon_instance: CouponInstance, was_trashed: bool) -> void:
	if coupon_instance == null:
		return

	coupon_instance.was_trashed = was_trashed
	coupon_instance.was_activated_honestly = not was_trashed
	_update_customer_completion(customer)


func get_visible_product_count(customer: CustomerState) -> int:
	var count: int = 0
	for slot: BeltSlot in customer.visible_slots:
		if slot.slot_kind == BeltSlot.SlotKind.PRODUCT:
			count += 1
	return count


func get_visible_object_count(customer: CustomerState) -> int:
	var count: int = 0
	for slot: BeltSlot in customer.visible_slots:
		if slot.has_object():
			count += 1
	return count


func get_first_occupied_slot_index(customer: CustomerState) -> int:
	for slot: BeltSlot in customer.visible_slots:
		if slot.has_object():
			return slot.slot_index
	return -1


func _refill_slot_from_queue(customer: CustomerState, slot: BeltSlot) -> void:
	if customer.product_queue.is_empty():
		slot.clear_object()
		return

	var next_product: ProductInstance = customer.product_queue.pop_front()
	slot.set_product(next_product)


func _update_customer_completion(customer: CustomerState) -> void:
	customer.is_complete = (
		customer.processed_product_count >= customer.total_product_count
		and customer.product_queue.is_empty()
		and get_visible_product_count(customer) == 0
	)


func _find_slot(customer: CustomerState, slot_index: int) -> BeltSlot:
	for slot: BeltSlot in customer.visible_slots:
		if slot.slot_index == slot_index:
			return slot
	return null


func _copy_slot(slot: BeltSlot) -> BeltSlot:
	var copied_slot: BeltSlot = BeltSlot.new(slot.slot_index)
	match slot.slot_kind:
		BeltSlot.SlotKind.PRODUCT:
			copied_slot.set_product(slot.product_instance)
		BeltSlot.SlotKind.COUPON:
			copied_slot.set_coupon(slot.coupon_instance)
		_:
			copied_slot.clear_object()
	return copied_slot
