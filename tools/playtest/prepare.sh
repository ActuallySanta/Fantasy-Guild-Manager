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
	mkdir -p "$DEST/$(dirname "$f")"
	cp -p "$f" "$DEST/$f"
done
sed -i 's|^config/name="\(.*\)"$|config/name="\1 (Playtest)"|' "$DEST/project.godot"
"$GODOT_BIN" --headless --path "$(cygpath -w "$DEST")" --import >/dev/null 2>&1 || true
echo "prepared $DEST"
