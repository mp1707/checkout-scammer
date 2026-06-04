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

	var error_label: Label = _get_content_error_label()
	if error_label != null:
		error_label.visible = false
	var controller: RunController = _get_run_controller()
	if controller != null:
		controller.configure(registry)


func _show_content_errors(errors: PackedStringArray) -> void:
	var error_label: Label = _get_content_error_label()
	if error_label == null:
		for error: String in errors:
			push_error(error)
		return

	error_label.visible = true
	error_label.text = "\n".join(errors)


func _get_run_controller() -> RunController:
	var controller: RunController = run_controller as RunController
	if controller != null:
		return controller

	return get_node_or_null("RunController") as RunController


func _get_content_error_label() -> Label:
	var label: Label = content_error_label as Label
	if label != null:
		return label

	return get_node_or_null("ContentErrorLabel") as Label
