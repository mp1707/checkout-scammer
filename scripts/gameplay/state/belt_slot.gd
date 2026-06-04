extends RefCounted
class_name BeltSlot

enum SlotKind {
	EMPTY,
	PRODUCT,
	COUPON,
}

var slot_index: int = -1
var slot_kind: int = SlotKind.EMPTY
var product_instance: ProductInstance
var coupon_instance: CouponInstance


func _init(initial_slot_index: int = -1) -> void:
	slot_index = initial_slot_index


func has_object() -> bool:
	return slot_kind != SlotKind.EMPTY

