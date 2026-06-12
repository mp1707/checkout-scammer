extends Node2D
class_name CoinBurstVfx

@export var sprite: Sprite2D
@export var coin_sound_player: AudioStreamPlayer2D
@export var spritesheet: Texture2D = preload("res://assets/vfx/coin/spritesheet.png")
@export var normal_coin_sound: AudioStream = preload("res://assets/audio/sfx/ui/coins/1_coins.ogg")
@export var bonus_coin_sound: AudioStream = preload("res://assets/audio/sfx/ui/coins/5_coins.ogg")
@export var frame_size: Vector2i = Vector2i(128, 128)
@export var frame_count: int = 31
@export var frame_duration_seconds: float = 0.024
@export var pixel_scale: float = 0.44
@export var fallback_sound_lifetime_seconds: float = 1.35

var _play_tween: Tween


func _ready() -> void:
	if sprite == null:
		push_error("%s is missing required scene reference 'sprite'." % get_path())
		return

	sprite.texture = spritesheet
	sprite.region_enabled = true
	sprite.centered = true
	sprite.scale = Vector2.ONE * pixel_scale
	sprite.visible = true
	_set_frame_index(0.0)
	visible = false


func play_at(start_global_position: Vector2, use_bonus_sound: bool = false) -> void:
	global_position = start_global_position.round()
	visible = true
	if sprite != null:
		sprite.visible = true
	modulate = Color.WHITE
	var sound_lifetime_seconds: float = _play_coin_sound(use_bonus_sound)

	if _play_tween != null and _play_tween.is_valid():
		_play_tween.kill()

	var animation_duration_seconds: float = frame_duration_seconds * float(frame_count)
	_play_tween = create_tween()
	_play_tween.tween_method(
		_set_frame_index,
		0.0,
		float(maxi(frame_count - 1, 0)),
		animation_duration_seconds
	)
	_play_tween.tween_callback(_hide_sprite)
	var remaining_sound_seconds: float = maxf(sound_lifetime_seconds - animation_duration_seconds, 0.0)
	if remaining_sound_seconds > 0.0:
		_play_tween.tween_interval(remaining_sound_seconds)
	_play_tween.tween_callback(queue_free)


func _set_frame_index(frame_value: float) -> void:
	if sprite == null or frame_size.x <= 0 or frame_size.y <= 0:
		return

	var frame_index: int = clampi(roundi(frame_value), 0, maxi(frame_count - 1, 0))
	sprite.region_rect = Rect2(
		Vector2(float(frame_index * frame_size.x), 0.0),
		Vector2(float(frame_size.x), float(frame_size.y))
	)


func _play_coin_sound(use_bonus_sound: bool) -> float:
	if coin_sound_player == null:
		return 0.0

	var selected_sound: AudioStream = bonus_coin_sound if use_bonus_sound else normal_coin_sound
	if selected_sound == null:
		return 0.0

	_stop_coin_sound()
	coin_sound_player.stream = selected_sound
	coin_sound_player.play()

	var stream_length_seconds: float = selected_sound.get_length()
	if stream_length_seconds <= 0.0:
		return maxf(fallback_sound_lifetime_seconds, 0.0)
	return stream_length_seconds


func _stop_coin_sound() -> void:
	if coin_sound_player != null:
		coin_sound_player.stop()


func _hide_sprite() -> void:
	if sprite != null:
		sprite.visible = false
