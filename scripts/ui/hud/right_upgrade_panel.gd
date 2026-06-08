@tool
extends "res://scripts/ui/panels/pixel_panel.gd"
class_name RightUpgradePanel

signal coupon_button_pressed()
signal assortment_upgrade_button_pressed()

@export var title_label: Label
@export var coupon_button: Button
@export var assortment_upgrade_button: Button


func _ready() -> void:
	super()
	_resolve_child_references()
	_apply_label_theme(self)
	_connect_buttons()


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


func _connect_buttons() -> void:
	if Engine.is_editor_hint():
		return
	if coupon_button != null and not coupon_button.pressed.is_connected(_on_coupon_button_pressed):
		coupon_button.pressed.connect(_on_coupon_button_pressed)
	if assortment_upgrade_button != null and not assortment_upgrade_button.pressed.is_connected(_on_assortment_upgrade_button_pressed):
		assortment_upgrade_button.pressed.connect(_on_assortment_upgrade_button_pressed)


func _on_coupon_button_pressed() -> void:
	coupon_button_pressed.emit()


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_button_pressed.emit()


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


func _resolve_child_references() -> void:
	if title_label == null:
		title_label = get_node_or_null("Margin/UpgradeList/TitleLabel") as Label
	if coupon_button == null:
		coupon_button = get_node_or_null("Margin/UpgradeList/CouponButton") as Button
	if assortment_upgrade_button == null:
		assortment_upgrade_button = get_node_or_null("Margin/UpgradeList/AssortmentButton") as Button
