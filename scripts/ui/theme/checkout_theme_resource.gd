extends Resource
class_name CheckoutThemeResource

const PANEL_TEXTURE_OUTER_PADDING: int = 2
const PANEL_CORNER_SLICE_SIZE: int = 5
const PANEL_TEXTURE_MARGIN: int = PANEL_TEXTURE_OUTER_PADDING + PANEL_CORNER_SLICE_SIZE
const PANEL_CONTENT_MARGIN: int = 2

@export var font: FontFile
@export var panel_texture: Texture2D

@export var font_size_small: int = 11
@export var font_size_normal: int = 22
@export var font_size_large: int = 33
@export var font_size_title: int = 44

@export var panel_base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var panel_disabled_color: Color = Color(0.62, 0.65, 0.68, 1.0)
@export var text_color: Color = Color(0.08, 0.08, 0.08, 1.0)
@export var money_color: Color = Color(0.08, 0.42, 0.16, 1.0)
@export var danger_color: Color = Color(0.9, 0.12, 0.12, 1.0)
