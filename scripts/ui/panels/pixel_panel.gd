@tool
extends PanelContainer
class_name PixelPanel

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres"):
	set(value):
		theme_resource = value
		apply_pixel_panel_theme()
@export var panel_color: Color = Color.WHITE:
	set(value):
		panel_color = value
		apply_pixel_panel_theme()
@export var content_margin_override: int = -1:
	set(value):
		content_margin_override = value
		apply_pixel_panel_theme()


func _ready() -> void:
	apply_pixel_panel_theme()


func apply_pixel_panel_theme() -> void:
	if theme_resource == null or theme_resource.panel_texture == null:
		return

	var style_box: StyleBoxTexture = StyleBoxTexture.new()
	style_box.texture = theme_resource.panel_texture
	style_box.texture_margin_left = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.texture_margin_right = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.texture_margin_top = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.texture_margin_bottom = CheckoutThemeResource.PANEL_TEXTURE_MARGIN
	style_box.modulate_color = panel_color

	var content_margin: float = float(CheckoutThemeResource.PANEL_CONTENT_MARGIN)
	if content_margin_override >= 0:
		content_margin = float(content_margin_override)

	style_box.content_margin_left = content_margin
	style_box.content_margin_right = content_margin
	style_box.content_margin_top = content_margin
	style_box.content_margin_bottom = content_margin
	add_theme_stylebox_override("panel", style_box)
