#!/bin/bash
# Rules-mode action test for the agent bridge: plan, end_day, the run-over guard
# and the --test-hooks commands. Run: tools/playtest/tests/test_rules.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$(cd "$HERE/.." && pwd)"
TMP="$(mktemp -d)"
FAILS=0
check() { # name, condition result (0 = pass)
	if [ "$2" -eq 0 ]; then echo "PASS: $1"; else echo "FAIL: $1"; FAILS=$((FAILS + 1)); fi
}
# launch_bridge <name> [extra user args...]: seeded headless rules bridge in $TMP/<name>.
launch_bridge() {
	local name="$1"; shift
	"$TOOLS/launch.sh" "$TMP/pt" "$TMP/$name" --headless -- --bridge-dir="$(cygpath -m "$TMP/$name")" --mode=rules --seed=4417 "$@" >/dev/null
}
# quest_indexes <state json>: the quest indexes on today's Board, space separated.
quest_indexes() { echo "$1" | grep -o '"quests":\[.*\],"roster"' | grep -o '"index":[0-9]*' | cut -d: -f2 | tr '\n' ' '; }
# deny_json <state json> [skip index]: JSON array of every quest index but the skipped one.
deny_json() {
	local out="" i
	for i in $(quest_indexes "$1"); do [ "$i" != "$2" ] && out="$out${out:+,}$i"; done
	echo "[$out]"
}

"$TOOLS/prepare.sh" "$TMP/pt" >/dev/null

# ---- a normal day, no test hooks
launch_bridge a
S="$("$TOOLS/bridge.sh" "$TMP/a" state)"
HERO="$(echo "$S" | grep -o '"roster":\[.*' | grep -o '"id":"[0-9-]*"' | head -1 | grep -o '[0-9-]*')"
[ -n "$HERO" ]; check "starting hero found" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/a" end_day)"; echo "$OUT" | head -c 300; echo
[[ "$OUT" == *'"ok":false'* && "$OUT" == *undecided* ]]; check "end_day with undecided quests errors" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/a" plan "{\"assign\":[{\"quest\":0,\"party\":[\"$HERO\"]}],\"deny\":$(deny_json "$S" 0)}")"; echo "$OUT" | head -c 400; echo
[[ "$OUT" == *'"ok":true'* && "$OUT" != *'"applied":[]'* ]]; check "plan applied steps" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/a" plan '{"hire":["999"]}')"
[[ "$OUT" == *'"rejected":[{'* ]]; check "unknown hire id is rejected, not an error" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/a" end_day)"; echo "$OUT" | head -c 600; echo
[[ "$OUT" == *'"ok":true'* && "$OUT" == *'"run_over":false'* ]]; check "end_day ok" $?
[[ "$OUT" == *'"day":2'* ]]; check "new state is day 2" $?
echo "$OUT" | grep -o '"report":{.*"run_over"' | grep -o '"succeeded"' | wc -l | grep -qx 1; check "report has 1 result" $?
[[ "$OUT" != *'[b]'* && "$OUT" != *'[color'* ]]; check "story BBCode stripped" $?
# not a test-hooks launch: the hooks do not exist
OUT="$("$TOOLS/bridge.sh" "$TMP/a" kill_all)"
[[ "$OUT" == *"unknown command"* ]]; check "kill_all unavailable without --test-hooks" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/a" debug '{"call":"debug_jump_to_day","args":[50]}')"
[[ "$OUT" == *"unknown command"* ]]; check "debug unavailable without --test-hooks" $?
"$TOOLS/stop.sh" "$TMP/a"

# ---- day 50 and the hooks
launch_bridge b --test-hooks
OUT="$("$TOOLS/bridge.sh" "$TMP/b" debug '{"call":"debug_jump_to_day","args":[50]}')"; echo "$OUT" | head -c 200; echo
[[ "$OUT" == *'"ok":true'* ]]; check "debug jump ok" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/b" debug '{"call":"quit","args":[]}')"
[[ "$OUT" == *'"ok":false'* ]]; check "debug refuses non-debug_ names" $?
S="$("$TOOLS/bridge.sh" "$TMP/b" state)"
[[ "$S" == *'"day":50'* && "$S" == *'"kind":"final"'* ]]; check "day 50 has the final quest" $?
# the final battle rolls the credits instead of a Day Report, and ends the run
HERO="$(echo "$S" | grep -o '"roster":\[.*' | grep -o '"id":"[0-9-]*"' | head -1 | grep -o '[0-9-]*')"
FINAL="$(echo "$S" | grep -o '"index":[0-9]*,"kind":"final"' | grep -o '[0-9]*' | head -1)"
"$TOOLS/bridge.sh" "$TMP/b" plan "{\"assign\":[{\"quest\":$FINAL,\"party\":[\"$HERO\"]}],\"deny\":$(deny_json "$S" "$FINAL")}" >/dev/null
OUT="$("$TOOLS/bridge.sh" "$TMP/b" end_day)"; echo "$OUT" | head -c 300; echo
[[ "$OUT" == *'"run_over":true'* && "$OUT" == *'"run_over_reason":"final_'* ]]; check "final battle ends the run" $?
"$TOOLS/stop.sh" "$TMP/b"

# ---- game over
launch_bridge c --test-hooks
# Pip's tutorial locks Deny on day 1, so skip it first
"$TOOLS/bridge.sh" "$TMP/c" debug '{"call":"debug_skip_tutorial","args":[]}' >/dev/null
# the first days recruit for free, so the guild is only stuck from day 3 on
"$TOOLS/bridge.sh" "$TMP/c" debug '{"call":"debug_jump_to_day","args":[3]}' >/dev/null
S="$("$TOOLS/bridge.sh" "$TMP/c" state)"
OUT="$("$TOOLS/bridge.sh" "$TMP/c" kill_all)"
[[ "$OUT" == *'"ok":true'* ]]; check "kill_all ok" $?
"$TOOLS/bridge.sh" "$TMP/c" plan "{\"deny\":$(deny_json "$S")}" >/dev/null
OUT="$("$TOOLS/bridge.sh" "$TMP/c" end_day)"; echo "$OUT" | head -c 300; echo
[[ "$OUT" == *'"run_over":true'* && "$OUT" == *'"run_over_reason":"game_over"'* ]]; check "game over after everyone died" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/c" plan '{}')"
[[ "$OUT" == *'"ok":false'* && "$OUT" == *"run over"* ]]; check "plan after run over errors" $?
OUT="$("$TOOLS/bridge.sh" "$TMP/c" end_day)"
[[ "$OUT" == *"run over"* ]]; check "end_day after run over errors" $?
"$TOOLS/stop.sh" "$TMP/c"

rm -rf "$TMP"
[ "$FAILS" -eq 0 ]
