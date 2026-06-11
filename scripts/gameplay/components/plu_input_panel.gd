extends Control
class_name PluInputPanel

signal plu_submitted(plu_code: String)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var weight_label: Label
@export var line_edit: LineEdit

var _is_filtering_text: bool = false


func _ready() -> void:
	_resolve_child_references()
	_apply_theme()
	hide_input()
	if line_edit != null:
		if not line_edit.text_changed.is_connected(_on_text_changed):
			line_edit.text_changed.connect(_on_text_changed)
		if not line_edit.text_submitted.is_connected(_on_text_submitted):
			line_edit.text_submitted.connect(_on_text_submitted)


func show_for_product(product_instance: ProductInstance) -> void:
	if product_instance == null:
		hide_input()
		return

	visible = true
	if weight_label != null:
		weight_label.text = "%dg" % product_instance.weight_grams
	if line_edit != null:
		line_edit.text = ""
		line_edit.editable = true
		line_edit.call_deferred("grab_focus")


func hide_input() -> void:
	visible = false
	if line_edit != null:
		line_edit.text = ""
		line_edit.release_focus()


func is_input_active() -> bool:
	return visible and line_edit != null and line_edit.has_focus()


func play_invalid_feedback() -> void:
	if line_edit == null:
		return

	line_edit.modulate = Color(1.0, 0.0, 0.25098, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(line_edit, "modulate", Color.WHITE, 0.12) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	line_edit.call_deferred("grab_focus")


func clear_code_and_refocus() -> void:
	if line_edit == null:
		return
	line_edit.text = ""
	line_edit.call_deferred("grab_focus")


func _on_text_changed(new_text: String) -> void:
	if _is_filtering_text:
		return

	var filtered_text: String = ""
	for index: int in range(new_text.length()):
		var character: String = new_text.substr(index, 1)
		if character.is_valid_int():
			filtered_text += character
		if filtered_text.length() >= 4:
			break

	if filtered_text == new_text:
		return

	_is_filtering_text = true
	line_edit.text = filtered_text
	line_edit.caret_column = filtered_text.length()
	_is_filtering_text = false


func _on_text_submitted(submitted_text: String) -> void:
	if not visible:
		return
	plu_submitted.emit(submitted_text)


func _apply_theme() -> void:
	if theme_resource == null:
		return

	for label: Label in [weight_label]:
		if label == null:
			continue
		if theme_resource.font != null:
			label.add_theme_font_override("font", theme_resource.font)
		label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		label.add_theme_color_override("font_color", theme_resource.text_color)

	if line_edit != null:
		if theme_resource.font != null:
			line_edit.add_theme_font_override("font", theme_resource.font)
		line_edit.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		line_edit.add_theme_color_override("font_color", theme_resource.text_color)


func _resolve_child_references() -> void:
	if weight_label == null:
		weight_label = get_node_or_null("Panel/VBox/WeightLabel") as Label
	if line_edit == null:
		line_edit = get_node_or_null("Panel/VBox/CodeInput") as LineEdit
