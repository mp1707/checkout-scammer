extends Node2D
class_name OneShotAnimatedVfx

@export var animated_sprite: AnimatedSprite2D
@export var animation_name: StringName = &"default"
@export var free_on_finished: bool = true
@export var hide_on_ready: bool = true
@export var autostart: bool = false


func _ready() -> void:
	if animated_sprite == null:
		push_error("%s is missing required scene reference 'animated_sprite'." % get_path())
		return

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	if hide_on_ready:
		visible = false
		animated_sprite.visible = false
	if autostart:
		play()


func play_at(start_global_position: Vector2) -> void:
	global_position = start_global_position.round()
	play()


func play() -> void:
	if animated_sprite == null:
		return

	visible = true
	animated_sprite.visible = true
	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.play(animation_name)


func stop_and_hide() -> void:
	if animated_sprite != null:
		animated_sprite.stop()
		animated_sprite.visible = false
	visible = false


func _on_animation_finished() -> void:
	if free_on_finished:
		queue_free()
	else:
		stop_and_hide()
