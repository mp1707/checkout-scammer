extends Control
class_name GameApp

@export var run_controller: RunController
@export var content_error_label: Label

var registry: ContentRegistry


func _ready() -> void:
	if run_controller == null:
		push_error("%s is missing required scene reference 'run_controller'." % get_path())
		return
	if content_error_label == null:
		push_error("%s is missing required scene reference 'content_error_label'." % get_path())
		return

	_load_content()


func _load_content() -> void:
	registry = ContentRegistry.new()
	var errors: PackedStringArray = registry.load_all()
	if not errors.is_empty():
		_show_content_errors(errors)
		return

	content_error_label.visible = false
	run_controller.configure(registry)


func _show_content_errors(errors: PackedStringArray) -> void:
	for error: String in errors:
		push_error(error)

	content_error_label.visible = true
	content_error_label.text = "\n".join(errors)
