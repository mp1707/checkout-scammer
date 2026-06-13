extends Node2D
class_name ScannerStation

signal product_hand_scan_requested(actor: ProductActor, contact_position: Vector2)
signal coupon_hand_scan_requested(actor: CouponActor, contact_position: Vector2)
signal mouse_mode_changed(is_mouse_mode: bool)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var hit_area: Area2D
@export var scanner_cursor_root: Node2D
@export var scanner_sprite: Sprite2D
@export var docked_scanner_sprite: Sprite2D
@export var station_sprite: Sprite2D
@export var crosshair_root: Node2D
@export var beam: CanvasItem
@export var beep_player: AudioStreamPlayer2D
@export var animation_player: AnimationPlayer

const CROSSHAIR_IDLE_ALPHA: float = 0.46
const CROSSHAIR_SCANNING_ALPHA: float = 0.82

var _is_scanner_mode: bool = false
var _is_scanning: bool = false
var _last_scan_actor_key: String = ""
var _crosshair_tween: Tween


func _ready() -> void:
	_apply_theme()
	_validate_required_references()
	_set_scanner_mode(false)


func flash() -> void:
	if animation_player != null and animation_player.has_animation("flash"):
		animation_player.play("flash")


func play_success_feedback(scan_count: int) -> void:
	_play_beep(scan_count)
	_pulse_crosshair(scan_count)
	flash()


func _unhandled_input(event: InputEvent) -> void:
	var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion_event != null:
		_update_scanner_cursor(mouse_motion_event.position.round())
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
		_set_scanner_mode(not _is_scanner_mode)
		get_viewport().set_input_as_handled()
		return

	if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not _is_scanner_mode:
		return

	_set_scanning(mouse_button_event.pressed)
	_update_scanner_cursor(mouse_button_event.position.round())
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _is_scanner_mode:
		_update_scanner_cursor(get_viewport().get_mouse_position().round())


func _physics_process(_delta: float) -> void:
	if not _is_scanner_mode or not _is_scanning:
		return

	var actor: TableActor = _find_topmost_scan_actor()
	var actor_key: String = _get_actor_scan_key(actor)
	if actor_key == _last_scan_actor_key:
		return

	_last_scan_actor_key = actor_key
	if actor == null:
		return

	var contact_position: Vector2 = hit_area.global_position if hit_area != null else actor.global_position
	var product_actor: ProductActor = actor as ProductActor
	if product_actor != null:
		product_hand_scan_requested.emit(product_actor, contact_position)
		return

	var coupon_actor: CouponActor = actor as CouponActor
	if coupon_actor != null:
		coupon_hand_scan_requested.emit(coupon_actor, contact_position)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


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


func _find_topmost_scan_actor() -> TableActor:
	if hit_area == null:
		return null

	var top_actor: TableActor = null
	for area: Area2D in hit_area.get_overlapping_areas():
		var actor: TableActor = _find_actor_from_area(area)
		if actor == null:
			continue
		if top_actor == null or _actor_is_above(actor, top_actor):
			top_actor = actor

	return top_actor


func _actor_is_above(candidate: TableActor, current: TableActor) -> bool:
	if candidate.z_index != current.z_index:
		return candidate.z_index > current.z_index
	return candidate.get_index() > current.get_index()


func _get_actor_scan_key(actor: TableActor) -> String:
	if actor == null:
		return ""
	if not actor.actor_id.is_empty():
		return actor.actor_id
	return str(actor.get_instance_id())


func _set_scanner_mode(is_enabled: bool) -> void:
	_is_scanner_mode = is_enabled
	if not _is_scanner_mode:
		_set_scanning(false)
		_last_scan_actor_key = ""

	if scanner_cursor_root != null:
		scanner_cursor_root.visible = _is_scanner_mode
	if docked_scanner_sprite != null:
		docked_scanner_sprite.visible = not _is_scanner_mode

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if _is_scanner_mode else Input.MOUSE_MODE_VISIBLE)
	mouse_mode_changed.emit(not _is_scanner_mode)
	_refresh_scanner_visuals()


func _set_scanning(is_enabled: bool) -> void:
	_is_scanning = is_enabled
	_last_scan_actor_key = ""
	_refresh_scanner_visuals()


func _update_scanner_cursor(global_mouse_position: Vector2) -> void:
	if scanner_cursor_root != null:
		scanner_cursor_root.global_position = global_mouse_position


func _refresh_scanner_visuals() -> void:
	if beam != null:
		beam.visible = _is_scanner_mode and _is_scanning
	if crosshair_root != null:
		crosshair_root.visible = _is_scanner_mode
		var target_alpha: float = CROSSHAIR_SCANNING_ALPHA if _is_scanning else CROSSHAIR_IDLE_ALPHA
		crosshair_root.modulate.a = target_alpha


func _play_beep(scan_count: int) -> void:
	if beep_player == null:
		return

	beep_player.pitch_scale = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.42)
	beep_player.stop()
	beep_player.play()


func _pulse_crosshair(scan_count: int) -> void:
	if crosshair_root == null:
		return

	if _crosshair_tween != null and _crosshair_tween.is_valid():
		_crosshair_tween.kill()

	var flash_scale: float = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.24)
	crosshair_root.scale = Vector2.ONE * flash_scale
	_crosshair_tween = create_tween()
	_crosshair_tween.tween_property(crosshair_root, "scale", Vector2.ONE, 0.09) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


func _validate_required_references() -> void:
	if station_sprite == null:
		push_error("%s is missing required scene reference 'station_sprite'." % get_path())
	if docked_scanner_sprite == null:
		push_error("%s is missing required scene reference 'docked_scanner_sprite'." % get_path())
	if scanner_cursor_root == null:
		push_error("%s is missing required scene reference 'scanner_cursor_root'." % get_path())
	if scanner_sprite == null:
		push_error("%s is missing required scene reference 'scanner_sprite'." % get_path())
	if crosshair_root == null:
		push_error("%s is missing required scene reference 'crosshair_root'." % get_path())
	if beam == null:
		push_error("%s is missing required scene reference 'beam'." % get_path())
	if hit_area == null:
		push_error("%s is missing required scene reference 'hit_area'." % get_path())


func _apply_theme() -> void:
	if theme_resource == null:
		return
	if beam != null:
		beam.modulate = theme_resource.scanner_beam_color
	if crosshair_root != null:
		crosshair_root.modulate = theme_resource.scanner_beam_color
