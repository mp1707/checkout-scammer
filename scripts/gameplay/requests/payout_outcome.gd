extends RefCounted
class_name PayoutOutcome

var product_instance: ProductInstance
var payout_cents: int = 0
var cash_before_cents: int = 0
var cash_after_cents: int = 0
var was_trashed: bool = false

