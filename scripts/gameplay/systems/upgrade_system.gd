extends RefCounted
class_name UpgradeSystem


func get_next_assortment_upgrade(run_state: RunState, upgrades: Array[UpgradeResource]) -> UpgradeResource:
	if run_state == null:
		return null

	var next_upgrade: UpgradeResource = null
	for upgrade: UpgradeResource in upgrades:
		if upgrade == null or upgrade.upgrade_kind != UpgradeResource.UpgradeKind.ASSORTMENT_LEVEL:
			continue
		if upgrade.target_assortment_level <= run_state.pending_assortment_level:
			continue
		if next_upgrade == null or upgrade.target_assortment_level < next_upgrade.target_assortment_level:
			next_upgrade = upgrade

	return next_upgrade


func can_purchase_assortment_upgrade(run_state: RunState, upgrade: UpgradeResource) -> bool:
	if run_state == null or upgrade == null:
		return false
	if upgrade.upgrade_kind != UpgradeResource.UpgradeKind.ASSORTMENT_LEVEL:
		return false
	if upgrade.target_assortment_level != run_state.pending_assortment_level + 1:
		return false

	return run_state.cash_cents >= upgrade.cost_cents


func purchase_assortment_upgrade(run_state: RunState, upgrade: UpgradeResource, balance: GameBalanceResource) -> bool:
	if not can_purchase_assortment_upgrade(run_state, upgrade):
		return false

	var activation: RunSchedule.Activation = RunSchedule.get_next_customer_activation(run_state, balance)
	run_state.cash_cents -= upgrade.cost_cents
	run_state.pending_assortment_level = upgrade.target_assortment_level
	run_state.pending_assortment_activation_day = activation.day
	run_state.pending_assortment_activation_customer_number = activation.customer_number
	return true


func apply_pending_assortment_for_customer(run_state: RunState) -> void:
	if run_state == null:
		return

	if (
		run_state.pending_assortment_level > run_state.assortment_level
		and RunSchedule.is_activation_due(
			run_state.pending_assortment_activation_day,
			run_state.pending_assortment_activation_customer_number,
			run_state.current_day,
			run_state.current_customer_number
		)
	):
		run_state.assortment_level = run_state.pending_assortment_level

