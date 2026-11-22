class_name TestCase
extends Node
## Base class for headless tests (tools/tests/<name>_test.gd + matching .tscn).
## A test's _ready() runs checks, then calls finish(). Run with
## `bash tools/tests/run_test.sh <name>`.

## Number of failed checks so far.
var failures: int = 0


## Records a failure (and prints "TEST FAIL <message>") when condition is false.
## @param condition: what must be true.
## @param message: describes the check.
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("TEST FAIL %s" % message)


## Fails unless actual is within tolerance of expected.
## @param actual: measured value.
## @param expected: wanted value.
## @param tolerance: allowed absolute difference.
## @param message: describes the check.
func check_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	check(
		absf(actual - expected) <= tolerance,
		"%s (actual %s, expected %s +/- %s)" % [message, actual, expected, tolerance]
	)


## Prints the verdict and quits with exit code 0 (all passed) or 1 (any failed).
func finish() -> void:
	if failures == 0:
		print("TEST PASS %s" % name)
	else:
		print("TEST FAILED %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
