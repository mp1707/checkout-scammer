@tool
extends Control
class_name RegisterDisplay

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres"):
	set(value):
		theme_resource = value
		_apply_label_theme()
@export var amount_label: Label:
	set(value):
		amount_label = value
		_apply_label_theme()
@export var empty_text: String = ""


func _ready() -> void:
	_resolve_child_references()
	_apply_label_theme()
	if not Engine.is_editor_hint():
		clear_amount()


func show_amount_cents(cents: int) -> void:
	if cents <= 0:
		clear_amount()
		return

	if amount_label == null:
		return

	amount_label.visible = true
	amount_label.text = _format_cents(cents)


func clear_amount() -> void:
	if amount_label == null:
		return

	amount_label.scale = Vector2.ONE
	amount_label.text = empty_text
	amount_label.visible = not empty_text.is_empty()


func get_display_text() -> String:
	if amount_label == null:
		return ""
	return amount_label.text


func _apply_label_theme() -> void:
	if amount_label == null or theme_resource == null:
		return

	if theme_resource.font != null:
		amount_label.add_theme_font_override("font", theme_resource.font)
	amount_label.add_theme_font_size_override("font_size", theme_resource.font_size_detail)
	amount_label.add_theme_color_override("font_color", theme_resource.register_display_text_color)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _format_cents(cents: int) -> String:
	var sign_prefix: String = ""
	var absolute_cents: int = cents
	if cents < 0:
		sign_prefix = "-"
		absolute_cents = -cents

	var dollars: int = floori(float(absolute_cents) / 100.0)
	return "%s$%d.%02d" % [sign_prefix, dollars, absolute_cents % 100]


func _resolve_child_references() -> void:
	if amount_label == null:
		amount_label = get_node_or_null("AmountLabel") as Label
