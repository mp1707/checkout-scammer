extends RefCounted
class_name ReceiptBuilder


func build_lines(customer: CustomerState) -> Array[ReceiptLine]:
	var lines: Array[ReceiptLine] = []
	if customer == null:
		return lines

	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot == null or slot.slot_kind != VisibleObjectSlot.SlotKind.PRODUCT:
			continue
		_append_product_lines(lines, slot.product_instance)
	return lines


func calculate_total_cents(lines: Array[ReceiptLine]) -> int:
	var total_cents: int = 0
	for line: ReceiptLine in lines:
		if line != null:
			total_cents += line.amount_cents
	return total_cents


func get_billable_products(customer: CustomerState) -> Array[ProductInstance]:
	var products: Array[ProductInstance] = []
	if customer == null:
		return products

	for slot: VisibleObjectSlot in customer.visible_slots:
		if slot == null or slot.slot_kind != VisibleObjectSlot.SlotKind.PRODUCT:
			continue
		var product_instance: ProductInstance = slot.product_instance
		if _is_billable_product(product_instance):
			products.append(product_instance)
	return products


func _append_product_lines(lines: Array[ReceiptLine], product_instance: ProductInstance) -> void:
	if not _is_billable_product(product_instance):
		return

	var scan_count: int = maxi(product_instance.scan_count, 1)
	var base_amount_cents: int = floori(float(product_instance.open_amount_cents) / float(scan_count))
	var remainder_cents: int = product_instance.open_amount_cents - base_amount_cents * scan_count
	var product_name: String = product_instance.variant.display_name
	if product_name.strip_edges().is_empty():
		product_name = product_instance.variant.id

	for entry_index: int in range(scan_count):
		var line_amount_cents: int = base_amount_cents
		if entry_index < remainder_cents:
			line_amount_cents += 1
		lines.append(ReceiptLine.new(
			product_name,
			product_instance.instance_id,
			line_amount_cents,
			entry_index,
			entry_index > 0
		))


func _is_billable_product(product_instance: ProductInstance) -> bool:
	return (
		product_instance != null
		and product_instance.variant != null
		and product_instance.scan_count > 0
		and product_instance.open_amount_cents > 0
	)
