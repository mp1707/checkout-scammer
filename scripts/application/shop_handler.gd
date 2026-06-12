extends RefCounted
class_name ShopHandler

## Handles shop intents from the HUD: coupon purchases, assortment upgrades
## and opening the sticker inventory.

var _context: RunContext
var _flow: RunFlowController


func _init(context: RunContext, flow: RunFlowController) -> void:
	_context = context
	_flow = flow


func handle_coupon_button_pressed() -> void:
	if _context.run_state == null:
		return

	_context.hud_root.show_coupon_popup(
		_context.coupon_system.get_available_coupons(_context.run_state, _context.registry),
		_context.coupon_system.get_affordable_coupon_ids(_context.run_state, _context.registry)
	)


func handle_coupon_selected(coupon_id: String) -> void:
	if _flow.is_menu_input_locked():
		return

	var coupon: CouponResource = _context.registry.get_coupon(coupon_id)
	if coupon == null:
		return

	var purchased_coupon: CouponInstance = _context.coupon_system.purchase_coupon(
		_context.run_state,
		coupon,
		_context.registry,
		_context.get_balance()
	)
	if purchased_coupon == null:
		return

	_flow.refresh_hud()


func handle_assortment_upgrade_button_pressed() -> void:
	if _flow.is_menu_input_locked():
		return

	var next_upgrade: UpgradeResource = _context.upgrade_system.get_next_assortment_upgrade(
		_context.run_state,
		_context.registry.upgrades
	)
	if _context.upgrade_system.purchase_assortment_upgrade(_context.run_state, next_upgrade, _context.get_balance()):
		_flow.refresh_hud()


func handle_sticker_button_pressed() -> void:
	if _context.run_state == null:
		return

	_context.hud_root.show_sticker_popup(_context.sticker_system.get_inventory_entries(_context.run_state))
