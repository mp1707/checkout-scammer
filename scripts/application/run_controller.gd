extends Node
class_name RunController

signal product_scan_requested(actor: Node2D, contact_position: Vector2)
signal bag_drop_requested(actor: Node2D)
signal trash_drop_requested(actor: Node2D)
signal coupon_purchase_requested()
signal assortment_upgrade_requested()

const CAUGHT_MESSAGE: String = "Kunde: Hey, do you want to scam me? I want compensation!"
const CUSTOMER_BYE_MESSAGE: String = "Thanks, byyyyyeeeeee"
const LOSE_MESSAGE: String = "Rent is due, but the drawer is short. Shift over."
const WIN_MESSAGE: String = "Day 8 rent is paid. You win!"
const CUSTOMER_DONE_DELAY_SECONDS: float = 0.6
const COUPON_BUTTON_TOOLTIP: String = "Coupons wirken ab dem naechsten Kunden. Beim letzten Kunden starten sie morgen."

enum DialogKind {
	NONE,
	CAUGHT,
	CUSTOMER_BYE,
	LOSE,
	WIN,
}

@export var checkout_table: CheckoutTable
@export var hud_root: HudRoot

var registry: ContentRegistry
var run_state: RunState

var _customer_generator: CustomerGenerator = CustomerGenerator.new()
var _belt_system: BeltSystem = BeltSystem.new()
var _scan_system: ScanSystem = ScanSystem.new()
var _suspicion_system: SuspicionSystem = SuspicionSystem.new()
var _economy_system: EconomySystem = EconomySystem.new()
var _coupon_system: CouponSystem = CouponSystem.new()
var _upgrade_system: UpgradeSystem = UpgradeSystem.new()
var _scan_random: RandomNumberGenerator = RandomNumberGenerator.new()
var _taken_actor_ids: Dictionary[String, bool] = {}
var _dialog_kind: int = DialogKind.NONE
var _is_advancing_customer: bool = false
var _is_run_finished: bool = false


func _ready() -> void:
	_resolve_presentation_references()
	_connect_presentation()


func configure(content_registry: ContentRegistry) -> void:
	registry = content_registry
	_resolve_presentation_references()
	_connect_presentation()
	_start_run()


func _connect_presentation() -> void:
	if checkout_table != null:
		_connect_signal_once(checkout_table, "actor_taken_from_belt", _on_actor_taken_from_belt)
		_connect_signal_once(checkout_table, "actor_scan_contact_started", _on_actor_scan_contact_started)
		_connect_signal_once(checkout_table, "product_scan_contact_started", _on_product_scan_contact_started)
		_connect_signal_once(checkout_table, "actor_bag_drop_requested", _on_actor_bag_drop_requested)
		_connect_signal_once(checkout_table, "actor_trash_drop_requested", _on_actor_trash_drop_requested)

	if hud_root != null:
		_connect_signal_once(hud_root, "coupon_button_pressed", _on_coupon_button_pressed)
		_connect_signal_once(hud_root, "coupon_selected", _on_coupon_selected)
		_connect_signal_once(hud_root, "assortment_upgrade_button_pressed", _on_assortment_upgrade_button_pressed)
		_connect_signal_once(hud_root, "dialog_closed", _on_dialog_closed)


func _start_run() -> void:
	if registry == null or registry.game_balance == null:
		return

	run_state = RunState.new()
	run_state.apply_balance(registry.game_balance)
	_scan_random.seed = run_state.run_seed
	_taken_actor_ids.clear()
	_dialog_kind = DialogKind.NONE
	_is_advancing_customer = false
	_is_run_finished = false
	if hud_root != null:
		hud_root.hide_dialog()
		hud_root.close_coupon_popup()

	_start_customer()


func _start_customer() -> void:
	if run_state == null or registry == null or registry.game_balance == null:
		return

	_taken_actor_ids.clear()
	_coupon_system.apply_pending_coupons_for_customer(run_state)
	_upgrade_system.apply_pending_assortment_for_customer(run_state)

	var customer: CustomerState = _customer_generator.generate_customer(registry, run_state)
	_suspicion_system.setup_customer(customer, registry.suspicion_curve)
	var customer_coupon: CouponInstance = _coupon_system.create_customer_belt_coupon(run_state)
	_belt_system.start_customer(customer, registry.game_balance.visible_belt_slots, customer_coupon)
	run_state.current_customer = customer

	_update_belt_view()
	_update_mood_ring()
	_update_hud_state()


func _update_belt_view() -> void:
	if checkout_table == null or run_state == null or run_state.current_customer == null:
		return

	checkout_table.display_belt_slots(run_state.current_customer.visible_slots)


func _update_hud_state() -> void:
	if hud_root == null or registry == null or registry.game_balance == null:
		return

	var balance: GameBalanceResource = registry.game_balance
	var current_day: int = 1
	var current_customer_number: int = 1
	var cash_cents: int = balance.start_money_cents
	var rent_due_cents: int = balance.daily_rent_cents
	if run_state != null:
		current_day = run_state.current_day
		current_customer_number = run_state.current_customer_number
		cash_cents = run_state.cash_cents
		rent_due_cents = run_state.rent_due_cents

	hud_root.update_run_summary(
		current_day,
		current_customer_number,
		balance.customers_per_day,
		rent_due_cents,
		cash_cents
	)
	hud_root.set_coupon_button_enabled(not _is_run_finished and not _get_available_coupon_options().is_empty())
	hud_root.set_coupon_button_tooltip(COUPON_BUTTON_TOOLTIP)
	_update_assortment_button()


func _update_assortment_button() -> void:
	if hud_root == null or registry == null or run_state == null:
		return

	var next_upgrade: UpgradeResource = _upgrade_system.get_next_assortment_upgrade(run_state, registry.upgrades)
	if next_upgrade == null:
		hud_root.set_assortment_upgrade_button("Max Stock", false)
		hud_root.set_assortment_upgrade_tooltip("Alle Sortiment-Level sind freigeschaltet.")
		return

	var label_text: String = "Lvl %d %s" % [
		next_upgrade.target_assortment_level,
		_economy_system.format_cents(next_upgrade.cost_cents),
	]
	hud_root.set_assortment_upgrade_button(
		label_text,
		not _is_run_finished and _upgrade_system.can_purchase_assortment_upgrade(run_state, next_upgrade)
	)
	hud_root.set_assortment_upgrade_tooltip(_build_assortment_upgrade_tooltip(next_upgrade))


func _update_mood_ring() -> void:
	if checkout_table == null or registry == null or run_state == null or run_state.current_customer == null:
		return

	var color: Color = _suspicion_system.get_mood_ring_color(
		run_state.current_customer.current_suspicion_percent,
		registry.suspicion_curve
	)
	checkout_table.set_mood_ring_color(color)


func _on_product_scan_contact_started(actor: Node2D, contact_position: Vector2) -> void:
	product_scan_requested.emit(actor, contact_position)
	if _should_ignore_player_input():
		return

	var product_instance: ProductInstance = _get_product_instance(actor)
	if product_instance == null:
		return

	var request: ScanRequest = ScanRequest.new()
	request.actor_id = _get_actor_id(actor)
	request.product_instance = product_instance
	request.is_held = _get_actor_bool(actor, "is_held")
	request.is_touching_scanner = _get_actor_bool(actor, "is_touching_scanner")
	request.movement_direction = _get_actor_vector(actor, "movement_direction")
	request.scanner_contact_position = contact_position
	request.product_rotation_degrees = actor.rotation_degrees

	var result: ScanResult = _scan_system.evaluate_scan(
		request,
		run_state.current_customer,
		_suspicion_system,
		registry.suspicion_curve,
		_scan_random
	)
	if result.was_caught:
		_handle_caught_scan(actor, product_instance)
		return
	if not result.is_valid_scan:
		return

	_economy_system.apply_successful_scan(
		result,
		_coupon_system.get_honest_customer_coupons(run_state.current_customer)
	)
	if actor.has_method("update_open_amount_label"):
		actor.call("update_open_amount_label")
	_update_mood_ring()


func _on_actor_bag_drop_requested(actor: Node2D) -> void:
	bag_drop_requested.emit(actor)
	if _should_ignore_player_input():
		return

	var product_instance: ProductInstance = _get_product_instance(actor)
	if product_instance != null:
		_economy_system.payout_product(run_state, product_instance)
		_belt_system.mark_product_processed(run_state.current_customer, product_instance)
		_finish_actor(actor)
		_after_customer_object_processed()
		return

	var coupon_instance: CouponInstance = _get_coupon_instance(actor)
	if coupon_instance != null:
		_process_coupon_honestly(actor, coupon_instance)


func _on_actor_trash_drop_requested(actor: Node2D) -> void:
	trash_drop_requested.emit(actor)
	if _should_ignore_player_input():
		return

	var product_instance: ProductInstance = _get_product_instance(actor)
	if product_instance != null:
		_economy_system.trash_product(run_state, product_instance)
		_belt_system.mark_product_processed(run_state.current_customer, product_instance)
		_finish_actor(actor)
		_after_customer_object_processed()
		return

	var coupon_instance: CouponInstance = _get_coupon_instance(actor)
	if coupon_instance != null:
		_coupon_system.mark_coupon_trashed(coupon_instance)
		_belt_system.mark_coupon_processed(run_state.current_customer, coupon_instance, true)
		_finish_actor(actor)
		_after_customer_object_processed()


func _on_actor_taken_from_belt(actor: Node2D) -> void:
	if _should_ignore_player_input():
		return
	if run_state == null or run_state.current_customer == null:
		return

	var actor_id: String = _get_actor_id(actor)
	if actor_id.is_empty() or _taken_actor_ids.has(actor_id):
		return

	var slot_index: int = _get_actor_slot_index(actor)
	if slot_index < 0:
		return

	var taken_slot: BeltSlot = _belt_system.take_slot_object(run_state.current_customer, slot_index)
	if not taken_slot.has_object():
		return

	_taken_actor_ids[actor_id] = true
	_update_belt_view()


func _on_actor_scan_contact_started(actor: Node2D, _contact_position: Vector2) -> void:
	if _should_ignore_player_input():
		return

	var coupon_instance: CouponInstance = _get_coupon_instance(actor)
	if coupon_instance == null:
		return
	if coupon_instance.was_activated_honestly or coupon_instance.was_trashed:
		return
	if not _get_actor_bool(actor, "is_held"):
		return
	if _get_actor_vector(actor, "movement_direction").x >= 0.0:
		return

	_process_coupon_honestly(actor, coupon_instance)


func _on_coupon_button_pressed() -> void:
	coupon_purchase_requested.emit()
	if hud_root == null or run_state == null:
		return

	hud_root.show_coupon_popup(_get_available_coupon_options(), _get_affordable_coupon_ids())


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_requested.emit()
	if _should_ignore_menu_input():
		return

	var next_upgrade: UpgradeResource = _upgrade_system.get_next_assortment_upgrade(run_state, registry.upgrades)
	if _upgrade_system.purchase_assortment_upgrade(run_state, next_upgrade, registry.game_balance):
		_update_hud_state()


func _on_coupon_selected(coupon_id: String) -> void:
	if _should_ignore_menu_input():
		return

	var coupon: CouponResource = registry.get_coupon(coupon_id)
	if coupon == null:
		return

	var purchased_coupon: CouponInstance = _coupon_system.purchase_coupon(run_state, coupon, registry, registry.game_balance)
	if purchased_coupon == null:
		return

	_update_hud_state()


func _on_dialog_closed() -> void:
	var closed_dialog_kind: int = _dialog_kind
	_dialog_kind = DialogKind.NONE

	match closed_dialog_kind:
		DialogKind.CAUGHT:
			_after_customer_object_processed()
		DialogKind.CUSTOMER_BYE:
			_is_advancing_customer = false
			_advance_after_customer()
		DialogKind.LOSE, DialogKind.WIN:
			_is_run_finished = true


func _process_coupon_honestly(actor: Node2D, coupon_instance: CouponInstance) -> void:
	_coupon_system.mark_coupon_honestly_activated(coupon_instance)
	_belt_system.mark_coupon_processed(run_state.current_customer, coupon_instance, false)
	_finish_actor(actor)
	_after_customer_object_processed()


func _handle_caught_scan(actor: Node2D, product_instance: ProductInstance) -> void:
	_economy_system.trash_product(run_state, product_instance)
	_belt_system.mark_product_processed(run_state.current_customer, product_instance)
	_finish_actor(actor)
	_update_hud_state()
	_update_mood_ring()
	_show_dialog(CAUGHT_MESSAGE, DialogKind.CAUGHT)


func _after_customer_object_processed() -> void:
	_update_hud_state()
	_update_mood_ring()
	if run_state == null or run_state.current_customer == null:
		return
	if not run_state.current_customer.is_complete:
		return

	_queue_customer_done_dialog()


func _queue_customer_done_dialog() -> void:
	if _is_advancing_customer or _is_run_finished:
		return

	_is_advancing_customer = true
	if checkout_table != null:
		checkout_table.clear_belt()

	await get_tree().create_timer(CUSTOMER_DONE_DELAY_SECONDS).timeout
	if run_state == null or run_state.current_customer == null or not run_state.current_customer.is_complete:
		_is_advancing_customer = false
		return
	if _is_run_finished:
		_is_advancing_customer = false
		return

	_show_dialog(CUSTOMER_BYE_MESSAGE, DialogKind.CUSTOMER_BYE)


func _advance_after_customer() -> void:
	if run_state == null or registry == null or registry.game_balance == null:
		return

	if run_state.current_customer_number < registry.game_balance.customers_per_day:
		run_state.current_customer_number += 1
		_start_customer()
		return

	_finish_day()


func _finish_day() -> void:
	if run_state == null or registry == null or registry.game_balance == null:
		return

	var completed_day: int = run_state.current_day
	if run_state.cash_cents < run_state.rent_due_cents:
		_is_run_finished = true
		_update_hud_state()
		_show_dialog(LOSE_MESSAGE, DialogKind.LOSE)
		return

	run_state.cash_cents -= run_state.rent_due_cents
	_coupon_system.expire_coupons_after_day(run_state, completed_day)
	_update_hud_state()

	if completed_day >= registry.game_balance.days_per_run:
		_is_run_finished = true
		_show_dialog(WIN_MESSAGE, DialogKind.WIN)
		return

	run_state.current_day += 1
	run_state.current_customer_number = 1
	_start_customer()


func _show_dialog(message: String, dialog_kind: int) -> void:
	_dialog_kind = dialog_kind
	if hud_root != null:
		hud_root.show_dialog(message)


func _finish_actor(actor: Node2D) -> void:
	var actor_id: String = _get_actor_id(actor)
	if not actor_id.is_empty():
		_taken_actor_ids.erase(actor_id)
	if actor != null and is_instance_valid(actor):
		actor.queue_free()


func _get_available_coupon_options() -> Array[CouponResource]:
	var available_coupons: Array[CouponResource] = []
	if registry == null or run_state == null:
		return available_coupons

	for coupon: CouponResource in registry.coupons:
		if _coupon_system.coupon_is_available_for_assortment(
			coupon,
			registry.product_variants,
			run_state.assortment_level
		):
			available_coupons.append(coupon)

	return available_coupons


func _get_affordable_coupon_ids() -> PackedStringArray:
	var affordable_coupon_ids: PackedStringArray = PackedStringArray()
	if registry == null or run_state == null:
		return affordable_coupon_ids

	for coupon: CouponResource in _get_available_coupon_options():
		if _coupon_system.can_purchase_coupon(run_state, coupon, registry):
			affordable_coupon_ids.append(coupon.id)

	return affordable_coupon_ids


func _build_assortment_upgrade_tooltip(upgrade: UpgradeResource) -> String:
	if upgrade == null:
		return ""

	var lines: PackedStringArray = PackedStringArray()
	if not upgrade.tooltip.strip_edges().is_empty():
		lines.append(upgrade.tooltip.strip_edges())
	lines.append("Wirkt ab dem naechsten Kunden.")

	if not upgrade.unlocked_products.is_empty():
		lines.append("Neue Produkte:")
		for product: ProductVariantResource in upgrade.unlocked_products:
			if product == null:
				continue
			lines.append("%s %s" % [
				product.display_name,
				_economy_system.format_cents(product.price_cents),
			])

	return _join_tooltip_lines(lines)


func _join_tooltip_lines(lines: PackedStringArray) -> String:
	var tooltip_text: String = ""
	for line_index: int in range(lines.size()):
		if line_index > 0:
			tooltip_text += "\n"
		tooltip_text += lines[line_index]
	return tooltip_text


func _should_ignore_player_input() -> bool:
	return (
		_should_ignore_menu_input()
		or _dialog_kind != DialogKind.NONE
		or _is_advancing_customer
	)


func _should_ignore_menu_input() -> bool:
	return _is_run_finished or registry == null or run_state == null or registry.game_balance == null


func _connect_signal_once(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _resolve_presentation_references() -> void:
	if checkout_table == null:
		checkout_table = get_node_or_null("../CheckoutTable") as CheckoutTable
	if hud_root == null:
		hud_root = get_node_or_null("../HudRoot") as HudRoot


func _get_actor_id(actor: Node2D) -> String:
	if actor == null:
		return ""

	var actor_id_value: Variant = actor.get("actor_id")
	if actor_id_value is String:
		return actor_id_value
	return ""


func _get_actor_slot_index(actor: Node2D) -> int:
	if actor == null:
		return -1

	var slot_index_value: Variant = actor.get("slot_index")
	if slot_index_value is int:
		return slot_index_value
	return -1


func _get_actor_bool(actor: Node2D, property_name: String) -> bool:
	if actor == null:
		return false

	var value: Variant = actor.get(property_name)
	if value is bool:
		return value
	return false


func _get_actor_vector(actor: Node2D, property_name: String) -> Vector2:
	if actor == null:
		return Vector2.ZERO

	var value: Variant = actor.get(property_name)
	if value is Vector2:
		return value
	return Vector2.ZERO


func _get_product_instance(actor: Node2D) -> ProductInstance:
	if actor == null:
		return null

	var value: Variant = actor.get("product_instance")
	return value as ProductInstance


func _get_coupon_instance(actor: Node2D) -> CouponInstance:
	if actor == null:
		return null

	var value: Variant = actor.get("coupon_instance")
	return value as CouponInstance
