extends Resource
class_name UpgradeResource

enum UpgradeKind {
	ASSORTMENT_LEVEL,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var tooltip: String = ""
@export var cost_cents: int = 0
@export_enum("Assortment Level") var upgrade_kind: int = UpgradeKind.ASSORTMENT_LEVEL
@export var target_assortment_level: int = 1
@export var unlocked_products: Array[ProductVariantResource] = []

