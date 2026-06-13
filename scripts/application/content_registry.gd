extends RefCounted
class_name ContentRegistry

const GAME_BALANCE_PATH: String = "res://content/balance/prototype_balance.tres"
const SUSPICION_CURVE_PATH: String = "res://content/balance/prototype_suspicion_curve.tres"
const PRODUCT_LINES_DIR: String = "res://content/products/lines"
const PRODUCT_VARIANTS_DIR: String = "res://content/products/variants"
const COUPONS_DIR: String = "res://content/coupons"
const STICKERS_DIR: String = "res://content/stickers"
const UPGRADES_DIR: String = "res://content/upgrades"
const CUSTOMER_TYPES_DIR: String = "res://content/customers"

var game_balance: GameBalanceResource
var suspicion_curve: SuspicionCurveResource
var product_lines: Array[ProductLineResource] = []
var product_variants: Array[ProductVariantResource] = []
var coupons: Array[CouponResource] = []
var stickers: Array[StickerResource] = []
var upgrades: Array[UpgradeResource] = []
var customer_types: Array[CustomerTypeResource] = []

var _product_lines_by_id: Dictionary[String, Resource] = {}
var _product_variants_by_id: Dictionary[String, Resource] = {}
var _coupons_by_id: Dictionary[String, Resource] = {}
var _stickers_by_id: Dictionary[String, Resource] = {}
var _upgrades_by_id: Dictionary[String, Resource] = {}
var _customer_types_by_id: Dictionary[String, Resource] = {}


func load_all() -> PackedStringArray:
	clear()

	var errors: PackedStringArray = PackedStringArray()
	game_balance = _load_game_balance(errors)
	suspicion_curve = _load_suspicion_curve(errors)
	product_lines = _load_product_lines(errors)
	product_variants = _load_product_variants(errors)
	coupons = _load_coupons(errors)
	stickers = _load_stickers(errors)
	upgrades = _load_upgrades(errors)
	customer_types = _load_customer_types(errors)

	_build_indexes(errors)
	_validate_balance(errors)
	_validate_suspicion_curve(errors)
	_validate_product_lines(errors)
	_validate_product_variants(errors)
	_validate_coupons(errors)
	_validate_stickers(errors)
	_validate_upgrades(errors)
	_validate_customer_types(errors)

	return errors


func clear() -> void:
	game_balance = null
	suspicion_curve = null
	product_lines.clear()
	product_variants.clear()
	coupons.clear()
	stickers.clear()
	upgrades.clear()
	customer_types.clear()
	_product_lines_by_id.clear()
	_product_variants_by_id.clear()
	_coupons_by_id.clear()
	_stickers_by_id.clear()
	_upgrades_by_id.clear()
	_customer_types_by_id.clear()


func get_product_line(id: String) -> ProductLineResource:
	return _product_lines_by_id.get(id) as ProductLineResource


func get_product_variant(id: String) -> ProductVariantResource:
	return _product_variants_by_id.get(id) as ProductVariantResource


func get_coupon(id: String) -> CouponResource:
	return _coupons_by_id.get(id) as CouponResource


func get_sticker(id: String) -> StickerResource:
	return _stickers_by_id.get(id) as StickerResource


func get_upgrade(id: String) -> UpgradeResource:
	return _upgrades_by_id.get(id) as UpgradeResource


func get_customer_type(id: String) -> CustomerTypeResource:
	return _customer_types_by_id.get(id) as CustomerTypeResource


func _load_game_balance(errors: PackedStringArray) -> GameBalanceResource:
	var resource: Resource = _load_required_resource(GAME_BALANCE_PATH, errors)
	var balance: GameBalanceResource = resource as GameBalanceResource
	if resource != null and balance == null:
		errors.append("Expected GameBalanceResource at %s." % GAME_BALANCE_PATH)

	return balance


func _load_suspicion_curve(errors: PackedStringArray) -> SuspicionCurveResource:
	var resource: Resource = _load_required_resource(SUSPICION_CURVE_PATH, errors)
	var curve: SuspicionCurveResource = resource as SuspicionCurveResource
	if resource != null and curve == null:
		errors.append("Expected SuspicionCurveResource at %s." % SUSPICION_CURVE_PATH)

	return curve


func _load_product_lines(errors: PackedStringArray) -> Array[ProductLineResource]:
	var loaded_lines: Array[ProductLineResource] = []
	for path: String in _list_resource_paths(PRODUCT_LINES_DIR, errors):
		var resource: Resource = _load_required_resource(path, errors)
		var product_line: ProductLineResource = resource as ProductLineResource
		if resource != null and product_line == null:
			errors.append("Expected ProductLineResource at %s." % path)
			continue

		if product_line != null:
			loaded_lines.append(product_line)

	return loaded_lines


func _load_product_variants(errors: PackedStringArray) -> Array[ProductVariantResource]:
	var loaded_variants: Array[ProductVariantResource] = []
	for path: String in _list_resource_paths(PRODUCT_VARIANTS_DIR, errors):
		var resource: Resource = _load_required_resource(path, errors)
		var product_variant: ProductVariantResource = resource as ProductVariantResource
		if resource != null and product_variant == null:
			errors.append("Expected ProductVariantResource at %s." % path)
			continue

		if product_variant != null:
			loaded_variants.append(product_variant)

	return loaded_variants


func _load_coupons(errors: PackedStringArray) -> Array[CouponResource]:
	var loaded_coupons: Array[CouponResource] = []
	for path: String in _list_resource_paths(COUPONS_DIR, errors):
		var resource: Resource = _load_required_resource(path, errors)
		var coupon: CouponResource = resource as CouponResource
		if resource != null and coupon == null:
			errors.append("Expected CouponResource at %s." % path)
			continue

		if coupon != null:
			loaded_coupons.append(coupon)

	return loaded_coupons


func _load_stickers(errors: PackedStringArray) -> Array[StickerResource]:
	var loaded_stickers: Array[StickerResource] = []
	for path: String in _list_resource_paths(STICKERS_DIR, errors):
		var resource: Resource = _load_required_resource(path, errors)
		var sticker: StickerResource = resource as StickerResource
		if resource != null and sticker == null:
			errors.append("Expected StickerResource at %s." % path)
			continue

		if sticker != null:
			loaded_stickers.append(sticker)

	return loaded_stickers


func _load_upgrades(errors: PackedStringArray) -> Array[UpgradeResource]:
	var loaded_upgrades: Array[UpgradeResource] = []
	for path: String in _list_resource_paths(UPGRADES_DIR, errors):
		var resource: Resource = _load_required_resource(path, errors)
		var upgrade: UpgradeResource = resource as UpgradeResource
		if resource != null and upgrade == null:
			errors.append("Expected UpgradeResource at %s." % path)
			continue

		if upgrade != null:
			loaded_upgrades.append(upgrade)

	return loaded_upgrades


func _load_customer_types(errors: PackedStringArray) -> Array[CustomerTypeResource]:
	var loaded_customer_types: Array[CustomerTypeResource] = []
	for path: String in _list_resource_paths(CUSTOMER_TYPES_DIR, errors):
		var resource: Resource = _load_required_resource(path, errors)
		var customer_type: CustomerTypeResource = resource as CustomerTypeResource
		if resource != null and customer_type == null:
			errors.append("Expected CustomerTypeResource at %s." % path)
			continue

		if customer_type != null:
			loaded_customer_types.append(customer_type)

	return loaded_customer_types


func _load_required_resource(path: String, errors: PackedStringArray) -> Resource:
	if not ResourceLoader.exists(path):
		errors.append("Content resource missing: %s." % path)
		return null

	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		errors.append("Could not load content resource: %s." % path)

	return resource


func _list_resource_paths(directory_path: String, errors: PackedStringArray) -> PackedStringArray:
	var paths: PackedStringArray = PackedStringArray()
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		errors.append("Content directory missing: %s." % directory_path)
		return paths

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			paths.append("%s/%s" % [directory_path, file_name])
		file_name = directory.get_next()
	directory.list_dir_end()

	paths.sort()
	return paths


func _build_indexes(errors: PackedStringArray) -> void:
	for product_line: ProductLineResource in product_lines:
		_add_unique_resource_id(product_line.id, "product line", product_line.resource_path, _product_lines_by_id, product_line, errors)

	for product_variant: ProductVariantResource in product_variants:
		_add_unique_resource_id(product_variant.id, "product variant", product_variant.resource_path, _product_variants_by_id, product_variant, errors)

	for coupon: CouponResource in coupons:
		_add_unique_resource_id(coupon.id, "coupon", coupon.resource_path, _coupons_by_id, coupon, errors)

	for sticker: StickerResource in stickers:
		_add_unique_resource_id(sticker.id, "sticker", sticker.resource_path, _stickers_by_id, sticker, errors)

	for upgrade: UpgradeResource in upgrades:
		_add_unique_resource_id(upgrade.id, "upgrade", upgrade.resource_path, _upgrades_by_id, upgrade, errors)

	for customer_type: CustomerTypeResource in customer_types:
		_add_unique_resource_id(customer_type.id, "customer type", customer_type.resource_path, _customer_types_by_id, customer_type, errors)


func _add_unique_resource_id(
	id: String,
	label: String,
	path: String,
	index: Dictionary[String, Resource],
	resource: Resource,
	errors: PackedStringArray
) -> void:
	if id.strip_edges().is_empty():
		errors.append("Missing %s id in %s." % [label, path])
		return

	if index.has(id):
		errors.append("Duplicate %s id '%s' in %s." % [label, id, path])
		return

	index[id] = resource


func _validate_balance(errors: PackedStringArray) -> void:
	if game_balance == null:
		return

	if game_balance.start_money_cents < 0:
		errors.append("Game balance start_money_cents must not be negative.")
	if game_balance.daily_rent_cents <= 0:
		errors.append("Game balance daily_rent_cents must be greater than zero.")
	if game_balance.days_per_run <= 0:
		errors.append("Game balance days_per_run must be greater than zero.")
	if game_balance.customers_per_day <= 0:
		errors.append("Game balance customers_per_day must be greater than zero.")
	if game_balance.products_per_customer <= 0:
		errors.append("Game balance products_per_customer must be greater than zero.")
	if game_balance.visible_object_slots <= 0:
		errors.append("Game balance visible_object_slots must be greater than zero.")
	if game_balance.starting_assortment_level <= 0:
		errors.append("Game balance starting_assortment_level must be greater than zero.")


func _validate_suspicion_curve(errors: PackedStringArray) -> void:
	if suspicion_curve == null:
		return

	if suspicion_curve.stage_percentages.is_empty():
		errors.append("Suspicion curve needs at least one stage.")

	var previous_percent: int = -1
	for percent: int in suspicion_curve.stage_percentages:
		if percent <= previous_percent:
			errors.append("Suspicion curve stages must be strictly ascending.")
		if percent < 0 or percent > 100:
			errors.append("Suspicion curve stage %d must be between 0 and 100." % percent)
		previous_percent = percent


func _validate_product_lines(errors: PackedStringArray) -> void:
	for product_line: ProductLineResource in product_lines:
		if product_line.display_name.strip_edges().is_empty():
			errors.append("Product line '%s' needs a display_name." % product_line.id)


func _validate_product_variants(errors: PackedStringArray) -> void:
	for product_variant: ProductVariantResource in product_variants:
		if product_variant.display_name.strip_edges().is_empty():
			errors.append("Product variant '%s' needs a display_name." % product_variant.id)
		if product_variant.product_line == null:
			errors.append("Product variant '%s' is missing product_line." % product_variant.id)
		elif not _product_lines_by_id.has(product_variant.product_line.id):
			errors.append("Product variant '%s' references missing product line '%s'." % [product_variant.id, product_variant.product_line.id])
		if product_variant.sale_mode == ProductVariantResource.SaleMode.FIXED_PRICE and product_variant.price_cents <= 0:
			errors.append("Product variant '%s' price_cents must be greater than zero." % product_variant.id)
		if product_variant.sale_mode == ProductVariantResource.SaleMode.WEIGHED:
			_validate_weighed_product_variant(product_variant, errors)
		if product_variant.generator_weight <= 0:
			errors.append("Product variant '%s' generator_weight must be greater than zero." % product_variant.id)
		if product_variant.assortment_level <= 0:
			errors.append("Product variant '%s' assortment_level must be greater than zero." % product_variant.id)
		if product_variant.texture == null:
			errors.append("Product variant '%s' is missing texture." % product_variant.id)


func _validate_weighed_product_variant(product_variant: ProductVariantResource, errors: PackedStringArray) -> void:
	if product_variant.price_per_kg_cents <= 0:
		errors.append("Weighed product '%s' price_per_kg_cents must be greater than zero." % product_variant.id)
	if product_variant.min_weight_grams <= 0:
		errors.append("Weighed product '%s' min_weight_grams must be greater than zero." % product_variant.id)
	if product_variant.max_weight_grams <= product_variant.min_weight_grams:
		errors.append("Weighed product '%s' max_weight_grams must be greater than min_weight_grams." % product_variant.id)
	if product_variant.weight_step_grams <= 0:
		errors.append("Weighed product '%s' weight_step_grams must be greater than zero." % product_variant.id)
	if product_variant.weight_distribution_power <= 0.0:
		errors.append("Weighed product '%s' weight_distribution_power must be greater than zero." % product_variant.id)
	if product_variant.min_visual_scale <= 0.0 or product_variant.max_visual_scale < product_variant.min_visual_scale:
		errors.append("Weighed product '%s' visual scale range is invalid." % product_variant.id)


func _validate_coupons(errors: PackedStringArray) -> void:
	for coupon: CouponResource in coupons:
		if coupon.display_name.strip_edges().is_empty():
			errors.append("Coupon '%s' needs a display_name." % coupon.id)
		if coupon.purchase_price_cents < 0:
			errors.append("Coupon '%s' purchase_price_cents must not be negative." % coupon.id)
		if coupon.discount_percent < 0 or coupon.discount_percent > 100:
			errors.append("Coupon '%s' discount_percent must be between 0 and 100." % coupon.id)
		if coupon.weight_multiplier_percent <= 0:
			errors.append("Coupon '%s' weight_multiplier_percent must be greater than zero." % coupon.id)
		if coupon.duration_days <= 0:
			errors.append("Coupon '%s' duration_days must be greater than zero." % coupon.id)

		if coupon.targets_product():
			if coupon.target_product == null:
				errors.append("Coupon '%s' targets a product but target_product is empty." % coupon.id)
			elif not _product_variants_by_id.has(coupon.target_product.id):
				errors.append("Coupon '%s' references missing product '%s'." % [coupon.id, coupon.target_product.id])
		elif coupon.targets_line():
			if coupon.target_line == null:
				errors.append("Coupon '%s' targets a product line but target_line is empty." % coupon.id)
			elif not _product_lines_by_id.has(coupon.target_line.id):
				errors.append("Coupon '%s' references missing product line '%s'." % [coupon.id, coupon.target_line.id])
		else:
			errors.append("Coupon '%s' has an unknown target_kind." % coupon.id)


func _validate_stickers(errors: PackedStringArray) -> void:
	for sticker: StickerResource in stickers:
		if sticker.display_name.strip_edges().is_empty():
			errors.append("Sticker '%s' needs a display_name." % sticker.id)
		if sticker.texture == null:
			errors.append("Sticker '%s' is missing texture." % sticker.id)
		if sticker.price_multiplier_percent <= 0:
			errors.append("Sticker '%s' price_multiplier_percent must be greater than zero." % sticker.id)
		if sticker.daily_refill_count < 0:
			errors.append("Sticker '%s' daily_refill_count must not be negative." % sticker.id)


func _validate_upgrades(errors: PackedStringArray) -> void:
	for upgrade: UpgradeResource in upgrades:
		if upgrade.display_name.strip_edges().is_empty():
			errors.append("Upgrade '%s' needs a display_name." % upgrade.id)
		if upgrade.cost_cents <= 0:
			errors.append("Upgrade '%s' cost_cents must be greater than zero." % upgrade.id)
		if upgrade.target_assortment_level <= 1:
			errors.append("Upgrade '%s' target_assortment_level must be greater than one." % upgrade.id)
		if upgrade.unlocked_products.is_empty():
			errors.append("Upgrade '%s' needs at least one unlocked product." % upgrade.id)

		for product_variant: ProductVariantResource in upgrade.unlocked_products:
			if product_variant == null:
				errors.append("Upgrade '%s' contains an empty unlocked product reference." % upgrade.id)
			elif not _product_variants_by_id.has(product_variant.id):
				errors.append("Upgrade '%s' references missing product '%s'." % [upgrade.id, product_variant.id])
			elif product_variant.assortment_level != upgrade.target_assortment_level:
				errors.append("Upgrade '%s' unlocks product '%s' at assortment level %d but targets level %d." % [upgrade.id, product_variant.id, product_variant.assortment_level, upgrade.target_assortment_level])


func _validate_customer_types(errors: PackedStringArray) -> void:
	if customer_types.is_empty():
		errors.append("At least one customer type is required.")
	if get_customer_type(CustomerGenerator.FIRST_CUSTOMER_TYPE_ID) == null:
		errors.append("Customer types need required first-customer id '%s'." % CustomerGenerator.FIRST_CUSTOMER_TYPE_ID)

	for customer_type: CustomerTypeResource in customer_types:
		if customer_type.display_name.strip_edges().is_empty():
			errors.append("Customer type '%s' needs a display_name." % customer_type.id)
		if customer_type.tooltip.strip_edges().is_empty():
			errors.append("Customer type '%s' needs a tooltip." % customer_type.id)
		if customer_type.caught_dialog_text.strip_edges().is_empty():
			errors.append("Customer type '%s' needs a caught_dialog_text." % customer_type.id)
		if customer_type.farewell_dialog_text.strip_edges().is_empty():
			errors.append("Customer type '%s' needs a farewell_dialog_text." % customer_type.id)
		if customer_type.price_percentile_min < 0 or customer_type.price_percentile_min > 100:
			errors.append("Customer type '%s' price_percentile_min must be between 0 and 100." % customer_type.id)
		if customer_type.price_percentile_max < 0 or customer_type.price_percentile_max > 100:
			errors.append("Customer type '%s' price_percentile_max must be between 0 and 100." % customer_type.id)
		if customer_type.price_percentile_max <= customer_type.price_percentile_min:
			errors.append("Customer type '%s' price percentile max must be greater than min." % customer_type.id)
		_validate_customer_type_suspicion_stages(customer_type, errors)
		_validate_customer_type_penalty(customer_type, errors)
		_validate_customer_type_textures(customer_type, errors)
		_validate_customer_type_product_pool(customer_type, errors)


func _validate_customer_type_suspicion_stages(customer_type: CustomerTypeResource, errors: PackedStringArray) -> void:
	if customer_type.suspicion_stage_percentages.size() < 3:
		errors.append("Customer type '%s' needs at least three suspicion stages." % customer_type.id)
		return

	var previous_percent: int = -1
	for percent: int in customer_type.suspicion_stage_percentages:
		if percent <= previous_percent:
			errors.append("Customer type '%s' suspicion stages must be strictly ascending." % customer_type.id)
		if percent < 0 or percent > 100:
			errors.append("Customer type '%s' suspicion stage %d must be between 0 and 100." % [customer_type.id, percent])
		previous_percent = percent


func _validate_customer_type_penalty(customer_type: CustomerTypeResource, errors: PackedStringArray) -> void:
	match customer_type.caught_penalty_kind:
		CustomerTypeResource.CaughtPenaltyKind.NONE:
			pass
		CustomerTypeResource.CaughtPenaltyKind.CASH_PRODUCT_VALUE:
			if customer_type.cash_penalty_product_value_multiplier_percent <= 0:
				errors.append("Customer type '%s' cash penalty multiplier must be greater than zero." % customer_type.id)
		CustomerTypeResource.CaughtPenaltyKind.NEXT_CUSTOMER_SUSPICION_BONUS:
			if customer_type.next_customer_suspicion_bonus_percent <= 0:
				errors.append("Customer type '%s' next customer suspicion bonus must be greater than zero." % customer_type.id)
		_:
			errors.append("Customer type '%s' has an unknown caught_penalty_kind." % customer_type.id)


func _validate_customer_type_textures(customer_type: CustomerTypeResource, errors: PackedStringArray) -> void:
	if customer_type.green_texture == null:
		errors.append("Customer type '%s' is missing green_texture." % customer_type.id)
	if customer_type.yellow_texture == null:
		errors.append("Customer type '%s' is missing yellow_texture." % customer_type.id)
	if customer_type.red_texture == null:
		errors.append("Customer type '%s' is missing red_texture." % customer_type.id)


func _validate_customer_type_product_pool(customer_type: CustomerTypeResource, errors: PackedStringArray) -> void:
	if game_balance == null:
		return

	var available_products: Array[ProductVariantResource] = []
	for product_variant: ProductVariantResource in product_variants:
		if product_variant.is_available_at_assortment_level(game_balance.starting_assortment_level):
			available_products.append(product_variant)

	var product_pool: Array[ProductVariantResource] = CustomerGenerator.get_products_for_customer_type(
		available_products,
		customer_type
	)
	if product_pool.is_empty():
		errors.append("Customer type '%s' has no products in the starting assortment price range." % customer_type.id)
