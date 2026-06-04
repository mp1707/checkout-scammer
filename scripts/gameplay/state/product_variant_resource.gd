extends Resource
class_name ProductVariantResource

@export var id: String = ""
@export var display_name: String = ""
@export var product_line: ProductLineResource
@export var price_cents: int = 0
@export var generator_weight: int = 1
@export var assortment_level: int = 1
@export var normal_texture: Texture2D
@export var highlight_texture: Texture2D


func is_available_at_assortment_level(level: int) -> bool:
	return level >= assortment_level

