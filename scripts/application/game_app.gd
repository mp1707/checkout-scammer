extends Control
class_name GameApp

@export var run_controller: Node
@export var content_error_label: Label

var registry: ContentRegistry


func _ready() -> void:
	_load_content()


func _load_content() -> void:
	registry = ContentRegistry.new()
	var errors: PackedStringArray = registry.load_all()
	if not errors.is_empty():
		_show_content_errors(errors)
		return

	if content_error_label != null:
		content_error_label.visible = false
	if run_controller != null and run_controller.has_method("configure"):
		run_controller.call("configure", registry)


func _show_content_errors(errors: PackedStringArray) -> void:
	if content_error_label == null:
		for error: String in errors:
			push_error(error)
		return

	content_error_label.visible = true
	content_error_label.text = "\n".join(errors)
