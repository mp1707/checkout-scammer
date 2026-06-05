extends Node2D
class_name ScannerStation

signal product_contact_started(actor: Node2D, contact_position: Vector2)
signal product_contact_ended(actor: Node2D)
signal actor_contact_started(actor: Node2D, contact_position: Vector2)
signal actor_contact_ended(actor: Node2D)

@export var hit_area: Area2D
@export var beam: CanvasItem
@export var feedback_anchor: Marker2D
@export var flash_rect: CanvasItem
@export var beep_player: AudioStreamPlayer2D
@export var animation_player: AnimationPlayer

var _beam_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	_resolve_child_references()
	if flash_rect != null:
		flash_rect.visible = false
	if hit_area == null:
		return
	if not hit_area.area_entered.is_connected(_on_hit_area_entered):
		hit_area.area_entered.connect(_on_hit_area_entered)
	if not hit_area.area_exited.is_connected(_on_hit_area_exited):
		hit_area.area_exited.connect(_on_hit_area_exited)


func set_beam_visible(is_visible: bool) -> void:
	if beam != null:
		beam.visible = is_visible


func flash() -> void:
	if animation_player != null and animation_player.has_animation("flash"):
		animation_player.play("flash")


func play_success_feedback(scan_count: int) -> void:
	_play_beep(scan_count)
	_play_beam_flash()
	_play_anchor_flash(scan_count)
	flash()


func _on_hit_area_entered(area: Area2D) -> void:
	var actor: Node2D = _find_actor_from_area(area)
	if actor == null:
		return

	var contact_position: Vector2 = area.global_position
	actor_contact_started.emit(actor, contact_position)

	if not actor.has_method("set_touching_scanner"):
		return

	actor.call("set_touching_scanner", true, contact_position)
	product_contact_started.emit(actor, contact_position)


func _on_hit_area_exited(area: Area2D) -> void:
	var actor: Node2D = _find_actor_from_area(area)
	if actor == null:
		return

	actor_contact_ended.emit(actor)

	if not actor.has_method("set_touching_scanner"):
		return

	actor.call("set_touching_scanner", false, Vector2.ZERO)
	product_contact_ended.emit(actor)


func _find_actor_from_area(area: Area2D) -> Node2D:
	if area == null:
		return null

	var node: Node = area
	while node != null:
		var actor: Node2D = node as Node2D
		if actor != null and actor.has_method("get_contact_area"):
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
	beam.modulate = Color(1.45, 1.45, 1.45, 1.0)
	_beam_tween = create_tween()
	_beam_tween.tween_property(beam, "modulate", Color.WHITE, 0.12) \
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
	flash_rect.modulate = Color(1.0, 0.92, 0.52, 0.72)

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


func _resolve_child_references() -> void:
	if hit_area == null:
		hit_area = get_node_or_null("HitArea") as Area2D
	if beam == null:
		beam = get_node_or_null("Beam") as CanvasItem
	if feedback_anchor == null:
		feedback_anchor = get_node_or_null("FeedbackAnchor") as Marker2D
	if flash_rect == null:
		flash_rect = get_node_or_null("FeedbackAnchor/ScannerFlash") as CanvasItem
	if beep_player == null:
		beep_player = get_node_or_null("BeepPlayer") as AudioStreamPlayer2D
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
