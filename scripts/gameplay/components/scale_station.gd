@tool
extends Area2D
class_name ScaleStation

const OneShotAnimatedVfxScript = preload("res://scripts/vfx/one_shot_animated_vfx.gd")

signal actor_dropped(actor: Node2D)
signal actor_removed(actor: Node2D)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres"):
	set(value):
		theme_resource = value
		_apply_weight_label_theme()
@export var scale_sprite: Sprite2D
@export var drop_anchor: Marker2D
@export var weight_label: Label:
	set(value):
		weight_label = value
		_apply_weight_label_theme()
@export var impact_vfx: OneShotAnimatedVfxScript
@export var drop_sound_player: AudioStreamPlayer2D

var _current_actor: Node2D
var _press_tween: Tween
var _feedback_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	_apply_weight_label_theme()
	_set_frame(0)
	if not Engine.is_editor_hint():
		clear_weight()


func try_drop_actor(actor: Node2D) -> bool:
	if not can_accept_actor(actor):
		return false

	_current_actor = actor
	if drop_anchor != null:
		actor.global_position = drop_anchor.global_position.round()
	actor.z_index = 40
	_show_actor_weight(actor)
	_play_press_animation()
	_play_impact_vfx()
	_play_drop_sound()
	actor_dropped.emit(actor)
	return true


func release_actor(actor: Node2D) -> void:
	if actor == null or _current_actor != actor:
		return

	var released_actor: Node2D = _current_actor
	_current_actor = null
	_set_frame(0)
	clear_weight()
	actor_removed.emit(released_actor)


func can_accept_actor(actor: Node2D) -> bool:
	if _current_actor != null:
		return false
	if not _actor_is_weighable_product(actor):
		return false

	var contact_area: Area2D = _get_actor_contact_area(actor)
	return contact_area != null and get_overlapping_areas().has(contact_area)


func has_actor(actor: Node2D) -> bool:
	return actor != null and _current_actor == actor


func get_current_actor() -> Node2D:
	return _current_actor


func get_drop_position() -> Vector2:
	if drop_anchor != null:
		return drop_anchor.global_position
	return global_position


func show_weight_grams(weight_grams: int) -> void:
	if weight_label == null:
		return
	if weight_grams <= 0:
		clear_weight()
		return

	weight_label.visible = true
	weight_label.text = _format_weight_grams(weight_grams)


func clear_weight() -> void:
	if weight_label == null:
		return

	weight_label.text = ""
	weight_label.visible = false


func get_weight_display_text() -> String:
	if weight_label == null:
		return ""
	return weight_label.text


func play_success_feedback() -> void:
	if scale_sprite == null:
		return
	_play_scale_tint(Color(1.0, 0.921568, 0.341176, 1.0), 0.10)


func play_invalid_feedback() -> void:
	if scale_sprite == null:
		return
	_play_scale_tint(Color(1.0, 0.0, 0.25098, 1.0), 0.12)


func _play_press_animation() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()

	_set_frame(0)
	_press_tween = create_tween()
	_press_tween.tween_callback(_set_frame.bind(1))
	_press_tween.tween_interval(0.055)
	_press_tween.tween_callback(_set_frame.bind(2))


func _play_impact_vfx() -> void:
	if impact_vfx != null:
		impact_vfx.play()


func _play_drop_sound() -> void:
	if drop_sound_player == null:
		return

	drop_sound_player.stop()
	drop_sound_player.play()


func _play_scale_tint(color: Color, duration: float) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	scale_sprite.modulate = color
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(scale_sprite, "modulate", Color.WHITE, duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _set_frame(frame_index: int) -> void:
	if scale_sprite != null:
		scale_sprite.frame = frame_index


func _show_actor_weight(actor: Node2D) -> void:
	var product_instance: ProductInstance = actor.get("product_instance") as ProductInstance
	if product_instance == null:
		clear_weight()
		return

	show_weight_grams(product_instance.weight_grams)


func _apply_weight_label_theme() -> void:
	if weight_label == null or theme_resource == null:
		return

	if theme_resource.font != null:
		weight_label.add_theme_font_override("font", theme_resource.font)
	weight_label.add_theme_font_size_override("font_size", theme_resource.font_size_detail)
	weight_label.add_theme_color_override("font_color", theme_resource.register_display_text_color)
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _format_weight_grams(weight_grams: int) -> String:
	if weight_grams >= 1000:
		var whole_kilos: int = floori(float(weight_grams) / 1000.0)
		var decimal_grams: int = floori(float(weight_grams % 1000) / 10.0)
		return "%d.%02dkg" % [whole_kilos, decimal_grams]
	return "%dg" % weight_grams


func _actor_is_weighable_product(actor: Node2D) -> bool:
	if actor == null:
		return false

	var product_instance: ProductInstance = actor.get("product_instance") as ProductInstance
	return product_instance != null and product_instance.is_weighable() and not product_instance.is_processed


func _get_actor_contact_area(actor: Node2D) -> Area2D:
	if actor == null or not actor.has_method("get_contact_area"):
		return null
	return actor.call("get_contact_area") as Area2D


func _resolve_child_references() -> void:
	if scale_sprite == null:
		scale_sprite = get_node_or_null("ScaleSprite") as Sprite2D
	if drop_anchor == null:
		drop_anchor = get_node_or_null("DropAnchor") as Marker2D
	if weight_label == null:
		weight_label = get_node_or_null("WeightLabel") as Label
	if impact_vfx == null:
		impact_vfx = get_node_or_null("ImpactVfx") as OneShotAnimatedVfxScript
	if drop_sound_player == null:
		drop_sound_player = get_node_or_null("DropSoundPlayer") as AudioStreamPlayer2D
