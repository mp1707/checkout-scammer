extends Node2D
class_name ConveyorBeltView

signal actor_spawned(actor: Node2D, slot_index: int)
signal product_actor_spawned(actor: Node2D, slot_index: int)
signal coupon_actor_spawned(actor: Node2D, slot_index: int)

@export var actor_container: Node2D
@export var slot_marker_root: Node2D
@export var spawn_marker: Marker2D
@export var exit_marker: Marker2D
@export var product_actor_scene: PackedScene
@export var coupon_actor_scene: PackedScene

var _actors_by_slot: Dictionary[int, Node2D] = {}


func _ready() -> void:
	_resolve_child_references()


func display_slots(slots: Array[BeltSlot]) -> void:
	_resolve_child_references()
	clear_actors()

	for slot: BeltSlot in slots:
		if slot == null or not slot.has_object():
			continue

		var slot_marker: Marker2D = get_slot_marker(slot.slot_index)
		if slot_marker == null:
			push_warning("Missing conveyor slot marker for slot %d." % slot.slot_index)
			continue

		var actor: Node2D = _instantiate_actor_for_slot(slot)
		if actor == null:
			continue

		actor.position = actor_container.to_local(slot_marker.global_position) if actor_container != null else slot_marker.position
		if actor_container != null:
			actor_container.add_child(actor)
		else:
			add_child(actor)

		_actors_by_slot[slot.slot_index] = actor
		_emit_actor_spawned(actor, slot.slot_index)


func clear_actors() -> void:
	for actor: Node2D in _actors_by_slot.values():
		if actor != null and is_instance_valid(actor):
			actor.queue_free()
	_actors_by_slot.clear()


func release_actor(actor: Node2D) -> void:
	if actor == null:
		return

	var slot_index: int = _get_actor_slot_index(actor)
	if slot_index < 0:
		return
	if _actors_by_slot.get(slot_index) == actor:
		_actors_by_slot.erase(slot_index)


func get_actor_for_slot(slot_index: int) -> Node2D:
	return _actors_by_slot.get(slot_index) as Node2D


func get_slot_marker(slot_index: int) -> Marker2D:
	if slot_marker_root == null:
		return null
	var marker_index: int = 0
	for child: Node in slot_marker_root.get_children():
		var marker: Marker2D = child as Marker2D
		if marker == null:
			continue
		if marker_index == slot_index:
			return marker
		marker_index += 1
	return null


func _instantiate_actor_for_slot(slot: BeltSlot) -> Node2D:
	match slot.slot_kind:
		BeltSlot.SlotKind.PRODUCT:
			return _instantiate_product_actor(slot)
		BeltSlot.SlotKind.COUPON:
			return _instantiate_coupon_actor(slot)
		_:
			return null


func _instantiate_product_actor(slot: BeltSlot) -> Node2D:
	if product_actor_scene == null:
		push_warning("ConveyorBeltView needs a ProductActor scene.")
		return null

	var actor: Node2D = product_actor_scene.instantiate() as Node2D
	if actor == null:
		push_warning("Configured product_actor_scene does not instance Node2D.")
		return null

	actor.set("slot_index", slot.slot_index)
	if actor.has_method("set_product_instance"):
		actor.call("set_product_instance", slot.product_instance)
	return actor


func _instantiate_coupon_actor(slot: BeltSlot) -> Node2D:
	if coupon_actor_scene == null:
		push_warning("ConveyorBeltView needs a CouponActor scene.")
		return null

	var actor: Node2D = coupon_actor_scene.instantiate() as Node2D
	if actor == null:
		push_warning("Configured coupon_actor_scene does not instance Node2D.")
		return null

	actor.set("slot_index", slot.slot_index)
	if actor.has_method("set_coupon_instance"):
		actor.call("set_coupon_instance", slot.coupon_instance)
	return actor


func _emit_actor_spawned(actor: Node2D, slot_index: int) -> void:
	actor_spawned.emit(actor, slot_index)
	if actor.has_method("set_product_instance"):
		product_actor_spawned.emit(actor, slot_index)
		return

	if actor.has_method("set_coupon_instance"):
		coupon_actor_spawned.emit(actor, slot_index)


func _get_actor_slot_index(actor: Node2D) -> int:
	var slot_index_value: Variant = actor.get("slot_index")
	if slot_index_value is int:
		return slot_index_value
	return -1


func _resolve_child_references() -> void:
	if actor_container == null:
		actor_container = get_node_or_null("ActorContainer") as Node2D
	if slot_marker_root == null:
		slot_marker_root = get_node_or_null("SlotMarkers") as Node2D
	if spawn_marker == null:
		spawn_marker = get_node_or_null("SpawnMarker") as Marker2D
	if exit_marker == null:
		exit_marker = get_node_or_null("ExitMarker") as Marker2D
