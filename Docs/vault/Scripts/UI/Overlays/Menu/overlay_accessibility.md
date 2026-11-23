---
source: Scripts/UI/Overlays/Menu/overlay_accessibility.gd
class_name: ""
extends: Control
scene: "[[overlay_accessibility (scene)]]"
systems: ["[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_accessibility.gd

## Purpose
Menu > Accessibility: Text size, the colorblind filter and Reduced Motion, each a button that steps to the next choice. Changes apply right away and are saved ([[hall_settings]]). Back returns to the Menu; tapping the dim closes both. Opened by [[overlay_menu]]'s Accessibility button. Scene: [[overlay_accessibility (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUTTON_FONT_SIZE` | const | Font size of the buttons and note (design px; `HallFontScale` grows it). |
| `BUTTON_TEXT_SIZE`, `BUTTON_COLOR`, `BUTTON_MOTION`, `MOTION_ON`, `MOTION_OFF`, `BUTTON_BACK` | const | UI strings. |
| `_dim`, `_text_size_button`, `_color_button`, `_motion_button`, `_back_button` | onready | Scene nodes `%Dim`, `%TextSizeButton`, `%ColorButton`, `%MotionButton`, `%BackButton`. |
| `hall` | var | The [[hall_main]] node, set in `setup`. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Menu/overlay_accessibility.gd:31`

Stores the hall, connects the buttons straight to hall actions and styles them (paper for the three settings, wood for Back).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in `view.setup(self)` over `_all_overlays()` ([[hall_main#_ready]], `hall_main.gd:427`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%TextSizeButton` to [[hall_main#cycle_text_size]], on `%ColorButton` to [[hall_main#cycle_color_filter]], on `%MotionButton` to [[hall_main#toggle_reduce_motion]], on `%BackButton` to [[hall_main#close_accessibility]]; `gui_input` on `%Dim` to [[overlay_accessibility#_on_dim_input]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Menu/overlay_accessibility.gd:45`

Rewrites the three button labels from `hall.text_size`, `hall.color_filter` and `hall.reduce_motion` (names from `HallSettings.TEXT_SIZES` / `COLOR_FILTERS`).

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`), only while the overlay is visible.

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Menu/overlay_accessibility.gd:52`

A mouse press on the dim closes Accessibility and the Menu.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[hall_main#close_accessibility]] with `false`.

## Suspected issues
- None found.
