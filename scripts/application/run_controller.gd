extends Node
class_name RunController

signal product_scan_requested(actor: Node2D, contact_position: Vector2)
signal bag_drop_requested(actor: Node2D)
signal trash_drop_requested(actor: Node2D)
signal coupon_purchase_requested()
signal assortment_upgrade_requested()

@export var checkout_table: Control
@export var hud_root: Control

var registry: ContentRegistry


func _ready() -> void:
	_connect_presentation()


func configure(content_registry: ContentRegistry) -> void:
	registry = content_registry
	_update_phase_three_hud_preview()


func _connect_presentation() -> void:
	if checkout_table != null:
		_connect_signal_once(checkout_table, "product_scan_contact_started", _on_product_scan_contact_started)
		_connect_signal_once(checkout_table, "actor_bag_drop_requested", _on_actor_bag_drop_requested)
		_connect_signal_once(checkout_table, "actor_trash_drop_requested", _on_actor_trash_drop_requested)

	if hud_root != null:
		_connect_signal_once(hud_root, "coupon_button_pressed", _on_coupon_button_pressed)
		_connect_signal_once(hud_root, "assortment_upgrade_button_pressed", _on_assortment_upgrade_button_pressed)


func _update_phase_three_hud_preview() -> void:
	if hud_root == null or registry == null or registry.game_balance == null:
		return

	var balance: GameBalanceResource = registry.game_balance
	if not hud_root.has_method("update_run_summary"):
		return

	hud_root.call(
		"update_run_summary",
		1,
		1,
		balance.customers_per_day,
		balance.daily_rent_cents,
		balance.start_money_cents
	)
	if hud_root.has_method("set_coupon_button_enabled"):
		hud_root.call("set_coupon_button_enabled", true)
	if hud_root.has_method("set_assortment_upgrade_button"):
		hud_root.call("set_assortment_upgrade_button", "Stock Up", true)


func _on_product_scan_contact_started(actor: Node2D, contact_position: Vector2) -> void:
	product_scan_requested.emit(actor, contact_position)


func _on_actor_bag_drop_requested(actor: Node2D) -> void:
	bag_drop_requested.emit(actor)


func _on_actor_trash_drop_requested(actor: Node2D) -> void:
	trash_drop_requested.emit(actor)


func _on_coupon_button_pressed() -> void:
	coupon_purchase_requested.emit()
	if hud_root != null and hud_root.has_method("show_coupon_popup"):
		hud_root.call("show_coupon_popup")


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_requested.emit()


func _connect_signal_once(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)
