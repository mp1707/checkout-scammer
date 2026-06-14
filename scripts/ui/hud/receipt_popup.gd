@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name ReceiptPopup

signal receipt_closed()

@export var title_label: Label
@export var empty_label: Label
@export var lines_container: VBoxContainer
@export var total_label: Label
@export var continue_button: Button
@export var receipt_line_row_scene: PackedScene


func _ready() -> void:
	super()
	_validate_required_references()
	_apply_label_theme(self)
	_apply_texts()
	if continue_button != null and not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)


func configure_receipt(lines: Array[ReceiptLine], total_cents: int) -> void:
	_clear_lines()
	if empty_label != null:
		empty_label.visible = lines.is_empty()
	for line: ReceiptLine in lines:
		_add_line(line)
	if total_label != null:
		total_label.text = "%s %s" % [UiTexts.RECEIPT_TOTAL_LABEL, _format_cents(total_cents)]
	queue_fit_to_content()


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		receipt_closed.emit()
		get_viewport().set_input_as_handled()


func _add_line(line: ReceiptLine) -> void:
	if lines_container == null or receipt_line_row_scene == null:
		return
	var row_node: Node = receipt_line_row_scene.instantiate()
	var row: ReceiptLineRow = row_node as ReceiptLineRow
	if row == null:
		row_node.queue_free()
		return
	row.configure(line)
	lines_container.add_child(row)


func _clear_lines() -> void:
	if lines_container == null:
		return
	for child: Node in lines_container.get_children():
		child.queue_free()


func _on_continue_pressed() -> void:
	receipt_closed.emit()


func _apply_texts() -> void:
	if title_label != null:
		title_label.text = UiTexts.RECEIPT_TITLE
	if empty_label != null:
		empty_label.text = UiTexts.RECEIPT_EMPTY_LABEL
	if continue_button != null:
		continue_button.text = UiTexts.RECEIPT_CONTINUE_BUTTON


func _apply_label_theme(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		var label: Label = child as Label
		if label != null:
			_apply_label_theme_to_label(label, label == title_label or label == total_label)
		_apply_label_theme(child)


func _apply_label_theme_to_label(label: Label, is_strong: bool) -> void:
	if label == null or theme_resource == null:
		return
	var label_font: Font = theme_resource.bold_font if is_strong else theme_resource.font
	if label_font != null:
		label.add_theme_font_override("font", label_font)
	label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	label.add_theme_color_override("font_color", theme_resource.text_color)


func _format_cents(cents: int) -> String:
	var dollars: int = floori(float(cents) / 100.0)
	return "$%d.%02d" % [dollars, cents % 100]


func _validate_required_references() -> void:
	if lines_container == null or total_label == null or continue_button == null or receipt_line_row_scene == null:
		push_error("%s is missing required references. Assign them in the scene." % get_path())
