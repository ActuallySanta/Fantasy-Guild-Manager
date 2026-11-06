## Which build of the game is running, for the Menu's small footer line.
##
## The web deploy workflow (.github/workflows/deploy-web.yml, "Stamp the
## build") writes BUILD_INFO_PATH with the commit and time it was built from,
## e.g. "ab12cd3 · 2026-11-04 20:55 UTC". The file is gitignored, so editor
## runs and local exports have none and show "Build dev" instead. It lets a
## phone show whether it's on the latest deploy or an old cached copy.
class_name HallBuildInfo
extends RefCounted

## Written by the deploy workflow. Text data in External Content has no UID,
## so it stays on a res:// path (CLAUDE.md); the export presets ship it.
const BUILD_INFO_PATH := "res://External Content/build_info.txt"

# ---- TEXT
## Shown in front of the stamp.
const LABEL := "Build %s"
## No stamp file: an editor run or a local export.
const DEV_BUILD := "dev"


## The Menu's build line, e.g. "Build ab12cd3 · 2026-11-04 20:55 UTC".
## Returns LABEL with DEV_BUILD when there's no stamp file.
static func label() -> String:
	return LABEL % stamp()


## Just the stamp text from BUILD_INFO_PATH (first line, trimmed), or DEV_BUILD.
static func stamp() -> String:
	if not FileAccess.file_exists(BUILD_INFO_PATH):
		return DEV_BUILD
	var text := FileAccess.get_file_as_string(BUILD_INFO_PATH).strip_edges()
	if text == "":
		return DEV_BUILD
	return text.get_slice("\n", 0).strip_edges()
