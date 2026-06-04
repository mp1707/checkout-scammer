extends Control
class_name CheckoutTable

signal product_scan_contact_started(actor: Node2D, contact_position: Vector2)
signal product_scan_contact_ended(actor: Node2D)
signal actor_bag_drop_requested(actor: Node2D)
signal actor_trash_drop_requested(actor: Node2D)
signal actor_released_outside_drop_zones(actor: Node2D)
signal product_actor_spawned(actor: Node2D, slot_index: int)
signal coupon_actor_spawned(actor: Node2D, slot_index: int)

@export var conveyor_belt_view: Node2D
@export var scanner_station: Node2D
@export var bag_zone: Area2D
@export var trash_zone: Area2D
@export var customer_hand_view: Node2D


func _ready() -> void:
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


func _connect_children() -> void:
	if scanner_station != null:
		_connect_signal_once(scanner_station, "product_contact_started", _on_product_scan_contact_started)
		_connect_signal_once(scanner_station, "product_contact_ended", _on_product_scan_contact_ended)

	if conveyor_belt_view != null:
		_connect_signal_once(conveyor_belt_view, "product_actor_spawned", _on_product_actor_spawned)
		_connect_signal_once(conveyor_belt_view, "coupon_actor_spawned", _on_coupon_actor_spawned)

	_connect_signal_once(bag_zone, "actor_dropped", _on_bag_zone_actor_dropped)
	_connect_signal_once(trash_zone, "actor_dropped", _on_trash_zone_actor_dropped)


func _on_product_actor_spawned(actor: Node2D, slot_index: int) -> void:
	product_actor_spawned.emit(actor, slot_index)
	_connect_signal_once(actor, "drag_ended", _on_actor_drag_ended)


func _on_coupon_actor_spawned(actor: Node2D, slot_index: int) -> void:
	coupon_actor_spawned.emit(actor, slot_index)
	_connect_signal_once(actor, "drag_ended", _on_actor_drag_ended)


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


func _on_bag_zone_actor_dropped(actor: Node2D) -> void:
	actor_bag_drop_requested.emit(actor)


func _on_trash_zone_actor_dropped(actor: Node2D) -> void:
	actor_trash_drop_requested.emit(actor)


func _connect_signal_once(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)
