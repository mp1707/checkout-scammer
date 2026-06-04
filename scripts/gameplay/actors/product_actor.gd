extends Node2D
class_name ProductActor

signal drag_started(actor: ProductActor)
signal drag_moved(actor: ProductActor, previous_position: Vector2, current_position: Vector2, movement_delta: Vector2)
signal drag_ended(actor: ProductActor, drop_position: Vector2)
signal rotation_changed(actor: ProductActor, rotation_degrees: float)
signal scanner_contact_changed(actor: ProductActor, is_touching_scanner: bool, contact_position: Vector2)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var normal_sprite: Sprite2D
@export var highlight_sprite: Sprite2D
@export var shadow_sprite: Sprite2D
@export var amount_label: Label
@export var interaction_area: Area2D
@export var animation_player: AnimationPlayer

var actor_id: String = ""
var slot_index: int = -1
var product_instance: ProductInstance
var is_held: bool = false
var is_touching_scanner: bool = false
var movement_direction: Vector2 = Vector2.ZERO
var scanner_contact_position: Vector2 = Vector2.ZERO

var _is_hovered: bool = false
var _last_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_resolve_child_references()
	if product_instance != null and product_instance.variant != null:
		_set_product_textures(product_instance.variant.normal_texture, product_instance.variant.highlight_texture)
	_apply_label_theme()
	_connect_interaction_area()
	_update_visual_state()
	update_open_amount_label()


func set_product_instance(initial_product_instance: ProductInstance) -> void:
	product_instance = initial_product_instance
	if product_instance == null:
		actor_id = ""
		_set_product_textures(null, null)
		update_open_amount_label()
		return

	actor_id = product_instance.instance_id
	if product_instance.variant != null:
		_set_product_textures(product_instance.variant.normal_texture, product_instance.variant.highlight_texture)
	update_open_amount_label()


func get_contact_area() -> Area2D:
	return interaction_area


func set_touching_scanner(value: bool, contact_position: Vector2) -> void:
	if is_touching_scanner == value and scanner_contact_position == contact_position:
		return

	is_touching_scanner = value
	scanner_contact_position = contact_position
	scanner_contact_changed.emit(self, is_touching_scanner, scanner_contact_position)
	_update_visual_state()


func update_open_amount_label() -> void:
	if amount_label == null:
		return
	if product_instance == null or product_instance.open_amount_cents <= 0:
		amount_label.visible = false
		amount_label.text = ""
		return

	amount_label.visible = true
	amount_label.text = _format_cents(product_instance.open_amount_cents)


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
	_last_global_position = global_position
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
	_last_global_position = previous_position
	drag_moved.emit(self, previous_position, global_position, movement_delta)


func _end_drag(drop_position: Vector2) -> void:
	is_held = false
	z_index = 0
	_update_drag_position(drop_position)
	drag_ended.emit(self, global_position)
	_update_visual_state()


func _handle_rotation_input(mouse_button_event: InputEventMouseButton) -> void:
	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		rotation_degrees -= 15.0
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		rotation_degrees += 15.0
	else:
		return
	rotation_changed.emit(self, rotation_degrees)
	get_viewport().set_input_as_handled()


func _set_product_textures(normal_texture: Texture2D, highlight_texture: Texture2D) -> void:
	if normal_sprite != null:
		normal_sprite.texture = normal_texture
	if highlight_sprite != null:
		highlight_sprite.texture = highlight_texture
	if shadow_sprite != null:
		shadow_sprite.texture = normal_texture
	_update_visual_state()


func _update_visual_state() -> void:
	var should_highlight: bool = _is_hovered or is_held or is_touching_scanner
	var has_highlight_texture: bool = highlight_sprite != null and highlight_sprite.texture != null
	if highlight_sprite != null:
		highlight_sprite.visible = should_highlight and has_highlight_texture
	if normal_sprite != null:
		normal_sprite.visible = not should_highlight or not has_highlight_texture


func _apply_label_theme() -> void:
	if amount_label == null or theme_resource == null:
		return
	if theme_resource.font != null:
		amount_label.add_theme_font_override("font", theme_resource.font)
	amount_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	amount_label.add_theme_color_override("font_color", theme_resource.money_color)


func _format_cents(cents: int) -> String:
	var dollars: int = floori(float(cents) / 100.0)
	return "$%d.%02d" % [dollars, cents % 100]


func _resolve_child_references() -> void:
	if normal_sprite == null:
		normal_sprite = get_node_or_null("SpriteRoot/NormalSprite") as Sprite2D
	if highlight_sprite == null:
		highlight_sprite = get_node_or_null("SpriteRoot/HighlightSprite") as Sprite2D
	if shadow_sprite == null:
		shadow_sprite = get_node_or_null("ShadowAnchor/ShadowSprite") as Sprite2D
	if amount_label == null:
		amount_label = get_node_or_null("AmountLabel") as Label
	if interaction_area == null:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
