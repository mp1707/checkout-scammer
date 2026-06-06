extends Node2D
class_name CoinBurstVfx

@export var sprite: Sprite2D
@export var spritesheet: Texture2D = preload("res://assets/vfx/coin/spritesheet.png")
@export var frame_size: Vector2i = Vector2i(128, 128)
@export var frame_count: int = 31
@export var frame_duration_seconds: float = 0.024
@export var pixel_scale: float = 0.44

var _play_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	if sprite == null:
		return

	sprite.texture = spritesheet
	sprite.region_enabled = true
	sprite.centered = true
	sprite.scale = Vector2.ONE * pixel_scale
	_set_frame_index(0.0)
	visible = false


func play_at(start_global_position: Vector2) -> void:
	global_position = start_global_position.round()
	visible = true
	modulate = Color.WHITE

	if _play_tween != null and _play_tween.is_valid():
		_play_tween.kill()

	_play_tween = create_tween()
	_play_tween.tween_method(
		Callable(self, "_set_frame_index"),
		0.0,
		float(maxi(frame_count - 1, 0)),
		frame_duration_seconds * float(frame_count)
	)
	_play_tween.tween_callback(queue_free)


func _set_frame_index(frame_value: float) -> void:
	if sprite == null or frame_size.x <= 0 or frame_size.y <= 0:
		return

	var frame_index: int = clampi(roundi(frame_value), 0, maxi(frame_count - 1, 0))
	sprite.region_rect = Rect2(
		Vector2(float(frame_index * frame_size.x), 0.0),
		Vector2(float(frame_size.x), float(frame_size.y))
	)


func _resolve_child_references() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite") as Sprite2D
