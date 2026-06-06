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
@export var amount_label_panel: PanelContainer
@export var amount_label: Label
@export var amount_label_anchor: Marker2D
@export var sprite_root: Node2D
@export var interaction_area: Area2D
@export var animation_player: AnimationPlayer

var actor_id: String = ""
var slot_index: int = -1
var product_instance: ProductInstance
var is_held: bool = false
var is_touching_scanner: bool = false
var movement_direction: Vector2 = Vector2.ZERO
var scanner_contact_position: Vector2 = Vector2.ZERO

var _last_global_position: Vector2 = Vector2.ZERO
var _feedback_tween: Tween
var _finish_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	if product_instance != null and product_instance.variant != null:
		_set_product_texture(product_instance.variant.texture)
	_apply_shadow_theme()
	_apply_label_theme()
	_connect_interaction_area()
	update_open_amount_label()


func set_product_instance(initial_product_instance: ProductInstance) -> void:
	product_instance = initial_product_instance
	if product_instance == null:
		actor_id = ""
		_set_product_texture(null)
		update_open_amount_label()
		return

	actor_id = product_instance.instance_id
	if product_instance.variant != null:
		_set_product_texture(product_instance.variant.texture)
	update_open_amount_label()


func get_contact_area() -> Area2D:
	return interaction_area


func set_touching_scanner(value: bool, contact_position: Vector2) -> void:
	if is_touching_scanner == value and scanner_contact_position == contact_position:
		return

	is_touching_scanner = value
	scanner_contact_position = contact_position
	scanner_contact_changed.emit(self, is_touching_scanner, scanner_contact_position)


func update_open_amount_label() -> void:
	if amount_label == null and amount_label_panel == null:
		return
	if product_instance == null or product_instance.open_amount_cents <= 0:
		if amount_label_panel != null:
			amount_label_panel.visible = false
		if amount_label != null:
			amount_label.visible = false
			amount_label.text = ""
		return

	if amount_label_panel != null:
		amount_label_panel.visible = true
	if amount_label != null:
		amount_label.visible = true
		amount_label.text = _format_cents(product_instance.open_amount_cents)


func get_feedback_anchor_global_position() -> Vector2:
	if amount_label_anchor != null:
		return amount_label_anchor.global_position
	return global_position


func play_successful_scan_feedback(scan_count: int) -> void:
	if animation_player != null and animation_player.has_animation("scan_success"):
		animation_player.play("scan_success")
		return

	_play_scan_wobble(maxi(scan_count, 1))


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


func _play_scan_wobble(scan_count: int) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	var wobble_strength: float = minf(0.10 + float(scan_count - 1) * 0.025, 0.18)
	var squash_scale: Vector2 = Vector2(1.0 + wobble_strength, 1.0 - wobble_strength)
	var stretch_scale: Vector2 = Vector2(1.0 - wobble_strength * 0.55, 1.0 + wobble_strength * 0.55)

	if sprite_root != null:
		sprite_root.scale = squash_scale
	if amount_label_panel != null and amount_label_panel.visible:
		amount_label_panel.scale = Vector2(1.12, 1.12)

	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	if sprite_root != null:
		_feedback_tween.tween_property(sprite_root, "scale", stretch_scale, 0.045)
		_feedback_tween.tween_property(sprite_root, "scale", Vector2.ONE, 0.09).set_delay(0.045) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
	if amount_label_panel != null and amount_label_panel.visible:
		_feedback_tween.tween_property(amount_label_panel, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
	_feedback_tween.set_parallel(false)


func _apply_label_theme() -> void:
	if amount_label == null or theme_resource == null:
		return
	if theme_resource.font != null:
		amount_label.add_theme_font_override("font", theme_resource.font)
	amount_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	amount_label.add_theme_color_override("font_color", theme_resource.money_color)


func _apply_shadow_theme() -> void:
	if shadow_sprite == null or theme_resource == null:
		return
	shadow_sprite.modulate = theme_resource.shadow_color


func _format_cents(cents: int) -> String:
	var dollars: int = floori(float(cents) / 100.0)
	return "$%d.%02d" % [dollars, cents % 100]


func _resolve_child_references() -> void:
	if sprite_root == null:
		sprite_root = get_node_or_null("SpriteRoot") as Node2D
	if product_sprite == null:
		product_sprite = get_node_or_null("SpriteRoot/ProductSprite") as Sprite2D
	if shadow_sprite == null:
		shadow_sprite = get_node_or_null("ShadowAnchor/ShadowSprite") as Sprite2D
	if amount_label_panel == null:
		amount_label_panel = get_node_or_null("AmountLabelPanel") as PanelContainer
	if amount_label == null:
		amount_label = get_node_or_null("AmountLabelPanel/AmountLabel") as Label
		if amount_label == null:
			amount_label = get_node_or_null("AmountLabel") as Label
	if amount_label_anchor == null:
		amount_label_anchor = get_node_or_null("AmountLabelAnchor") as Marker2D
	if interaction_area == null:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
