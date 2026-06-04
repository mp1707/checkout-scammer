extends SceneTree
class_name ContentValidationTest


func _initialize() -> void:
	var registry: ContentRegistry = ContentRegistry.new()
	var errors: PackedStringArray = registry.load_all()
	if errors.size() > 0:
		for message: String in errors:
			push_error(message)
		quit(1)
		return

	print("Content validation passed: %d lines, %d products, %d coupons, %d upgrades." % [
		registry.product_lines.size(),
		registry.product_variants.size(),
		registry.coupons.size(),
		registry.upgrades.size(),
	])
	quit(0)
