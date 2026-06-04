extends Node2D
class_name ScannerStation

signal product_contact_started(actor: Node2D, contact_position: Vector2)
signal product_contact_ended(actor: Node2D)
signal actor_contact_started(actor: Node2D, contact_position: Vector2)
signal actor_contact_ended(actor: Node2D)

@export var hit_area: Area2D
@export var beam: CanvasItem
@export var feedback_anchor: Marker2D
@export var animation_player: AnimationPlayer


func _ready() -> void:
	_resolve_child_references()
	if hit_area == null:
		return
	if not hit_area.area_entered.is_connected(_on_hit_area_entered):
		hit_area.area_entered.connect(_on_hit_area_entered)
	if not hit_area.area_exited.is_connected(_on_hit_area_exited):
		hit_area.area_exited.connect(_on_hit_area_exited)


func set_beam_visible(is_visible: bool) -> void:
	if beam != null:
		beam.visible = is_visible


func flash() -> void:
	if animation_player != null and animation_player.has_animation("flash"):
		animation_player.play("flash")


func _on_hit_area_entered(area: Area2D) -> void:
	var actor: Node2D = _find_actor_from_area(area)
	if actor == null:
		return

	var contact_position: Vector2 = area.global_position
	actor_contact_started.emit(actor, contact_position)

	if not actor.has_method("set_touching_scanner"):
		return

	actor.call("set_touching_scanner", true, contact_position)
	product_contact_started.emit(actor, contact_position)


func _on_hit_area_exited(area: Area2D) -> void:
	var actor: Node2D = _find_actor_from_area(area)
	if actor == null:
		return

	actor_contact_ended.emit(actor)

	if not actor.has_method("set_touching_scanner"):
		return

	actor.call("set_touching_scanner", false, Vector2.ZERO)
	product_contact_ended.emit(actor)


func _find_actor_from_area(area: Area2D) -> Node2D:
	if area == null:
		return null

	var node: Node = area
	while node != null:
		var actor: Node2D = node as Node2D
		if actor != null and actor.has_method("get_contact_area"):
			return actor
		node = node.get_parent()

	return null


func _resolve_child_references() -> void:
	if hit_area == null:
		hit_area = get_node_or_null("HitArea") as Area2D
	if beam == null:
		beam = get_node_or_null("Beam") as CanvasItem
	if feedback_anchor == null:
		feedback_anchor = get_node_or_null("FeedbackAnchor") as Marker2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
