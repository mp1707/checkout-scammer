extends "res://tests/checkout_test_base.gd"
class_name ContentValidationTest


func _initialize() -> void:
	var registry: ContentRegistry = ContentRegistry.new()
	var errors: PackedStringArray = registry.load_all()
	for message: String in errors:
		_fail("content validation", message)

	if _failure_count == 0:
		print("Content loaded: %d lines, %d products, %d coupons, %d stickers, %d upgrades, %d scripted customers." % [
			registry.product_lines.size(),
			registry.product_variants.size(),
			registry.coupons.size(),
			registry.stickers.size(),
			registry.upgrades.size(),
			registry.scripted_customers.size(),
		])

	_finish_suite("Content validation")
