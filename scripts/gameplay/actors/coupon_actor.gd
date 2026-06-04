extends Node2D
class_name CouponActor

signal drag_started(actor: CouponActor)
signal drag_moved(actor: CouponActor, previous_position: Vector2, current_position: Vector2, movement_delta: Vector2)
signal drag_ended(actor: CouponActor, drop_position: Vector2)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var title_label: Label
@export var detail_label: Label
@export var interaction_area: Area2D

var actor_id: String = ""
var slot_index: int = -1
var coupon_instance: CouponInstance
var is_held: bool = false
var movement_direction: Vector2 = Vector2.ZERO

var _is_hovered: bool = false


func _ready() -> void:
	_apply_label_theme()
	_connect_interaction_area()
	_update_visual_state()


func set_coupon_instance(initial_coupon_instance: CouponInstance) -> void:
	coupon_instance = initial_coupon_instance
	if coupon_instance == null:
		actor_id = ""
		_set_label_text("Coupon", "")
		return

	actor_id = coupon_instance.instance_id
	if coupon_instance.coupon == null:
		_set_label_text("Coupon", "")
	else:
		_set_label_text(coupon_instance.coupon.display_name, "-%d%%" % coupon_instance.coupon.discount_percent)


func get_contact_area() -> Area2D:
	return interaction_area


func _unhandled_input(event: InputEvent) -> void:
	if not is_held:
		return

	var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if motion_event != null:
		_update_drag_position(motion_event.position.round())
		get_viewport().set_input_as_handled()
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null and mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
		_end_drag(mouse_button_event.position.round())
		get_viewport().set_input_as_handled()


func _connect_interaction_area() -> void:
	if interaction_area == null:
		return
	if not interaction_area.input_event.is_connected(_on_interaction_area_input_event):
		interaction_area.input_event.connect(_on_interaction_area_input_event)
	if not interaction_area.mouse_entered.is_connected(_on_interaction_area_mouse_entered):
		interaction_area.mouse_entered.connect(_on_interaction_area_mouse_entered)
	if not interaction_area.mouse_exited.is_connected(_on_interaction_area_mouse_exited):
		interaction_area.mouse_exited.connect(_on_interaction_area_mouse_exited)


func _on_interaction_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return
	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		_start_drag(mouse_button_event.position.round())
		get_viewport().set_input_as_handled()


func _on_interaction_area_mouse_entered() -> void:
	_is_hovered = true
	_update_visual_state()


func _on_interaction_area_mouse_exited() -> void:
	_is_hovered = false
	_update_visual_state()


func _start_drag(pointer_position: Vector2) -> void:
	is_held = true
	z_index = 100
	_update_drag_position(pointer_position)
	drag_started.emit(self)
	_update_visual_state()


func _update_drag_position(next_global_position: Vector2) -> void:
	var previous_position: Vector2 = global_position
	global_position = next_global_position
	var movement_delta: Vector2 = global_position - previous_position
	movement_direction = Vector2.ZERO
	if movement_delta.length_squared() > 0.0:
		movement_direction = movement_delta.normalized()
	drag_moved.emit(self, previous_position, global_position, movement_delta)


func _end_drag(drop_position: Vector2) -> void:
	is_held = false
	z_index = 0
	_update_drag_position(drop_position)
	drag_ended.emit(self, global_position)
	_update_visual_state()


func _set_label_text(title_text: String, detail_text: String) -> void:
	if title_label != null:
		title_label.text = title_text
	if detail_label != null:
		detail_label.text = detail_text


func _update_visual_state() -> void:
	modulate = Color(1.12, 1.12, 1.12, 1.0) if _is_hovered or is_held else Color.WHITE


func _apply_label_theme() -> void:
	if theme_resource == null:
		return
	for label: Label in [title_label, detail_label]:
		if label == null:
			continue
		if theme_resource.font != null:
			label.add_theme_font_override("font", theme_resource.font)
		label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		label.add_theme_color_override("font_color", theme_resource.text_color)
