extends RefCounted
class_name VisibleObjectSlot

enum SlotKind {
	EMPTY,
	PRODUCT,
	COUPON,
}

var slot_index: int = -1
var slot_kind: int = SlotKind.EMPTY
var product_instance: ProductInstance
var coupon_instance: CouponInstance
var is_taken: bool = false


func _init(initial_slot_index: int = -1) -> void:
	slot_index = initial_slot_index


func has_object() -> bool:
	return slot_kind != SlotKind.EMPTY


func set_product(product: ProductInstance) -> void:
	slot_kind = SlotKind.PRODUCT
	product_instance = product
	coupon_instance = null
	is_taken = false


func set_coupon(coupon: CouponInstance) -> void:
	slot_kind = SlotKind.COUPON
	product_instance = null
	coupon_instance = coupon
	is_taken = false


func clear_object() -> void:
	slot_kind = SlotKind.EMPTY
	product_instance = null
	coupon_instance = null
	is_taken = false
