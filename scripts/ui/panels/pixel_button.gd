@tool
extends Button
class_name PixelButton

const TOOLTIP_PANEL_SCENE: PackedScene = preload("res://scenes/ui/tooltips/tooltip_panel.tscn")

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres"):
	set(value):
		theme_resource = value
		apply_pixel_button_theme()
@export var button_color: Color = Color.WHITE:
	set(value):
		button_color = value
		apply_pixel_button_theme()


func _ready() -> void:
	apply_pixel_button_theme()


func apply_pixel_button_theme() -> void:
	if theme_resource == null or theme_resource.panel_texture == null:
		return

	var normal_color: Color = button_color
	if normal_color == Color.WHITE:
		normal_color = theme_resource.button_color

	add_theme_stylebox_override("normal", _make_style(normal_color))
	add_theme_stylebox_override("hover", _make_style(theme_resource.button_hover_color))
	add_theme_stylebox_override("pressed", _make_style(theme_resource.button_pressed_color))
	add_theme_stylebox_override("disabled", _make_style(theme_resource.panel_disabled_color))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if theme_resource.font != null:
		add_theme_font_override("font", theme_resource.font)
	add_theme_font_size_override("font_size", theme_resource.font_size_small)
	add_theme_color_override("font_color", theme_resource.text_color)
	add_theme_color_override("font_hover_color", theme_resource.text_color)
	add_theme_color_override("font_pressed_color", theme_resource.text_color)
	add_theme_color_override("font_disabled_color", theme_resource.text_disabled_color)


func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.strip_edges().is_empty():
		return null

	var tooltip_node: Node = TOOLTIP_PANEL_SCENE.instantiate()
	if tooltip_node.has_method("configure_text"):
		tooltip_node.call("configure_text", for_text)
	return tooltip_node


func _make_style(color: Color) -> StyleBoxTexture:
	var style_box: StyleBoxTexture = StyleBoxTexture.new()
	style_box.texture = theme_resource.panel_texture
	style_box.texture_margin_left = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.texture_margin_right = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.texture_margin_top = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.texture_margin_bottom = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.content_margin_left = CheckoutThemeResource.PANEL_CONTENT_MARGIN
	style_box.content_margin_right = CheckoutThemeResource.PANEL_CONTENT_MARGIN
	style_box.content_margin_top = CheckoutThemeResource.PANEL_CONTENT_MARGIN
	style_box.content_margin_bottom = CheckoutThemeResource.PANEL_CONTENT_MARGIN
	style_box.modulate_color = color
	return style_box
