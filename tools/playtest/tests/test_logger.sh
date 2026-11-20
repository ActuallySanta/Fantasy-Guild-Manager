#!/bin/bash
# AI run-log target test: the AI CSV, the human CSV left alone, distinct run ids
# and the redeploy check against the live URL (GET only, nothing is posted).
# Run: tools/playtest/tests/test_logger.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$(cd "$HERE/.." && pwd)"
TMP="$(mktemp -d)"
# however the test ends, stop every bridge it started (no leaked Godot) and remove the scratch copy
cleanup() {
	for pidfile in "$TMP"/*/pid; do
		[ -f "$pidfile" ] && "$TOOLS/stop.sh" "$(dirname "$pidfile")" >/dev/null 2>&1
	done
	rm -rf "$TMP"
}
trap cleanup EXIT
FAILS=0
check() { # name, condition result (0 = pass)
	if [ "$2" -eq 0 ]; then echo "PASS: $1"; else echo "FAIL: $1"; FAILS=$((FAILS + 1)); fi
}
launch_bridge() { # name [extra user args...]
	local name="$1"; shift
	"$TOOLS/launch.sh" "$TMP/pt" "$TMP/$name" --headless -- --bridge-dir="$(cygpath -m "$TMP/$name")" --mode=rules --seed=4417 --persona=typical --label=t "$@" >/dev/null
}
# json_field <json> <key>: a top-level string or number value.
json_field() { echo "$1" | grep -o "\"$2\":\"\?[^,\"}]*" | head -1 | sed -E "s/\"$2\":\"?//"; }
quest_indexes() { echo "$1" | grep -o '"quests":\[.*],"resp_id"' | grep -o '"index":[0-9]*' | cut -d: -f2 | tr '\n' ' '; }
deny_json() {
	local out="" i
	for i in $(quest_indexes "$1"); do out="$out${out:+,}$i"; done
	echo "[$out]"
}

"$TOOLS/prepare.sh" "$TMP/pt" >/dev/null

# ---- --no-sheet: AI CSV written, human CSV untouched
launch_bridge a --no-sheet --run=1 --test-hooks
S="$("$TOOLS/bridge.sh" "$TMP/a" status)"; echo "$S"
USER_DIR="$(json_field "$S" user_dir)"
HUMAN="$USER_DIR/run_log.csv"
BEFORE="$(stat -c %Y "$HUMAN" 2>/dev/null || echo none)"
[ "$(json_field "$S" sheet)" = "off" ]; check "sheet is off with --no-sheet" $?
"$TOOLS/bridge.sh" "$TMP/a" debug '{"call":"debug_skip_tutorial","args":[]}' >/dev/null
S="$("$TOOLS/bridge.sh" "$TMP/a" state)"
"$TOOLS/bridge.sh" "$TMP/a" plan "{\"deny\":$(deny_json "$S")}" >/dev/null
OUT="$("$TOOLS/bridge.sh" "$TMP/a" end_day)"
[[ "$OUT" == *'"ok":true'* ]]; check "end_day ok" $?
AI="$USER_DIR/run_log_ai.csv"
[ -f "$AI" ]; check "run_log_ai.csv exists" $?
head -1 "$AI" | tr -d '\r' | grep -q ',persona,seed,run_number,mode$'; check "AI header ends with the extra columns" $?
sed -n 2p "$AI" | grep -q 'typical'; check "AI row contains the persona" $?
S="$("$TOOLS/bridge.sh" "$TMP/a" status)"
[ "$(json_field "$S" pending_rows)" = "0" ]; check "no rows pending when sheet is off" $?
AFTER="$(stat -c %Y "$HUMAN" 2>/dev/null || echo none)"
[ "$BEFORE" = "$AFTER" ]; check "human run_log.csv untouched ($BEFORE)" $?
RUN_A="$(json_field "$S" run_id)"
"$TOOLS/stop.sh" "$TMP/a"

# ---- same seed, parallel: different run ids
launch_bridge b --no-sheet --run=2
launch_bridge c --no-sheet --run=3
RUN_B="$(json_field "$("$TOOLS/bridge.sh" "$TMP/b" status)" run_id)"
RUN_C="$(json_field "$("$TOOLS/bridge.sh" "$TMP/c" status)" run_id)"
echo "$RUN_A $RUN_B $RUN_C"
[[ "$RUN_B" == ai-t-typical-2-* && "$RUN_B" != "$RUN_C" && "$RUN_A" != "$RUN_B" ]]; check "run ids differ and follow ai-<label>-<persona>-<run>-<time>" $?
"$TOOLS/stop.sh" "$TMP/b"; "$TOOLS/stop.sh" "$TMP/c"

# ---- live URL still on the old script: posting must stay off (GET only)
launch_bridge d --run=4
SHEET=""
for ((i = 0; i < 150; i++)); do
	SHEET="$(json_field "$("$TOOLS/bridge.sh" "$TMP/d" status)" sheet)"
	[ "$SHEET" != "checking" ] && break
	sleep 0.1
done
echo "sheet status: $SHEET"
[ "$SHEET" = "not_redeployed" ]; check "old script answers not_redeployed" $?
"$TOOLS/stop.sh" "$TMP/d"

[ "$FAILS" -eq 0 ]
