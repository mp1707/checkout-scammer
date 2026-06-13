extends RefCounted
class_name CheckoutInteractionHandler

## Translates checkout-table intents (scan, weigh, bag, trash, sticker) into
## simulation calls and presentation feedback for the current customer.

var _context: RunContext
var _flow: RunFlowController
var _taken_actor_ids: Dictionary[String, bool] = {}
var _active_scale_actor: ProductActor


func _init(context: RunContext, flow: RunFlowController) -> void:
	_context = context
	_flow = flow


func reset_for_new_customer() -> void:
	_taken_actor_ids.clear()
	_active_scale_actor = null


func handle_product_hand_scan(actor: ProductActor, contact_position: Vector2) -> void:
	if _flow.is_player_input_locked():
		return
	if actor == null or actor.product_instance == null:
		return

	var customer: CustomerState = _context.run_state.current_customer
	var suspicion_before_scan: int = customer.current_suspicion_percent
	var request: ScanRequest = ScanRequest.new()
	request.actor_id = actor.actor_id
	request.product_instance = actor.product_instance
	request.scanner_contact_position = contact_position
	request.product_rotation_degrees = actor.rotation_degrees

	var result: ScanResult = _context.scan_system.evaluate_scan(
		request,
		customer,
		_context.suspicion_system,
		_context.scan_random
	)
	if result.was_caught:
		_handle_caught_scan(actor, actor.product_instance)
		return
	if not result.is_valid_scan:
		if result.failure_reason == ScanResult.FailureReason.PRODUCT_WEIGHABLE:
			_context.checkout_table.play_rejected_drop_feedback(actor)
		return

	_context.economy_system.apply_successful_scan(
		result,
		_context.coupon_system.get_honest_customer_coupons(customer)
	)
	_context.checkout_table.show_scanned_product_amount(actor.product_instance.open_amount_cents)
	_context.checkout_table.play_successful_scan_feedback(actor, actor.product_instance.scan_count)
	_flow.refresh_customer_hand()
	if customer.current_suspicion_percent > suspicion_before_scan:
		_context.checkout_table.pulse_customer_hand()


func handle_coupon_hand_scan(actor: CouponActor) -> void:
	if _flow.is_player_input_locked():
		return

	if actor == null or actor.coupon_instance == null:
		return
	var coupon_instance: CouponInstance = actor.coupon_instance
	if coupon_instance.was_activated_honestly or coupon_instance.was_trashed:
		return

	_process_coupon_honestly(actor, coupon_instance)


func handle_product_click_sale(actor: ProductActor, click_position: Vector2) -> void:
	if _flow.is_player_input_locked():
		return
	if actor == null or actor.product_instance == null:
		return

	var product_instance: ProductInstance = actor.product_instance
	if product_instance.is_processed or product_instance.is_weighable() or product_instance.open_amount_cents <= 0:
		return

	_context.economy_system.payout_product(_context.run_state, product_instance)
	_context.checkout_table.clear_scanned_product_amount()
	_context.visible_object_queue_system.mark_product_processed(_context.run_state.current_customer, product_instance)
	_finish_actor(actor, true, true, click_position)
	_flow.notify_customer_object_processed()


func handle_bag_drop(actor: TableActor) -> void:
	if _flow.is_player_input_locked():
		return

	var product_actor: ProductActor = actor as ProductActor
	if product_actor != null and product_actor.product_instance != null:
		var product_instance: ProductInstance = product_actor.product_instance
		if not product_instance.is_weighable():
			_context.checkout_table.play_rejected_drop_feedback(product_actor)
			return
		if product_instance.open_amount_cents <= 0:
			_context.checkout_table.play_rejected_drop_feedback(product_actor)
			return
		_context.economy_system.payout_product(_context.run_state, product_instance)
		_context.checkout_table.clear_scanned_product_amount()
		_context.visible_object_queue_system.mark_product_processed(_context.run_state.current_customer, product_instance)
		_finish_actor(product_actor, true)
		_flow.notify_customer_object_processed()
		return

	var coupon_actor: CouponActor = actor as CouponActor
	if coupon_actor != null and coupon_actor.coupon_instance != null:
		_process_coupon_honestly(coupon_actor, coupon_actor.coupon_instance)


func handle_trash_drop(actor: TableActor) -> void:
	if _flow.is_player_input_locked():
		return

	var product_actor: ProductActor = actor as ProductActor
	if product_actor != null and product_actor.product_instance != null:
		_context.economy_system.trash_product(_context.run_state, product_actor.product_instance)
		_context.checkout_table.clear_scanned_product_amount()
		_context.visible_object_queue_system.mark_product_processed(_context.run_state.current_customer, product_actor.product_instance)
		_finish_actor(product_actor, false)
		_flow.notify_customer_object_processed()
		return

	var coupon_actor: CouponActor = actor as CouponActor
	if coupon_actor != null and coupon_actor.coupon_instance != null:
		_context.coupon_system.mark_coupon_trashed(coupon_actor.coupon_instance)
		_context.visible_object_queue_system.mark_coupon_processed(_context.run_state.current_customer, coupon_actor.coupon_instance, true)
		_finish_actor(coupon_actor, false)
		_flow.notify_customer_object_processed()


func handle_scale_drop(actor: ProductActor) -> void:
	if _flow.is_player_input_locked():
		return

	if actor == null or actor.product_instance == null or not actor.product_instance.is_weighable():
		_context.checkout_table.play_rejected_drop_feedback(actor)
		return

	_active_scale_actor = actor
	_charge_weighed_product(actor, actor.product_instance)


func handle_scale_removed(actor: ProductActor) -> void:
	if _active_scale_actor == actor:
		_active_scale_actor = null

	_context.checkout_table.clear_scanned_product_amount()


func handle_actor_taken(actor: TableActor) -> void:
	if _flow.is_player_input_locked():
		return
	if not _context.has_active_customer():
		return

	var product_actor: ProductActor = actor as ProductActor
	var product_instance: ProductInstance = product_actor.product_instance if product_actor != null else null
	if product_instance != null and product_instance.open_amount_cents > 0 and not product_instance.is_weighable():
		_context.checkout_table.show_scanned_product_amount(product_instance.open_amount_cents)
	else:
		_context.checkout_table.clear_scanned_product_amount()

	if actor == null or actor.actor_id.is_empty() or _taken_actor_ids.has(actor.actor_id):
		return
	if actor.slot_index < 0:
		return

	var taken_slot: VisibleObjectSlot = _context.visible_object_queue_system.take_slot_object(
		_context.run_state.current_customer,
		actor.slot_index
	)
	if not taken_slot.has_object():
		return

	_taken_actor_ids[actor.actor_id] = true


func handle_sticker_drag_released(sticker_id: String, global_drop_position: Vector2) -> void:
	if _flow.is_player_input_locked():
		return

	var product_actor: ProductActor = _find_sticker_target(global_drop_position)
	if product_actor == null:
		return

	var product_instance: ProductInstance = product_actor.product_instance
	var sticker_instance: StickerInstance = _context.sticker_system.apply_sticker(_context.run_state, sticker_id, product_instance)
	if sticker_instance == null:
		_context.checkout_table.play_rejected_drop_feedback(product_actor)
		return

	_context.checkout_table.refresh_product_actor(product_actor)
	_context.checkout_table.play_sticker_apply_feedback(product_actor)
	if _active_scale_actor == product_actor:
		_refresh_active_scale_amount(product_instance)
	_context.hud_root.refresh_sticker_popup(_context.sticker_system.get_inventory_entries(_context.run_state))


func _find_sticker_target(global_drop_position: Vector2) -> ProductActor:
	if _active_scale_actor != null and is_instance_valid(_active_scale_actor) \
			and _active_scale_actor.contains_global_point(global_drop_position):
		return _active_scale_actor

	return _context.checkout_table.find_product_actor_at_global_position(global_drop_position)


func _process_coupon_honestly(actor: CouponActor, coupon_instance: CouponInstance) -> void:
	_context.coupon_system.mark_coupon_honestly_activated(coupon_instance)
	_context.visible_object_queue_system.mark_coupon_processed(_context.run_state.current_customer, coupon_instance, false)
	_finish_actor(actor, true)
	_flow.notify_customer_object_processed()


func _handle_caught_scan(actor: TableActor, product_instance: ProductInstance) -> void:
	_apply_customer_caught_penalty(product_instance)
	_context.economy_system.trash_product(_context.run_state, product_instance)
	_context.checkout_table.release_scale_actor(actor)
	_context.checkout_table.clear_scanned_product_amount()
	_context.checkout_table.play_customer_caught_sound()
	_context.visible_object_queue_system.mark_product_processed(_context.run_state.current_customer, product_instance)
	_finish_actor(actor, false)
	_flow.show_caught_dialog()


func _charge_weighed_product(actor: ProductActor, product_instance: ProductInstance) -> void:
	var customer: CustomerState = _context.run_state.current_customer
	var suspicion_before_charge: int = customer.current_suspicion_percent
	var result: ScanResult = _context.scan_system.evaluate_product_charge_attempt(
		product_instance,
		customer,
		_context.suspicion_system,
		_context.scan_random
	)
	if result.was_caught:
		_handle_caught_scan(actor, product_instance)
		return
	if not result.is_valid_scan:
		_context.checkout_table.play_invalid_weigh_feedback(actor)
		return

	_context.economy_system.apply_successful_weighing(
		result,
		_context.coupon_system.get_honest_customer_coupons(customer)
	)
	_context.checkout_table.show_scanned_product_amount(product_instance.open_amount_cents)
	_context.checkout_table.play_successful_weigh_feedback(actor, product_instance.scan_count)
	_flow.refresh_customer_hand()
	if customer.current_suspicion_percent > suspicion_before_charge:
		_context.checkout_table.pulse_customer_hand()


func _refresh_active_scale_amount(product_instance: ProductInstance) -> void:
	if product_instance == null or not product_instance.is_weighable() or product_instance.open_amount_cents <= 0:
		return

	_context.economy_system.refresh_weighed_open_amount(
		product_instance,
		_context.coupon_system.get_honest_customer_coupons(_context.run_state.current_customer)
	)
	_context.checkout_table.show_scanned_product_amount(product_instance.open_amount_cents)


func _apply_customer_caught_penalty(product_instance: ProductInstance) -> void:
	var customer: CustomerState = _context.run_state.current_customer
	if customer == null or customer.customer_type == null:
		return

	match customer.customer_type.caught_penalty_kind:
		CustomerTypeResource.CaughtPenaltyKind.NONE:
			return
		CustomerTypeResource.CaughtPenaltyKind.CASH_PRODUCT_VALUE:
			_context.economy_system.apply_caught_cash_penalty(
				_context.run_state,
				product_instance,
				_context.coupon_system.get_honest_customer_coupons(customer),
				customer.customer_type.cash_penalty_product_value_multiplier_percent
			)
		CustomerTypeResource.CaughtPenaltyKind.NEXT_CUSTOMER_SUSPICION_BONUS:
			_context.suspicion_system.apply_next_customer_suspicion_bonus(customer, _context.run_state)


func _finish_actor(
	actor: TableActor,
	is_sale: bool,
	use_custom_coin_burst_position: bool = false,
	coin_burst_global_position: Vector2 = Vector2.ZERO
) -> void:
	if actor != null and not actor.actor_id.is_empty():
		_taken_actor_ids.erase(actor.actor_id)
	if actor != null and is_instance_valid(actor):
		_context.checkout_table.play_actor_finish_feedback(
			actor,
			is_sale,
			use_custom_coin_burst_position,
			coin_burst_global_position
		)
