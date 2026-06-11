@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name RightUpgradePanel

signal coupon_button_pressed()
signal assortment_upgrade_button_pressed()
signal sticker_button_pressed()

@export var title_label: Label
@export var coupon_button: Button
@export var assortment_upgrade_button: Button
@export var sticker_button: Button


func _ready() -> void:
	super()
	_resolve_child_references()
	_apply_label_theme(self)
	_apply_button_theme()
	_connect_buttons()
	queue_fit_to_content()


func set_coupon_button_enabled(is_enabled: bool) -> void:
	if coupon_button != null:
		coupon_button.disabled = not is_enabled
	queue_fit_to_content()


func set_coupon_button_tooltip(button_tooltip_text: String) -> void:
	if coupon_button != null:
		coupon_button.tooltip_text = button_tooltip_text


func set_assortment_upgrade_button(label_text: String, is_enabled: bool) -> void:
	if assortment_upgrade_button == null:
		return
	assortment_upgrade_button.text = label_text
	assortment_upgrade_button.disabled = not is_enabled
	queue_fit_to_content()


func set_assortment_upgrade_tooltip(button_tooltip_text: String) -> void:
	if assortment_upgrade_button != null:
		assortment_upgrade_button.tooltip_text = button_tooltip_text


func set_sticker_button_enabled(is_enabled: bool) -> void:
	if sticker_button != null:
		sticker_button.disabled = not is_enabled
	queue_fit_to_content()


func set_sticker_button_tooltip(button_tooltip_text: String) -> void:
	if sticker_button != null:
		sticker_button.tooltip_text = button_tooltip_text


func _connect_buttons() -> void:
	if Engine.is_editor_hint():
		return
	if coupon_button != null and not coupon_button.pressed.is_connected(_on_coupon_button_pressed):
		coupon_button.pressed.connect(_on_coupon_button_pressed)
	if assortment_upgrade_button != null and not assortment_upgrade_button.pressed.is_connected(_on_assortment_upgrade_button_pressed):
		assortment_upgrade_button.pressed.connect(_on_assortment_upgrade_button_pressed)
	if sticker_button != null and not sticker_button.pressed.is_connected(_on_sticker_button_pressed):
		sticker_button.pressed.connect(_on_sticker_button_pressed)


func _on_coupon_button_pressed() -> void:
	coupon_button_pressed.emit()


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_button_pressed.emit()


func _on_sticker_button_pressed() -> void:
	sticker_button_pressed.emit()


func _apply_label_theme(root: Node) -> void:
	if root == null or theme_resource == null:
		return

	for child: Node in root.get_children():
		var label: Label = child as Label
		if label != null:
			var label_font: Font = theme_resource.bold_font
			if label != title_label and theme_resource.compact_bold_font != null:
				label_font = theme_resource.compact_bold_font
			if label_font == null:
				label_font = theme_resource.font
			if label_font != null:
				label.add_theme_font_override("font", label_font)
			var font_size: int = theme_resource.font_size_detail
			if label == title_label:
				font_size = theme_resource.font_size_small
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", theme_resource.text_color)
		_apply_label_theme(child)


func _apply_button_theme() -> void:
	if theme_resource == null:
		return

	_apply_button_font(coupon_button)
	_apply_button_font(assortment_upgrade_button)
	_apply_button_font(sticker_button)


func _apply_button_font(button: Button) -> void:
	if button == null:
		return
	var button_font: Font = theme_resource.compact_bold_font
	if button_font == null:
		button_font = theme_resource.bold_font
	if button_font == null:
		button_font = theme_resource.font
	if button_font != null:
		button.add_theme_font_override("font", button_font)
	button.add_theme_font_size_override("font_size", theme_resource.font_size_detail)


func _resolve_child_references() -> void:
	if title_label == null:
		title_label = _get_main_panel_label("UpgradeList/HeaderPanel/TitleLabel")
	if coupon_button == null:
		coupon_button = _get_main_panel_button("UpgradeList/CouponButton")
	if assortment_upgrade_button == null:
		assortment_upgrade_button = _get_main_panel_button("UpgradeList/AssortmentButton")
	if sticker_button == null:
		sticker_button = _get_main_panel_button("UpgradeList/StickerButton")


func _get_main_panel_label(label_path: String) -> Label:
	if main_panel == null:
		return null
	return main_panel.get_node_or_null(NodePath(label_path)) as Label


func _get_main_panel_button(button_path: String) -> Button:
	if main_panel == null:
		return null
	return main_panel.get_node_or_null(NodePath(button_path)) as Button
