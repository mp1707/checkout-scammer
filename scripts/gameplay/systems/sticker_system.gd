extends RefCounted
class_name StickerSystem


func setup_run_inventory(run_state: RunState, stickers: Array[StickerResource]) -> void:
	if run_state == null:
		return

	run_state.sticker_inventory.clear()
	for sticker: StickerResource in stickers:
		if sticker == null:
			continue
		var entry: StickerInventoryEntry = StickerInventoryEntry.new(sticker, sticker.daily_refill_count)
		run_state.sticker_inventory.append(entry)


func refill_daily(run_state: RunState) -> void:
	if run_state == null:
		return

	for entry: StickerInventoryEntry in run_state.sticker_inventory:
		if entry != null:
			entry.refill_daily()


func get_inventory_entries(run_state: RunState) -> Array[StickerInventoryEntry]:
	var entries: Array[StickerInventoryEntry] = []
	if run_state == null:
		return entries

	for entry: StickerInventoryEntry in run_state.sticker_inventory:
		if entry != null:
			entries.append(entry)

	return entries


func get_sticker_count(run_state: RunState, sticker_id: String) -> int:
	var entry: StickerInventoryEntry = _find_entry(run_state, sticker_id)
	if entry == null:
		return 0
	return entry.count


func can_apply_sticker(run_state: RunState, sticker_id: String, product_instance: ProductInstance) -> bool:
	var entry: StickerInventoryEntry = _find_entry(run_state, sticker_id)
	if entry == null or entry.sticker == null or entry.count <= 0:
		return false
	if product_instance == null or product_instance.is_processed:
		return false
	if product_instance.has_sticker(sticker_id):
		return false
	return entry.sticker.can_apply_to_product(product_instance)


func apply_sticker(run_state: RunState, sticker_id: String, product_instance: ProductInstance) -> StickerInstance:
	if not can_apply_sticker(run_state, sticker_id, product_instance):
		return null

	var entry: StickerInventoryEntry = _find_entry(run_state, sticker_id)
	if entry == null or entry.sticker == null:
		return null

	entry.count -= 1
	var sticker_instance: StickerInstance = StickerInstance.new(
		entry.sticker,
		"%s_%s_%d" % [product_instance.instance_id, sticker_id, product_instance.applied_stickers.size() + 1]
	)
	product_instance.add_sticker(sticker_instance)
	return sticker_instance


func _find_entry(run_state: RunState, sticker_id: String) -> StickerInventoryEntry:
	if run_state == null:
		return null

	for entry: StickerInventoryEntry in run_state.sticker_inventory:
		if entry == null or entry.sticker == null:
			continue
		if entry.sticker.id == sticker_id:
			return entry

	return null
