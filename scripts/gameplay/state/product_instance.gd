extends RefCounted
class_name ProductInstance

var instance_id: String = ""
var variant: ProductVariantResource
var scan_count: int = 0
var open_amount_cents: int = 0
var is_processed: bool = false


func _init(initial_variant: ProductVariantResource = null, initial_instance_id: String = "") -> void:
	variant = initial_variant
	instance_id = initial_instance_id

