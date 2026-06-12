extends SceneTree
class_name CheckoutTestBase

## Shared assertion helpers for the headless test suites.
## Run a suite with: godot --headless --script tests/<suite>.gd
## (see tools/run_tests.sh)

var _failure_count: int = 0


func _finish_suite(suite_name: String) -> void:
	if _failure_count > 0:
		push_error("%s failed: %d failure(s)." % [suite_name, _failure_count])
		quit(1)
		return

	print("%s passed." % suite_name)
	quit(0)


func _expect_true(value: bool, label: String) -> void:
	if not value:
		_fail(label, "Expected true.")


func _expect_false(value: bool, label: String) -> void:
	if value:
		_fail(label, "Expected false.")


func _expect_equal_int(expected: int, actual: int, label: String) -> void:
	if expected != actual:
		_fail(label, "Expected %d, got %d." % [expected, actual])


func _expect_equal_string(expected: String, actual: String, label: String) -> void:
	if expected != actual:
		_fail(label, "Expected '%s', got '%s'." % [expected, actual])


func _expect_string_arrays_equal(expected: PackedStringArray, actual: PackedStringArray, label: String) -> void:
	if expected.size() != actual.size():
		_fail(label, "Expected %s, got %s." % [str(expected), str(actual)])
		return

	for index: int in range(expected.size()):
		if expected[index] != actual[index]:
			_fail(label, "Expected %s, got %s." % [str(expected), str(actual)])
			return


func _fail(label: String, message: String) -> void:
	_failure_count += 1
	push_error("%s: %s" % [label, message])


func _format_cents(cents: int) -> String:
	var sign_prefix: String = ""
	var absolute_cents: int = cents
	if cents < 0:
		sign_prefix = "-"
		absolute_cents = -cents

	var dollars: int = floori(float(absolute_cents) / 100.0)
	return "%s$%d.%02d" % [sign_prefix, dollars, absolute_cents % 100]
