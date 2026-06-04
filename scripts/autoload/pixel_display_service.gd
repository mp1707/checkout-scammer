extends Node

const INTERNAL_SIZE: Vector2i = Vector2i(640, 360)
const DEFAULT_WINDOW_SIZE: Vector2i = Vector2i(1280, 720)

func _ready() -> void:
	_apply_pixel_display_settings()


func _apply_pixel_display_settings() -> void:
	var root_window: Window = get_window()
	if root_window == null:
		push_error("PixelDisplayService could not find the root window.")
		return

	root_window.content_scale_size = INTERNAL_SIZE
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	root_window.content_scale_factor = 1.0

	if Engine.is_editor_hint():
		return

	root_window.mode = Window.MODE_WINDOWED
	root_window.size = DEFAULT_WINDOW_SIZE
	root_window.min_size = DEFAULT_WINDOW_SIZE
	root_window.max_size = DEFAULT_WINDOW_SIZE
	root_window.unresizable = true
	root_window.move_to_center()
