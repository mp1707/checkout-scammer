extends Node2D
class_name CustomerHandView

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var hand_sprite: Sprite2D
@export var green_texture: Texture2D = preload("res://assets/textures/environment/hand_green.png")
@export var yellow_texture: Texture2D = preload("res://assets/textures/environment/hand_yellow.png")
@export var red_texture: Texture2D = preload("res://assets/textures/environment/hand_red.png")
@export var animation_player: AnimationPlayer
@export var yellow_alert_vfx: OneShotAnimatedVfx
@export var red_alert_vfx: OneShotAnimatedVfx
@export var alert_sound_player: AudioStreamPlayer2D
@export var caught_sound_player: AudioStreamPlayer2D

var _base_position: Vector2 = Vector2.ZERO
var _pulse_tween: Tween
var _jitter_tween: Tween
var _current_hand_stage_index: int = -1


func _ready() -> void:
	_base_position = position
	if hand_sprite == null:
		push_error("%s is missing required scene reference 'hand_sprite'." % get_path())
	set_suspicion_state(0, 10)


func set_suspicion_state(hand_stage_index: int, suspicion_percent: int) -> void:
	var previous_stage_index: int = _current_hand_stage_index
	if hand_sprite != null:
		hand_sprite.texture = _get_texture_for_stage(hand_stage_index)
	_current_hand_stage_index = hand_stage_index
	_play_alert_transition_vfx(previous_stage_index, hand_stage_index)
	if hand_stage_index >= 2:
		_play_high_suspicion_jitter(suspicion_percent)
	else:
		_reset_hand_jitter()


func pulse_customer_hand() -> void:
	if animation_player != null and animation_player.has_animation("pulse"):
		animation_player.play("pulse")
		return

	if hand_sprite == null:
		return

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	hand_sprite.scale = Vector2(1.05, 1.05)
	hand_sprite.modulate = theme_resource.hand_pulse_color if theme_resource != null else Color.WHITE
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)
	_pulse_tween.tween_property(hand_sprite, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(hand_sprite, "modulate", Color.WHITE, 0.16)
	_pulse_tween.set_parallel(false)


func play_alert_sound() -> void:
	_play_alert_transition_sound()


func play_caught_sound() -> void:
	_play_audio_player(caught_sound_player)


func _get_texture_for_stage(hand_stage_index: int) -> Texture2D:
	match hand_stage_index:
		0:
			return green_texture
		1:
			return yellow_texture
		_:
			return red_texture


func _play_high_suspicion_jitter(suspicion_percent: int) -> void:
	if _jitter_tween != null and _jitter_tween.is_valid():
		_jitter_tween.kill()

	var jitter_strength: float = 1.0 if suspicion_percent < 90 else 1.5
	position = _base_position
	_jitter_tween = create_tween()
	_jitter_tween.tween_property(self, "position", _base_position + Vector2(jitter_strength, 0.0), 0.035)
	_jitter_tween.tween_property(self, "position", _base_position + Vector2(-jitter_strength, 0.0), 0.045)
	_jitter_tween.tween_property(self, "position", _base_position, 0.055) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _reset_hand_jitter() -> void:
	if _jitter_tween != null and _jitter_tween.is_valid():
		_jitter_tween.kill()
	position = _base_position


func _play_alert_transition_vfx(previous_stage_index: int, new_stage_index: int) -> void:
	if previous_stage_index < 0 or new_stage_index <= previous_stage_index:
		return

	_play_alert_transition_sound()
	match new_stage_index:
		1:
			if yellow_alert_vfx != null:
				yellow_alert_vfx.play()
		_:
			if red_alert_vfx != null:
				red_alert_vfx.play()


func _play_alert_transition_sound() -> void:
	_play_audio_player(alert_sound_player)


func _play_audio_player(player: AudioStreamPlayer2D) -> void:
	if player == null:
		return

	player.stop()
	player.play()

