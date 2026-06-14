extends Node2D
class_name ProductScatterView

signal product_actor_spawned(actor: ProductActor, slot_index: int)
signal coupon_actor_spawned(actor: CouponActor, slot_index: int)

@export var actor_container: Node2D
@export var slot_marker_root: Node2D
@export var spawn_marker: Marker2D
@export var exit_marker: Marker2D
@export var product_actor_scene: PackedScene
@export var coupon_actor_scene: PackedScene
@export var spawn_tween_duration: float = 0.22
@export var spawn_stagger_seconds: float = 0.04

var _actors_by_slot: Dictionary[int, TableActor] = {}
var _actors_by_object_key: Dictionary[String, TableActor] = {}
var _object_keys_by_slot: Dictionary[int, String] = {}
var _spawn_tweens_by_object_key: Dictionary[String, Tween] = {}


func _ready() -> void:
	_validate_required_references()


func display_slots(slots: Array[VisibleObjectSlot]) -> void:
	var stale_object_keys: Dictionary[String, bool] = {}
	for object_key: String in _actors_by_object_key.keys():
		stale_object_keys[object_key] = true

	_actors_by_slot.clear()
	_object_keys_by_slot.clear()

	for slot: VisibleObjectSlot in slots:
		if slot == null or not slot.has_object() or slot.is_taken:
			continue

		var slot_marker: Marker2D = get_slot_marker(slot.slot_index)
		if slot_marker == null:
			push_warning("Missing product scatter slot marker for slot %d." % slot.slot_index)
			continue

		var object_key: String = _get_slot_object_key(slot)
		if object_key.is_empty():
			continue

		var actor: TableActor = _actors_by_object_key.get(object_key) as TableActor
		var is_new_actor: bool = actor == null or not is_instance_valid(actor)
		if is_new_actor:
			actor = _instantiate_actor_for_slot(slot)
			if actor == null:
				continue
			_add_actor_to_container(actor)
			_actors_by_object_key[object_key] = actor
			_emit_actor_spawned(actor, slot.slot_index)
		else:
			actor.slot_index = slot.slot_index

		stale_object_keys.erase(object_key)
		_actors_by_slot[slot.slot_index] = actor
		_object_keys_by_slot[slot.slot_index] = object_key
		if is_new_actor:
			_move_actor_to_slot(actor, object_key, slot_marker, true, slot.slot_index)

	for object_key: String in stale_object_keys.keys():
		_remove_actor_for_object_key(object_key)


func clear_actors() -> void:
	for actor: TableActor in _actors_by_slot.values():
		if actor != null and is_instance_valid(actor):
			actor.queue_free()
	_actors_by_slot.clear()
	_actors_by_object_key.clear()
	_object_keys_by_slot.clear()
	for tween: Tween in _spawn_tweens_by_object_key.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_spawn_tweens_by_object_key.clear()


func release_actor(actor: TableActor) -> void:
	if actor == null or actor.slot_index < 0:
		return
	var object_key: String = _object_keys_by_slot.get(actor.slot_index, "")
	if not object_key.is_empty():
		_kill_spawn_tween(object_key)


func set_actor_input_enabled(is_enabled: bool) -> void:
	for actor: TableActor in _actors_by_object_key.values():
		if actor != null and is_instance_valid(actor):
			actor.set_interaction_enabled(is_enabled)


## Finds the topmost product actor whose hitbox contains the point. Searches the
## actor container directly so actors lying loose on the table are found too.
func find_product_actor_at(global_point: Vector2) -> ProductActor:
	if actor_container == null:
		return null

	var children: Array[Node] = actor_container.get_children()
	for child_index: int in range(children.size() - 1, -1, -1):
		var product_actor: ProductActor = children[child_index] as ProductActor
		if product_actor != null and product_actor.contains_global_point(global_point):
			return product_actor

	return null


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


func _validate_required_references() -> void:
	if actor_container == null:
		push_error("%s is missing required scene reference 'actor_container'." % get_path())
	if slot_marker_root == null:
		push_error("%s is missing required scene reference 'slot_marker_root'." % get_path())
	if product_actor_scene == null:
		push_error("%s is missing required scene reference 'product_actor_scene'." % get_path())
	if coupon_actor_scene == null:
		push_error("%s is missing required scene reference 'coupon_actor_scene'." % get_path())


func _instantiate_actor_for_slot(slot: VisibleObjectSlot) -> TableActor:
	match slot.slot_kind:
		VisibleObjectSlot.SlotKind.PRODUCT:
			return _instantiate_product_actor(slot)
		VisibleObjectSlot.SlotKind.COUPON:
			return _instantiate_coupon_actor(slot)
		_:
			return null


func _instantiate_product_actor(slot: VisibleObjectSlot) -> ProductActor:
	if product_actor_scene == null:
		return null

	var actor: ProductActor = product_actor_scene.instantiate() as ProductActor
	if actor == null:
		push_error("Configured product_actor_scene does not instance a ProductActor.")
		return null

	actor.slot_index = slot.slot_index
	actor.set_product_instance(slot.product_instance)
	return actor


func _instantiate_coupon_actor(slot: VisibleObjectSlot) -> CouponActor:
	if coupon_actor_scene == null:
		return null

	var actor: CouponActor = coupon_actor_scene.instantiate() as CouponActor
	if actor == null:
		push_error("Configured coupon_actor_scene does not instance a CouponActor.")
		return null

	actor.slot_index = slot.slot_index
	actor.set_coupon_instance(slot.coupon_instance)
	return actor


func _add_actor_to_container(actor: TableActor) -> void:
	if actor_container != null:
		actor_container.add_child(actor)
	else:
		add_child(actor)


func _move_actor_to_slot(
	actor: TableActor,
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
	var actor: TableActor = _actors_by_object_key.get(object_key) as TableActor
	_kill_spawn_tween(object_key)
	if actor != null and is_instance_valid(actor):
		actor.queue_free()
	_actors_by_object_key.erase(object_key)


func _kill_spawn_tween(object_key: String) -> void:
	var tween: Tween = _spawn_tweens_by_object_key.get(object_key) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_spawn_tweens_by_object_key.erase(object_key)


func _get_slot_object_key(slot: VisibleObjectSlot) -> String:
	match slot.slot_kind:
		VisibleObjectSlot.SlotKind.PRODUCT:
			if slot.product_instance != null:
				return "product:%s" % slot.product_instance.instance_id
		VisibleObjectSlot.SlotKind.COUPON:
			if slot.coupon_instance != null:
				return "coupon:%s" % slot.coupon_instance.instance_id
		_:
			return ""
	return ""


func _emit_actor_spawned(actor: TableActor, slot_index: int) -> void:
	var product_actor: ProductActor = actor as ProductActor
	if product_actor != null:
		product_actor_spawned.emit(product_actor, slot_index)
		return

	var coupon_actor: CouponActor = actor as CouponActor
	if coupon_actor != null:
		coupon_actor_spawned.emit(coupon_actor, slot_index)
