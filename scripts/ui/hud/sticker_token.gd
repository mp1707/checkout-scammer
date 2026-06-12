extends TextureRect
class_name StickerToken

signal sticker_drag_released(sticker_id: String, global_drop_position: Vector2)

const TOOLTIP_PANEL_SCENE: PackedScene = preload("res://scenes/ui/tooltips/tooltip_panel.tscn")

var sticker: StickerResource

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _home_position: Vector2 = Vector2.ZERO


func configure(initial_sticker: StickerResource) -> void:
	sticker = initial_sticker
	if sticker == null:
		texture = null
		tooltip_text = ""
		return

	texture = sticker.texture
	tooltip_text = sticker.tooltip


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	stretch_mode = TextureRect.STRETCH_KEEP_CENTERED


func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.strip_edges().is_empty():
		return null

	var tooltip_panel: TooltipPanel = TOOLTIP_PANEL_SCENE.instantiate() as TooltipPanel
	if tooltip_panel == null:
		push_error("Tooltip panel scene does not instance a TooltipPanel.")
		return null

	tooltip_panel.configure_text(for_text)
	return tooltip_panel


func _gui_input(event: InputEvent) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_button_event.pressed:
			_start_drag()
			accept_event()
			return
		if _is_dragging:
			_finish_drag()
			accept_event()
			return

	var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion_event != null and _is_dragging:
		global_position = (get_global_mouse_position() - _drag_offset).round()
		accept_event()


func _start_drag() -> void:
	_is_dragging = true
	_home_position = position
	_drag_offset = get_global_mouse_position() - global_position
	top_level = true
	z_index = 200


func _finish_drag() -> void:
	_is_dragging = false
	var drop_position: Vector2 = get_global_mouse_position().round()
	top_level = false
	z_index = 0
	position = _home_position
	if sticker != null:
		sticker_drag_released.emit(sticker.id, drop_position)
