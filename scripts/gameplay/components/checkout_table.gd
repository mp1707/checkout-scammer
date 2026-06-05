extends Control
class_name CheckoutTable

signal product_scan_contact_started(actor: Node2D, contact_position: Vector2)
signal product_scan_contact_ended(actor: Node2D)
signal actor_scan_contact_started(actor: Node2D, contact_position: Vector2)
signal actor_scan_contact_ended(actor: Node2D)
signal actor_taken_from_belt(actor: Node2D)
signal actor_bag_drop_requested(actor: Node2D)
signal actor_trash_drop_requested(actor: Node2D)
signal actor_released_outside_drop_zones(actor: Node2D)
signal product_actor_spawned(actor: Node2D, slot_index: int)
signal coupon_actor_spawned(actor: Node2D, slot_index: int)

@export var conveyor_belt_view: ConveyorBeltView
@export var scanner_station: ScannerStation
@export var bag_zone: Area2D
@export var trash_zone: Area2D
@export var customer_hand_view: Node2D
@export var vfx_container: Node2D
@export var coin_burst_scene: PackedScene

var _shake_tween: Tween
var _base_position: Vector2


func _ready() -> void:
	_base_position = position
	_resolve_child_references()
	_connect_children()


func display_belt_slots(slots: Array[BeltSlot]) -> void:
	if conveyor_belt_view != null:
		conveyor_belt_view.call("display_slots", slots)


func clear_belt() -> void:
	if conveyor_belt_view != null:
		conveyor_belt_view.call("clear_actors")


func set_mood_ring_color(color: Color) -> void:
	if customer_hand_view != null:
		customer_hand_view.call("set_mood_ring_color", color)


func set_mood_ring_state(color: Color, suspicion_percent: int) -> void:
	if customer_hand_view == null:
		return
	if customer_hand_view.has_method("set_mood_ring_state"):
		customer_hand_view.call("set_mood_ring_state", color, suspicion_percent)
	else:
		customer_hand_view.call("set_mood_ring_color", color)


func pulse_mood_ring() -> void:
	if customer_hand_view != null and customer_hand_view.has_method("pulse_mood_ring"):
		customer_hand_view.call("pulse_mood_ring")


func play_successful_scan_feedback(actor: Node2D, scan_count: int, contact_position: Vector2) -> void:
	if scanner_station != null and scanner_station.has_method("play_success_feedback"):
		scanner_station.call("play_success_feedback", scan_count)

	if actor != null and actor.has_method("play_successful_scan_feedback"):
		actor.call("play_successful_scan_feedback", scan_count)

	_spawn_coin_burst(_get_actor_feedback_position(actor, contact_position))
	if scan_count > 1:
		_play_table_jolt(scan_count)


func play_actor_finish_feedback(actor: Node2D, is_sale: bool) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var finish_position: Vector2 = _get_actor_finish_position(actor, is_sale)
	if actor.has_method("play_finish_feedback"):
		actor.call("play_finish_feedback", finish_position, is_sale)
	else:
		actor.queue_free()


func _connect_children() -> void:
	if scanner_station != null:
		_connect_signal_once(scanner_station, "actor_contact_started", _on_actor_scan_contact_started)
		_connect_signal_once(scanner_station, "actor_contact_ended", _on_actor_scan_contact_ended)
		_connect_signal_once(scanner_station, "product_contact_started", _on_product_scan_contact_started)
		_connect_signal_once(scanner_station, "product_contact_ended", _on_product_scan_contact_ended)

	if conveyor_belt_view != null:
		_connect_signal_once(conveyor_belt_view, "product_actor_spawned", _on_product_actor_spawned)
		_connect_signal_once(conveyor_belt_view, "coupon_actor_spawned", _on_coupon_actor_spawned)

	_connect_signal_once(bag_zone, "actor_dropped", _on_bag_zone_actor_dropped)
	_connect_signal_once(trash_zone, "actor_dropped", _on_trash_zone_actor_dropped)


func _on_product_actor_spawned(actor: Node2D, slot_index: int) -> void:
	product_actor_spawned.emit(actor, slot_index)
	_connect_signal_once(actor, "drag_started", _on_actor_drag_started)
	_connect_signal_once(actor, "drag_ended", _on_actor_drag_ended)


func _on_coupon_actor_spawned(actor: Node2D, slot_index: int) -> void:
	coupon_actor_spawned.emit(actor, slot_index)
	_connect_signal_once(actor, "drag_started", _on_actor_drag_started)
	_connect_signal_once(actor, "drag_ended", _on_actor_drag_ended)


func _on_actor_drag_started(actor: Node2D) -> void:
	if conveyor_belt_view != null:
		conveyor_belt_view.release_actor(actor)
	actor_taken_from_belt.emit(actor)


func _on_actor_drag_ended(actor: Node2D, _drop_position: Vector2) -> void:
	_route_actor_drop(actor)


func _route_actor_drop(actor: Node2D) -> void:
	if bag_zone != null and bag_zone.has_method("try_drop_actor") and bag_zone.call("try_drop_actor", actor):
		return
	if trash_zone != null and trash_zone.has_method("try_drop_actor") and trash_zone.call("try_drop_actor", actor):
		return
	actor_released_outside_drop_zones.emit(actor)


func _on_product_scan_contact_started(actor: Node2D, contact_position: Vector2) -> void:
	product_scan_contact_started.emit(actor, contact_position)


func _on_product_scan_contact_ended(actor: Node2D) -> void:
	product_scan_contact_ended.emit(actor)


func _on_actor_scan_contact_started(actor: Node2D, contact_position: Vector2) -> void:
	actor_scan_contact_started.emit(actor, contact_position)


func _on_actor_scan_contact_ended(actor: Node2D) -> void:
	actor_scan_contact_ended.emit(actor)


func _on_bag_zone_actor_dropped(actor: Node2D) -> void:
	actor_bag_drop_requested.emit(actor)


func _on_trash_zone_actor_dropped(actor: Node2D) -> void:
	actor_trash_drop_requested.emit(actor)


func _connect_signal_once(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _spawn_coin_burst(burst_global_position: Vector2) -> void:
	if coin_burst_scene == null:
		return

	var vfx_node: Node2D = coin_burst_scene.instantiate() as Node2D
	if vfx_node == null:
		return

	if vfx_container != null:
		vfx_container.add_child(vfx_node)
	else:
		add_child(vfx_node)

	if vfx_node.has_method("play_at"):
		vfx_node.call("play_at", burst_global_position)
	else:
		vfx_node.global_position = burst_global_position.round()


func _get_actor_feedback_position(actor: Node2D, fallback_position: Vector2) -> Vector2:
	if actor != null and actor.has_method("get_feedback_anchor_global_position"):
		var feedback_position: Variant = actor.call("get_feedback_anchor_global_position")
		if feedback_position is Vector2:
			return feedback_position
	return fallback_position


func _get_actor_finish_position(actor: Node2D, is_sale: bool) -> Vector2:
	var zone: Area2D = bag_zone if is_sale else trash_zone
	if zone != null and zone.has_method("get_drop_position"):
		var drop_position: Variant = zone.call("get_drop_position")
		if drop_position is Vector2:
			return drop_position
	if actor != null:
		return actor.global_position
	return global_position


func _play_table_jolt(scan_count: int) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	var strength: float = minf(1.0 + float(scan_count - 2) * 0.35, 2.0)
	position = _base_position
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "position", _base_position + Vector2(-strength, 0.0), 0.025)
	_shake_tween.tween_property(self, "position", _base_position + Vector2(strength, 0.0), 0.035)
	_shake_tween.tween_property(self, "position", _base_position, 0.045) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _resolve_child_references() -> void:
	if conveyor_belt_view == null:
		conveyor_belt_view = get_node_or_null("ConveyorBeltView") as ConveyorBeltView
	if scanner_station == null:
		scanner_station = get_node_or_null("ScannerStation") as ScannerStation
	if bag_zone == null:
		bag_zone = get_node_or_null("BagZone") as Area2D
	if trash_zone == null:
		trash_zone = get_node_or_null("TrashZone") as Area2D
	if customer_hand_view == null:
		customer_hand_view = get_node_or_null("CustomerHandView") as Node2D
	if vfx_container == null:
		vfx_container = get_node_or_null("VfxContainer") as Node2D
