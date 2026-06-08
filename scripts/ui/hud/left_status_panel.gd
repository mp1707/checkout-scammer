@tool
extends "res://scripts/ui/panels/pixel_panel.gd"
class_name LeftStatusPanel

@export var title_label: Label
@export var day_value_label: Label
@export var customer_value_label: Label
@export var rent_value_label: Label
@export var cash_value_label: Label

var _displayed_cash_cents: int = -1
var _cash_tween: Tween


func _ready() -> void:
	super()
	_resolve_child_references()
	_apply_label_theme(self)


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
		if _displayed_cash_cents < 0 or Engine.is_editor_hint():
			_set_displayed_cash_cents(cash_cents)
		elif _displayed_cash_cents != cash_cents:
			_animate_cash_value(cash_cents)


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
	if title_label == null:
		title_label = get_node_or_null("Margin/StatusList/TitleLabel") as Label
	if day_value_label == null:
		day_value_label = get_node_or_null("Margin/StatusList/DayValue") as Label
	if customer_value_label == null:
		customer_value_label = get_node_or_null("Margin/StatusList/CustomerValue") as Label
	if rent_value_label == null:
		rent_value_label = get_node_or_null("Margin/StatusList/RentValue") as Label
	if cash_value_label == null:
		cash_value_label = get_node_or_null("Margin/StatusList/CashValue") as Label
