---
source: Scripts/Hall/Style/hall_font_scale.gd
class_name: HallFontScale
extends: RefCounted
scene: ""
systems: ["[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_font_scale.gd

## Purpose
Grows every font in the Mobile Hall at start-up so the smallest text reads at `MIN_POINT_SIZE` points on the player's screen, then multiplies by the player's Text size setting (Menu > Accessibility). Only fonts scale, not layout, so the screen factor is capped at `MAX_SCALE`. Three routes keep sizes scaled exactly once: [[hall_font_scale#scale_theme]] for `hall_theme.tres`, [[hall_font_scale#scale_authored_overrides]] for overrides written in `.tscn` files, and [[hall_font_scale#set_size]] / [[hall_font_scale#px]] for sizes set from code. Each scaled override keeps its authored size in a meta tag so [[hall_font_scale#set_text_factor]] can re-apply a new factor without a reload. State is in static vars, so it survives `start_new_run`'s scene reload. Set up by [[hall_main#_enter_tree]]; the Text size choice comes from [[hall_settings]]. No scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `MIN_POINT_SIZE` | const | Smallest text wanted on screen, in points (16.0). |
| `SMALLEST_DESIGN_SIZE` | const | Smallest font authored in the hall, design px (16.0, plan_row's number). |
| `DESIGN_WIDTH`, `DESIGN_HEIGHT` | const | The 720x1280 design canvas, px. |
| `MAX_SCALE` | const | Biggest screen factor (1.5); the unscaled layout stops fitting past it. |
| `MIN_TOTAL_SCALE`, `MAX_TOTAL_SCALE` | const | Range of the final factor, screen x Text size (0.75 to 1.75). |
| `ANDROID_BASE_DPI`, `DESKTOP_BASE_DPI` | const | Physical px per point on Android (160) and Windows/Linux (96). |
| `CMDLINE_PREFIX` | const | Dev override `-- --font-scale=2.0` (forces the factor, uncapped). |
| `FONT_SIZE_NAMES` | const | Font-size theme items a Control can override (`font_size`, RichTextLabel's `*_font_size`). |
| `BASE_META_PREFIX` | const | Meta tag prefix holding an override's authored size; also marks it as scaled. |
| `MAX_FACTOR_META` | const | Meta key (`font_max_factor`) capping how much a Control's text may grow; set in scenes or via `set_size`. |
| `scale` | static var | The factor every font size is multiplied by: `screen_factor * text_factor`, clamped. |
| `screen_factor`, `text_factor` | static var | The screen part ([[hall_font_scale#compute_scale]]) and the Text size part (`HallSettings.TEXT_SIZE_FACTORS`). |
| `_theme_base_sizes` | static var | Theme's authored font sizes saved on the first scale, so rescaling never compounds. |

No signals defined. Externally, `SceneTree.node_added` is connected to [[hall_font_scale#scale_authored_overrides]] (`hall_main.gd:410`) and disconnected at `hall_main.gd:415`.

## Functions

### init
`static func init(window: Window, theme: Theme, player_text_factor: float = 1.0) -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:95`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `window` | `Window` | The game window; its `size` is in physical px | `get_window()` in [[hall_main#_enter_tree]] |
| `theme` | `Theme` | The hall's theme (hall_theme.tres), or null to skip it | the `theme` variable in [[hall_main#_enter_tree]] |
| `player_text_factor` | `float` | The player's Text size multiplier (1.0 = Normal) | `HallSettings.text_size_factor(text_size)` in [[hall_main#_enter_tree]] |

**Returns:** nothing.

**Side effects:** writes the static vars `screen_factor`, `text_factor`, `scale`; rewrites the theme's font sizes.

**Called by:** [[hall_main#_enter_tree]] (`hall_main.gd:409`)

**Calls:** [[hall_font_scale#_cmdline_scale]], [[hall_font_scale#compute_scale]], [[hall_font_scale#pixels_per_point]], [[hall_font_scale#_update_scale]], [[hall_font_scale#scale_theme]]

### set_text_factor
`static func set_text_factor(factor: float, theme: Theme, root: Node) -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:110`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `factor` | `float` | New Text size multiplier (1.0 = Normal) | `HallSettings.text_size_factor(text_size)` in [[hall_main#set_text_size]] |
| `theme` | `Theme` | Theme to rescale; may be null | `theme` in [[hall_main#set_text_size]] |
| `root` | `Node` | Subtree whose Controls get re-scaled; may be null | `self` (the hall) in [[hall_main#set_text_size]] |

**Returns:** nothing.

**Side effects:** writes `text_factor` and `scale`; rewrites the theme and every tagged override under `root`.

**Called by:** [[hall_main#set_text_size]] (`hall_main.gd:1368`)

**Calls:** [[hall_font_scale#_update_scale]], [[hall_font_scale#scale_theme]], [[hall_font_scale#rescale_tree]]

### _update_scale
`static func _update_scale() -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:121`

**Returns:** nothing (writes `scale`).

**Side effects:** writes `scale`, clamped to [`MIN_TOTAL_SCALE`, `MAX_TOTAL_SCALE`] unless forced by the command line.

**Called by:** [[hall_font_scale#init]] (`hall_font_scale.gd:102`), [[hall_font_scale#set_text_factor]] (`hall_font_scale.gd:112`)

**Calls:** [[hall_font_scale#_cmdline_scale]]

### compute_scale
`static func compute_scale(window_pixels: Vector2, pixels_per_point: float) -> float:` · `Scripts/Hall/Style/hall_font_scale.gd:131`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `window_pixels` | `Vector2` | Window size in physical px | `Vector2(window.size)` in [[hall_font_scale#init]] |
| `pixels_per_point` | `float` | Physical px per point on this device | [[hall_font_scale#pixels_per_point]] |

**Returns:** `float` in [1.0, `MAX_SCALE`]; 1.0 when the window size or points-per-pixel is not positive. [[hall_font_scale#init]] stores it as `screen_factor`.

**Side effects:** none

**Called by:** [[hall_font_scale#init]] (`hall_font_scale.gd:100`)

**Calls:** none.

> [!note] How it works
> Canvas scale = `min(window.x / 720, window.y / 1280)`; points per design px = that over `pixels_per_point`; factor = `MIN_POINT_SIZE / (SMALLEST_DESIGN_SIZE * points_per_design_px)`, clamped to [1, `MAX_SCALE`].

### pixels_per_point
`static func pixels_per_point() -> float:` · `Scripts/Hall/Style/hall_font_scale.gd:142`

**Returns:** `float` physical px per point, 1.0 when the OS reports zero or less. Used by [[hall_font_scale#init]].

**Side effects:** none

**Called by:** [[hall_font_scale#init]] (`hall_font_scale.gd:100`)

**Calls:** none.

### _cmdline_scale
`static func _cmdline_scale() -> float:` · `Scripts/Hall/Style/hall_font_scale.gd:156`

**Returns:** `float`, the `--font-scale=` value, or 0.0 when absent. Non-zero means forced and uncapped (read by [[hall_font_scale#init]] and [[hall_font_scale#_update_scale]]).

**Side effects:** none

**Called by:** [[hall_font_scale#init]] (`hall_font_scale.gd:96`), [[hall_font_scale#_update_scale]] (`hall_font_scale.gd:123`)

**Calls:** none.

### px
`static func px(base: int) -> int:` · `Scripts/Hall/Style/hall_font_scale.gd:166`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `base` | `int` | Authored size in design px | Row and screen constants, e.g. `EMPTY_SEAT_HEIGHT` (party_slot.gd:52), `FILTER_HEIGHT` (tab_pack.gd:132), `FOLD_CARET_BOX_SIZE` (report_entry.gd:221) |

**Returns:** `int`, `max(round(base * scale), 1)`. Callers use it as a minimum size or scroll gap.

**Side effects:** none

**Called by:** [[report_entry#_add_fold_hint]] (`report_entry.gd:221`), [[party_slot#setup]] (`party_slot.gd:52`), [[screen_assign#scroll_to_picker]] (`screen_assign.gd:180`), [[tab_pack#_show_filters]] (`tab_pack.gd:132`), [[hall_font_scale#scale_theme]] (`hall_font_scale.gd:215`)

**Calls:** none.

### px_vec
`static func px_vec(base: Vector2, max_factor: float = 0.0) -> Vector2:` · `Scripts/Hall/Style/hall_font_scale.gd:176`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `base` | `Vector2` | Authored size in design px | Size constants, e.g. `TILE_SIZE` (pack_tile.gd:35, shop_tile.gd:37), `TYPE_SEAL_SIZE` (quest_row.gd:66), `STANDING_BOX_SIZE` (hall_header.gd:175) |
| `max_factor` | `float` | Most it may grow (0 = no cap) | `SIDE_BOX_MAX_FACTOR` (quest_row.gd:66-67), `STANDING_MAX_FACTOR` (hall_header.gd:175); omitted elsewhere |

**Returns:** `Vector2`, each axis `round(base * factor)`, factor = `scale` capped at `max_factor`. Callers assign it to `custom_minimum_size`.

**Side effects:** none

**Called by:** [[report_entry#setup]] (`report_entry.gd:153`), [[pack_tile#setup]] (`pack_tile.gd:35`), [[shop_tile#setup]] (`shop_tile.gd:37`), [[quest_row#setup]] (`quest_row.gd:66, 67`), [[screen_assign#refresh]] (`screen_assign.gd:191`), [[hall_header#refresh]] (`hall_header.gd:175`), [[hall_header#_update_counter]] (`hall_header.gd:325`)

**Calls:** none.

### px_capped
`static func px_capped(base: int, max_factor: float) -> int:` · `Scripts/Hall/Style/hall_font_scale.gd:183`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `base` | `int` | Authored size in design px | the authored override size read by the calling function in this file |
| `max_factor` | `float` | Most it may grow (0 = no cap) | [[hall_font_scale#_max_factor_of]] |

**Returns:** `int`, at least 1.

**Side effects:** none

**Called by:** [[hall_font_scale#set_size]] (`hall_font_scale.gd:196`), [[hall_font_scale#scale_authored_overrides]] (`hall_font_scale.gd:235`), [[hall_font_scale#rescale_tree]] (`hall_font_scale.gd:247`)

**Calls:** none.

### set_size
`static func set_size(control: Control, name: StringName, base: int, max_factor: float = 0.0) -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:193`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `control` | `Control` | Control to set the override on | the label or button the caller is building or restyling |
| `name` | `StringName` | Font-size item name, usually `"font_size"` | literal at the call site |
| `base` | `int` | Authored size in design px | a `*_FONT_SIZE` constant, or the `font_size` argument of [[hall_style#style_button]], [[hall_fx#float_text]], [[hall_fx#_make_stamp]] |
| `max_factor` | `float` | Growth cap stored as `MAX_FACTOR_META` (0 = keep existing) | e.g. `MAX_FONT_FACTOR` (hall_nav.gd:54-55); omitted by most callers |

**Returns:** nothing.

**Side effects:** adds a theme font-size override on `control`; sets meta `_font_base_<name>` and, if `max_factor` > 0, `font_max_factor`.

**Called by:** [[hall_fx#float_text]] (`hall_fx.gd:285`), [[hall_fx#_make_stamp]] (`hall_fx.gd:397`), [[hall_style#style_button]] (`hall_style.gd:599`), [[crawl_sections#make_line]] (`crawl_sections.gd:95`), [[crawl_sections#_make_story]] (`crawl_sections.gd:128, 129`), [[stat_tile#setup]] (`stat_tile.gd:20`), [[overlay_intro#_show_text]] (`overlay_intro.gd:116`), [[overlay_report#_update_scroll_arrow]] (`overlay_report.gd:144`), [[overlay_tutorial#_build]] (`overlay_tutorial.gd:715, 732, 738, 748, 749, 760, 794`), [[overlay_welcome#_build_row]] (`overlay_welcome.gd:210, 215`), [[overlay_menu#setup]] (`overlay_menu.gd:54`), [[report_entry#_add_fold_hint]] (`report_entry.gd:231, 249`), [[party_slot#setup]] (`party_slot.gd:54`), [[hall_nav#setup]] (`hall_nav.gd:54, 55`)

**Calls:** [[hall_font_scale#px_capped]], [[hall_font_scale#_max_factor_of]]

### _max_factor_of
`static func _max_factor_of(control: Control) -> float:` · `Scripts/Hall/Style/hall_font_scale.gd:201`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `control` | `Control` | Control whose `MAX_FACTOR_META` is read | callers in this file |

**Returns:** `float` cap, 0.0 for none.

**Side effects:** none

**Called by:** [[hall_font_scale#set_size]] (`hall_font_scale.gd:196`), [[hall_font_scale#scale_authored_overrides]] (`hall_font_scale.gd:235`), [[hall_font_scale#rescale_tree]] (`hall_font_scale.gd:247`)

**Calls:** none.

### scale_theme
`static func scale_theme(theme: Theme) -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:207`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `theme` | `Theme` | Theme whose font sizes are rewritten | the theme given to [[hall_font_scale#init]] / [[hall_font_scale#set_text_factor]] |

**Returns:** nothing.

**Side effects:** first call stores `_theme_base_sizes`; sets `theme.default_font_size` and every theme font size.

**Called by:** [[hall_font_scale#init]] (`hall_font_scale.gd:104`), [[hall_font_scale#set_text_factor]] (`hall_font_scale.gd:114`)

**Calls:** [[hall_font_scale#px]]

> [!note] How it works
> Base sizes are recorded once (keys `"<type>/<name>"` plus `"default"`), so rescaling after a scene reload or a Text size change never compounds.

### scale_authored_overrides
`static func scale_authored_overrides(node: Node) -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:224`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | The node that just entered the tree; non-Controls are ignored | signal argument of `SceneTree.node_added` |

**Returns:** nothing.

**Side effects:** re-adds each untagged `.tscn` font-size override at the scaled size and tags it with `_font_base_*`.

**Called by:** no caller found in `Globals/`, `Scripts/` or `Scenes/`.

**Calls:** [[hall_font_scale#px_capped]], [[hall_font_scale#_max_factor_of]]

### rescale_tree
`static func rescale_tree(root: Node) -> void:` · `Scripts/Hall/Style/hall_font_scale.gd:241`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `root` | `Node` | Subtree to re-apply the factor to | `root` of [[hall_font_scale#set_text_factor]]; then each child (recursion) |

**Returns:** nothing.

**Side effects:** re-adds each tagged override at the current factor.

**Called by:** [[hall_font_scale#set_text_factor]] (`hall_font_scale.gd:116`)

**Calls:** [[hall_font_scale#px_capped]], [[hall_font_scale#_max_factor_of]]

## Suspected issues
- `Scripts/Hall/Style/hall_font_scale.gd:94` init's doc comment names the third parameter `text_factor`, but the parameter is `player_text_factor`.
