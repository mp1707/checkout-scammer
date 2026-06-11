extends Resource
class_name ProductVariantResource

enum SaleMode {
	FIXED_PRICE,
	WEIGHED,
}

@export var id: String = ""
@export var display_name: String = ""
@export var product_line: ProductLineResource
@export_enum("Fixed Price", "Weighed") var sale_mode: int = SaleMode.FIXED_PRICE
@export var price_cents: int = 0
@export var price_per_kg_cents: int = 0
@export var min_weight_grams: int = 0
@export var max_weight_grams: int = 0
@export var weight_step_grams: int = 10
@export var weight_distribution_power: float = 2.8
@export var min_visual_scale: float = 1.0
@export var max_visual_scale: float = 1.0
@export var generator_weight: int = 1
@export var assortment_level: int = 1
@export var texture: Texture2D


func is_available_at_assortment_level(level: int) -> bool:
	return level >= assortment_level


func is_weighable() -> bool:
	return sale_mode == SaleMode.WEIGHED


func get_visual_scale_for_weight(weight_grams: int) -> float:
	if not is_weighable():
		return 1.0
	if max_weight_grams <= min_weight_grams:
		return min_visual_scale

	var clamped_weight: int = clampi(weight_grams, min_weight_grams, max_weight_grams)
	var weight_range: float = float(max_weight_grams - min_weight_grams)
	var normalized_weight: float = float(clamped_weight - min_weight_grams) / weight_range
	return lerpf(min_visual_scale, max_visual_scale, normalized_weight)
