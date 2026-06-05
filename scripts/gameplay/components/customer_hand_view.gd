extends Node2D
class_name CustomerHandView

@export var mood_ring_rect: ColorRect
@export var animation_player: AnimationPlayer

var _base_position: Vector2 = Vector2.ZERO
var _pulse_tween: Tween
var _jitter_tween: Tween


func _ready() -> void:
	_base_position = position
	if mood_ring_rect == null:
		mood_ring_rect = get_node_or_null("MoodRing") as ColorRect
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if mood_ring_rect != null:
		mood_ring_rect.pivot_offset = mood_ring_rect.size * 0.5


func set_mood_ring_color(color: Color) -> void:
	if mood_ring_rect != null:
		mood_ring_rect.color = color


func set_mood_ring_state(color: Color, suspicion_percent: int) -> void:
	set_mood_ring_color(color)
	if suspicion_percent >= 75:
		_play_high_suspicion_jitter(suspicion_percent)
	else:
		_reset_hand_jitter()


func pulse_mood_ring() -> void:
	if animation_player != null and animation_player.has_animation("pulse"):
		animation_player.play("pulse")
		return

	if mood_ring_rect == null:
		return

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	mood_ring_rect.scale = Vector2(1.35, 1.35)
	mood_ring_rect.modulate = Color(1.35, 1.35, 1.35, 1.0)
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)
	_pulse_tween.tween_property(mood_ring_rect, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(mood_ring_rect, "modulate", Color.WHITE, 0.16)
	_pulse_tween.set_parallel(false)


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
