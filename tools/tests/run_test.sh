#!/bin/bash
# Usage: run_test.sh <name>
# Runs res://tools/tests/<name>_test.tscn headless in a scratch copy of the
# project. Reuses $TEST_SCRATCH if set (else a fresh mktemp dir). Prints only
# the TEST lines and exits with Godot's exit code.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../playtest/common.sh"
NAME="$1"
[ -n "$NAME" ] || { echo "usage: run_test.sh <name>" >&2; exit 2; }
SCRATCH="${TEST_SCRATCH:-$(mktemp -d)}"
bash "$HERE/../playtest/prepare.sh" "$SCRATCH" >/dev/null || exit 2
OUT="$("$GODOT_BIN" --headless --path "$(cygpath -m "$SCRATCH")" "res://tools/tests/${NAME}_test.tscn" 2>&1)"
CODE=$?
echo "$OUT" | grep '^TEST' || true
exit $CODE
