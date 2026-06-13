extends Control
class_name CustomerTooltipArea

const TOOLTIP_PANEL_SCENE: PackedScene = preload("res://scenes/ui/tooltips/tooltip_panel.tscn")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func set_customer_type(customer_type: CustomerTypeResource) -> void:
	tooltip_text = customer_type.get_tooltip_text() if customer_type != null else ""


func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.strip_edges().is_empty():
		return null

	var tooltip_panel: TooltipPanel = TOOLTIP_PANEL_SCENE.instantiate() as TooltipPanel
	if tooltip_panel == null:
		push_error("Tooltip panel scene does not instance a TooltipPanel.")
		return null

	tooltip_panel.configure_text(for_text)
	return tooltip_panel
