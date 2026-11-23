---
source: Scripts/Hall/Save/hall_settings.gd
class_name: HallSettings
extends: null
scene: null
systems: ["[[Saving Migration and Backup Codes]]", "[[Boot and Autoload Order]]", "[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_settings.gd

## Purpose
`HallSettings`: the player's accessibility choices and the dev "Save runs" switch, saved to `user://settings.cfg` (a `ConfigFile`). Static functions, no state: [[hall_main]] keeps the current values (`color_filter`, `reduce_motion`, `text_size`, `is_save_enabled`) and calls in to load them at start-up and to save each change.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `COLOR_FILTERS` | const | `["Off", "Red-weak", "Green-weak", "Blue-yellow"]`, in Menu order. Index = the shader's `mode`. |
| `TEXT_SIZES` | const | `["Small", "Normal", "Large"]`, in Menu order. |
| `TEXT_SIZE_FACTORS` | const | `[0.85, 1.0, 1.15]`, multiplier on every font on top of the screen's own factor ([[hall_font_scale]]). The last one times `HallFontScale.MAX_SCALE` must stay within `HallFontScale.MAX_TOTAL_SCALE`. |
| `DEFAULT_TEXT_SIZE` | const | `1` (Normal). An old settings file with the removed fourth size (index 3) loads as Large because the index is clamped. |
| `PATH` | const | `"user://settings.cfg"`. |
| `SECTION` | const | `"accessibility"`, the section for player settings. |
| `SECTION_DEV` | const | `"dev"`, the section for development switches. |
| `KEY_COLOR_FILTER` / `KEY_REDUCE_MOTION` / `KEY_TEXT_SIZE` | const | `"color_filter"`, `"reduce_motion"`, `"text_size"`. |
| `KEY_SAVE_ENABLED` | const | `"save_enabled"` (in `SECTION_DEV`): whether the run is saved to / loaded from [[hall_save]]'s file. |
| `DEFAULT_SAVE_ENABLED` | const | `false`. Off while developing so every launch is a fresh Day 1; flip to true before a release. The Debug tools "Save runs" checkbox overrides it. |

## Functions

### load_settings
`static func load_settings() -> Dictionary` · `Scripts/Hall/Save/hall_settings.gd:45`

The saved settings, or the defaults when nothing is saved.

**Returns:** `{color_filter: int (clamped), reduce_motion: bool, text_size: int (clamped), save_enabled: bool}`. [[hall_main#_enter_tree]] reads `.text_size` (`hall_main.gd:408`), [[hall_main#_ready]] reads `.save_enabled` (`hall_main.gd:455`) to decide whether to load a run, and [[hall_main#_load_settings]] copies all four (`hall_main.gd:1391`).

**Side effects:** reads the config file.

**Called by:** [[hall_main#_enter_tree]] (`hall_main.gd:408`), [[hall_main#_ready]] (`hall_main.gd:455`), [[hall_main#_load_settings]] (`hall_main.gd:1391`).

**Calls:** [[hall_settings#clamp_color_filter]], [[hall_settings#clamp_text_size]].

### save_value
`static func save_value(key: String, value: Variant, section := SECTION) -> void` · `Scripts/Hall/Save/hall_settings.gd:63`

Save one setting, keeping the rest of the file.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `key` | `String` | A `KEY_*` constant | `HallSettings.KEY_*` at each call |
| `value` | `Variant` | The new value | the setter's argument, stored on [[hall_main]] |
| `section` | `String` | `SECTION` (default) or `SECTION_DEV` for `KEY_SAVE_ENABLED` | `HallSettings.SECTION_DEV` in `set_save_enabled` and `import_snapshot` |

**Returns:** nothing.

**Side effects:** rewrites `user://settings.cfg`.

**Called by:** [[hall_main#set_color_filter]] (`hall_main.gd:1350`), [[hall_main#set_text_size]] (`hall_main.gd:1369`), [[hall_main#set_reduce_motion]] (`hall_main.gd:1377`), [[hall_main#set_save_enabled]] (`hall_main.gd:1386`), [[hall_save_transfer#import_snapshot]] (`hall_save_transfer.gd:95`).

**Calls:** nothing in the project.

### clamp_color_filter
`static func clamp_color_filter(filter_index: int) -> int` · `Scripts/Hall/Save/hall_settings.gd:71`

`filter_index` pulled into the range of `COLOR_FILTERS`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `filter_index` | `int` | Requested filter | the Menu's choice passed to `set_color_filter`; the stored value in `load_settings` |

**Returns:** `int`, used as `hall.color_filter`.

**Side effects:** none.

**Called by:** [[hall_main#set_color_filter]] (`hall_main.gd:1348`), [[hall_settings#load_settings]] (`hall_settings.gd:54`).

**Calls:** nothing.

### clamp_text_size
`static func clamp_text_size(size_index: int) -> int` · `Scripts/Hall/Save/hall_settings.gd:76`

`size_index` pulled into the range of `TEXT_SIZES`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `size_index` | `int` | Requested size | the Menu's choice passed to `set_text_size`; the stored value in `load_settings`; the caller's index in `text_size_factor` |

**Returns:** `int`, used as `hall.text_size`.

**Side effects:** none.

**Called by:** [[hall_main#set_text_size]] (`hall_main.gd:1367`), [[hall_settings#load_settings]] (`hall_settings.gd:56`), [[hall_settings#text_size_factor]] (`hall_settings.gd:82`).

**Calls:** nothing.

### text_size_factor
`static func text_size_factor(size_index: int) -> float` · `Scripts/Hall/Save/hall_settings.gd:81`

The font multiplier for the Text size at `size_index` (from `TEXT_SIZE_FACTORS`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `size_index` | `int` | Text size index | `text_size` on [[hall_main]] |

**Returns:** `float`, handed to `HallFontScale.init` ([[hall_main#_enter_tree]], `hall_main.gd:409`) and `HallFontScale.set_text_factor` ([[hall_main#set_text_size]], `hall_main.gd:1368`).

**Side effects:** none.

**Called by:** [[hall_main#_enter_tree]] (`hall_main.gd:409`), [[hall_main#set_text_size]] (`hall_main.gd:1368`).

**Calls:** [[hall_settings#clamp_text_size]].

## Suspected issues
- None found.
