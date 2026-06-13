extends Resource
class_name CustomerTypeResource

enum CaughtPenaltyKind {
	NONE,
	CASH_PRODUCT_VALUE,
	NEXT_CUSTOMER_SUSPICION_BONUS,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var tooltip: String = ""
@export_multiline var caught_dialog_text: String = ""
@export_multiline var farewell_dialog_text: String = ""
@export_range(0, 100, 1) var price_percentile_min: int = 0
@export_range(0, 100, 1) var price_percentile_max: int = 100
@export var suspicion_stage_percentages: Array[int] = [10, 50, 75, 90]
@export var caught_penalty_kind: CaughtPenaltyKind = CaughtPenaltyKind.NONE
@export var cash_penalty_product_value_multiplier_percent: int = 100
@export var next_customer_suspicion_bonus_percent: int = 0
@export var green_texture: Texture2D
@export var yellow_texture: Texture2D
@export var red_texture: Texture2D
@export var sprite_offset: Vector2 = Vector2.ZERO


func get_initial_suspicion_percent() -> int:
	if suspicion_stage_percentages.is_empty():
		return 0
	return suspicion_stage_percentages[0]


func get_stage_texture(stage_index: int) -> Texture2D:
	match stage_index:
		0:
			return green_texture
		1:
			return yellow_texture
		_:
			return red_texture


func get_tooltip_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	if not display_name.strip_edges().is_empty():
		lines.append(display_name.strip_edges())
	if not tooltip.strip_edges().is_empty():
		lines.append(tooltip.strip_edges())
	return "\n".join(lines)
