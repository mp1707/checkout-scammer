extends Node2D
class_name CustomerHandView

@export var mood_ring_rect: ColorRect
@export var animation_player: AnimationPlayer


func _ready() -> void:
	if mood_ring_rect == null:
		mood_ring_rect = get_node_or_null("MoodRing") as ColorRect
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer


func set_mood_ring_color(color: Color) -> void:
	if mood_ring_rect != null:
		mood_ring_rect.color = color


func pulse_mood_ring() -> void:
	if animation_player != null and animation_player.has_animation("pulse"):
		animation_player.play("pulse")
