extends RefCounted
class_name RunFlowController

## Owns the run lifecycle: day/customer progression, win/lose conditions and
## the dialog state machine. Mechanics for individual player actions live in
## CheckoutInteractionHandler; shop intents live in ShopHandler.

signal customer_started()

enum DialogKind {
	NONE,
	CAUGHT,
	CUSTOMER_BYE,
	LOSE,
	WIN,
}

const CUSTOMER_DONE_DELAY_SECONDS: float = 0.6

var _context: RunContext
var _hud_updater: HudStateUpdater
var _tree: SceneTree
var _dialog_kind: DialogKind = DialogKind.NONE
var _is_advancing_customer: bool = false
var _is_run_finished: bool = false


func _init(context: RunContext, hud_updater: HudStateUpdater, tree: SceneTree) -> void:
	_context = context
	_hud_updater = hud_updater
	_tree = tree


func start_run() -> void:
	if not _context.has_loaded_content():
		return

	var run_state: RunState = RunState.new()
	run_state.apply_balance(_context.get_balance())
	_context.run_state = run_state
	_context.sticker_system.setup_run_inventory(run_state, _context.registry.stickers)
	_context.scan_random.seed = run_state.run_seed
	_dialog_kind = DialogKind.NONE
	_is_advancing_customer = false
	_is_run_finished = false
	_context.hud_root.hide_dialog()
	_context.hud_root.close_active_popup()
	_context.checkout_table.clear_scanned_product_amount()

	_start_customer()


func is_run_finished() -> bool:
	return _is_run_finished


## True while player table input must be ignored (dialog open, customer
## hand-off running, run over or content not ready).
func is_player_input_locked() -> bool:
	return (
		is_menu_input_locked()
		or _dialog_kind != DialogKind.NONE
		or _is_advancing_customer
	)


## True while shop/menu intents must be ignored (run over or content not ready).
func is_menu_input_locked() -> bool:
	return _is_run_finished or not _context.has_loaded_content() or _context.run_state == null


func refresh_hud() -> void:
	_hud_updater.refresh(_is_run_finished)


func refresh_customer_views() -> void:
	if _context.has_active_customer():
		_context.checkout_table.display_visible_object_slots(_context.run_state.current_customer.visible_slots)
	refresh_customer_hand()


func refresh_customer_hand() -> void:
	if not _context.has_active_customer():
		return

	var suspicion_percent: int = _context.run_state.current_customer.current_suspicion_percent
	var hand_stage_index: int = _context.suspicion_system.get_customer_hand_stage_index(
		suspicion_percent,
		_context.registry.suspicion_curve
	)
	_context.checkout_table.set_customer_hand_state(hand_stage_index, suspicion_percent)


func show_caught_dialog() -> void:
	refresh_customer_views()
	refresh_hud()
	_show_dialog(UiTexts.CUSTOMER_CAUGHT_DIALOG, DialogKind.CAUGHT)


## Called after every processed product/coupon: refreshes views and moves to
## the next customer once everything is handled.
func notify_customer_object_processed() -> void:
	refresh_customer_views()
	refresh_hud()
	if not _context.has_active_customer():
		return
	if not _context.run_state.current_customer.is_complete:
		return

	_queue_customer_done_dialog()


func handle_dialog_closed() -> void:
	var closed_dialog_kind: DialogKind = _dialog_kind
	_dialog_kind = DialogKind.NONE

	match closed_dialog_kind:
		DialogKind.CAUGHT:
			notify_customer_object_processed()
		DialogKind.CUSTOMER_BYE:
			_is_advancing_customer = false
			_advance_after_customer()
		DialogKind.LOSE, DialogKind.WIN:
			_is_run_finished = true


func _start_customer() -> void:
	if not _context.has_loaded_content() or _context.run_state == null:
		return

	var run_state: RunState = _context.run_state
	_context.coupon_system.apply_pending_coupons_for_customer(run_state)
	_context.upgrade_system.apply_pending_assortment_for_customer(run_state)

	var customer: CustomerState = _context.customer_generator.generate_customer(_context.registry, run_state)
	_context.suspicion_system.setup_customer(customer, _context.registry.suspicion_curve)
	var customer_coupon: CouponInstance = _context.coupon_system.create_customer_visible_coupon(run_state)
	_context.visible_object_queue_system.start_customer(customer, _context.get_balance().visible_object_slots, customer_coupon)
	run_state.current_customer = customer

	customer_started.emit()
	_context.checkout_table.clear_scanned_product_amount()
	refresh_customer_views()
	refresh_hud()


func _queue_customer_done_dialog() -> void:
	if _is_advancing_customer or _is_run_finished:
		return

	_is_advancing_customer = true
	_context.checkout_table.clear_scanned_product_amount()
	_context.checkout_table.clear_visible_objects()

	# Short beat before the goodbye dialog. State is re-checked after the await
	# because the run can end or restart while the timer is pending.
	await _tree.create_timer(CUSTOMER_DONE_DELAY_SECONDS).timeout
	if not _context.has_active_customer() or not _context.run_state.current_customer.is_complete:
		_is_advancing_customer = false
		return
	if _is_run_finished:
		_is_advancing_customer = false
		return

	_show_dialog(UiTexts.CUSTOMER_BYE_DIALOG, DialogKind.CUSTOMER_BYE)


func _advance_after_customer() -> void:
	if not _context.has_loaded_content() or _context.run_state == null:
		return

	if _context.run_state.current_customer_number < _context.get_balance().customers_per_day:
		_context.run_state.current_customer_number += 1
		_start_customer()
		return

	_finish_day()


func _finish_day() -> void:
	var run_state: RunState = _context.run_state
	var completed_day: int = run_state.current_day
	if run_state.cash_cents < run_state.rent_due_cents:
		_is_run_finished = true
		refresh_hud()
		_show_dialog(UiTexts.RUN_LOST_DIALOG, DialogKind.LOSE)
		return

	run_state.cash_cents -= run_state.rent_due_cents
	_context.coupon_system.expire_coupons_after_day(run_state, completed_day)
	refresh_hud()

	if completed_day >= _context.get_balance().days_per_run:
		_is_run_finished = true
		_show_dialog(UiTexts.RUN_WON_DIALOG_FORMAT % _context.get_balance().days_per_run, DialogKind.WIN)
		return

	run_state.current_day += 1
	run_state.current_customer_number = 1
	_context.sticker_system.refill_daily(run_state)
	_start_customer()


func _show_dialog(message: String, dialog_kind: DialogKind) -> void:
	_dialog_kind = dialog_kind
	_context.hud_root.show_dialog(message)
