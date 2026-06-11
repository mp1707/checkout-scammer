extends RefCounted
class_name StickerInstance

var sticker: StickerResource
var instance_id: String = ""


func _init(initial_sticker: StickerResource = null, initial_instance_id: String = "") -> void:
	sticker = initial_sticker
	instance_id = initial_instance_id
