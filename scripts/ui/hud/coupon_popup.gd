extends "res://scripts/ui/panels/pixel_panel.gd"
class_name CouponPopup

signal popup_closed()

@export var title_label: Label
@export var body_label: Label
@export var close_button: Button


func _ready() -> void:
	super()
	_apply_popup_label_theme()
	if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)


func set_placeholder_text(message: String) -> void:
	if body_label != null:
		body_label.text = message


func _on_close_button_pressed() -> void:
	popup_closed.emit()


func _apply_popup_label_theme() -> void:
	if theme_resource == null:
		return

	if title_label != null:
		if theme_resource.font != null:
			title_label.add_theme_font_override("font", theme_resource.font)
		title_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		title_label.add_theme_color_override("font_color", theme_resource.text_color)

	if body_label != null:
		if theme_resource.font != null:
			body_label.add_theme_font_override("font", theme_resource.font)
		body_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
		body_label.add_theme_color_override("font_color", theme_resource.text_color)
