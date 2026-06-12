extends RefCounted
class_name HudStateUpdater

## Pushes the current run state into the HUD (status summary, shop buttons,
## tooltips). Pure presentation sync; never mutates the run.

var _context: RunContext


func _init(context: RunContext) -> void:
	_context = context


func refresh(is_run_finished: bool) -> void:
	if _context.hud_root == null or not _context.has_loaded_content() or _context.run_state == null:
		return

	var balance: GameBalanceResource = _context.get_balance()
	var run_state: RunState = _context.run_state
	var hud_root: HudRoot = _context.hud_root

	hud_root.update_run_summary(
		run_state.current_day,
		run_state.current_customer_number,
		balance.customers_per_day,
		run_state.rent_due_cents,
		run_state.cash_cents
	)
	hud_root.set_coupon_button_enabled(
		not is_run_finished and not _context.coupon_system.get_available_coupons(run_state, _context.registry).is_empty()
	)
	hud_root.set_coupon_button_tooltip(UiTexts.COUPON_BUTTON_TOOLTIP)
	hud_root.set_sticker_button_enabled(not is_run_finished and not _context.registry.stickers.is_empty())
	hud_root.set_sticker_button_tooltip(UiTexts.STICKER_BUTTON_TOOLTIP)
	_refresh_assortment_button(is_run_finished)


func _refresh_assortment_button(is_run_finished: bool) -> void:
	var hud_root: HudRoot = _context.hud_root
	var next_upgrade: UpgradeResource = _context.upgrade_system.get_next_assortment_upgrade(
		_context.run_state,
		_context.registry.upgrades
	)
	if next_upgrade == null:
		hud_root.set_assortment_upgrade_button(UiTexts.ASSORTMENT_MAXED_BUTTON_LABEL, false)
		hud_root.set_assortment_upgrade_tooltip(UiTexts.ASSORTMENT_MAXED_TOOLTIP)
		return

	var label_text: String = UiTexts.ASSORTMENT_BUTTON_LABEL_FORMAT % [
		next_upgrade.target_assortment_level,
		_context.economy_system.format_cents(next_upgrade.cost_cents),
	]
	hud_root.set_assortment_upgrade_button(
		label_text,
		not is_run_finished and _context.upgrade_system.can_purchase_assortment_upgrade(_context.run_state, next_upgrade)
	)
	hud_root.set_assortment_upgrade_tooltip(_build_assortment_upgrade_tooltip(next_upgrade))


func _build_assortment_upgrade_tooltip(upgrade: UpgradeResource) -> String:
	var lines: PackedStringArray = PackedStringArray()
	if not upgrade.tooltip.strip_edges().is_empty():
		lines.append(upgrade.tooltip.strip_edges())
	lines.append(UiTexts.ASSORTMENT_EFFECT_TOOLTIP_LINE)

	if not upgrade.unlocked_products.is_empty():
		lines.append(UiTexts.ASSORTMENT_NEW_PRODUCTS_HEADER)
		for product: ProductVariantResource in upgrade.unlocked_products:
			if product == null:
				continue
			lines.append("%s %s" % [
				product.display_name,
				_context.economy_system.format_cents(product.price_cents),
			])

	return "\n".join(lines)
