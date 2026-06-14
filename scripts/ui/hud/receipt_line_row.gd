@tool
extends PanelContainer
class_name ReceiptLineRow

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres"):
	set(value):
		theme_resource = value
		_apply_theme()
@export var item_label: Label
@export var amount_label: Label


func _ready() -> void:
	_apply_theme()


func configure(line: ReceiptLine) -> void:
	if line == null:
		return
	if item_label != null:
		item_label.text = line.product_display_name
	if amount_label != null:
		amount_label.text = _format_cents(line.amount_cents)
	_apply_background(line.is_duplicate)


func _apply_theme() -> void:
	if theme_resource == null:
		return
	if item_label != null:
		_apply_label_theme(item_label)
	if amount_label != null:
		_apply_label_theme(amount_label)


func _apply_label_theme(label: Label) -> void:
	if theme_resource.font != null:
		label.add_theme_font_override("font", theme_resource.font)
	label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	label.add_theme_color_override("font_color", theme_resource.text_color)


func _apply_background(is_duplicate: bool) -> void:
	if theme_resource == null:
		return
	if not is_duplicate:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		return
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = theme_resource.panel_accent_color
	style_box.content_margin_left = 2
	style_box.content_margin_right = 2
	style_box.content_margin_top = 1
	style_box.content_margin_bottom = 1
	add_theme_stylebox_override("panel", style_box)


func _format_cents(cents: int) -> String:
	var dollars: int = floori(float(cents) / 100.0)
	return "$%d.%02d" % [dollars, cents % 100]
