extends RefCounted
class_name ScanResult

var product_instance: ProductInstance
var is_valid_scan: bool = false
var is_first_scan: bool = false
var is_duplicate_scan: bool = false
var was_caught: bool = false
var added_amount_cents: int = 0
var resulting_open_amount_cents: int = 0
var suspicion_percent_after: int = 0
var failure_reason: String = ""

