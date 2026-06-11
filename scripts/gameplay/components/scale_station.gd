extends Area2D
class_name ScaleStation

signal actor_dropped(actor: Node2D)
signal actor_removed(actor: Node2D)

@export var scale_sprite: Sprite2D
@export var drop_anchor: Marker2D

var _current_actor: Node2D
var _press_tween: Tween
var _feedback_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	_set_frame(0)


func try_drop_actor(actor: Node2D) -> bool:
	if not can_accept_actor(actor):
		return false

	_current_actor = actor
	if drop_anchor != null:
		actor.global_position = drop_anchor.global_position.round()
	actor.z_index = 40
	_play_press_animation()
	actor_dropped.emit(actor)
	return true


func release_actor(actor: Node2D) -> void:
	if actor == null or _current_actor != actor:
		return

	var released_actor: Node2D = _current_actor
	_current_actor = null
	_set_frame(0)
	actor_removed.emit(released_actor)


func can_accept_actor(actor: Node2D) -> bool:
	if _current_actor != null:
		return false
	if not _actor_is_weighable_product(actor):
		return false

	var contact_area: Area2D = _get_actor_contact_area(actor)
	return contact_area != null and get_overlapping_areas().has(contact_area)


func has_actor(actor: Node2D) -> bool:
	return actor != null and _current_actor == actor


func get_current_actor() -> Node2D:
	return _current_actor


func get_drop_position() -> Vector2:
	if drop_anchor != null:
		return drop_anchor.global_position
	return global_position


func play_success_feedback() -> void:
	if scale_sprite == null:
		return
	_play_scale_tint(Color(1.0, 0.921568, 0.341176, 1.0), 0.10)


func play_invalid_feedback() -> void:
	if scale_sprite == null:
		return
	_play_scale_tint(Color(1.0, 0.0, 0.25098, 1.0), 0.12)


func _play_press_animation() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()

	_set_frame(0)
	_press_tween = create_tween()
	_press_tween.tween_callback(_set_frame.bind(1))
	_press_tween.tween_interval(0.055)
	_press_tween.tween_callback(_set_frame.bind(2))


func _play_scale_tint(color: Color, duration: float) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	scale_sprite.modulate = color
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(scale_sprite, "modulate", Color.WHITE, duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _set_frame(frame_index: int) -> void:
	if scale_sprite != null:
		scale_sprite.frame = frame_index


func _actor_is_weighable_product(actor: Node2D) -> bool:
	if actor == null:
		return false

	var product_instance: ProductInstance = actor.get("product_instance") as ProductInstance
	return product_instance != null and product_instance.is_weighable() and not product_instance.is_processed


func _get_actor_contact_area(actor: Node2D) -> Area2D:
	if actor == null or not actor.has_method("get_contact_area"):
		return null
	return actor.call("get_contact_area") as Area2D


func _resolve_child_references() -> void:
	if scale_sprite == null:
		scale_sprite = get_node_or_null("ScaleSprite") as Sprite2D
	if drop_anchor == null:
		drop_anchor = get_node_or_null("DropAnchor") as Marker2D
