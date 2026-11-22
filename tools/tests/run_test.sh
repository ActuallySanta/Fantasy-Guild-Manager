#!/bin/bash
# Usage: run_test.sh <name>
# Runs res://tools/tests/<name>_test.tscn headless in a scratch copy of the
# project. Reuses $TEST_SCRATCH if set (incremental: only changed files are
# re-synced), else a fresh mktemp dir. Prints the TEST lines; if there is no
# "TEST PASS" line, also prints the tail of Godot's output.
#
# Godot stops itself: --quit-after gives it a frame budget, so a test that never
# calls finish() exits on its own (reported as a failure). A script error
# (SCRIPT ERROR / Parse Error) before any TEST line ends the run within about a
# second: this script stops that Godot by its own PID. The same PID kill is the
# last-resort timeout. Exits with Godot's exit code, or 1 if Godot exited 0
# without a TEST PASS line, or 124 on the last-resort timeout.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../playtest/common.sh"
NAME="$1"
[ -n "$NAME" ] || { echo "usage: run_test.sh <name>" >&2; exit 2; }
## Seconds of headless frames a test may run before Godot quits itself.
TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-300}"
## Headless frames Godot ran per second on the dev machine (measured: 3000
## frames in about 23 s including startup). Slightly low on purpose.
HEADLESS_FRAMES_PER_SECOND=130
## Frame budget passed to Godot's --quit-after.
QUIT_AFTER_FRAMES=$((TEST_TIMEOUT_SECONDS * HEADLESS_FRAMES_PER_SECOND))
## Extra seconds past the frame budget before the last-resort PID kill.
KILL_GRACE_SECONDS=60
SCRATCH="${TEST_SCRATCH:-$(mktemp -d)}"
bash "$HERE/../playtest/prepare.sh" "$SCRATCH" >/dev/null || exit 2
OUTFILE="$(mktemp)"
trap 'rm -f "$OUTFILE"' EXIT

"$GODOT_BIN" --headless --quit-after "$QUIT_AFTER_FRAMES" \
	--path "$(cygpath -m "$SCRATCH")" "res://tools/tests/${NAME}_test.tscn" >"$OUTFILE" 2>&1 &
GODOT_PID=$!

## Stops our Godot by PID (Windows PID via /proc/<pid>/winpid, else the MSYS PID).
kill_godot() {
	local winpid
	winpid="$(cat "/proc/$GODOT_PID/winpid" 2>/dev/null)"
	if [ -n "$winpid" ]; then
		taskkill //PID "$winpid" //F >/dev/null 2>&1
	fi
	kill "$GODOT_PID" 2>/dev/null
}

DEADLINE=$((SECONDS + TEST_TIMEOUT_SECONDS + KILL_GRACE_SECONDS))
REASON=""
while kill -0 "$GODOT_PID" 2>/dev/null; do
	if ! grep -q '^TEST' "$OUTFILE" && grep -qE 'SCRIPT ERROR|Parse Error' "$OUTFILE"; then
		REASON="script error before any TEST line"
		sleep 1 # let Godot finish printing the error context
		kill_godot
		break
	fi
	if [ "$SECONDS" -ge "$DEADLINE" ]; then
		REASON="timeout"
		kill_godot
		break
	fi
	sleep 0.3
done
wait "$GODOT_PID" 2>/dev/null
CODE=$?
[ -n "$REASON" ] && CODE=1
[ "$REASON" = "timeout" ] && CODE=124
OUT="$(cat "$OUTFILE")"

echo "$OUT" | grep '^TEST'
if ! echo "$OUT" | grep -q '^TEST PASS'; then
	[ "$CODE" = 124 ] && echo "TEST TIMEOUT after ${TEST_TIMEOUT_SECONDS}s"
	if [ -n "$REASON" ] && [ "$REASON" != "timeout" ]; then
		echo "TEST ABORTED: $REASON"
	elif ! echo "$OUT" | grep -q '^TEST'; then
		echo "TEST FAILED: never called finish() (no TEST line before Godot exited)"
	fi
	echo "$OUT" | grep -E -A1 'SCRIPT ERROR|Parse Error' | head -20
	echo "--- last 30 lines of Godot output ---"
	echo "$OUT" | tail -30
	[ "$CODE" = 0 ] && CODE=1
fi
exit $CODE
