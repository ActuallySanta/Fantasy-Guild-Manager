#!/bin/bash
# Usage: launch.sh <project_dir> <bridge_dir> [--headless] -- <user args>
# Starts the game on the agent bridge scene and waits for ready.json.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
PROJECT="$1"; BRIDGE="$2"; shift 2
HEADLESS=()
if [ "$1" = "--headless" ]; then HEADLESS=(--headless); shift; fi
[ "$1" = "--" ] && shift
mkdir -p "$BRIDGE"
rm -f "$BRIDGE/ready.json" "$BRIDGE/resp.json" "$BRIDGE/cmd.json" "$BRIDGE/next_id"
"$GODOT_BIN" "${HEADLESS[@]}" --path "$(cygpath -w "$PROJECT")" res://Scenes/Playtest/agent_bridge.tscn -- "$@" >"$BRIDGE/godot.log" 2>&1 &
PID=$!
echo "$PID" > "$BRIDGE/pid"
for ((i = 0; i < ${LAUNCH_TIMEOUT_SECONDS:-60} * 10; i++)); do
	[ -f "$BRIDGE/ready.json" ] && exit 0
	if ! kill -0 "$PID" 2>/dev/null; then
		echo "godot exited before ready (see $BRIDGE/godot.log)" >&2
		exit 2
	fi
	sleep 0.1
done
kill -9 "$PID" 2>/dev/null
echo "launch timeout (see $BRIDGE/godot.log)" >&2
exit 2
