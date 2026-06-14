extends RefCounted
class_name ReceiptLine

var product_display_name: String = ""
var product_instance_id: String = ""
var amount_cents: int = 0
var entry_index: int = 0
var is_duplicate: bool = false


func _init(
	initial_product_display_name: String = "",
	initial_product_instance_id: String = "",
	initial_amount_cents: int = 0,
	initial_entry_index: int = 0,
	initial_is_duplicate: bool = false
) -> void:
	product_display_name = initial_product_display_name
	product_instance_id = initial_product_instance_id
	amount_cents = initial_amount_cents
	entry_index = initial_entry_index
	is_duplicate = initial_is_duplicate
