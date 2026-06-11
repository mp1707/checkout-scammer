extends RefCounted
class_name ProductInstance

var instance_id: String = ""
var variant: ProductVariantResource
var scan_count: int = 0
var open_amount_cents: int = 0
var is_processed: bool = false
var weight_grams: int = 0
var applied_stickers: Array[StickerInstance] = []


func _init(initial_variant: ProductVariantResource = null, initial_instance_id: String = "") -> void:
	variant = initial_variant
	instance_id = initial_instance_id


func is_weighable() -> bool:
	return variant != null and variant.is_weighable()


func get_visual_scale() -> float:
	if variant == null:
		return 1.0
	return variant.get_visual_scale_for_weight(weight_grams)


func has_sticker(sticker_id: String) -> bool:
	for sticker_instance: StickerInstance in applied_stickers:
		if sticker_instance != null and sticker_instance.sticker != null and sticker_instance.sticker.id == sticker_id:
			return true
	return false


func add_sticker(sticker_instance: StickerInstance) -> void:
	if sticker_instance == null:
		return
	applied_stickers.append(sticker_instance)


func get_price_multiplier_percent() -> int:
	var multiplier_percent: int = 100
	for sticker_instance: StickerInstance in applied_stickers:
		if sticker_instance == null or sticker_instance.sticker == null:
			continue
		multiplier_percent = floori(float(multiplier_percent * sticker_instance.sticker.price_multiplier_percent) / 100.0)
	return maxi(multiplier_percent, 0)
