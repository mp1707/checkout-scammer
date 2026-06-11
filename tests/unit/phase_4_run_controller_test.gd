extends SceneTree
class_name Phase4RunControllerTest

var _failure_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var app_scene: PackedScene = load("res://scenes/application/game_app.tscn") as PackedScene
	_expect_true(app_scene != null, "GameApp scene loads")
	if app_scene == null:
		_finish()
		return

	var app: Node = app_scene.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame

	var controller: RunController = app.get_node("RunController") as RunController
	var checkout_table: CheckoutTable = app.get_node("CheckoutTable") as CheckoutTable
	var register_display: Node = app.get_node("CheckoutTable/RegisterDisplay")
	var hud_root: HudRoot = app.get_node("HudRoot") as HudRoot
	_expect_true(controller != null, "RunController node is present")
	_expect_true(controller != null and controller.run_state != null, "RunController starts a run from GameApp")
	_expect_true(checkout_table != null, "CheckoutTable is present")
	_expect_true(register_display != null, "RegisterDisplay is present")
	_expect_true(hud_root != null, "HudRoot is present")
	if controller == null or controller.run_state == null or checkout_table == null or register_display == null or hud_root == null:
		app.queue_free()
		_finish()
		return

	_expect_equal_int(1, controller.run_state.current_day, "Run starts on day one")
	_expect_equal_int(1, controller.run_state.current_customer_number, "Run starts on first customer")
	_expect_equal_int(4, controller.run_state.current_customer.visible_slots.size(), "Run displays four visible object slots")

	var actor_container: Node = app.get_node("CheckoutTable/ProductScatterView/ActorContainer")
	var product_actor: ProductActor = _get_first_fixed_price_product_actor(actor_container)
	_expect_true(product_actor != null, "Product scatter view spawns product actors")
	if product_actor == null:
		app.queue_free()
		_finish()
		return

	product_actor.emit_signal("drag_started", product_actor)
	await process_frame
	_expect_equal_int(4, controller.run_state.current_customer.visible_slots.size(), "Taking a product keeps visible slot records")
	_expect_equal_int(6, controller.run_state.current_customer.product_queue.size(), "Taking a product keeps hidden queue unchanged")

	product_actor.is_held = true
	product_actor.is_touching_scanner = true
	product_actor.movement_direction = Vector2.LEFT
	checkout_table.emit_signal("product_scan_contact_started", product_actor, product_actor.global_position)
	_expect_true(product_actor.product_instance.open_amount_cents > 0, "Right-to-left scanner intent adds open product amount")
	_expect_equal_string(
		_format_cents(product_actor.product_instance.open_amount_cents),
		_get_register_display_text(register_display),
		"Right-to-left scanner intent updates register display"
	)

	var cash_after_scan_before_payout: int = controller.run_state.cash_cents
	checkout_table.emit_signal("actor_bag_drop_requested", product_actor)
	await process_frame
	_expect_true(controller.run_state.cash_cents > cash_after_scan_before_payout, "Bag drop pays product into drawer")
	_expect_equal_string("", _get_register_display_text(register_display), "Bag drop clears register display")
	_expect_equal_int(1, controller.run_state.current_customer.processed_product_count, "Bag drop marks product processed")
	_expect_equal_int(5, controller.run_state.current_customer.product_queue.size(), "Bag drop refills from hidden queue")

	var cash_before_coupon: int = controller.run_state.cash_cents
	hud_root.emit_signal("coupon_selected", "apple_20_discount")
	_expect_equal_int(cash_before_coupon - 200, controller.run_state.cash_cents, "Coupon intent deducts coupon cost")
	_expect_equal_int(1, controller.run_state.pending_coupons.size(), "Coupon intent queues delayed activation")

	var product_actor_scene: PackedScene = load("res://scenes/gameplay/products/product_actor.tscn") as PackedScene
	_expect_true(product_actor_scene != null, "ProductActor scene loads for scale test")
	if product_actor_scene == null:
		app.queue_free()
		_finish()
		return

	var fruit_actor: ProductActor = product_actor_scene.instantiate() as ProductActor
	var fruit_product: ProductInstance = ProductInstance.new(controller.registry.get_product_variant("apple"), "direct_weigh_apple")
	fruit_product.weight_grams = 200
	fruit_actor.set_product_instance(fruit_product)
	checkout_table.add_child(fruit_actor)

	checkout_table.emit_signal("actor_scale_drop_requested", fruit_actor)
	_expect_equal_int(60, fruit_product.open_amount_cents, "Scale drop directly adds weighed fruit amount")
	_expect_equal_string("$0.60", _get_register_display_text(register_display), "Scale drop updates register display")

	hud_root.emit_signal("sticker_drag_released", "bio_sticker", fruit_actor.global_position)
	_expect_equal_int(180, fruit_product.open_amount_cents, "Sticker on scaled fruit refreshes open amount")
	_expect_equal_string("$1.80", _get_register_display_text(register_display), "Sticker on scaled fruit updates register display")

	checkout_table.emit_signal("actor_scale_removed", fruit_actor)
	_expect_equal_int(180, fruit_product.open_amount_cents, "Removing weighed fruit keeps open amount")
	_expect_equal_string("", _get_register_display_text(register_display), "Removing weighed fruit hides register display")

	controller.run_state.current_customer.current_suspicion_percent = 0
	checkout_table.emit_signal("actor_scale_drop_requested", fruit_actor)
	_expect_equal_int(360, fruit_product.open_amount_cents, "Second scale drop adds another weighed fruit amount")
	_expect_equal_string("$3.60", _get_register_display_text(register_display), "Second scale drop shows updated open amount")
	fruit_actor.queue_free()
	checkout_table.clear_scanned_product_amount()

	var cash_before_upgrade: int = controller.run_state.cash_cents
	hud_root.emit_signal("assortment_upgrade_button_pressed")
	_expect_equal_int(cash_before_upgrade - 600, controller.run_state.cash_cents, "Upgrade intent deducts next level cost")
	_expect_equal_int(2, controller.run_state.pending_assortment_level, "Upgrade intent queues next assortment level")

	app.queue_free()
	_finish()


func _get_first_fixed_price_product_actor(actor_container: Node) -> ProductActor:
	if actor_container == null:
		return null

	for child: Node in actor_container.get_children():
		var product_actor: ProductActor = child as ProductActor
		if product_actor != null and product_actor.product_instance != null and not product_actor.product_instance.is_weighable():
			return product_actor

	return null


func _finish() -> void:
	if _failure_count > 0:
		push_error("Phase 4 run controller tests failed: %d failure(s)." % _failure_count)
		quit(1)
		return

	print("Phase 4 run controller tests passed.")
	quit(0)


func _expect_true(value: bool, label: String) -> void:
	if not value:
		_fail(label, "Expected true.")


func _expect_equal_int(expected: int, actual: int, label: String) -> void:
	if expected != actual:
		_fail(label, "Expected %d, got %d." % [expected, actual])


func _expect_equal_string(expected: String, actual: String, label: String) -> void:
	if expected != actual:
		_fail(label, "Expected '%s', got '%s'." % [expected, actual])


func _get_register_display_text(register_display: Node) -> String:
	if register_display == null or not register_display.has_method("get_display_text"):
		return ""

	var display_text: Variant = register_display.call("get_display_text")
	if display_text is String:
		return display_text
	return ""


func _format_cents(cents: int) -> String:
	var sign_prefix: String = ""
	var absolute_cents: int = cents
	if cents < 0:
		sign_prefix = "-"
		absolute_cents = -cents

	var dollars: int = floori(float(absolute_cents) / 100.0)
	return "%s$%d.%02d" % [sign_prefix, dollars, absolute_cents % 100]


func _fail(label: String, message: String) -> void:
	_failure_count += 1
	push_error("%s: %s" % [label, message])
