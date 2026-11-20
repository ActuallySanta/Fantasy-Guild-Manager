#!/bin/bash
# Usage: stop.sh <bridge_dir>
# Asks the bridge to quit, then kills the process if it lingers past 15 s.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE="$1"
# Polls of 0.1 s each before the process is killed (150 = 15 s).
KILL_AFTER_POLLS=150
BRIDGE_TIMEOUT_SECONDS=5 "$HERE/bridge.sh" "$BRIDGE" quit >/dev/null
PID="$(cat "$BRIDGE/pid" 2>/dev/null)"
[ -n "$PID" ] || exit 0
for ((i = 0; i < KILL_AFTER_POLLS; i++)); do
	kill -0 "$PID" 2>/dev/null || exit 0
	sleep 0.1
done
kill -9 "$PID" 2>/dev/null
exit 0
