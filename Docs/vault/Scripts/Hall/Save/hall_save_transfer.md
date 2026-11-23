---
source: Scripts/Hall/Save/hall_save_transfer.gd
class_name: HallSaveTransfer
extends: null
scene: null
systems: ["[[Saving Migration and Backup Codes]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_save_transfer.gd

## Purpose
`HallSaveTransfer`: the run as a save code (one line of text) so a player can keep a backup outside the browser. Static functions, no nodes, no state. The Backup overlay ([[overlay_backup]]) builds and reads codes here, and [[hall_web_files]] moves them on and off the device.

A code is `CODE_PREFIX` + base64(gzip(`var_to_bytes`([[hall_save#build_snapshot]]))). Reading runs the steps backwards, then [[hall_save#migrate]] brings an older save up to date. `parse_code` uses `bytes_to_var` (no objects), caps the decompressed size and checks the snapshot's shape, so a bad code changes nothing.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `CODE_PREFIX` | const | `"FGMSAVE1:"`, starts every code. The number is the code format, separate from `HallSave.SAVE_VERSION`. |
| `MAX_SNAPSHOT_BYTES` | const | 8,000,000 bytes: the most a code may unpack to. |
| `FILE_NAME_FORMAT` | const | `"fantasy-guild-day%d.txt"`, a backup file's name with the day. |
| `ParseError` | enum | `NONE, NOT_A_CODE, NEWER_VERSION`: the `error` in `parse_code`'s result. |

## Functions

### build_code
`static func build_code(hall: HallMain) -> String` · `Scripts/Hall/Save/hall_save_transfer.gd:42`

The current run as a save code. Works whether or not "Save runs" is on (reads live state).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The hall whose run it is | `hall` stored by `setup(hall)` in the overlay |

**Returns:** `String` code. Used by [[overlay_backup#_on_save_file_pressed]] (`overlay_backup.gd:73`, passed with the file name to `share_or_download`), [[overlay_backup#_on_copy_code_pressed]] (`overlay_backup.gd:81`, copied to the clipboard) and [[overlay_update_confirm#_on_export_pressed]] (`overlay_update_confirm.gd:78`, same as the save-file button before an update).

**Side effects:** none.

**Called by:** [[overlay_backup#_on_save_file_pressed]] (`overlay_backup.gd:73`), [[overlay_backup#_on_copy_code_pressed]] (`overlay_backup.gd:81`), [[overlay_update_confirm#_on_export_pressed]] (`overlay_update_confirm.gd:78`).

**Calls:** [[hall_save#build_snapshot]].

### file_name_for
`static func file_name_for(day: int) -> String` · `Scripts/Hall/Save/hall_save_transfer.gd:49`

A backup file name for a run on `day`, e.g. `fantasy-guild-day12.txt`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | Current day | `GameState.day` in both overlays |

**Returns:** `String`, the second argument of [[hall_web_files#share_or_download]].

**Side effects:** none.

**Called by:** [[overlay_backup#_on_save_file_pressed]] (`overlay_backup.gd:74`), [[overlay_update_confirm#_on_export_pressed]] (`overlay_update_confirm.gd:79`).

**Calls:** nothing.

### parse_code
`static func parse_code(text: String) -> Dictionary` · `Scripts/Hall/Save/hall_save_transfer.gd:60`

Read a save code. Whitespace (spaces, tabs, line breaks) is removed first. Fails with `NOT_A_CODE` if the prefix is missing, base64 or gzip decode gives nothing, or [[hall_save#migrate]] returns `{}`. A snapshot from a newer version gives `NEWER_VERSION`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | What the player pasted or the backup file held | `text` passed to `_import_text`, from the file picker callback or the paste prompt ([[hall_web_files#pick_file]], [[hall_web_files#ask_for_text]]) |

**Returns:** `Dictionary` `{"snapshot": Dictionary, "error": ParseError}`. The snapshot is migrated and `{}` whenever `error` isn't `NONE`. [[overlay_backup#_import_text]] matches on `error` for the message and passes a good snapshot on to the hall's import.

**Side effects:** none.

**Called by:** [[overlay_backup#_import_text]] (`overlay_backup.gd:105`).

**Calls:** [[hall_save#is_from_newer_version]], [[hall_save#has_snapshot_shape]], [[hall_save#migrate]].

### import_snapshot
`static func import_snapshot(hall: HallMain, snapshot: Dictionary) -> bool` · `Scripts/Hall/Save/hall_save_transfer.gd:89`

Replace the current run with `snapshot`: write it as the save file, turn "Save runs" on, reset the autoloads and reload the hall scene, which loads it like any saved run.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The hall being replaced | `self` in [[hall_main#import_run]] |
| `snapshot` | `Dictionary` | Result of `parse_code` | `snapshot` argument of `import_run`, from the Backup overlay |

**Returns:** `bool`, false (nothing changed) if the save file couldn't be written. [[hall_main#import_run]] returns it to its caller.

**Side effects:** writes the save file; sets `hall.uses_save_file = false` (so the dying hall's last refresh can't overwrite the import); `HallSave.forget_cache()`; saves `KEY_SAVE_ENABLED = true` in `SECTION_DEV`; `hall.reset_autoloads()`; `change_scene_to_file(HallMain.MAIN_SCENE_PATH)`.

**Called by:** [[hall_main#import_run]] (`hall_main.gd:1700`).

**Calls:** [[hall_save#write_bytes]], [[hall_save#forget_cache]], [[hall_settings#save_value]], [[hall_main#reset_autoloads]].

## Suspected issues
- None found.
