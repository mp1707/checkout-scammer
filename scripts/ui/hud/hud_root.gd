extends Control
class_name HudRoot

signal coupon_button_pressed()
signal coupon_selected(coupon_id: String)
signal assortment_upgrade_button_pressed()
signal sticker_button_pressed()
signal sticker_drag_released(sticker_id: String, global_drop_position: Vector2)
signal receipt_confirmed()
signal receipt_cancelled()
signal receipt_closed()
signal dialog_closed()

const FALLBACK_VIEWPORT_SIZE: Vector2 = Vector2(640.0, 360.0)
const DIALOG_HORIZONTAL_MARGIN: float = 16.0
const DIALOG_BOTTOM_MARGIN: float = 28.0
const DIALOG_PANEL_HORIZONTAL_PADDING: int = 24
const DIALOG_LAYER_Z_INDEX: int = 1000
const POPUP_LAYER_Z_INDEX: int = 1100

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var left_status_panel: LeftStatusPanel
@export var right_upgrade_panel: RightUpgradePanel
@export var dialog_layer: Control
@export var dialog_panel_frame: PixelPanelFrame
@export var dialog_message_label: Label
@export var dialog_continue_button: Button
@export var popup_layer: Control
@export var coupon_popup_scene: PackedScene
@export var sticker_popup_scene: PackedScene
@export var receipt_confirm_popup_scene: PackedScene
@export var receipt_popup_scene: PackedScene
@export var dialog_min_text_width: int = 120
@export var dialog_max_text_width: int = 380
@export var sticker_popup_position: Vector2 = Vector2(532.0, 134.0)

var _active_popup: Control


func _ready() -> void:
	_validate_required_references()
	_apply_layer_order()
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
	left_status_panel.update_run_summary(day, customer_number, customers_per_day, rent_due_cents, cash_cents)


func set_coupon_button_enabled(is_enabled: bool) -> void:
	right_upgrade_panel.set_coupon_button_enabled(is_enabled)


func set_coupon_button_tooltip(button_tooltip_text: String) -> void:
	right_upgrade_panel.set_coupon_button_tooltip(button_tooltip_text)


func set_assortment_upgrade_button(label_text: String, is_enabled: bool) -> void:
	right_upgrade_panel.set_assortment_upgrade_button(label_text, is_enabled)


func set_assortment_upgrade_tooltip(button_tooltip_text: String) -> void:
	right_upgrade_panel.set_assortment_upgrade_tooltip(button_tooltip_text)


func set_sticker_button_enabled(is_enabled: bool) -> void:
	right_upgrade_panel.set_sticker_button_enabled(is_enabled)


func set_sticker_button_tooltip(button_tooltip_text: String) -> void:
	right_upgrade_panel.set_sticker_button_tooltip(button_tooltip_text)


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

	close_active_popup()
	var popup: CouponPopup = coupon_popup_scene.instantiate() as CouponPopup
	if popup == null:
		push_error("Configured coupon_popup_scene does not instance a CouponPopup.")
		return

	_active_popup = popup
	popup_layer.add_child(popup)
	_set_popup_layer_visible(true)

	popup.popup_closed.connect(close_active_popup)
	popup.coupon_selected.connect(_on_coupon_selected)
	popup.configure_options(coupons, affordable_coupon_ids)


func show_sticker_popup(entries: Array[StickerInventoryEntry]) -> void:
	if sticker_popup_scene == null or popup_layer == null:
		return

	close_active_popup()
	var popup: StickerPopup = sticker_popup_scene.instantiate() as StickerPopup
	if popup == null:
		push_error("Configured sticker_popup_scene does not instance a StickerPopup.")
		return

	_active_popup = popup
	popup_layer.add_child(popup)
	popup.position = sticker_popup_position
	_set_popup_layer_visible(true)

	popup.popup_closed.connect(close_active_popup)
	popup.sticker_drag_released.connect(_on_sticker_drag_released)
	popup.configure_inventory(entries)


func refresh_sticker_popup(entries: Array[StickerInventoryEntry]) -> void:
	var sticker_popup: StickerPopup = _active_popup as StickerPopup
	if sticker_popup != null:
		sticker_popup.configure_inventory(entries)


func show_receipt_confirm() -> void:
	if receipt_confirm_popup_scene == null or popup_layer == null:
		return

	close_active_popup()
	var popup: ReceiptConfirmPopup = receipt_confirm_popup_scene.instantiate() as ReceiptConfirmPopup
	if popup == null:
		push_error("Configured receipt_confirm_popup_scene does not instance a ReceiptConfirmPopup.")
		return

	_active_popup = popup
	popup_layer.add_child(popup)
	_set_popup_layer_visible(true)
	popup.confirmed.connect(_on_receipt_confirmed)
	popup.cancelled.connect(_on_receipt_cancelled)


func show_receipt(lines: Array[ReceiptLine], total_cents: int) -> void:
	if receipt_popup_scene == null or popup_layer == null:
		return

	close_active_popup()
	var popup: ReceiptPopup = receipt_popup_scene.instantiate() as ReceiptPopup
	if popup == null:
		push_error("Configured receipt_popup_scene does not instance a ReceiptPopup.")
		return

	_active_popup = popup
	popup_layer.add_child(popup)
	_set_popup_layer_visible(true)
	popup.receipt_closed.connect(_on_receipt_closed)
	popup.configure_receipt(lines, total_cents)


func close_active_popup() -> void:
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


func _validate_required_references() -> void:
	if left_status_panel == null:
		push_error("%s is missing required scene reference 'left_status_panel'." % get_path())
	if right_upgrade_panel == null:
		push_error("%s is missing required scene reference 'right_upgrade_panel'." % get_path())
	if dialog_layer == null:
		push_error("%s is missing required scene reference 'dialog_layer'." % get_path())
	if dialog_panel_frame == null:
		push_error("%s is missing required scene reference 'dialog_panel_frame'." % get_path())
	if dialog_message_label == null:
		push_error("%s is missing required scene reference 'dialog_message_label'." % get_path())
	if dialog_continue_button == null:
		push_error("%s is missing required scene reference 'dialog_continue_button'." % get_path())
	if popup_layer == null:
		push_error("%s is missing required scene reference 'popup_layer'." % get_path())
	if receipt_confirm_popup_scene == null:
		push_error("%s is missing required scene reference 'receipt_confirm_popup_scene'." % get_path())
	if receipt_popup_scene == null:
		push_error("%s is missing required scene reference 'receipt_popup_scene'." % get_path())
	if theme_resource == null or theme_resource.font == null:
		push_error("%s needs a theme_resource with a font for dialog sizing." % get_path())


func _apply_layer_order() -> void:
	if dialog_layer != null:
		dialog_layer.z_index = DIALOG_LAYER_Z_INDEX
	if popup_layer != null:
		popup_layer.z_index = POPUP_LAYER_Z_INDEX


func _connect_panel_signals() -> void:
	if right_upgrade_panel == null:
		return
	right_upgrade_panel.coupon_button_pressed.connect(_on_coupon_button_pressed)
	right_upgrade_panel.assortment_upgrade_button_pressed.connect(_on_assortment_upgrade_button_pressed)
	right_upgrade_panel.sticker_button_pressed.connect(_on_sticker_button_pressed)


func _connect_dialog_signals() -> void:
	if dialog_continue_button == null:
		return
	dialog_continue_button.pressed.connect(_on_dialog_continue_pressed)


func _on_coupon_button_pressed() -> void:
	coupon_button_pressed.emit()


func _on_assortment_upgrade_button_pressed() -> void:
	assortment_upgrade_button_pressed.emit()


func _on_sticker_button_pressed() -> void:
	sticker_button_pressed.emit()


func _on_coupon_selected(coupon_id: String) -> void:
	coupon_selected.emit(coupon_id)
	close_active_popup()


func _on_sticker_drag_released(sticker_id: String, global_drop_position: Vector2) -> void:
	sticker_drag_released.emit(sticker_id, global_drop_position)


func _on_receipt_confirmed() -> void:
	close_active_popup()
	receipt_confirmed.emit()


func _on_receipt_cancelled() -> void:
	close_active_popup()
	receipt_cancelled.emit()


func _on_receipt_closed() -> void:
	close_active_popup()
	receipt_closed.emit()


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


## Sizes the dialog frame to the message using the font's own line metrics,
## so the measured wrap matches what the Label renders.
func _fit_dialog_to_message(message: String) -> void:
	if dialog_message_label == null or dialog_panel_frame == null:
		return
	if theme_resource == null or theme_resource.font == null:
		return

	var font: Font = theme_resource.font
	var font_size: int = theme_resource.font_size_small
	var natural_width: int = ceili(font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
	var text_width: int = clampi(natural_width, dialog_min_text_width, dialog_max_text_width)
	var wrapped_size: Vector2 = font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, float(text_width), font_size)

	dialog_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_message_label.custom_minimum_size = Vector2(float(text_width), ceilf(wrapped_size.y))
	dialog_message_label.update_minimum_size()
	dialog_panel_frame.panel_width = _get_dialog_panel_width(text_width)
	dialog_panel_frame.fit_frame_to_content()
	_position_dialog_frame()
	call_deferred("_position_dialog_frame")


func _get_dialog_panel_width(text_width: int) -> int:
	var button_min_width: int = 0
	if dialog_continue_button != null:
		button_min_width = ceili(dialog_continue_button.get_combined_minimum_size().x)
	return max(text_width + DIALOG_PANEL_HORIZONTAL_PADDING, button_min_width + DIALOG_PANEL_HORIZONTAL_PADDING)


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
