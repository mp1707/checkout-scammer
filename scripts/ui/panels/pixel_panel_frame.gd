@tool
extends Control
class_name PixelPanelFrame

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres"):
	set(value):
		theme_resource = value
		apply_frame_theme()
@export var main_panel: PixelPanel
@export var shadow_panel: PixelPanel
@export var panel_color: Color = Color.WHITE:
	set(value):
		panel_color = value
		apply_frame_theme()
@export var shadow_color: Color = Color.TRANSPARENT:
	set(value):
		shadow_color = value
		apply_frame_theme()
@export var content_margin_override: int = 6:
	set(value):
		content_margin_override = value
		apply_frame_theme()
@export var panel_width: int = 104:
	set(value):
		panel_width = value
		queue_fit_to_content()
@export var panel_min_height: int = 0:
	set(value):
		panel_min_height = value
		queue_fit_to_content()
@export var shadow_offset: Vector2 = Vector2(2.0, 3.0):
	set(value):
		shadow_offset = value.round()
		queue_fit_to_content()
@export var fit_height_to_content: bool = true:
	set(value):
		fit_height_to_content = value
		queue_fit_to_content()

var _is_fit_queued: bool = false


func _ready() -> void:
	if main_panel == null:
		push_error("%s is missing required scene reference 'main_panel'." % get_path())
	if shadow_panel == null:
		push_error("%s is missing required scene reference 'shadow_panel'." % get_path())
	_connect_main_panel_minimum_size_changed()
	apply_frame_theme()
	queue_fit_to_content()


func apply_frame_theme() -> void:
	if main_panel != null:
		main_panel.theme_resource = theme_resource
		main_panel.panel_color = _get_panel_color()
		main_panel.content_margin_override = content_margin_override

	if shadow_panel != null:
		shadow_panel.theme_resource = theme_resource
		shadow_panel.panel_color = _get_shadow_color()
		shadow_panel.content_margin_override = content_margin_override
		shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	queue_fit_to_content()


func queue_fit_to_content() -> void:
	if not fit_height_to_content:
		return
	if not is_inside_tree():
		fit_frame_to_content()
		return
	if _is_fit_queued:
		return

	_is_fit_queued = true
	call_deferred("fit_frame_to_content")


func fit_frame_to_content() -> void:
	_is_fit_queued = false
	if main_panel == null:
		return

	var target_width: float = float(panel_width)
	if target_width <= 0.0:
		target_width = maxf(size.x, main_panel.get_combined_minimum_size().x)
	target_width = ceilf(target_width)

	main_panel.position = Vector2.ZERO
	main_panel.size = Vector2(target_width, main_panel.size.y)

	var target_height: float = main_panel.get_combined_minimum_size().y
	if panel_min_height > 0:
		target_height = maxf(target_height, float(panel_min_height))
	target_height = ceilf(target_height)

	main_panel.size = Vector2(target_width, target_height)
	var actual_panel_size: Vector2 = main_panel.size
	if shadow_panel != null:
		shadow_panel.position = shadow_offset
		shadow_panel.size = actual_panel_size

	var frame_size: Vector2 = Vector2(
		actual_panel_size.x + maxf(0.0, shadow_offset.x),
		actual_panel_size.y + maxf(0.0, shadow_offset.y)
	)
	custom_minimum_size = frame_size
	size = frame_size


func _connect_main_panel_minimum_size_changed() -> void:
	if main_panel == null:
		return
	if not main_panel.minimum_size_changed.is_connected(_on_main_panel_minimum_size_changed):
		main_panel.minimum_size_changed.connect(_on_main_panel_minimum_size_changed)


func _on_main_panel_minimum_size_changed() -> void:
	queue_fit_to_content()



func _get_panel_color() -> Color:
	if panel_color == Color.WHITE and theme_resource != null:
		return theme_resource.panel_base_color
	return panel_color


func _get_shadow_color() -> Color:
	if shadow_color.a <= 0.0 and theme_resource != null:
		return theme_resource.shadow_color
	return shadow_color
