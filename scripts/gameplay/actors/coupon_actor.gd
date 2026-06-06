extends Node2D
class_name CouponActor

signal drag_started(actor: CouponActor)
signal drag_moved(actor: CouponActor, previous_position: Vector2, current_position: Vector2, movement_delta: Vector2)
signal drag_ended(actor: CouponActor, drop_position: Vector2)

@export var coupon_sprite: Sprite2D
@export var interaction_area: Area2D

var actor_id: String = ""
var slot_index: int = -1
var coupon_instance: CouponInstance
var is_held: bool = false
var movement_direction: Vector2 = Vector2.ZERO

var _finish_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	_refresh_coupon_id()
	_connect_interaction_area()


func set_coupon_instance(initial_coupon_instance: CouponInstance) -> void:
	coupon_instance = initial_coupon_instance
	_refresh_coupon_id()


func get_contact_area() -> Area2D:
	return interaction_area


func play_finish_feedback(target_global_position: Vector2, is_sale: bool) -> void:
	is_held = false
	if interaction_area != null:
		interaction_area.input_pickable = false
		interaction_area.set_deferred("monitorable", false)
		interaction_area.set_deferred("monitoring", false)

	if _finish_tween != null and _finish_tween.is_valid():
		_finish_tween.kill()

	var finish_duration: float = 0.16 if is_sale else 0.11
	var target_scale: Vector2 = Vector2(0.40, 0.40) if is_sale else Vector2(0.60, 0.60)
	z_index = 120

	_finish_tween = create_tween()
	_finish_tween.set_parallel(true)
	_finish_tween.tween_property(self, "global_position", target_global_position.round(), finish_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	_finish_tween.tween_property(self, "scale", target_scale, finish_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	_finish_tween.tween_property(self, "modulate:a", 0.0, finish_duration)
	_finish_tween.set_parallel(false)
	_finish_tween.tween_callback(queue_free)


func _refresh_coupon_id() -> void:
	if coupon_instance == null:
		actor_id = ""
		return

	actor_id = coupon_instance.instance_id


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


func _on_interaction_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return
	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		_start_drag(mouse_button_event.position.round())
		get_viewport().set_input_as_handled()


func _start_drag(pointer_position: Vector2) -> void:
	is_held = true
	z_index = 100
	_update_drag_position(pointer_position)
	drag_started.emit(self)


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


func _resolve_child_references() -> void:
	if coupon_sprite == null:
		coupon_sprite = get_node_or_null("CouponSprite") as Sprite2D
	if interaction_area == null:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
