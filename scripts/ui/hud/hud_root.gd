extends Control
class_name HudRoot

signal coupon_button_pressed()
signal coupon_selected(coupon_id: String)
signal assortment_upgrade_button_pressed()
signal dialog_closed()

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var day_value_label: Label
@export var customer_value_label: Label
@export var rent_value_label: Label
@export var cash_value_label: Label
@export var coupon_button: Button
@export var assortment_upgrade_button: Button
@export var dialog_layer: Control
@export var dialog_message_label: Label
@export var popup_layer: Control
@export var coupon_popup_scene: PackedScene

var _active_popup: Control
var _displayed_cash_cents: int = -1
var _cash_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	_connect_buttons()
	_apply_label_theme(self)
	hide_dialog()
	_set_popup_layer_visible(false)


func update_run_summary(
	day: int,
	customer_number: int,
	customers_per_day: int,
	rent_due_cents: int,
	cash_cents: int
) -> void:
	if day_value_label != null:
		day_value_label.text = str(day)
	if customer_value_label != null:
		customer_value_label.text = "%d/%d" % [customer_number, customers_per_day]
	if rent_value_label != null:
		rent_value_label.text = _format_cents(rent_due_cents)
	if cash_value_label != null:
		if _displayed_cash_cents < 0:
			_set_displayed_cash_cents(cash_cents)
		elif _displayed_cash_cents != cash_cents:
			_animate_cash_value(cash_cents)


func set_coupon_button_enabled(is_enabled: bool) -> void:
	if coupon_button != null:
		coupon_button.disabled = not is_enabled


func set_coupon_button_tooltip(button_tooltip_text: String) -> void:
	if coupon_button != null:
		coupon_button.tooltip_text = button_tooltip_text


func set_assortment_upgrade_button(label_text: String, is_enabled: bool) -> void:
	if assortment_upgrade_button == null:
		return
	assortment_upgrade_button.text = label_text
	assortment_upgrade_button.disabled = not is_enabled


func set_assortment_upgrade_tooltip(button_tooltip_text: String) -> void:
	if assortment_upgrade_button != null:
		assortment_upgrade_button.tooltip_text = button_tooltip_text


func show_dialog(message: String) -> void:
	if dialog_layer != null:
		dialog_layer.visible = true
	if dialog_message_label != null:
		dialog_message_label.text = message


func hide_dialog() -> void:
	if dialog_layer != null:
		dialog_layer.visible = false


func show_coupon_popup(coupons: Array[CouponResource], affordable_coupon_ids: PackedStringArray) -> void:
	if coupon_popup_scene == null or popup_layer == null:
		return

	close_coupon_popup()
	var popup_node: Node = coupon_popup_scene.instantiate()
	var popup_control: Control = popup_node as Control
	if popup_control == null:
		popup_node.queue_free()
		return

	_active_popup = popup_control
	popup_layer.add_child(_active_popup)
	_set_popup_layer_visible(true)

	if _active_popup.has_signal("popup_closed"):
		_active_popup.connect("popup_closed", Callable(self, "close_coupon_popup"))
	if _active_popup.has_signal("coupon_selected"):
		_active_popup.connect("coupon_selected", _on_coupon_selected)
	if _active_popup.has_method("configure_options"):
		_active_popup.call("configure_options", coupons, affordable_coupon_ids)


func close_coupon_popup() -> void:
	if _active_popup != null:
		_active_popup.queue_free()
		_active_popup = null
	_set_popup_layer_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ENTER and key_event.keycode != KEY_KP_ENTER:
		return
	if dialog_layer != null and dialog_layer.visible:
		hide_dialog()
		dialog_closed.emit()
		get_viewport().set_input_as_handled()


func _connect_buttons() -> void:
	if coupon_button != null and not coupon_button.pressed.is_connected(_on_coupon_button_pressed):
		coupon_button.pressed.connect(_on_coupon_button_pressed)
	if assortment_upgrade_button != null and not assortment_upgrade_button.pressed.is_connected(_on_assortment_upgrade_button_pressed):
		assortment_upgrade_button.pressed.connect(_on_assortment_upgrade_button_pressed)


func _on_coupon_button_pressed() -> void:
	coupon_button_pressed.emit()


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_button_pressed.emit()


func _on_coupon_selected(coupon_id: String) -> void:
	coupon_selected.emit(coupon_id)
	close_coupon_popup()


func _apply_label_theme(root: Node) -> void:
	if theme_resource == null:
		return

	for child: Node in root.get_children():
		var label: Label = child as Label
		if label != null:
			if theme_resource.font != null:
				label.add_theme_font_override("font", theme_resource.font)
			label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
			label.add_theme_color_override("font_color", theme_resource.text_color)
		_apply_label_theme(child)


func _set_popup_layer_visible(should_show_popup_layer: bool) -> void:
	if popup_layer != null:
		popup_layer.visible = should_show_popup_layer


func _animate_cash_value(target_cents: int) -> void:
	if _cash_tween != null and _cash_tween.is_valid():
		_cash_tween.kill()

	var distance_cents: int = absi(target_cents - _displayed_cash_cents)
	var duration_seconds: float = clampf(0.12 + float(distance_cents) / 2500.0, 0.16, 0.45)
	_cash_tween = create_tween()
	_cash_tween.tween_method(
		Callable(self, "_set_displayed_cash_cents_from_float"),
		float(_displayed_cash_cents),
		float(target_cents),
		duration_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_displayed_cash_cents_from_float(cents_value: float) -> void:
	_set_displayed_cash_cents(roundi(cents_value))


func _set_displayed_cash_cents(cents: int) -> void:
	_displayed_cash_cents = cents
	if cash_value_label != null:
		cash_value_label.text = _format_cents(_displayed_cash_cents)


func _format_cents(cents: int) -> String:
	var sign_prefix: String = ""
	var absolute_cents: int = cents
	if cents < 0:
		sign_prefix = "-"
		absolute_cents = -cents

	var dollars: int = floori(float(absolute_cents) / 100.0)
	return "%s$%d.%02d" % [sign_prefix, dollars, absolute_cents % 100]


func _resolve_child_references() -> void:
	if day_value_label == null:
		day_value_label = get_node_or_null("LeftStatusPanel/Margin/StatusList/DayValue") as Label
	if customer_value_label == null:
		customer_value_label = get_node_or_null("LeftStatusPanel/Margin/StatusList/CustomerValue") as Label
	if rent_value_label == null:
		rent_value_label = get_node_or_null("LeftStatusPanel/Margin/StatusList/RentValue") as Label
	if cash_value_label == null:
		cash_value_label = get_node_or_null("LeftStatusPanel/Margin/StatusList/CashValue") as Label
	if coupon_button == null:
		coupon_button = get_node_or_null("RightUpgradePanel/Margin/UpgradeList/CouponButton") as Button
	if assortment_upgrade_button == null:
		assortment_upgrade_button = get_node_or_null("RightUpgradePanel/Margin/UpgradeList/AssortmentButton") as Button
	if dialog_layer == null:
		dialog_layer = get_node_or_null("DialogLayer") as Control
	if dialog_message_label == null:
		dialog_message_label = get_node_or_null("DialogLayer/DialogPanel/Margin/DialogMessage") as Label
	if popup_layer == null:
		popup_layer = get_node_or_null("PopupLayer") as Control
