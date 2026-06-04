extends Resource
class_name CouponResource

enum TargetKind {
	PRODUCT_VARIANT,
	PRODUCT_LINE,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var tooltip: String = ""
@export var purchase_price_cents: int = 0
@export_range(0, 100, 1) var discount_percent: int = 0
@export var weight_multiplier_percent: int = 100
@export var duration_days: int = 1
@export_enum("Product Variant", "Product Line") var target_kind: int = TargetKind.PRODUCT_VARIANT
@export var target_product: ProductVariantResource
@export var target_line: ProductLineResource


func targets_product() -> bool:
	return target_kind == TargetKind.PRODUCT_VARIANT


func targets_line() -> bool:
	return target_kind == TargetKind.PRODUCT_LINE

