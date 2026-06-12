@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
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
	_validate_required_references()
	_apply_label_theme(self)
	_apply_status_value_colors()
	queue_fit_to_content()


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
	queue_fit_to_content()


func _apply_label_theme(root: Node) -> void:
	if root == null or theme_resource == null:
		return

	for child: Node in root.get_children():
		var label: Label = child as Label
		if label != null:
			var label_font: Font = theme_resource.font
			if not _is_value_label(label) and theme_resource.bold_font != null:
				label_font = theme_resource.bold_font
				if label != title_label and theme_resource.compact_bold_font != null:
					label_font = theme_resource.compact_bold_font
			if label_font != null:
				label.add_theme_font_override("font", label_font)
			var font_size: int = theme_resource.font_size_detail
			if label == title_label:
				font_size = theme_resource.font_size_small
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", theme_resource.text_color)
		_apply_label_theme(child)


func _is_value_label(label: Label) -> bool:
	return (
		label == day_value_label
		or label == customer_value_label
		or label == rent_value_label
		or label == cash_value_label
	)


func _apply_status_value_colors() -> void:
	if theme_resource == null:
		return
	if rent_value_label != null:
		rent_value_label.add_theme_color_override("font_color", theme_resource.danger_color)
	if cash_value_label != null:
		cash_value_label.add_theme_color_override("font_color", theme_resource.money_color)


func _animate_cash_value(target_cents: int) -> void:
	if _cash_tween != null and _cash_tween.is_valid():
		_cash_tween.kill()

	var distance_cents: int = absi(target_cents - _displayed_cash_cents)
	var duration_seconds: float = clampf(0.12 + float(distance_cents) / 2500.0, 0.16, 0.45)
	_cash_tween = create_tween()
	_cash_tween.tween_method(
		_set_displayed_cash_cents_from_float,
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


func _validate_required_references() -> void:
	if day_value_label == null or customer_value_label == null or rent_value_label == null or cash_value_label == null:
		push_error("%s is missing required label references. Assign them in the scene." % get_path())
