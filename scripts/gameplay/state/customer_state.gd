extends RefCounted
class_name CustomerState

var id: String = ""
var product_queue: Array[ProductInstance] = []
var visible_slots: Array[BeltSlot] = []
var coupon_instance: CouponInstance
var processed_product_count: int = 0
var current_suspicion_percent: int = 10
var is_complete: bool = false


func _init(initial_id: String = "") -> void:
	id = initial_id

