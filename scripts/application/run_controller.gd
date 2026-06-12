extends Node
class_name RunController

## Thin wiring layer: connects presentation signals to the flow, interaction
## and shop handlers that operate on the shared RunContext.

@export var checkout_table: CheckoutTable
@export var hud_root: HudRoot

var registry: ContentRegistry:
	get:
		return _context.registry if _context != null else null
var run_state: RunState:
	get:
		return _context.run_state if _context != null else null

var _context: RunContext
var _flow: RunFlowController
var _interaction: CheckoutInteractionHandler
var _shop: ShopHandler


func _ready() -> void:
	if checkout_table == null:
		push_error("%s is missing required scene reference 'checkout_table'." % get_path())
		return
	if hud_root == null:
		push_error("%s is missing required scene reference 'hud_root'." % get_path())
		return

	_connect_presentation()


func configure(content_registry: ContentRegistry) -> void:
	if checkout_table == null or hud_root == null:
		push_error("RunController cannot start a run without checkout_table and hud_root.")
		return

	_context = RunContext.new(content_registry, checkout_table, hud_root)
	var hud_updater: HudStateUpdater = HudStateUpdater.new(_context)
	_flow = RunFlowController.new(_context, hud_updater, get_tree())
	_interaction = CheckoutInteractionHandler.new(_context, _flow)
	_shop = ShopHandler.new(_context, _flow)
	_flow.customer_started.connect(_interaction.reset_for_new_customer)
	_flow.start_run()


func _connect_presentation() -> void:
	checkout_table.actor_taken_from_product_area.connect(_on_actor_taken_from_product_area)
	checkout_table.actor_scan_contact_started.connect(_on_actor_scan_contact_started)
	checkout_table.product_scan_contact_started.connect(_on_product_scan_contact_started)
	checkout_table.actor_bag_drop_requested.connect(_on_actor_bag_drop_requested)
	checkout_table.actor_trash_drop_requested.connect(_on_actor_trash_drop_requested)
	checkout_table.actor_scale_drop_requested.connect(_on_actor_scale_drop_requested)
	checkout_table.actor_scale_removed.connect(_on_actor_scale_removed)

	hud_root.coupon_button_pressed.connect(_on_coupon_button_pressed)
	hud_root.coupon_selected.connect(_on_coupon_selected)
	hud_root.assortment_upgrade_button_pressed.connect(_on_assortment_upgrade_button_pressed)
	hud_root.sticker_button_pressed.connect(_on_sticker_button_pressed)
	hud_root.sticker_drag_released.connect(_on_sticker_drag_released)
	hud_root.dialog_closed.connect(_on_dialog_closed)


func _on_product_scan_contact_started(actor: ProductActor, contact_position: Vector2) -> void:
	if _interaction != null:
		_interaction.handle_product_scan_contact(actor, contact_position)


func _on_actor_scan_contact_started(actor: TableActor, _contact_position: Vector2) -> void:
	if _interaction != null:
		_interaction.handle_coupon_scan_contact(actor)


func _on_actor_bag_drop_requested(actor: TableActor) -> void:
	if _interaction != null:
		_interaction.handle_bag_drop(actor)


func _on_actor_trash_drop_requested(actor: TableActor) -> void:
	if _interaction != null:
		_interaction.handle_trash_drop(actor)


func _on_actor_scale_drop_requested(actor: ProductActor) -> void:
	if _interaction != null:
		_interaction.handle_scale_drop(actor)


func _on_actor_scale_removed(actor: ProductActor) -> void:
	if _interaction != null:
		_interaction.handle_scale_removed(actor)


func _on_actor_taken_from_product_area(actor: TableActor) -> void:
	if _interaction != null:
		_interaction.handle_actor_taken(actor)


func _on_sticker_drag_released(sticker_id: String, global_drop_position: Vector2) -> void:
	if _interaction != null:
		_interaction.handle_sticker_drag_released(sticker_id, global_drop_position)


func _on_coupon_button_pressed() -> void:
	if _shop != null:
		_shop.handle_coupon_button_pressed()


func _on_coupon_selected(coupon_id: String) -> void:
	if _shop != null:
		_shop.handle_coupon_selected(coupon_id)


func _on_assortment_upgrade_button_pressed() -> void:
	if _shop != null:
		_shop.handle_assortment_upgrade_button_pressed()


func _on_sticker_button_pressed() -> void:
	if _shop != null:
		_shop.handle_sticker_button_pressed()


func _on_dialog_closed() -> void:
	if _flow != null:
		_flow.handle_dialog_closed()
