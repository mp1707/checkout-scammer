extends Resource
class_name StickerResource

enum TargetKind {
	WEIGHABLE_PRODUCT,
}

@export var id: String = ""
@export var display_name: String = ""
@export var tooltip: String = ""
@export var texture: Texture2D
@export var price_multiplier_percent: int = 100
@export var daily_refill_count: int = 0
@export_enum("Weighable Product") var target_kind: int = TargetKind.WEIGHABLE_PRODUCT


func can_apply_to_product(product_instance: ProductInstance) -> bool:
	if product_instance == null or product_instance.variant == null:
		return false

	match target_kind:
		TargetKind.WEIGHABLE_PRODUCT:
			return product_instance.variant.is_weighable()
		_:
			return false
