extends Control
class_name HudRoot

const LeftStatusPanelScript: GDScript = preload("res://scripts/ui/hud/left_status_panel.gd")
const RightUpgradePanelScript: GDScript = preload("res://scripts/ui/hud/right_upgrade_panel.gd")

signal coupon_button_pressed()
signal coupon_selected(coupon_id: String)
signal assortment_upgrade_button_pressed()
signal dialog_closed()

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var left_status_panel: Control
@export var right_upgrade_panel: Control
@export var dialog_layer: Control
@export var dialog_message_label: Label
@export var popup_layer: Control
@export var coupon_popup_scene: PackedScene

var _active_popup: Control


func _ready() -> void:
	_resolve_child_references()
	_connect_panel_signals()
	_apply_label_theme(dialog_layer)
	hide_dialog()
	_set_popup_layer_visible(false)


func update_run_summary(
	day: int,
	customer_number: int,
	customers_per_day: int,
	rent_due_cents: int,
	cash_cents: int
) -> void:
	var panel: LeftStatusPanelScript = _get_left_status_panel()
	if panel != null:
		panel.update_run_summary(day, customer_number, customers_per_day, rent_due_cents, cash_cents)


func set_coupon_button_enabled(is_enabled: bool) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_coupon_button_enabled(is_enabled)


func set_coupon_button_tooltip(button_tooltip_text: String) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_coupon_button_tooltip(button_tooltip_text)


func set_assortment_upgrade_button(label_text: String, is_enabled: bool) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_assortment_upgrade_button(label_text, is_enabled)


func set_assortment_upgrade_tooltip(button_tooltip_text: String) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_assortment_upgrade_tooltip(button_tooltip_text)


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


func _connect_panel_signals() -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel == null:
		return
	if not panel.coupon_button_pressed.is_connected(_on_coupon_button_pressed):
		panel.coupon_button_pressed.connect(_on_coupon_button_pressed)
	if not panel.assortment_upgrade_button_pressed.is_connected(_on_assortment_upgrade_button_pressed):
		panel.assortment_upgrade_button_pressed.connect(_on_assortment_upgrade_button_pressed)


func _on_coupon_button_pressed() -> void:
	coupon_button_pressed.emit()


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_button_pressed.emit()


func _on_coupon_selected(coupon_id: String) -> void:
	coupon_selected.emit(coupon_id)
	close_coupon_popup()


func _apply_label_theme(root: Node) -> void:
	if root == null or theme_resource == null:
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


func _get_left_status_panel() -> LeftStatusPanelScript:
	return left_status_panel as LeftStatusPanelScript


func _get_right_upgrade_panel() -> RightUpgradePanelScript:
	return right_upgrade_panel as RightUpgradePanelScript


func _resolve_child_references() -> void:
	if left_status_panel == null:
		left_status_panel = get_node_or_null("LeftStatusPanel") as Control
	if left_status_panel == null:
		left_status_panel = get_node_or_null("../LeftStatusPanel") as Control
	if right_upgrade_panel == null:
		right_upgrade_panel = get_node_or_null("RightUpgradePanel") as Control
	if right_upgrade_panel == null:
		right_upgrade_panel = get_node_or_null("../RightUpgradePanel") as Control
	if dialog_layer == null:
		dialog_layer = get_node_or_null("DialogLayer") as Control
	if dialog_message_label == null:
		dialog_message_label = get_node_or_null("DialogLayer/DialogPanel/Margin/DialogMessage") as Label
	if popup_layer == null:
		popup_layer = get_node_or_null("PopupLayer") as Control
