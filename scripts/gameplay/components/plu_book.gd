extends Node2D
class_name PluBook

signal book_pressed()

@export var book_sprite: Sprite2D
@export var interaction_area: Area2D
@export var normal_texture: Texture2D
@export var highlighted_texture: Texture2D


func _ready() -> void:
	_resolve_child_references()
	_set_highlighted(false)
	if interaction_area == null:
		return
	if not interaction_area.mouse_entered.is_connected(_on_mouse_entered):
		interaction_area.mouse_entered.connect(_on_mouse_entered)
	if not interaction_area.mouse_exited.is_connected(_on_mouse_exited):
		interaction_area.mouse_exited.connect(_on_mouse_exited)
	if not interaction_area.input_event.is_connected(_on_input_event):
		interaction_area.input_event.connect(_on_input_event)


func _on_mouse_entered() -> void:
	_set_highlighted(true)


func _on_mouse_exited() -> void:
	_set_highlighted(false)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return
	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		book_pressed.emit()
		get_viewport().set_input_as_handled()


func _set_highlighted(is_highlighted: bool) -> void:
	if book_sprite == null:
		return
	if is_highlighted and highlighted_texture != null:
		book_sprite.texture = highlighted_texture
	elif normal_texture != null:
		book_sprite.texture = normal_texture


func _resolve_child_references() -> void:
	if book_sprite == null:
		book_sprite = get_node_or_null("BookSprite") as Sprite2D
	if interaction_area == null:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
