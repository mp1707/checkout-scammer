@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name TooltipPanel

@export var text_label: Label
@export var min_text_width: int = 64
@export var max_text_width: int = 156


func _ready() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_tooltip_references()
	_apply_tooltip_theme()
	call_deferred("_clear_engine_tooltip_backdrop")
	queue_fit_to_content()


func configure_text(tooltip_body: String) -> void:
	_resolve_tooltip_references()
	if text_label == null:
		return

	text_label.text = tooltip_body.strip_edges()
	var text_width: int = _get_tooltip_text_width(text_label.text)
	text_label.custom_minimum_size = Vector2(
		float(text_width),
		float(_get_wrapped_text_height(text_label.text, text_width))
	)
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


func _get_tooltip_text_width(tooltip_body: String) -> int:
	var text_width: int = _get_estimated_text_width(tooltip_body)
	return clampi(text_width, min_text_width, max_text_width)


func _get_estimated_text_width(tooltip_body: String) -> int:
	if theme_resource == null or theme_resource.font == null:
		return ceili(float(tooltip_body.length()) * float(CheckoutThemeResource.PANEL_TEXTURE_MARGIN))

	var widest_line_width: float = 0.0
	var font_size: int = theme_resource.font_size_small
	var text_lines: PackedStringArray = tooltip_body.split("\n", false)
	for text_line: String in text_lines:
		widest_line_width = maxf(widest_line_width, _get_text_line_width(text_line, font_size))

	return ceili(widest_line_width)


func _get_wrapped_text_height(tooltip_body: String, text_width: int) -> int:
	if theme_resource == null or theme_resource.font == null:
		return theme_resource.font_size_small if theme_resource != null else 8

	var font_size: int = theme_resource.font_size_small
	var line_count: int = _get_wrapped_line_count(tooltip_body, text_width, font_size)
	var line_height: int = ceili(theme_resource.font.get_height(font_size))
	return maxi(font_size, line_count * line_height)


func _get_wrapped_line_count(text: String, text_width: int, font_size: int) -> int:
	var wrapped_line_count: int = 0
	var source_lines: PackedStringArray = text.split("\n", true)
	for source_line: String in source_lines:
		if source_line.is_empty():
			wrapped_line_count += 1
			continue

		var current_line: String = ""
		var words: PackedStringArray = source_line.split(" ", false)
		for word: String in words:
			var candidate_line: String = word if current_line.is_empty() else "%s %s" % [current_line, word]
			if current_line.is_empty() or _get_text_line_width(candidate_line, font_size) <= float(text_width):
				current_line = candidate_line
				continue

			wrapped_line_count += 1
			current_line = word

		if not current_line.is_empty():
			wrapped_line_count += 1

	return maxi(1, wrapped_line_count)


func _get_text_line_width(text_line: String, font_size: int) -> float:
	if theme_resource == null or theme_resource.font == null:
		return float(text_line.length()) * float(CheckoutThemeResource.PANEL_TEXTURE_MARGIN)

	var line_size: Vector2 = theme_resource.font.get_string_size(
		text_line,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	)
	return line_size.x


func _clear_engine_tooltip_backdrop() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null:
		var popup_panel: PopupPanel = ancestor as PopupPanel
		if popup_panel != null:
			popup_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			return
		ancestor = ancestor.get_parent()


func _resolve_tooltip_references() -> void:
	if text_label == null:
		text_label = get_node_or_null("MainPanel/TooltipLabel") as Label
