extends Node2D
class_name ProductActor

signal drag_started(actor: ProductActor)
signal drag_moved(actor: ProductActor, previous_position: Vector2, current_position: Vector2, movement_delta: Vector2)
signal drag_ended(actor: ProductActor, drop_position: Vector2)
signal rotation_changed(actor: ProductActor, rotation_degrees: float)
signal scanner_contact_changed(actor: ProductActor, is_touching_scanner: bool, contact_position: Vector2)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var product_sprite: Sprite2D
@export var shadow_sprite: Sprite2D
@export var sprite_root: Node2D
@export var sticker_layer: Node2D
@export var interaction_area: Area2D
@export var collision_shape: CollisionShape2D
@export var animation_player: AnimationPlayer
@export var sticker_visual_scene: PackedScene = preload("res://scenes/gameplay/stickers/sticker_visual.tscn")

var actor_id: String = ""
var slot_index: int = -1
var product_instance: ProductInstance
var is_held: bool = false
var is_touching_scanner: bool = false
var movement_direction: Vector2 = Vector2.ZERO
var scanner_contact_position: Vector2 = Vector2.ZERO

var _last_global_position: Vector2 = Vector2.ZERO
var _base_visual_scale: Vector2 = Vector2.ONE
var _feedback_tween: Tween
var _finish_tween: Tween
var _reject_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	if product_instance != null and product_instance.variant != null:
		_refresh_product_visuals()
	_apply_shadow_theme()
	_connect_interaction_area()


func set_product_instance(initial_product_instance: ProductInstance) -> void:
	product_instance = initial_product_instance
	if product_instance == null:
		actor_id = ""
		_set_product_texture(null)
		return

	actor_id = product_instance.instance_id
	if product_instance.variant != null:
		_refresh_product_visuals()


func get_contact_area() -> Area2D:
	return interaction_area


func refresh_product_state() -> void:
	_refresh_product_visuals()


func contains_global_point(global_point: Vector2) -> bool:
	if collision_shape == null or collision_shape.shape == null:
		return false

	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		var local_point: Vector2 = collision_shape.to_local(global_point)
		var half_size: Vector2 = rectangle_shape.size * 0.5
		return absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y

	var circle_shape: CircleShape2D = collision_shape.shape as CircleShape2D
	if circle_shape != null:
		return collision_shape.to_local(global_point).length() <= circle_shape.radius

	return false


func set_touching_scanner(value: bool, contact_position: Vector2) -> void:
	if is_touching_scanner == value and scanner_contact_position == contact_position:
		return

	is_touching_scanner = value
	scanner_contact_position = contact_position
	scanner_contact_changed.emit(self, is_touching_scanner, scanner_contact_position)


func play_successful_scan_feedback(scan_count: int) -> void:
	if animation_player != null and animation_player.has_animation("scan_success"):
		animation_player.play("scan_success")
		return

	_play_scan_wobble(maxi(scan_count, 1))


func play_reject_feedback() -> void:
	if _reject_tween != null and _reject_tween.is_valid():
		_reject_tween.kill()
	if sprite_root == null:
		return

	var base_position: Vector2 = sprite_root.position
	_reject_tween = create_tween()
	_reject_tween.tween_property(sprite_root, "position", base_position + Vector2(-2.0, 0.0), 0.035)
	_reject_tween.tween_property(sprite_root, "position", base_position + Vector2(2.0, 0.0), 0.045)
	_reject_tween.tween_property(sprite_root, "position", base_position, 0.055) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func play_finish_feedback(target_global_position: Vector2, is_sale: bool) -> void:
	is_held = false
	is_touching_scanner = false
	if interaction_area != null:
		interaction_area.input_pickable = false
		interaction_area.set_deferred("monitorable", false)
		interaction_area.set_deferred("monitoring", false)

	if _finish_tween != null and _finish_tween.is_valid():
		_finish_tween.kill()
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	var finish_duration: float = 0.18 if is_sale else 0.12
	var target_scale: Vector2 = Vector2(0.35, 0.35) if is_sale else Vector2(0.55, 0.55)
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


func _unhandled_input(event: InputEvent) -> void:
	if not is_held:
		return

	var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if motion_event != null:
		_update_drag_position(motion_event.position.round())
		get_viewport().set_input_as_handled()
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null:
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
			_end_drag(mouse_button_event.position.round())
			get_viewport().set_input_as_handled()
			return
		if mouse_button_event.pressed:
			_handle_rotation_input(mouse_button_event)


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
	_last_global_position = global_position
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
	_last_global_position = previous_position
	drag_moved.emit(self, previous_position, global_position, movement_delta)


func _end_drag(drop_position: Vector2) -> void:
	is_held = false
	z_index = 0
	_update_drag_position(drop_position)
	drag_ended.emit(self, global_position)


func _handle_rotation_input(mouse_button_event: InputEventMouseButton) -> void:
	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		rotation_degrees -= 15.0
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		rotation_degrees += 15.0
	else:
		return
	rotation_changed.emit(self, rotation_degrees)
	get_viewport().set_input_as_handled()


func _set_product_texture(product_texture: Texture2D) -> void:
	if product_sprite != null:
		product_sprite.texture = product_texture
	if shadow_sprite != null:
		shadow_sprite.texture = product_texture


func _refresh_product_visuals() -> void:
	if product_instance == null or product_instance.variant == null:
		_set_product_texture(null)
		_apply_product_scale(1.0)
		_refresh_sticker_visuals()
		return

	_set_product_texture(product_instance.variant.texture)
	_apply_product_scale(product_instance.get_visual_scale())
	_refresh_sticker_visuals()


func _apply_product_scale(visual_scale: float) -> void:
	_base_visual_scale = Vector2.ONE * maxf(visual_scale, 0.1)
	if sprite_root != null:
		sprite_root.scale = _base_visual_scale
	if shadow_sprite != null:
		shadow_sprite.scale = _base_visual_scale
	if collision_shape != null:
		var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
		rectangle_shape.size = Vector2(32.0, 32.0) * _base_visual_scale
		collision_shape.shape = rectangle_shape


func _refresh_sticker_visuals() -> void:
	if sticker_layer == null:
		return

	for child: Node in sticker_layer.get_children():
		child.queue_free()
	if product_instance == null or sticker_visual_scene == null:
		return

	var sticker_index: int = 0
	for sticker_instance: StickerInstance in product_instance.applied_stickers:
		if sticker_instance == null or sticker_instance.sticker == null:
			continue
		var sticker_node: Node = sticker_visual_scene.instantiate()
		var sticker_sprite: Sprite2D = sticker_node as Sprite2D
		if sticker_sprite == null:
			sticker_node.queue_free()
			continue
		sticker_sprite.texture = sticker_instance.sticker.texture
		sticker_sprite.position = Vector2(8.0 + float(sticker_index * 3), -8.0 + float(sticker_index * 2))
		sticker_layer.add_child(sticker_sprite)
		sticker_index += 1


func _play_scan_wobble(scan_count: int) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	var wobble_strength: float = minf(0.10 + float(scan_count - 1) * 0.025, 0.18)
	var squash_scale: Vector2 = Vector2(1.0 + wobble_strength, 1.0 - wobble_strength)
	var stretch_scale: Vector2 = Vector2(1.0 - wobble_strength * 0.55, 1.0 + wobble_strength * 0.55)

	if sprite_root != null:
		sprite_root.scale = _base_visual_scale * squash_scale

	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	if sprite_root != null:
		_feedback_tween.tween_property(sprite_root, "scale", _base_visual_scale * stretch_scale, 0.045)
		_feedback_tween.tween_property(sprite_root, "scale", _base_visual_scale, 0.09).set_delay(0.045) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
	_feedback_tween.set_parallel(false)


func _apply_shadow_theme() -> void:
	if shadow_sprite == null or theme_resource == null:
		return
	shadow_sprite.modulate = theme_resource.shadow_color


func _resolve_child_references() -> void:
	if sprite_root == null:
		sprite_root = get_node_or_null("SpriteRoot") as Node2D
	if product_sprite == null:
		product_sprite = get_node_or_null("SpriteRoot/ProductSprite") as Sprite2D
	if sticker_layer == null:
		sticker_layer = get_node_or_null("SpriteRoot/StickerLayer") as Node2D
	if shadow_sprite == null:
		shadow_sprite = get_node_or_null("ShadowAnchor/ShadowSprite") as Sprite2D
	if interaction_area == null:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
	if collision_shape == null:
		collision_shape = get_node_or_null("InteractionArea/CollisionShape2D") as CollisionShape2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
