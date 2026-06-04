extends Area2D
class_name TrashZone

signal actor_dropped(actor: Node2D)

@export var drop_anchor: Marker2D


func _ready() -> void:
	if drop_anchor == null:
		drop_anchor = get_node_or_null("DropAnchor") as Marker2D


func try_drop_actor(actor: Node2D) -> bool:
	if not can_accept_actor(actor):
		return false

	actor_dropped.emit(actor)
	return true


func can_accept_actor(actor: Node2D) -> bool:
	var contact_area: Area2D = _get_actor_contact_area(actor)
	return contact_area != null and get_overlapping_areas().has(contact_area)


func get_drop_position() -> Vector2:
	if drop_anchor != null:
		return drop_anchor.global_position
	return global_position


func _get_actor_contact_area(actor: Node2D) -> Area2D:
	if actor == null or not actor.has_method("get_contact_area"):
		return null
	return actor.call("get_contact_area") as Area2D
