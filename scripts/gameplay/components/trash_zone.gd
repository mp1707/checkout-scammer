extends Area2D
class_name TrashZone

signal actor_dropped(actor: TableActor)

@export var drop_anchor: Marker2D
@export var swoosh_player: AudioStreamPlayer2D


func _ready() -> void:
	if drop_anchor == null:
		push_error("%s is missing required scene reference 'drop_anchor'." % get_path())
	if swoosh_player == null:
		push_error("%s is missing required scene reference 'swoosh_player'." % get_path())


func try_drop_actor(actor: TableActor) -> bool:
	if not can_accept_actor(actor):
		return false

	_play_swoosh_sound()
	actor_dropped.emit(actor)
	return true


func can_accept_actor(actor: TableActor) -> bool:
	if actor == null:
		return false

	var contact_area: Area2D = actor.get_contact_area()
	return contact_area != null and get_overlapping_areas().has(contact_area)


func get_drop_position() -> Vector2:
	if drop_anchor != null:
		return drop_anchor.global_position
	return global_position


func _play_swoosh_sound() -> void:
	if swoosh_player == null:
		return

	swoosh_player.stop()
	swoosh_player.play()
