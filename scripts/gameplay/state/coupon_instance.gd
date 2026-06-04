extends RefCounted
class_name CouponInstance

var instance_id: String = ""
var coupon: CouponResource
var is_active: bool = false
var was_activated_honestly: bool = false
var was_trashed: bool = false
var activates_on_day: int = 1
var expires_after_day: int = 1


func _init(initial_coupon: CouponResource = null, initial_instance_id: String = "") -> void:
	coupon = initial_coupon
	instance_id = initial_instance_id

