#!/bin/bash
# Usage: run_test.sh <name>
# Runs res://tools/tests/<name>_test.tscn headless in a scratch copy of the
# project. Reuses $TEST_SCRATCH if set (incremental: only changed files are
# re-synced), else a fresh mktemp dir. Prints the TEST lines; if there is no
# "TEST PASS" line, also prints the tail of Godot's output. Exits with Godot's
# exit code, or 1 if Godot exited 0 without a TEST PASS line, or 124 on timeout.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../playtest/common.sh"
NAME="$1"
[ -n "$NAME" ] || { echo "usage: run_test.sh <name>" >&2; exit 2; }
## Seconds before a hung test (parse error, missing finish()) is killed.
TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-300}"
SCRATCH="${TEST_SCRATCH:-$(mktemp -d)}"
bash "$HERE/../playtest/prepare.sh" "$SCRATCH" >/dev/null || exit 2
OUT="$(timeout "$TEST_TIMEOUT_SECONDS" "$GODOT_BIN" --headless --path "$(cygpath -m "$SCRATCH")" "res://tools/tests/${NAME}_test.tscn" 2>&1)"
CODE=$?
echo "$OUT" | grep '^TEST'
if ! echo "$OUT" | grep -q '^TEST PASS'; then
	[ "$CODE" = 124 ] && echo "TEST TIMEOUT after ${TEST_TIMEOUT_SECONDS}s"
	echo "$OUT" | grep -E -A1 'SCRIPT ERROR|Parse Error' | head -20
	echo "--- last 30 lines of Godot output ---"
	echo "$OUT" | tail -30
	[ "$CODE" = 0 ] && CODE=1
fi
exit $CODE
