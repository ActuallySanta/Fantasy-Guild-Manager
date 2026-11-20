#!/bin/bash
# Seeding test for the agent bridge: same --seed => same first state, different seed => different.
# Run: tools/playtest/tests/test_seed.sh
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
# Strips instance ids (they differ per process) so two runs can be compared.
strip_ids() {
	sed -E 's/"(id|worn_by)":"[^"]*",?//g; s/"gear":\[[^]]*\]/"gear":[]/g; s/"party":\[[^]]*\]/"party":[]/g'
}
# state_of <name> <seed>: launches a bridge, saves its state to $TMP/<name>.json, stops it.
state_of() {
	"$TOOLS/launch.sh" "$TMP/pt" "$TMP/$1" --headless -- --bridge-dir="$(cygpath -m "$TMP/$1")" --mode=rules --seed="$2" >/dev/null
	"$TOOLS/bridge.sh" "$TMP/$1" state > "$TMP/$1.json"
	"$TOOLS/stop.sh" "$TMP/$1"
}
"$TOOLS/prepare.sh" "$TMP/pt" >/dev/null
state_of a 4417
state_of b 4417
state_of c 99
head -c 600 "$TMP/a.json"; echo
grep -q '"ok":true' "$TMP/a.json"; check "state ok" $?
grep -q '"hires":\[{' "$TMP/a.json"; check "day 1 has a hire" $?
grep -q '"id":"-\?[0-9]\+"' "$TMP/a.json"; check "ids are JSON strings" $?
grep -q '"quests":\[{' "$TMP/a.json"; check "day 1 has quests" $?
# every worn_by must be a JSON string; this pattern catches an int (checked against a sample too)
INT_WORN_BY='"worn_by":[^"]'
echo '{"items":[{"worn_by":0}]}' | grep -q "$INT_WORN_BY"; check "int worn_by pattern matches a bad sample" $?
! grep -q "$INT_WORN_BY" "$TMP/a.json"; check "no non-string worn_by in state" $?
grep -q '"shop":\[{' "$TMP/a.json"; check "shop stocked" $?
A="$(strip_ids < "$TMP/a.json")"; B="$(strip_ids < "$TMP/b.json")"; C="$(strip_ids < "$TMP/c.json")"
[ "$A" == "$B" ]; check "same seed gives identical state" $?
[ "$A" != "$C" ]; check "different seed gives different state" $?
[ "$FAILS" -eq 0 ]
