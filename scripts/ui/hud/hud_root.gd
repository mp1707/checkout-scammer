extends Control
class_name HudRoot

const LeftStatusPanelScript: GDScript = preload("res://scripts/ui/hud/left_status_panel.gd")
const RightUpgradePanelScript: GDScript = preload("res://scripts/ui/hud/right_upgrade_panel.gd")

signal coupon_button_pressed()
signal coupon_selected(coupon_id: String)
signal assortment_upgrade_button_pressed()
signal dialog_closed()

const FALLBACK_VIEWPORT_SIZE: Vector2 = Vector2(640.0, 360.0)
const DIALOG_HORIZONTAL_MARGIN: float = 16.0
const DIALOG_BOTTOM_MARGIN: float = 28.0
const DIALOG_PANEL_HORIZONTAL_PADDING: int = 24

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var left_status_panel: Control
@export var right_upgrade_panel: Control
@export var dialog_layer: Control
@export var dialog_panel_frame: PixelPanelFrame
@export var dialog_message_label: Label
@export var dialog_continue_button: Button
@export var popup_layer: Control
@export var coupon_popup_scene: PackedScene
@export var dialog_min_text_width: int = 120
@export var dialog_max_text_width: int = 380

var _active_popup: Control


func _ready() -> void:
	_resolve_child_references()
	_connect_panel_signals()
	_connect_dialog_signals()
	_apply_label_theme(dialog_layer)
	hide_dialog()
	_set_popup_layer_visible(false)


func update_run_summary(
	day: int,
	customer_number: int,
	customers_per_day: int,
	rent_due_cents: int,
	cash_cents: int
) -> void:
	var panel: LeftStatusPanelScript = _get_left_status_panel()
	if panel != null:
		panel.update_run_summary(day, customer_number, customers_per_day, rent_due_cents, cash_cents)


func set_coupon_button_enabled(is_enabled: bool) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_coupon_button_enabled(is_enabled)


func set_coupon_button_tooltip(button_tooltip_text: String) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_coupon_button_tooltip(button_tooltip_text)


func set_assortment_upgrade_button(label_text: String, is_enabled: bool) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_assortment_upgrade_button(label_text, is_enabled)


func set_assortment_upgrade_tooltip(button_tooltip_text: String) -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel != null:
		panel.set_assortment_upgrade_tooltip(button_tooltip_text)


func show_dialog(message: String) -> void:
	if dialog_layer != null:
		dialog_layer.visible = true
	if dialog_message_label != null:
		dialog_message_label.text = message
		_fit_dialog_to_message(message)


func hide_dialog() -> void:
	if dialog_layer != null:
		dialog_layer.visible = false


func show_coupon_popup(coupons: Array[CouponResource], affordable_coupon_ids: PackedStringArray) -> void:
	if coupon_popup_scene == null or popup_layer == null:
		return

	close_coupon_popup()
	var popup_node: Node = coupon_popup_scene.instantiate()
	var popup_control: Control = popup_node as Control
	if popup_control == null:
		popup_node.queue_free()
		return

	_active_popup = popup_control
	popup_layer.add_child(_active_popup)
	_set_popup_layer_visible(true)

	if _active_popup.has_signal("popup_closed"):
		_active_popup.connect("popup_closed", Callable(self, "close_coupon_popup"))
	if _active_popup.has_signal("coupon_selected"):
		_active_popup.connect("coupon_selected", _on_coupon_selected)
	if _active_popup.has_method("configure_options"):
		_active_popup.call("configure_options", coupons, affordable_coupon_ids)


func close_coupon_popup() -> void:
	if _active_popup != null:
		_active_popup.queue_free()
		_active_popup = null
	_set_popup_layer_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ENTER and key_event.keycode != KEY_KP_ENTER:
		return
	if dialog_layer != null and dialog_layer.visible:
		_close_visible_dialog()
		get_viewport().set_input_as_handled()


func _connect_panel_signals() -> void:
	var panel: RightUpgradePanelScript = _get_right_upgrade_panel()
	if panel == null:
		return
	if not panel.coupon_button_pressed.is_connected(_on_coupon_button_pressed):
		panel.coupon_button_pressed.connect(_on_coupon_button_pressed)
	if not panel.assortment_upgrade_button_pressed.is_connected(_on_assortment_upgrade_button_pressed):
		panel.assortment_upgrade_button_pressed.connect(_on_assortment_upgrade_button_pressed)


func _connect_dialog_signals() -> void:
	if dialog_continue_button == null:
		return
	if not dialog_continue_button.pressed.is_connected(_on_dialog_continue_pressed):
		dialog_continue_button.pressed.connect(_on_dialog_continue_pressed)


func _on_coupon_button_pressed() -> void:
	coupon_button_pressed.emit()


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_button_pressed.emit()


func _on_coupon_selected(coupon_id: String) -> void:
	coupon_selected.emit(coupon_id)
	close_coupon_popup()


func _on_dialog_continue_pressed() -> void:
	_close_visible_dialog()


func _close_visible_dialog() -> void:
	if dialog_layer == null or not dialog_layer.visible:
		return

	hide_dialog()
	dialog_closed.emit()


func _apply_label_theme(root: Node) -> void:
	if root == null or theme_resource == null:
		return

	for child: Node in root.get_children():
		var label: Label = child as Label
		if label != null:
			if theme_resource.font != null:
				label.add_theme_font_override("font", theme_resource.font)
			label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
			label.add_theme_color_override("font_color", theme_resource.text_color)
		_apply_label_theme(child)


func _set_popup_layer_visible(should_show_popup_layer: bool) -> void:
	if popup_layer != null:
		popup_layer.visible = should_show_popup_layer


func _fit_dialog_to_message(message: String) -> void:
	if dialog_message_label == null or dialog_panel_frame == null:
		return

	var text_width: int = _get_dialog_text_width(message)
	dialog_message_label.custom_minimum_size = Vector2(
		float(text_width),
		float(_get_wrapped_dialog_text_height(message, text_width))
	)
	dialog_message_label.update_minimum_size()
	dialog_panel_frame.panel_width = _get_dialog_panel_width(text_width)
	dialog_panel_frame.fit_frame_to_content()
	_position_dialog_frame()
	call_deferred("_position_dialog_frame")


func _get_dialog_text_width(message: String) -> int:
	var text_width: int = _get_estimated_text_width(message)
	return clampi(text_width, dialog_min_text_width, dialog_max_text_width)


func _get_dialog_panel_width(text_width: int) -> int:
	var button_min_width: int = 0
	if dialog_continue_button != null:
		button_min_width = ceili(dialog_continue_button.get_combined_minimum_size().x)
	return max(text_width + DIALOG_PANEL_HORIZONTAL_PADDING, button_min_width + DIALOG_PANEL_HORIZONTAL_PADDING)


func _get_estimated_text_width(text: String) -> int:
	if theme_resource == null or theme_resource.font == null:
		return ceili(float(text.length()) * float(CheckoutThemeResource.PANEL_TEXTURE_MARGIN))

	var widest_line_width: float = 0.0
	var font_size: int = theme_resource.font_size_small
	var text_lines: PackedStringArray = text.split("\n", false)
	for text_line: String in text_lines:
		widest_line_width = maxf(widest_line_width, _get_text_line_width(text_line, font_size))

	return ceili(widest_line_width)


func _get_wrapped_dialog_text_height(text: String, text_width: int) -> int:
	if theme_resource == null or theme_resource.font == null:
		return theme_resource.font_size_small if theme_resource != null else 8

	var font_size: int = theme_resource.font_size_small
	var line_count: int = _get_wrapped_line_count(text, text_width, font_size)
	var line_height: int = ceili(theme_resource.font.get_height(font_size))
	return maxi(font_size, line_count * line_height)


func _get_wrapped_line_count(text: String, text_width: int, font_size: int) -> int:
	var wrapped_line_count: int = 0
	var source_lines: PackedStringArray = text.split("\n", true)
	for source_line: String in source_lines:
		if source_line.is_empty():
			wrapped_line_count += 1
			continue

		var current_line: String = ""
		var words: PackedStringArray = source_line.split(" ", false)
		for word: String in words:
			var candidate_line: String = word if current_line.is_empty() else "%s %s" % [current_line, word]
			if current_line.is_empty() or _get_text_line_width(candidate_line, font_size) <= float(text_width):
				current_line = candidate_line
				continue

			wrapped_line_count += 1
			current_line = word

		if not current_line.is_empty():
			wrapped_line_count += 1

	return maxi(1, wrapped_line_count)


func _get_text_line_width(text_line: String, font_size: int) -> float:
	if theme_resource == null or theme_resource.font == null:
		return float(text_line.length()) * float(CheckoutThemeResource.PANEL_TEXTURE_MARGIN)

	var line_size: Vector2 = theme_resource.font.get_string_size(
		text_line,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	)
	return line_size.x


func _position_dialog_frame() -> void:
	if dialog_panel_frame == null:
		return

	var available_size: Vector2 = size
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		available_size = get_viewport_rect().size
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		available_size = FALLBACK_VIEWPORT_SIZE

	var frame_size: Vector2 = dialog_panel_frame.size
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		frame_size = dialog_panel_frame.custom_minimum_size

	var max_x: float = maxf(DIALOG_HORIZONTAL_MARGIN, available_size.x - frame_size.x - DIALOG_HORIZONTAL_MARGIN)
	var max_y: float = maxf(DIALOG_HORIZONTAL_MARGIN, available_size.y - frame_size.y - DIALOG_HORIZONTAL_MARGIN)
	var target_x: float = clampf(roundf((available_size.x - frame_size.x) * 0.5), DIALOG_HORIZONTAL_MARGIN, max_x)
	var target_y: float = clampf(roundf(available_size.y - frame_size.y - DIALOG_BOTTOM_MARGIN), DIALOG_HORIZONTAL_MARGIN, max_y)
	dialog_panel_frame.position = Vector2(target_x, target_y)


func _get_left_status_panel() -> LeftStatusPanelScript:
	return left_status_panel as LeftStatusPanelScript


func _get_right_upgrade_panel() -> RightUpgradePanelScript:
	return right_upgrade_panel as RightUpgradePanelScript


func _resolve_child_references() -> void:
	if left_status_panel == null:
		left_status_panel = get_node_or_null("LeftStatusPanel") as Control
	if left_status_panel == null:
		left_status_panel = get_node_or_null("../LeftStatusPanel") as Control
	if right_upgrade_panel == null:
		right_upgrade_panel = get_node_or_null("RightUpgradePanel") as Control
	if right_upgrade_panel == null:
		right_upgrade_panel = get_node_or_null("../RightUpgradePanel") as Control
	if dialog_layer == null:
		dialog_layer = get_node_or_null("DialogLayer") as Control
	if dialog_panel_frame == null:
		dialog_panel_frame = get_node_or_null("DialogLayer/DialogFrame") as PixelPanelFrame
	if dialog_message_label == null:
		dialog_message_label = get_node_or_null("DialogLayer/DialogFrame/MainPanel/DialogContent/DialogMessage") as Label
	if dialog_continue_button == null:
		dialog_continue_button = get_node_or_null("DialogLayer/DialogFrame/MainPanel/DialogContent/ButtonRow/ContinueButton") as Button
	if popup_layer == null:
		popup_layer = get_node_or_null("PopupLayer") as Control
