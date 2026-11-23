---
source: Scripts/UI/Overlays/Menu/overlay_menu.gd
class_name: ""
extends: Control
scene: "[[overlay_menu (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_menu.gd

## Purpose
The Menu (header button): how to play, last night's report, Accessibility ([[overlay_accessibility]]), Backup save ([[overlay_backup]]), Debug tools ([[overlay_debug]], only when `GuildUpgrades.SHOW_DEBUG_BUTTONS`), and Abandon run (two taps: the first asks, the second deletes the saved run and starts a new guild). A small build line under Close (`HallBuildInfo`) says which build is running. Scene: [[overlay_menu (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUILD_FONT_SIZE` | const | Font size of the build line (px). |
| `BUTTON_*` | const | UI strings. |
| `_dim`, `_how_to_play_button`, `_report_button`, `_accessibility_button`, `_backup_button`, `_debug_button`, `_abandon_button`, `_close_button` | onready | Scene nodes `%Dim`, `%HowButton`, `%ReportButton`, `%AccessibilityButton`, `%BackupButton`, `%DebugButton`, `%AbandonButton`, `%CloseButton`. |
| `hall` | var | The [[hall_main]] node. |
| `_build_label` | var | Label made in `setup` under Close (so the scene needs no extra node). |
| `_is_abandon_armed` | var | Abandon was tapped once, so the next tap abandons. Cleared when the menu hides. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Menu/overlay_menu.gd:44`

Stores the hall, connects the buttons to hall actions, builds the build-info label, sets texts and styles (paper, red Abandon, wood Close).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in `view.setup(self)` ([[hall_main#_ready]], `hall_main.gd:424`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%HowButton` to [[hall_main#open_welcome]], `%ReportButton` to [[hall_main#open_previous_report]], `%AccessibilityButton` to [[hall_main#open_accessibility]], `%BackupButton` to [[hall_main#open_backup]], `%DebugButton` to [[hall_main#open_debug]], `%CloseButton` to [[hall_main#close_menu]], `%AbandonButton` to [[overlay_menu#_on_abandon_pressed]], `gui_input` on `%Dim` to [[overlay_menu#_on_dim_input]]; `visibility_changed` clears `_is_abandon_armed`. Adds `BuildLabel` next to Close.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:424`).

**Calls:** [[hall_font_scale#set_size]], [[hall_build_info#label]], [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Menu/overlay_menu.gd:78`

Disables the report button until `hall.previous_report` is non-empty, shows the Debug button only if `GuildUpgrades.SHOW_DEBUG_BUTTONS`, and sets the Abandon label by `_is_abandon_armed`.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1866`) while visible; [[overlay_menu#_on_abandon_pressed]].

### _on_abandon_pressed
`func _on_abandon_pressed() -> void` · `Scripts/UI/Overlays/Menu/overlay_menu.gd:87`

First tap arms and refreshes; the second calls `hall.start_new_run` (which deletes the save and reloads the scene).

**Called by:** `pressed` on `%AbandonButton`.

**Calls:** [[overlay_menu#refresh]], [[hall_main#start_new_run]].

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Menu/overlay_menu.gd:97`

A mouse press on the dim closes the menu.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[hall_main#close_menu]].

## Suspected issues
- `setup` uses the literal `28` for the button font size (`overlay_menu.gd:72-74`) where the sibling overlays use a named `BUTTON_FONT_SIZE` constant.
