#!/bin/bash
# Usage: bridge.sh <bridge_dir> <command> [json_args]
# Sends one command to the bridge and prints its JSON response.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
BRIDGE="$1"; CMD="$2"; ARGS="${3:-{\}}"
ID=$(( $(cat "$BRIDGE/next_id" 2>/dev/null || echo 0) + 1 ))
echo "$ID" > "$BRIDGE/next_id"
printf '{"id": %s, "command": "%s", "args": %s}' "$ID" "$CMD" "$ARGS" > "$BRIDGE/cmd.tmp"
mv -f "$BRIDGE/cmd.tmp" "$BRIDGE/cmd.json"
DEADLINE=$(( $(date +%s) + BRIDGE_TIMEOUT_SECONDS ))
while [ "$(date +%s)" -le "$DEADLINE" ]; do
	if [ -f "$BRIDGE/resp.json" ]; then
		RESP="$(cat "$BRIDGE/resp.json" 2>/dev/null)"
		# the id key may sit anywhere in the object (Godot keeps insertion order)
		if [[ "$RESP" =~ \"id\":$ID[,\}] ]]; then echo "$RESP"; exit 0; fi
	fi
	sleep 0.05
done
echo '{"ok":false,"error":"bridge timeout"}'
exit 2
