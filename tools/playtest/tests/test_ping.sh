#!/bin/bash
# Ping/transport test for the agent bridge. Run: tools/playtest/tests/test_ping.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$(cd "$HERE/.." && pwd)"
TMP="$(mktemp -d)"
FAILS=0
check() { # name, condition result (0 = pass)
	if [ "$2" -eq 0 ]; then echo "PASS: $1"; else echo "FAIL: $1"; FAILS=$((FAILS + 1)); fi
}
"$TOOLS/prepare.sh" "$TMP/pt" >/dev/null
grep -q '(Playtest)' "$TMP/pt/project.godot"; check "scratch project renamed (Playtest)" $?
"$TOOLS/launch.sh" "$TMP/pt" "$TMP/b1" --headless -- --bridge-dir="$(cygpath -m "$TMP/b1")" --mode=rules --seed=1
check "launch reached ready" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/b1" ping)"; echo "$OUT"
[[ "$OUT" == *'"ok":true'* && "$OUT" == *'"day":1'* ]]; check "ping ok, day 1" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/b1" nonsense)"; echo "$OUT"
[[ "$OUT" == *"unknown command"* ]]; check "unknown command" $?
PID="$(cat "$TMP/b1/pid")"
"$TOOLS/stop.sh" "$TMP/b1"
kill -0 "$PID" 2>/dev/null; [ $? -ne 0 ]; check "pid gone after stop" $?
BRIDGE_TIMEOUT_SECONDS=5 "$TOOLS/bridge.sh" "$TMP/b1" ping >/dev/null; [ $? -eq 2 ]; check "stopped bridge times out with 2" $?
rm -rf "$TMP"
[ "$FAILS" -eq 0 ]
