extends RefCounted
class_name StickerInventoryEntry

var sticker: StickerResource
var count: int = 0


func _init(initial_sticker: StickerResource = null, initial_count: int = 0) -> void:
	sticker = initial_sticker
	count = initial_count


func refill_daily() -> void:
	if sticker == null:
		count = 0
		return
	count = sticker.daily_refill_count
