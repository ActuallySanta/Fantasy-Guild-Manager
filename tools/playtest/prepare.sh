#!/bin/bash
# Usage: prepare.sh <dest_dir>
# Copies the working tree (tracked + untracked, minus ignored) into dest_dir,
# renames the project so its user:// is separate, and imports it headless.
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
DEST="$1"
[ -n "$DEST" ] || { echo "usage: prepare.sh <dest_dir>" >&2; exit 1; }
REPO="$(cd "$HERE/../.." && pwd)"
mkdir -p "$DEST"
cd "$REPO"
git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do
	[ -e "$f" ] || continue
	# Committed exports are ~600 MB and slow to copy; the game doesn't need them.
	case "$f" in Builds/*) continue ;; esac
	mkdir -p "$DEST/$(dirname "$f")"
	cp -p "$f" "$DEST/$f"
done
sed -i -E 's/^config\/name="(.*)"(\r?)$/config\/name="\1 (Playtest)"\2/' "$DEST/project.godot"
grep -q '^config/name=".* (Playtest)"' "$DEST/project.godot" || { echo "prepare: could not rename project in $DEST/project.godot" >&2; exit 1; }
# A first headless import can segfault part-way (an engine bug on some audio/font
# files); the next attempt resumes, so retry a few times.
for attempt in 1 2 3 4; do
	"$GODOT_BIN" --headless --path "$(cygpath -w "$DEST")" --import >"$DEST/import.log" 2>&1 && break
	echo "prepare: godot --import exited non-zero (attempt $attempt); see $DEST/import.log" >&2
done
echo "prepared $DEST"
