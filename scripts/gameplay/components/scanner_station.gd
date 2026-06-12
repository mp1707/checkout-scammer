extends Node2D
class_name ScannerStation

signal product_contact_started(actor: ProductActor, contact_position: Vector2)
signal product_contact_ended(actor: ProductActor)
signal actor_contact_started(actor: TableActor, contact_position: Vector2)
signal actor_contact_ended(actor: TableActor)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var hit_area: Area2D
@export var beam: CanvasItem
@export var feedback_anchor: Marker2D
@export var flash_rect: CanvasItem
@export var beep_player: AudioStreamPlayer2D
@export var animation_player: AnimationPlayer

var _beam_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	_apply_theme()
	if flash_rect != null:
		flash_rect.visible = false
	if hit_area == null:
		push_error("%s is missing required scene reference 'hit_area'." % get_path())
		return
	if not hit_area.area_entered.is_connected(_on_hit_area_entered):
		hit_area.area_entered.connect(_on_hit_area_entered)
	if not hit_area.area_exited.is_connected(_on_hit_area_exited):
		hit_area.area_exited.connect(_on_hit_area_exited)


func flash() -> void:
	if animation_player != null and animation_player.has_animation("flash"):
		animation_player.play("flash")


func play_success_feedback(scan_count: int) -> void:
	_play_beep(scan_count)
	_play_beam_flash()
	_play_anchor_flash(scan_count)
	flash()


func _on_hit_area_entered(area: Area2D) -> void:
	var actor: TableActor = _find_actor_from_area(area)
	if actor == null:
		return

	var contact_position: Vector2 = area.global_position
	actor_contact_started.emit(actor, contact_position)

	var product_actor: ProductActor = actor as ProductActor
	if product_actor == null:
		return

	product_actor.set_touching_scanner(true, contact_position)
	product_contact_started.emit(product_actor, contact_position)


func _on_hit_area_exited(area: Area2D) -> void:
	var actor: TableActor = _find_actor_from_area(area)
	if actor == null:
		return

	actor_contact_ended.emit(actor)

	var product_actor: ProductActor = actor as ProductActor
	if product_actor == null:
		return

	product_actor.set_touching_scanner(false, Vector2.ZERO)
	product_contact_ended.emit(product_actor)


func _find_actor_from_area(area: Area2D) -> TableActor:
	if area == null:
		return null

	var node: Node = area
	while node != null:
		var actor: TableActor = node as TableActor
		if actor != null:
			return actor
		node = node.get_parent()

	return null


func _play_beep(scan_count: int) -> void:
	if beep_player == null:
		return

	beep_player.pitch_scale = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.42)
	beep_player.stop()
	beep_player.play()


func _play_beam_flash() -> void:
	if beam == null:
		return

	if _beam_tween != null and _beam_tween.is_valid():
		_beam_tween.kill()

	beam.visible = true
	beam.modulate = Color.WHITE
	_beam_tween = create_tween()
	_beam_tween.tween_property(beam, "modulate", _get_scanner_beam_color(), 0.12) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _play_anchor_flash(scan_count: int) -> void:
	if flash_rect == null:
		return

	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	var flash_scale: float = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.30)
	flash_rect.visible = true
	flash_rect.scale = Vector2.ONE * flash_scale
	flash_rect.modulate = _get_scanner_flash_color()

	_flash_tween = create_tween()
	_flash_tween.set_parallel(true)
	_flash_tween.tween_property(flash_rect, "scale", Vector2.ONE * (flash_scale + 0.20), 0.10) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.10)
	_flash_tween.set_parallel(false)
	_flash_tween.tween_callback(_hide_flash_rect)


func _hide_flash_rect() -> void:
	if flash_rect != null:
		flash_rect.visible = false


func _apply_theme() -> void:
	if theme_resource == null:
		return
	if beam != null:
		beam.modulate = theme_resource.scanner_beam_color
	if flash_rect != null:
		flash_rect.modulate = theme_resource.scanner_flash_color


func _get_scanner_beam_color() -> Color:
	if theme_resource != null:
		return theme_resource.scanner_beam_color
	return Color(1.0, 0.0, 0.25098, 0.86)


func _get_scanner_flash_color() -> Color:
	if theme_resource != null:
		return theme_resource.scanner_flash_color
	return Color(1.0, 0.921568, 0.341176, 0.72)
