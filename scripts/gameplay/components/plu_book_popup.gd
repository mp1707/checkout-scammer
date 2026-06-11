@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name PluBookPopup

signal popup_closed()

@export var title_label: Label
@export var entries_container: VBoxContainer
@export var close_button: Button


func _ready() -> void:
	super()
	_resolve_popup_references()
	_apply_label_theme(self)
	if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)


func configure_products(products: Array[ProductVariantResource]) -> void:
	_clear_entries()
	for product: ProductVariantResource in products:
		if product == null or not product.is_weighable():
			continue
		_add_entry(product.display_name, product.plu_code)
	queue_fit_to_content()


func _add_entry(display_name: String, plu_code: String) -> void:
	if entries_container == null:
		return

	var entry_label: Label = Label.new()
	entry_label.text = "%s - %s" % [display_name, plu_code]
	entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_theme_to_label(entry_label, false)
	entries_container.add_child(entry_label)


func _clear_entries() -> void:
	if entries_container == null:
		return
	for child: Node in entries_container.get_children():
		child.queue_free()


func _on_close_button_pressed() -> void:
	popup_closed.emit()


func _apply_label_theme(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		var label: Label = child as Label
		if label != null:
			_apply_label_theme_to_label(label, label == title_label)
		_apply_label_theme(child)


func _apply_label_theme_to_label(label: Label, is_title: bool) -> void:
	if label == null or theme_resource == null:
		return
	var label_font: Font = theme_resource.bold_font if is_title else theme_resource.font
	if label_font != null:
		label.add_theme_font_override("font", label_font)
	label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	label.add_theme_color_override("font_color", theme_resource.text_color)


func _resolve_popup_references() -> void:
	if title_label == null:
		title_label = get_node_or_null("MainPanel/VBox/TitleLabel") as Label
	if entries_container == null:
		entries_container = get_node_or_null("MainPanel/VBox/Entries") as VBoxContainer
	if close_button == null:
		close_button = get_node_or_null("MainPanel/VBox/CloseButton") as Button
