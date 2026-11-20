#!/bin/bash
# Eyes-mode test: windowed (not headless), so a window opens while it runs.
# Run: tools/playtest/tests/test_eyes.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$(cd "$HERE/.." && pwd)"
TMP="$(mktemp -d)"
FAILS=0
check() { # name, condition result (0 = pass)
	if [ "$2" -eq 0 ]; then echo "PASS: $1"; else echo "FAIL: $1"; FAILS=$((FAILS + 1)); fi
}
"$TOOLS/prepare.sh" "$TMP/pt" >/dev/null
B1="$TMP/b1"
"$TOOLS/launch.sh" "$TMP/pt" "$B1" -- --bridge-dir="$(cygpath -m "$B1")" --mode=eyes --seed=4417 --intro --test-hooks
check "eyes launch reached ready" $?
OUT="$("$TOOLS/bridge.sh" "$B1" ping)"; echo "$OUT"
[[ "$OUT" == *'"intro_open":true'* ]]; check "ping reports intro_open true" $?
OUT="$("$TOOLS/bridge.sh" "$B1" screenshot)"; echo "$OUT"
[[ "$OUT" == *'"width":720'* && "$OUT" == *'"height":1280'* ]]; check "screenshot is 720x1280" $?
SHOT="$(echo "$OUT" | sed -E 's/.*"path":"([^"]*)".*/\1/')"
[ -s "$SHOT" ]; check "screenshot PNG exists" $?
OUT="$("$TOOLS/bridge.sh" "$B1" state)"; echo "$OUT"
[[ "$OUT" == *"not allowed in eyes mode"* ]]; check "state refused in eyes mode" $?
OUT="$("$TOOLS/bridge.sh" "$B1" end_day)"
[[ "$OUT" == *"not allowed in eyes mode"* ]]; check "end_day refused in eyes mode" $?
# the Begin button shows once the crawl has scrolled to its end (a few minutes at most)
RECT=""
for i in $(seq 1 30); do
	RECT="$("$TOOLS/bridge.sh" "$B1" debug_rect '{"node":"BeginButton"}')"
	[[ "$RECT" == *'"visible":true'* ]] && break
	"$TOOLS/bridge.sh" "$B1" wait '{"seconds":10}' >/dev/null
done
echo "$RECT"
[[ "$RECT" == *'"visible":true'* ]]; check "Begin button visible" $?
CX="$(echo "$RECT" | sed -E 's/.*"cx":([0-9.]+).*/\1/')"
CY="$(echo "$RECT" | sed -E 's/.*"cy":([0-9.]+).*/\1/')"
OUT="$("$TOOLS/bridge.sh" "$B1" tap "{\"x\":$CX,\"y\":$CY}")"; echo "$OUT"
[[ "$OUT" == *'"path"'* ]]; check "tap returns a screenshot" $?
OUT="$("$TOOLS/bridge.sh" "$B1" ping)"; echo "$OUT"
[[ "$OUT" == *'"intro_open":false'* ]]; check "tap on Begin closed the intro" $?
OUT="$("$TOOLS/bridge.sh" "$B1" wait '{"seconds":0.5}')"
[[ "$OUT" == *'"path"'* ]]; check "wait returns a screenshot" $?
"$TOOLS/stop.sh" "$B1"
# a second launch with accessibility flags
B2="$TMP/b2"
"$TOOLS/launch.sh" "$TMP/pt" "$B2" -- --bridge-dir="$(cygpath -m "$B2")" --mode=eyes --seed=1 --text-size=2 --color-filter=1 --reduce-motion
check "second launch reached ready" $?
OUT="$("$TOOLS/bridge.sh" "$B2" ping)"; echo "$OUT"
[[ "$OUT" == *'"text_size":2'* ]]; check "ping reports text_size 2" $?
"$TOOLS/stop.sh" "$B2"
# a third launch with no flags must not inherit the second one's saved settings
B3="$TMP/b3"
"$TOOLS/launch.sh" "$TMP/pt" "$B3" -- --bridge-dir="$(cygpath -m "$B3")" --mode=eyes --seed=1
OUT="$("$TOOLS/bridge.sh" "$B3" ping)"; echo "$OUT"
[[ "$OUT" == *'"text_size":1'* ]]; check "no flag resets text_size to default" $?
B2="$B3"
[[ "$OUT" == *'"intro_open":false'* ]]; check "no --intro means no intro in eyes mode" $?
"$TOOLS/stop.sh" "$B2"
rm -rf "$TMP"
[ "$FAILS" -eq 0 ]
