extends "res://scripts/ui/panels/pixel_panel.gd"
class_name CouponPopup

signal popup_closed()
signal coupon_selected(coupon_id: String)

@export var title_label: Label
@export var body_label: Label
@export var options_container: VBoxContainer
@export var close_button: Button
@export var coupon_option_button_scene: PackedScene


func _ready() -> void:
	super()
	_resolve_child_references()
	_apply_popup_label_theme()
	if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)


func set_placeholder_text(message: String) -> void:
	if body_label != null:
		body_label.text = message


func configure_options(coupons: Array[CouponResource], affordable_coupon_ids: PackedStringArray) -> void:
	_clear_options()

	if body_label != null:
		body_label.visible = coupons.is_empty()
		body_label.text = "No coupons available."

	for coupon: CouponResource in coupons:
		_add_coupon_option(coupon, affordable_coupon_ids.has(coupon.id))


func _on_close_button_pressed() -> void:
	popup_closed.emit()


func _apply_popup_label_theme() -> void:
	if theme_resource == null:
		return

	if title_label != null:
		if theme_resource.font != null:
			title_label.add_theme_font_override("font", theme_resource.font)
		title_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		title_label.add_theme_color_override("font_color", theme_resource.text_color)

	if body_label != null:
		if theme_resource.font != null:
			body_label.add_theme_font_override("font", theme_resource.font)
		body_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		body_label.add_theme_color_override("font_color", theme_resource.text_color)


func _add_coupon_option(coupon: CouponResource, is_affordable: bool) -> void:
	if coupon == null or options_container == null or coupon_option_button_scene == null:
		return

	var option_node: Node = coupon_option_button_scene.instantiate()
	var option_button: Button = option_node as Button
	if option_button == null:
		option_node.queue_free()
		return

	option_button.text = "%s %s" % [coupon.display_name, _format_cents(coupon.purchase_price_cents)]
	option_button.disabled = not is_affordable
	option_button.pressed.connect(_on_coupon_option_pressed.bind(coupon.id))
	options_container.add_child(option_button)


func _on_coupon_option_pressed(coupon_id: String) -> void:
	coupon_selected.emit(coupon_id)


func _clear_options() -> void:
	if options_container == null:
		return

	for child: Node in options_container.get_children():
		child.queue_free()


func _format_cents(cents: int) -> String:
	var dollars: int = floori(float(cents) / 100.0)
	return "$%d.%02d" % [dollars, cents % 100]


func _resolve_child_references() -> void:
	if title_label == null:
		title_label = get_node_or_null("VBox/TitleLabel") as Label
	if body_label == null:
		body_label = get_node_or_null("VBox/BodyLabel") as Label
	if options_container == null:
		options_container = get_node_or_null("VBox/OptionsAnchor") as VBoxContainer
	if close_button == null:
		close_button = get_node_or_null("VBox/CloseButton") as Button
