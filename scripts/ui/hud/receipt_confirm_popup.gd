@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name ReceiptConfirmPopup

signal confirmed()
signal cancelled()

@export var title_label: Label
@export var body_label: Label
@export var yes_button: Button
@export var no_button: Button


func _ready() -> void:
	super()
	_validate_required_references()
	_apply_label_theme(self)
	_apply_texts()
	if yes_button != null and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if no_button != null and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		cancelled.emit()
		get_viewport().set_input_as_handled()


func _on_yes_pressed() -> void:
	confirmed.emit()


func _on_no_pressed() -> void:
	cancelled.emit()


func _apply_texts() -> void:
	if title_label != null:
		title_label.text = UiTexts.RECEIPT_CONFIRM_TITLE
	if body_label != null:
		body_label.text = UiTexts.RECEIPT_CONFIRM_BODY
	if yes_button != null:
		yes_button.text = UiTexts.RECEIPT_CONFIRM_YES
	if no_button != null:
		no_button.text = UiTexts.RECEIPT_CONFIRM_NO


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


func _validate_required_references() -> void:
	if title_label == null or body_label == null or yes_button == null or no_button == null:
		push_error("%s is missing required references. Assign them in the scene." % get_path())
