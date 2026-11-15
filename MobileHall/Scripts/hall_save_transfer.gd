## Hall save transfer: the run as a save code (a line of text), so a player can
## keep a backup outside the browser (Files, Drive, notes, a chat) and bring it
## back after the browser clears its storage. No nodes and no state: the Backup
## overlay (overlay_backup.gd) builds and reads codes here, and HallWebFiles
## moves them in and out of the device.
##
## HOW A CODE IS MADE
##   HallSave.build_snapshot   the run as a Dictionary of plain values
##   var_to_bytes              -> bytes (the same bytes run_save.dat holds)
##   compress (gzip)           -> fewer bytes (field names repeat a lot)
##   base64                    -> text that survives clipboards and notes apps
##   CODE_PREFIX in front      -> "FGMSAVE1:H4sI..."
## Reading a code runs those steps backwards, then HallSave.migrate brings an
## older save up to date. A backup file is the same code saved as a .txt.
##
## SAFETY: a code can be anything someone pastes, so parse_code uses
## bytes_to_var (which can't build objects or run scripts), caps how big the
## decompressed data may get, and checks the snapshot's shape before anything
## is changed. A bad code changes nothing.
class_name HallSaveTransfer


# ============================================================ SETTINGS

## Starts every save code. The number is the code's own format (compression +
## text encoding), separate from HallSave.SAVE_VERSION (the snapshot's layout).
const CODE_PREFIX := "FGMSAVE1:"
## The biggest a code may unpack to (bytes). A real run is far smaller; the cap
## stops a crafted code that would unpack to gigabytes.
const MAX_SNAPSHOT_BYTES := 8_000_000
## A backup file's name, with the run's day filled in.
const FILE_NAME_FORMAT := "fantasy-guild-day%d.txt"

## What parse_result's "error" says went wrong.
enum ParseError { NONE, NOT_A_CODE, NEWER_VERSION }


# ============================================================ EXPORT

## The current run as a save code. hall: the HallMain whose run it is.
## Works whether or not "Save runs" is on: it reads the live state.
static func build_code(hall: HallMain) -> String:
	var bytes := var_to_bytes(HallSave.build_snapshot(hall))
	var packed := bytes.compress(FileAccess.COMPRESSION_GZIP)
	return CODE_PREFIX + Marshalls.raw_to_base64(packed)


## A backup file name for a run on day (e.g. "fantasy-guild-day12.txt").
static func file_name_for(day: int) -> String:
	return FILE_NAME_FORMAT % day


# ============================================================ IMPORT

## Read a save code. text: what the player pasted or the backup file held;
## spaces and line breaks are ignored (notes apps wrap long lines).
## Returns {"snapshot": Dictionary, "error": ParseError}. The snapshot is
## migrated up to HallSave.SAVE_VERSION and ready for import_snapshot; it's {}
## whenever error isn't NONE.
static func parse_code(text: String) -> Dictionary:
	var failed := {"snapshot": {}, "error": ParseError.NOT_A_CODE}
	# base64 has no whitespace in it, so any there came from wrapping
	var code := text
	for space in [" ", "\t", "\r", "\n"]:
		code = code.replace(space, "")
	if not code.begins_with(CODE_PREFIX):
		return failed
	var packed := Marshalls.base64_to_raw(code.substr(CODE_PREFIX.length()))
	if packed.is_empty():
		return failed
	var bytes := packed.decompress_dynamic(MAX_SNAPSHOT_BYTES, FileAccess.COMPRESSION_GZIP)
	if bytes.is_empty():
		return failed
	# plain values only: a crafted code can't build objects
	var value: Variant = bytes_to_var(bytes)
	if HallSave.is_from_newer_version(value) and HallSave.has_snapshot_shape(value):
		return {"snapshot": {}, "error": ParseError.NEWER_VERSION}
	var snapshot := HallSave.migrate(value)
	if snapshot.is_empty():
		return failed
	return {"snapshot": snapshot, "error": ParseError.NONE}


## Replace the current run with snapshot (from parse_code): it's written as the
## save file, "Save runs" is turned on so it stays, and the hall scene is loaded
## again, which loads it like any saved run ("Welcome back" toast and all).
## hall: the HallMain being replaced. Returns false (nothing changed) if the
## save file couldn't be written.
static func import_snapshot(hall: HallMain, snapshot: Dictionary) -> bool:
	if not HallSave.write_bytes(var_to_bytes(snapshot)):
		return false
	# this hall is on its way out: its last refresh mustn't save over the import
	hall.uses_save_file = false
	HallSave.forget_cache()
	HallSettings.save_value(HallSettings.KEY_SAVE_ENABLED, true, HallSettings.SECTION_DEV)
	# fresh autoloads first, as for a new run, so nothing of the old run is
	# left wherever the imported save has no value (see HallSave.apply_snapshot)
	hall.reset_autoloads()
	hall.get_tree().change_scene_to_file(HallMain.MAIN_SCENE_PATH)
	return true
