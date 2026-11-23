---
source: Scripts/UI/Overlays/Menu/overlay_update_confirm.gd
class_name: ""
extends: Control
scene: "[[overlay_update_confirm (scene)]]"
systems: ["[[Saving Migration and Backup Codes]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_update_confirm.gd

## Purpose
Update confirmation, shown by Debug tools' Check for update when the live site has a newer build ([[hall_web_update#check_latest]]). It shows this build and the newest, whether the run comes back after the reload (saving on and not a debug run) or would be lost, an Export save button (same as Menu > Backup save), and Cancel / Update ([[hall_web_update#update_now]]). It belongs to [[overlay_debug]], which sets it up and opens it. Tapping the dim cancels. `top_level`. Scene: [[overlay_update_confirm (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUTTON_FONT_SIZE` | const | Button font size (design px). |
| `TITLE`, `BUILDS`, `NOTE_SAVED`, `NOTE_NOT_SAVED`, `BUTTON_*` | const | UI strings. |
| `TOAST_SAVED`, `TOAST_SAVE_FAILED` | const | Same wording as the Backup sheet ([[overlay_backup]]). |
| `_dim`, `_title`, `_builds`, `_note`, `_export_button`, `_cancel_button`, `_update_button` | onready | Scene nodes `%Dim`, `%Title`, `%Builds`, `%Note`, `%ExportButton`, `%CancelButton`, `%UpdateButton`. |
| `hall` | var | The [[hall_main]] node. |
| `_files` | var | A `HallWebFiles` ([[hall_web_files]]) for the export. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Menu/overlay_update_confirm.gd:44`

Stores the hall, connects the buttons and dim, sets texts and styles (paper Export, wood Cancel, gold Update).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `hall` as passed to [[overlay_debug#setup]] (`overlay_debug.gd:95`: `_update_confirm.setup(hall)`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%ExportButton` to [[overlay_update_confirm#_on_export_pressed]], `%CancelButton` to [[overlay_update_confirm#close]], `%UpdateButton` to [[overlay_update_confirm#_on_update_pressed]], `gui_input` on `%Dim` to [[overlay_update_confirm#_on_dim_input]].

**Called by:** [[overlay_debug#setup]] (`overlay_debug.gd:95`). Not in `hall_main`'s overlay list.

**Calls:** [[hall_style#style_button]].

### open
`func open(current_stamp: String, latest_stamp: String) -> void` · `Scripts/UI/Overlays/Menu/overlay_update_confirm.gd:62`

Shows the popup with both build stamps and the "saved / not saved" note (`hall.is_save_enabled and not hall.is_debug_run`, the two cases where `HallMain.save_now` writes).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `current_stamp` | `String` | This build's stamp | `HallBuildInfo.stamp()` in [[overlay_debug#_on_update_checked]] (`overlay_debug.gd:186`) |
| `latest_stamp` | `String` | The site's newest stamp | `latest_stamp` argument of the `check_latest` callback |

**Returns:** nothing.

**Side effects:** becomes visible and fades in.

**Called by:** [[overlay_debug#_on_update_checked]] (`overlay_debug.gd:186`).

**Calls:** [[hall_fx#fade_in]].

### close
`func close() -> void` · `Scripts/UI/Overlays/Menu/overlay_update_confirm.gd:71`

Hides the popup.

**Called by:** `pressed` on `%CancelButton`; [[overlay_update_confirm#_on_update_pressed]]; [[overlay_update_confirm#_on_dim_input]]; the `visibility_changed` lambda in [[overlay_debug#setup]] (`overlay_debug.gd:99`), which closes it when Debug tools hide.

### _on_export_pressed
`func _on_export_pressed() -> void` · `Scripts/UI/Overlays/Menu/overlay_update_confirm.gd:77`

Export save: the run as a .txt through the share sheet or a download, then a toast. Runs straight from the press so the browser allows it. The popup stays open.

**Called by:** `pressed` on `%ExportButton`.

**Calls:** [[hall_save_transfer#build_code]], [[hall_save_transfer#file_name_for]], [[hall_web_files#share_or_download]], [[hall_main#show_toast]].

### _on_update_pressed
`func _on_update_pressed() -> void` · `Scripts/UI/Overlays/Menu/overlay_update_confirm.gd:83`

Closes, then calls `HallWebUpdate.update_now(hall)` (save, then reload into the new deploy).

**Called by:** `pressed` on `%UpdateButton`.

**Calls:** [[overlay_update_confirm#close]], [[hall_web_update#update_now]].

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Menu/overlay_update_confirm.gd:89`

A mouse press on the dim cancels.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[overlay_update_confirm#close]].

## Suspected issues
- `refresh()` is not defined here, and the overlay isn't in `_all_overlays()`, so `hall_main` never refreshes it (it is redrawn only by `open`).
