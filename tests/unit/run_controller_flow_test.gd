extends "res://tests/checkout_test_base.gd"
class_name RunControllerFlowTest


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
	var register_display: RegisterDisplay = app.get_node("CheckoutTable/RegisterDisplay") as RegisterDisplay
	var scale_station: ScaleStation = app.get_node("CheckoutTable/ScaleStation") as ScaleStation
	var hud_root: HudRoot = app.get_node("HudRoot") as HudRoot
	_expect_true(controller != null, "RunController node is present")
	_expect_true(controller != null and controller.run_state != null, "RunController starts a run from GameApp")
	_expect_true(checkout_table != null, "CheckoutTable is present")
	_expect_true(register_display != null, "RegisterDisplay is present")
	_expect_true(scale_station != null, "ScaleStation is present")
	_expect_true(hud_root != null, "HudRoot is present")
	if controller == null or controller.run_state == null or checkout_table == null or register_display == null or scale_station == null or hud_root == null:
		app.queue_free()
		_finish()
		return

	_expect_equal_int(1, controller.run_state.current_day, "Run starts on day one")
	_expect_equal_int(1, controller.run_state.current_customer_number, "Run starts on first customer")
	_expect_equal_string("jimmy", controller.run_state.current_customer.customer_type.id, "Run starts with Jimmy")
	_expect_equal_int(4, controller.run_state.current_customer.visible_slots.size(), "Run displays four visible object slots")

	var actor_container: Node = app.get_node("CheckoutTable/ProductScatterView/ActorContainer")
	var product_actor: ProductActor = _get_first_product_actor(actor_container)
	_expect_true(product_actor != null, "Product scatter view spawns product actors")
	if product_actor == null:
		app.queue_free()
		_finish()
		return

	product_actor.emit_signal("drag_started", product_actor)
	await process_frame
	_expect_equal_int(4, controller.run_state.current_customer.visible_slots.size(), "Taking a product keeps visible slot records")
	_expect_equal_int(6, controller.run_state.current_customer.product_queue.size(), "Taking a product keeps hidden queue unchanged")

	if product_actor.product_instance.is_weighable():
		checkout_table.emit_signal("actor_scale_drop_requested", product_actor)
	else:
		checkout_table.emit_signal("product_hand_scan_requested", product_actor, product_actor.global_position)
	_expect_true(product_actor.product_instance.open_amount_cents > 0, "Checkout charge intent adds open product amount")
	_expect_equal_string(
		_format_cents(product_actor.product_instance.open_amount_cents),
		_get_register_display_text(register_display),
		"Checkout charge intent updates register display"
	)

	var cash_after_scan_before_payout: int = controller.run_state.cash_cents
	if product_actor.product_instance.is_weighable():
		checkout_table.emit_signal("actor_bag_drop_requested", product_actor)
	else:
		checkout_table.emit_signal("product_click_sale_requested", product_actor, product_actor.global_position)
	await process_frame
	_expect_true(controller.run_state.cash_cents > cash_after_scan_before_payout, "Final sale pays product into drawer")
	_expect_equal_string("", _get_register_display_text(register_display), "Final sale clears register display")
	_expect_equal_int(1, controller.run_state.current_customer.processed_product_count, "Final sale marks product processed")
	_expect_equal_int(5, controller.run_state.current_customer.product_queue.size(), "Final sale refills from hidden queue")

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

	var fixed_actor: ProductActor = product_actor_scene.instantiate() as ProductActor
	var fixed_product: ProductInstance = ProductInstance.new(controller.registry.get_product_variant("chewing_gum"), "direct_scan_gum")
	fixed_actor.set_product_instance(fixed_product)
	checkout_table.add_child(fixed_actor)
	controller.run_state.current_customer.current_suspicion_percent = 0
	checkout_table.emit_signal("product_hand_scan_requested", fixed_actor, fixed_actor.global_position)
	_expect_equal_int(95, fixed_product.open_amount_cents, "Handscanner intent charges fixed-price products")
	_expect_equal_string("$0.95", _get_register_display_text(register_display), "Handscanner intent updates register display")

	checkout_table.emit_signal("product_hand_scan_requested", fixed_actor, fixed_actor.global_position)
	_expect_equal_int(190, fixed_product.open_amount_cents, "Second handscanner entry charges fixed-price products again")
	_expect_true(controller.run_state.current_customer.current_suspicion_percent > 0, "Second handscanner entry raises suspicion")

	var cash_before_click_sale: int = controller.run_state.cash_cents
	checkout_table.emit_signal("product_click_sale_requested", fixed_actor, fixed_actor.global_position)
	_expect_true(controller.run_state.cash_cents > cash_before_click_sale, "Click sale pays scanned fixed-price product into drawer")
	_expect_true(fixed_product.is_processed, "Click sale marks fixed-price product processed")
	_expect_equal_string("", _get_register_display_text(register_display), "Click sale clears register display")
	checkout_table.clear_scanned_product_amount()

	var coupon_actor_scene: PackedScene = load("res://scenes/gameplay/products/coupon_actor.tscn") as PackedScene
	_expect_true(coupon_actor_scene != null, "CouponActor scene loads for handscanner test")
	if coupon_actor_scene == null:
		app.queue_free()
		_finish()
		return

	var coupon_actor: CouponActor = coupon_actor_scene.instantiate() as CouponActor
	var coupon_instance: CouponInstance = CouponInstance.new(controller.registry.get_coupon("apple_20_discount"), "direct_scan_coupon")
	coupon_actor.set_coupon_instance(coupon_instance)
	checkout_table.add_child(coupon_actor)
	checkout_table.emit_signal("coupon_hand_scan_requested", coupon_actor, coupon_actor.global_position)
	_expect_true(coupon_instance.was_activated_honestly, "Handscanner intent activates coupons honestly")
	coupon_actor.queue_free()

	var fruit_actor: ProductActor = product_actor_scene.instantiate() as ProductActor
	var fruit_product: ProductInstance = ProductInstance.new(controller.registry.get_product_variant("apple"), "direct_weigh_apple")
	fruit_product.weight_grams = 200
	fruit_actor.set_product_instance(fruit_product)
	checkout_table.add_child(fruit_actor)

	checkout_table.emit_signal("actor_scale_drop_requested", fruit_actor)
	_expect_equal_int(60, fruit_product.open_amount_cents, "Scale drop directly adds weighed fruit amount")
	_expect_equal_string("$0.60", _get_register_display_text(register_display), "Scale drop updates register display")
	scale_station.show_weight_grams(fruit_product.weight_grams)
	_expect_equal_string("200g", scale_station.get_weight_display_text(), "Scale station display shows fruit weight")

	hud_root.emit_signal("sticker_drag_released", "bio_sticker", fruit_actor.global_position)
	_expect_equal_int(180, fruit_product.open_amount_cents, "Sticker on scaled fruit refreshes open amount")
	_expect_equal_string("$1.80", _get_register_display_text(register_display), "Sticker on scaled fruit updates register display")

	checkout_table.emit_signal("actor_scale_removed", fruit_actor)
	_expect_equal_int(180, fruit_product.open_amount_cents, "Removing weighed fruit keeps open amount")
	_expect_equal_string("", _get_register_display_text(register_display), "Removing weighed fruit hides register display")
	scale_station.clear_weight()
	_expect_equal_string("", scale_station.get_weight_display_text(), "Removing weighed fruit hides scale display")

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


func _get_first_product_actor(actor_container: Node) -> ProductActor:
	if actor_container == null:
		return null

	for child: Node in actor_container.get_children():
		var product_actor: ProductActor = child as ProductActor
		if product_actor != null and product_actor.product_instance != null:
			return product_actor

	return null


func _finish() -> void:
	_finish_suite("Run controller flow tests")


func _get_register_display_text(register_display: RegisterDisplay) -> String:
	if register_display == null:
		return ""
	return register_display.get_display_text()
