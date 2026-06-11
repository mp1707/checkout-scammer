@tool
extends "res://scripts/ui/panels/pixel_panel_frame.gd"
class_name StickerPopup

signal popup_closed()
signal sticker_drag_released(sticker_id: String, global_drop_position: Vector2)

@export var title_label: Label
@export var tokens_container: HBoxContainer
@export var empty_label: Label
@export var close_button: Button
@export var sticker_token_scene: PackedScene


func _ready() -> void:
	super()
	_resolve_popup_references()
	_apply_label_theme(self)
	if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)


func configure_inventory(entries: Array[StickerInventoryEntry]) -> void:
	_clear_tokens()
	var token_count: int = 0
	for entry: StickerInventoryEntry in entries:
		if entry == null or entry.sticker == null:
			continue
		for _index: int in range(entry.count):
			_add_sticker_token(entry.sticker)
			token_count += 1

	if empty_label != null:
		empty_label.visible = token_count == 0
	queue_fit_to_content()


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		popup_closed.emit()
		get_viewport().set_input_as_handled()


func _add_sticker_token(sticker: StickerResource) -> void:
	if tokens_container == null or sticker_token_scene == null:
		return

	var token_node: Node = sticker_token_scene.instantiate()
	var token: StickerToken = token_node as StickerToken
	if token == null:
		token_node.queue_free()
		return

	token.configure(sticker)
	if not token.sticker_drag_released.is_connected(_on_sticker_drag_released):
		token.sticker_drag_released.connect(_on_sticker_drag_released)
	tokens_container.add_child(token)


func _clear_tokens() -> void:
	if tokens_container == null:
		return
	for child: Node in tokens_container.get_children():
		child.queue_free()


func _on_sticker_drag_released(sticker_id: String, global_drop_position: Vector2) -> void:
	sticker_drag_released.emit(sticker_id, global_drop_position)


func _on_close_button_pressed() -> void:
	popup_closed.emit()


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


func _resolve_popup_references() -> void:
	if title_label == null:
		title_label = get_node_or_null("MainPanel/VBox/TitleLabel") as Label
	if tokens_container == null:
		tokens_container = get_node_or_null("MainPanel/VBox/Tokens") as HBoxContainer
	if empty_label == null:
		empty_label = get_node_or_null("MainPanel/VBox/EmptyLabel") as Label
	if close_button == null:
		close_button = get_node_or_null("MainPanel/VBox/CloseButton") as Button
