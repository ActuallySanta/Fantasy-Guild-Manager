---
source: Scripts/UI/Overlays/Menu/overlay_backup.gd
class_name: ""
extends: Control
scene: "[[overlay_backup (scene)]]"
systems: ["[[Saving Migration and Backup Codes]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_backup.gd

## Purpose
Menu > Backup save: keep a copy of the run outside the browser. Save backup file and Copy save code export the run as a save code ([[hall_save_transfer]]); Load backup file and Paste save code bring one back. Loading replaces the current guild, so those two take two taps (like Abandon run). Export and import work whether or not "Save runs" is on (an import turns it on). Back returns to the Menu; tapping the dim closes both. Scene: [[overlay_backup (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUTTON_FONT_SIZE` | const | Button font size (design px). |
| `BUTTON_*`, `PROMPT_PASTE`, `TOAST_*` | const | UI strings and toast messages. |
| `_dim`, `_save_file_button`, `_copy_code_button`, `_load_file_button`, `_paste_code_button`, `_back_button` | onready | Scene nodes `%Dim`, `%SaveFileButton`, `%CopyCodeButton`, `%LoadFileButton`, `%PasteCodeButton`, `%BackButton`. |
| `hall` | var | The [[hall_main]] node. |
| `_files` | var | A `HallWebFiles` ([[hall_web_files]]): share sheet, clipboard, file picker. |
| `_armed_button` | var | Which import button was tapped once (its next tap really imports), or null. Cleared when the sheet is hidden or another button is tapped. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:46`

Stores the hall, connects the buttons, sets texts and styles (paper, wood for Back).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in `view.setup(self)` ([[hall_main#_ready]], `hall_main.gd:427`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%SaveFileButton` to [[overlay_backup#_on_save_file_pressed]], `%CopyCodeButton` to [[overlay_backup#_on_copy_code_pressed]], `%LoadFileButton` and `%PasteCodeButton` to [[overlay_backup#_on_import_pressed]] (button bound), `%BackButton` to [[hall_main#close_backup]], `gui_input` on `%Dim` to [[overlay_backup#_on_dim_input]]; `visibility_changed` on itself to a lambda that clears `_armed_button`.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:65`

Sets the Load and Paste labels: `BUTTON_CONFIRM` ("Tap again to replace this guild") on the armed one, else their own text.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`) while visible, [[overlay_backup#_on_import_pressed]], [[overlay_backup#_disarm]].

### _on_save_file_pressed
`func _on_save_file_pressed() -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:71`

Save backup file: the run as a .txt through the share sheet or a download, then a toast (saved or failed).

**Returns:** nothing.

**Side effects:** shows a toast; may open the share sheet / download.

**Called by:** `pressed` on `%SaveFileButton`.

**Calls:** [[overlay_backup#_disarm]], [[hall_save_transfer#build_code]], [[hall_save_transfer#file_name_for]] (given `GameState.day`), [[hall_web_files#share_or_download]], [[hall_main#show_toast]].

### _on_copy_code_pressed
`func _on_copy_code_pressed() -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:79`

Copy save code: the same text as the file, put on the clipboard, then a toast.

**Called by:** `pressed` on `%CopyCodeButton`.

**Calls:** [[overlay_backup#_disarm]], [[hall_save_transfer#build_code]], [[hall_web_files#copy_text]], [[hall_main#show_toast]].

### _on_import_pressed
`func _on_import_pressed(button: Button) -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:88`

Load backup file / Paste save code. The first tap arms the button (it reads "Tap again to replace this guild"); the second opens the file picker or the paste box. A pasted blank text does nothing.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `button` | `Button` | Which of the two was tapped | Bound in [[overlay_backup#setup]]: `_load_file_button` or `_paste_code_button` |

**Returns:** nothing.

**Called by:** `pressed` on `%LoadFileButton` and `%PasteCodeButton`.

**Calls:** [[overlay_backup#refresh]], [[overlay_backup#_disarm]], [[hall_web_files#pick_file]] (with [[overlay_backup#_import_text]] as callback), [[hall_web_files#ask_for_text]], [[overlay_backup#_import_text]].

### _import_text
`func _import_text(text: String) -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:104`

Reads `text` as a save code. A newer-version code or a non-code only toasts (current run untouched); a good one goes to `hall.import_run`, which replaces the run (the hall reloads), with a toast if that fails.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | A pasted or file-read save code | The paste box text in [[overlay_backup#_on_import_pressed]], or the picked file's text via the `pick_file` callback |

**Returns:** nothing.

**Called by:** [[overlay_backup#_on_import_pressed]] (`overlay_backup.gd:96`, `:101`).

**Calls:** [[hall_save_transfer#parse_code]], [[hall_main#import_run]], [[hall_main#show_toast]].

### _disarm
`func _disarm() -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:117`

Takes back a half-made import: clears `_armed_button`, refreshes the labels.

**Called by:** [[overlay_backup#_on_save_file_pressed]], [[overlay_backup#_on_copy_code_pressed]], [[overlay_backup#_on_import_pressed]].

**Calls:** [[overlay_backup#refresh]].

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Menu/overlay_backup.gd:123`

A mouse press on the dim closes Backup save and the Menu.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[hall_main#close_backup]] with `false`.

## Suspected issues
- `_import_text` ignores `ParseError` values other than the two it names (`_` branch assumes success). Fine if the enum only has those.
