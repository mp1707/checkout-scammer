extends Resource
class_name CheckoutThemeResource

const PANEL_TEXTURE_OUTER_PADDING: int = 2
const PANEL_CORNER_SLICE_SIZE: int = 5
const PANEL_TEXTURE_MARGIN: int = PANEL_TEXTURE_OUTER_PADDING + PANEL_CORNER_SLICE_SIZE
const PANEL_CONTENT_MARGIN: int = 2

@export var font: FontFile
@export var bold_font: Font
@export var compact_bold_font: Font
@export var panel_texture: Texture2D

@export var font_size_small: int = 8
@export var font_size_detail: int = 6
@export var font_size_normal: int = 16
@export var font_size_large: int = 24
@export var font_size_title: int = 32

@export var panel_base_color: Color = Color(0.780392, 0.811765, 0.866667, 1.0)
@export var panel_warm_color: Color = Color(0.976471, 0.901961, 0.811765, 1.0)
@export var panel_accent_color: Color = Color(0.964706, 0.792157, 0.623529, 1.0)
@export var panel_muted_color: Color = Color(0.572549, 0.631373, 0.72549, 1.0)
@export var panel_disabled_color: Color = Color(0.396078, 0.45098, 0.572549, 1.0)
@export var button_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var button_hover_color: Color = Color(1.0, 0.921568, 0.341176, 1.0)
@export var button_pressed_color: Color = Color(0.929412, 0.670588, 0.313725, 1.0)
@export var text_color: Color = Color(0.101961, 0.098039, 0.196078, 1.0)
@export var text_disabled_color: Color = Color(0.054902, 0.027451, 0.105882, 1.0)
@export var money_color: Color = Color(0.117647, 0.435294, 0.313725, 1.0)
@export var register_display_text_color: Color = Color(0.388235, 0.780392, 0.301961, 1.0)
@export var danger_color: Color = Color(0.768627, 0.141176, 0.188235, 1.0)
@export var overlay_dim_color: Color = Color(0.054902, 0.027451, 0.105882, 0.58)
@export var shadow_color: Color = Color(0.054902, 0.027451, 0.105882, 0.42)
@export var scanner_beam_color: Color = Color(1.0, 0.0, 0.25098, 0.86)
@export var scanner_flash_color: Color = Color(1.0, 0.921568, 0.341176, 0.72)
@export var hand_pulse_color: Color = Color(1.0, 1.0, 1.0, 1.0)
