extends Node2D
class_name CoinBurstVfx

@export var sprite: Sprite2D
@export var coin_sound_player: AudioStreamPlayer2D
@export var spritesheet: Texture2D = preload("res://assets/vfx/coin/spritesheet.png")
@export var coin_sound_1: AudioStream = preload("res://assets/audio/sfx/ui/coinfx1_loop.mp3")
@export var coin_sound_2: AudioStream = preload("res://assets/audio/sfx/ui/coinfx2_loop.mp3")
@export var coin_sound_3: AudioStream = preload("res://assets/audio/sfx/ui/coinfx3_loop.mp3")
@export var frame_size: Vector2i = Vector2i(128, 128)
@export var frame_count: int = 31
@export var frame_duration_seconds: float = 0.024
@export var pixel_scale: float = 0.44
@export var coin_sound_cutoff_seconds: float = 0.72

var _play_tween: Tween
var _sound_stop_tween: Tween
var _coin_sound_random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_resolve_child_references()
	if sprite == null:
		return

	_coin_sound_random.randomize()
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
	_play_random_coin_sound()

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


func _play_random_coin_sound() -> void:
	if coin_sound_player == null:
		return

	var available_sounds: Array[AudioStream] = []
	if coin_sound_1 != null:
		available_sounds.append(coin_sound_1)
	if coin_sound_2 != null:
		available_sounds.append(coin_sound_2)
	if coin_sound_3 != null:
		available_sounds.append(coin_sound_3)
	if available_sounds.is_empty():
		return

	_stop_coin_sound()
	var selected_index: int = _coin_sound_random.randi_range(0, available_sounds.size() - 1)
	coin_sound_player.stream = available_sounds[selected_index]
	coin_sound_player.play()

	if _sound_stop_tween != null and _sound_stop_tween.is_valid():
		_sound_stop_tween.kill()
	_sound_stop_tween = create_tween()
	_sound_stop_tween.tween_interval(maxf(coin_sound_cutoff_seconds, 0.0))
	_sound_stop_tween.tween_callback(_stop_coin_sound)


func _stop_coin_sound() -> void:
	if coin_sound_player != null:
		coin_sound_player.stop()


func _resolve_child_references() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite") as Sprite2D
	if coin_sound_player == null:
		coin_sound_player = get_node_or_null("CoinSoundPlayer") as AudioStreamPlayer2D
