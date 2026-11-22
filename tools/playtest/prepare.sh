#!/bin/bash
# Usage: prepare.sh <dest_dir>
# Copies the working tree (tracked + untracked, minus ignored and Builds/) into
# dest_dir, renames the project so its user:// is separate, and imports it headless.
# Incremental: if dest_dir was prepared before (it holds a .prepared marker), only
# files modified since then are copied, and the import runs only when something changed.
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
DEST="$1"
[ -n "$DEST" ] || { echo "usage: prepare.sh <dest_dir>" >&2; exit 1; }
REPO="$(cd "$HERE/../.." && pwd)"
MARKER="$DEST/.prepared"
mkdir -p "$DEST"
cd "$REPO"
CHANGED_LIST="$(mktemp)"
# Committed exports are ~600 MB and slow to copy; the game doesn't need them.
git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do
	[ -e "$f" ] || continue
	case "$f" in Builds/*) continue ;; esac
	if [ ! -e "$MARKER" ] || [ "$f" -nt "$MARKER" ] || [ ! -e "$DEST/$f" ]; then
		printf '%s\0' "$f"
	fi
done > "$CHANGED_LIST"
if [ ! -s "$CHANGED_LIST" ]; then
	rm -f "$CHANGED_LIST"
	echo "prepared $DEST (up to date)"
	exit 0
fi
# One tar stream is far faster than a cp per file on Windows.
tar --null -T "$CHANGED_LIST" -cf - | tar -xf - -C "$DEST"
if grep -qz '^project.godot$' "$CHANGED_LIST"; then
	sed -i -E 's/^config\/name="(.*)"(\r?)$/config\/name="\1 (Playtest)"\2/' "$DEST/project.godot"
fi
rm -f "$CHANGED_LIST"
grep -q '^config/name=".* (Playtest)"' "$DEST/project.godot" || { echo "prepare: could not rename project in $DEST/project.godot" >&2; exit 1; }
# A first headless import can segfault part-way (an engine bug on some audio/font
# files); the next attempt resumes, so retry a few times.
IMPORTED=0
for attempt in 1 2 3 4; do
	if "$GODOT_BIN" --headless --path "$(cygpath -m "$DEST")" --import >"$DEST/import.log" 2>&1; then IMPORTED=1; break; fi
	echo "prepare: godot --import exited non-zero (attempt $attempt); see $DEST/import.log" >&2
done
# Only mark as prepared when the import succeeded, so a failed one is redone next time.
[ "$IMPORTED" = 1 ] && touch "$MARKER"
echo "prepared $DEST"
