extends RefCounted
class_name RunState

var run_seed: int = 0
var current_day: int = 1
var current_customer_number: int = 1
var cash_cents: int = 0
var rent_due_cents: int = 0
var assortment_level: int = 1
var pending_assortment_level: int = 1
var pending_assortment_activation_day: int = 1
var pending_assortment_activation_customer_number: int = 1
var current_customer: CustomerState
var active_coupons: Array[CouponInstance] = []
var pending_coupons: Array[CouponInstance] = []
var sticker_inventory: Array[StickerInventoryEntry] = []


func apply_balance(balance: GameBalanceResource) -> void:
	run_seed = balance.default_run_seed
	cash_cents = balance.start_money_cents
	rent_due_cents = balance.daily_rent_cents
	assortment_level = balance.starting_assortment_level
	pending_assortment_level = balance.starting_assortment_level
	pending_assortment_activation_day = current_day
	pending_assortment_activation_customer_number = current_customer_number
