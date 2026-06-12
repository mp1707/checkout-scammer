@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name TooltipPanel

@export var text_label: Label
@export var min_text_width: int = 64
@export var max_text_width: int = 156


func _ready() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if text_label == null:
		push_error("%s is missing required scene reference 'text_label'." % get_path())
	_apply_tooltip_theme()
	call_deferred("_clear_engine_tooltip_backdrop")
	queue_fit_to_content()


## Sizes the tooltip to its text using the font's own line metrics, so the
## measured wrap matches what the Label renders.
func configure_text(tooltip_body: String) -> void:
	if text_label == null:
		return

	text_label.text = tooltip_body.strip_edges()
	if theme_resource == null or theme_resource.font == null:
		return

	var font: Font = theme_resource.font
	var font_size: int = theme_resource.font_size_small
	var natural_width: int = ceili(font.get_multiline_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
	var text_width: int = clampi(natural_width, min_text_width, max_text_width)
	var wrapped_size: Vector2 = font.get_multiline_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, float(text_width), font_size)

	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(float(text_width), ceilf(wrapped_size.y))
	_apply_tooltip_theme()
	fit_frame_to_content()


func _apply_tooltip_theme() -> void:
	if text_label == null or theme_resource == null:
		return

	var tooltip_font: Font = theme_resource.font
	if tooltip_font != null:
		text_label.add_theme_font_override("font", tooltip_font)
	text_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	text_label.add_theme_color_override("font_color", theme_resource.text_color)


func _clear_engine_tooltip_backdrop() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null:
		var popup_panel: PopupPanel = ancestor as PopupPanel
		if popup_panel != null:
			popup_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			return
		ancestor = ancestor.get_parent()
