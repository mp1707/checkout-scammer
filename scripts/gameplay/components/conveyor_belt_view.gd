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
@export var spawn_tween_duration: float = 0.22
@export var spawn_stagger_seconds: float = 0.04

var _actors_by_slot: Dictionary[int, Node2D] = {}
var _actors_by_object_key: Dictionary[String, Node2D] = {}
var _object_keys_by_slot: Dictionary[int, String] = {}
var _spawn_tweens_by_object_key: Dictionary[String, Tween] = {}


func _ready() -> void:
	_resolve_child_references()


func display_slots(slots: Array[BeltSlot]) -> void:
	_resolve_child_references()
	var stale_object_keys: Dictionary[String, bool] = {}
	for object_key: String in _actors_by_object_key.keys():
		stale_object_keys[object_key] = true

	_actors_by_slot.clear()
	_object_keys_by_slot.clear()

	for slot: BeltSlot in slots:
		if slot == null or not slot.has_object():
			continue

		var slot_marker: Marker2D = get_slot_marker(slot.slot_index)
		if slot_marker == null:
			push_warning("Missing conveyor slot marker for slot %d." % slot.slot_index)
			continue

		var object_key: String = _get_slot_object_key(slot)
		if object_key.is_empty():
			continue

		var actor: Node2D = _actors_by_object_key.get(object_key) as Node2D
		var is_new_actor: bool = actor == null or not is_instance_valid(actor)
		if is_new_actor:
			actor = _instantiate_actor_for_slot(slot)
			if actor == null:
				continue
			_add_actor_to_container(actor)
			_actors_by_object_key[object_key] = actor
			_emit_actor_spawned(actor, slot.slot_index)
		else:
			actor.set("slot_index", slot.slot_index)

		stale_object_keys.erase(object_key)
		_actors_by_slot[slot.slot_index] = actor
		_object_keys_by_slot[slot.slot_index] = object_key
		_move_actor_to_slot(actor, object_key, slot_marker, is_new_actor, slot.slot_index)

	for object_key: String in stale_object_keys.keys():
		_remove_actor_for_object_key(object_key)


func clear_actors() -> void:
	for actor: Node2D in _actors_by_slot.values():
		if actor != null and is_instance_valid(actor):
			actor.queue_free()
	_actors_by_slot.clear()
	_actors_by_object_key.clear()
	_object_keys_by_slot.clear()
	for tween: Tween in _spawn_tweens_by_object_key.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_spawn_tweens_by_object_key.clear()


func release_actor(actor: Node2D) -> void:
	if actor == null:
		return

	var slot_index: int = _get_actor_slot_index(actor)
	if slot_index < 0:
		return
	if _actors_by_slot.get(slot_index) == actor:
		_actors_by_slot.erase(slot_index)
		var object_key: String = _object_keys_by_slot.get(slot_index, "")
		_object_keys_by_slot.erase(slot_index)
		if not object_key.is_empty() and _actors_by_object_key.get(object_key) == actor:
			_actors_by_object_key.erase(object_key)
			_kill_spawn_tween(object_key)


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


func _add_actor_to_container(actor: Node2D) -> void:
	if actor_container != null:
		actor_container.add_child(actor)
	else:
		add_child(actor)


func _move_actor_to_slot(
	actor: Node2D,
	object_key: String,
	slot_marker: Marker2D,
	from_spawn: bool,
	slot_index: int
) -> void:
	var target_position: Vector2 = _get_marker_position_in_actor_container(slot_marker)
	_kill_spawn_tween(object_key)

	if not from_spawn or spawn_marker == null or spawn_tween_duration <= 0.0:
		actor.position = target_position
		return

	actor.position = _get_marker_position_in_actor_container(spawn_marker)
	var tween: Tween = actor.create_tween()
	_spawn_tweens_by_object_key[object_key] = tween
	tween.tween_property(actor, "position", target_position, spawn_tween_duration) \
		.set_delay(spawn_stagger_seconds * float(slot_index)) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _get_marker_position_in_actor_container(marker: Marker2D) -> Vector2:
	if actor_container != null:
		return actor_container.to_local(marker.global_position)
	return marker.position


func _remove_actor_for_object_key(object_key: String) -> void:
	var actor: Node2D = _actors_by_object_key.get(object_key) as Node2D
	_kill_spawn_tween(object_key)
	if actor != null and is_instance_valid(actor):
		actor.queue_free()
	_actors_by_object_key.erase(object_key)


func _kill_spawn_tween(object_key: String) -> void:
	var tween: Tween = _spawn_tweens_by_object_key.get(object_key) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_spawn_tweens_by_object_key.erase(object_key)


func _get_slot_object_key(slot: BeltSlot) -> String:
	match slot.slot_kind:
		BeltSlot.SlotKind.PRODUCT:
			if slot.product_instance != null:
				return "product:%s" % slot.product_instance.instance_id
		BeltSlot.SlotKind.COUPON:
			if slot.coupon_instance != null:
				return "coupon:%s" % slot.coupon_instance.instance_id
		_:
			return ""
	return ""


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
