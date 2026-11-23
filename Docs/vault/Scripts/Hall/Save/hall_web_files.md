---
source: Scripts/Hall/Save/hall_web_files.gd
class_name: HallWebFiles
extends: RefCounted
scene: null
systems: ["[[Saving Migration and Backup Codes]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_web_files.gd

## Purpose
`HallWebFiles`: moves text (a save code from [[hall_save_transfer]]) in and out of the device. On the web it uses JavaScript through `JavaScriptBridge` (Web Share API on touch screens, a download link elsewhere, `window.prompt` for pasting, a hidden file input for picking a file). Off the web it uses plain Godot: a file in `user://backups` opened in the file manager, the system clipboard, a native `FileDialog`. Browsers only allow sharing, clipboard and file pickers right after a tap, so every function must be called straight from a button press. Instances are held by [[overlay_backup]] (`overlay_backup.gd:40`) and [[overlay_update_confirm]] (`overlay_update_confirm.gd:41`).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `DESKTOP_BACKUP_DIR` | const | `"user://backups"`, where an exported backup goes off the web. |
| `WEB_FILE_ACCEPT` | const | `".txt,text/plain"`, the web picker's accept list. |
| `DESKTOP_FILE_FILTER` | const | `"*.txt ; Save backups"`, the desktop dialog filter. |
| `_web_file_callback` | var (`JavaScriptObject`) | The JS callback the picker calls with the file's text. Kept so Godot doesn't free it while the picker is open. |
| `_is_web_ready` | var (`bool`) | Whether the JS helpers are defined on the page yet. |
| `_WEB_HELPERS` | const | JavaScript defining `window.fgmShareOrDownload(text, name)` (share on touch screens that can share files, else download; falls back to download if sharing fails other than a cancel) and `window.fgmPickFile(accept, callback)`. |

## Functions

### share_or_download
`func share_or_download(text: String, file_name: String) -> bool` · `Scripts/Hall/Save/hall_web_files.gd:86`

Save text as a file: the share sheet on a phone, a download on a desktop browser, or a file in `DESKTOP_BACKUP_DIR` (then opens that folder) off the web.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | The save code | [[hall_save_transfer#build_code]] |
| `file_name` | `String` | File name | [[hall_save_transfer#file_name_for]] with `GameState.day` |

**Returns:** `bool`, false if the file couldn't be written (off the web only; the web can't report). The overlays use it as `is_saved` to choose a toast.

**Side effects:** runs JS on the web; writes a file and calls `OS.shell_open` off the web.

**Called by:** [[overlay_backup#_on_save_file_pressed]] (`overlay_backup.gd:74`), [[overlay_update_confirm#_on_export_pressed]] (`overlay_update_confirm.gd:79`).

**Calls:** [[hall_web_files#_ensure_web]].

### copy_text
`func copy_text(text: String) -> void` · `Scripts/Hall/Save/hall_web_files.gd:106`

Put `text` on the clipboard (`DisplayServer.clipboard_set`; on the web Godot uses `navigator.clipboard`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Text to copy | `HallSaveTransfer.build_code(hall)` in [[overlay_backup#_on_copy_code_pressed]] |

**Returns:** nothing.

**Side effects:** changes the clipboard.

**Called by:** [[overlay_backup#_on_copy_code_pressed]] (`overlay_backup.gd:81`).

**Calls:** nothing in the project.

### ask_for_text
`func ask_for_text(message: String) -> String` · `Scripts/Hall/Save/hall_web_files.gd:113`

Ask the player for a pasted code. Web: the browser's `window.prompt` (the game waits while it's open). Off the web: whatever is on the clipboard.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `message` | `String` | The question shown with the box | `PROMPT_PASTE` constant in [[overlay_backup#_on_import_pressed]] |

**Returns:** `String`, the text, or `""` if cancelled. [[overlay_backup#_on_import_pressed]] passes it on to `_import_text`.

**Side effects:** shows a browser prompt on the web.

**Called by:** [[overlay_backup#_on_import_pressed]] (`overlay_backup.gd:97`).

**Calls:** nothing in the project.

### pick_file
`func pick_file(host: Node, on_text: Callable) -> void` · `Scripts/Hall/Save/hall_web_files.gd:123`

Let the player pick a text file, then call `on_text(text: String)` with its contents. Nothing is called on cancel. Web: `fgmPickFile` with a Godot callback kept in `_web_file_callback`. Off the web: a native `FileDialog` added under `host` and freed after use.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `host` | `Node` | A node in the tree for the dialog | `self` (the overlay) |
| `on_text` | `Callable` | Called with the file's text | `_import_text` in [[overlay_backup#_on_import_pressed]] |

**Returns:** nothing.

**Side effects:** adds and frees a `FileDialog` off the web; connects `file_selected` and `canceled` on it.

**Called by:** [[overlay_backup#_on_import_pressed]] (`overlay_backup.gd:95`).

**Calls:** [[hall_web_files#_ensure_web]].

### _ensure_web
`func _ensure_web() -> void` · `Scripts/Hall/Save/hall_web_files.gd:148`

Define the JavaScript helpers (`_WEB_HELPERS`) on the page the first time they're needed.

**Returns:** nothing.

**Side effects:** `JavaScriptBridge.eval`; sets `_is_web_ready`.

**Called by:** [[hall_web_files#share_or_download]] (`hall_web_files.gd:88`), [[hall_web_files#pick_file]] (`hall_web_files.gd:125`).

**Calls:** nothing.

## Suspected issues
- None found.
