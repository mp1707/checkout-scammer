extends RefCounted
class_name RunContext

## Shared state and simulation systems for one game session. Owned by
## RunController and handed to the flow/interaction/shop handlers so they
## work on the same run without referencing each other's internals.

var registry: ContentRegistry
var run_state: RunState
var checkout_table: CheckoutTable
var hud_root: HudRoot

var customer_generator: CustomerGenerator = CustomerGenerator.new()
var visible_object_queue_system: VisibleObjectQueueSystem = VisibleObjectQueueSystem.new()
var scan_system: ScanSystem = ScanSystem.new()
var suspicion_system: SuspicionSystem = SuspicionSystem.new()
var economy_system: EconomySystem = EconomySystem.new()
var coupon_system: CouponSystem = CouponSystem.new()
var upgrade_system: UpgradeSystem = UpgradeSystem.new()
var sticker_system: StickerSystem = StickerSystem.new()
var scan_random: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(
	initial_registry: ContentRegistry,
	initial_checkout_table: CheckoutTable,
	initial_hud_root: HudRoot
) -> void:
	registry = initial_registry
	checkout_table = initial_checkout_table
	hud_root = initial_hud_root


func has_loaded_content() -> bool:
	return registry != null and registry.game_balance != null


func has_active_customer() -> bool:
	return run_state != null and run_state.current_customer != null


func get_balance() -> GameBalanceResource:
	return registry.game_balance if registry != null else null
