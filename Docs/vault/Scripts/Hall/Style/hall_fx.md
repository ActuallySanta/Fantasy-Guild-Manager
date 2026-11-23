---
source: Scripts/Hall/Style/hall_fx.gd
class_name: HallFx
extends: RefCounted
scene: ""
systems: ["[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_fx.gd

## Purpose
Small bouncy animations that tie what the player did to what it changed: counters rolling, stamps landing, cards flying off. Every helper is static and creates its tween on the node it animates, so the tween dies with the node when a refresh rebuilds a row. Helpers that need a laid-out size wait one frame first. Things that must outlive a refresh (flying icons, floating numbers, stamps, curtains) are built on the hall's FX layer (`HallMain.fx_layer`, above the overlays, below Pip and the colorblind filter). Reduced Motion turns every helper into a no-op that leaves the node in its final state and runs any callback at once. No scene. Used by the tabs, screens, overlays, rows, header and [[hall_main]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `reduce_motion` | static var | True when Reduced Motion is on. Written by [[hall_main#set_reduce_motion]] (`hall_main.gd:1358`) and [[hall_main#_load_settings]] (`hall_main.gd:1377`). Read by this file's helpers and by [[hall_main#_hold_then_move_on]] (`hall_main.gd:1052`), [[hall_main#send_hired_letter]] (1107), [[hall_style#turn_caret]] (`hall_style.gd:719`), [[crawl_roll#start]] (`crawl_roll.gd:64`, 68), [[odds_bar#set_chance]] (22), [[overlay_report#_update_scroll_arrow]] (128), [[overlay_report#_play_reveal]] (179), [[report_entry#reveal]] (283), [[screen_assign#scroll_to_picker]] (182), [[hall_header#_refresh_day_tile]] (223), [[hall_header#land_earnings]] (248), [[header_popup#open]] (74). |
| `FLOAT_OUTLINE`, `FLOAT_OUTLINE_SIZE` | const | Cream outline colour and width (px) on floating numbers. |
| `FLOAT_RISE`, `FLOAT_SECONDS` | const | How far (px) a floating number rises and how long (s) it lives. |
| `STAMP_DROP_SCALE`, `STAMP_IMPACT_SCALE` | const | `stamp_onto`: scale the stamp starts at above the page (2.6) and squashes to on impact (0.9). |
| `STAMP_FALL_SECONDS`, `STAMP_SETTLE_SECONDS` | const | Seconds it falls and then settles. |
| `STAMP_PAGE_DIP` | const | Scale the page under the press dips to (0.96). |
| `SWING_START_ANGLE` | const | `swing_in`: starting angle in radians (0.26). |
| `SWING_CROSSINGS`, `SWING_SECONDS`, `SWING_FADE_SECONDS` | const | Times it crosses the middle (3), seconds the swing takes, seconds to fade in. |

No signals. Meta keys used on animated nodes: `fx_scale`, `fx_alpha`, `fx_move`, `fx_swing`, `fx_count`, `fx_flash` (current tween), `fx_resting_alpha`, `fx_flash_base`.

## Functions

### _wait_for_layout
`static func _wait_for_layout(node: Control) -> bool:` · `Scripts/Hall/Style/hall_fx.gd:51`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node whose size is needed | the `node` argument of the public helper that awaits it |

**Returns:** `bool`: false if the node left the tree before or during the frame wait, true otherwise. Callers `await` it and return on false.

**Side effects:** awaits `process_frame`.

**Called by:** [[hall_fx#pop]] (`hall_fx.gd:89`), [[hall_fx#pulse]] (`hall_fx.gd:103`), [[hall_fx#appear]] (`hall_fx.gd:123`), [[hall_fx#slide_in]] (`hall_fx.gd:159`), [[hall_fx#swing_in]] (`hall_fx.gd:180`), [[hall_fx#shake]] (`hall_fx.gd:197`), [[hall_fx#squash]] (`hall_fx.gd:211`), [[hall_fx#flip]] (`hall_fx.gd:226`)

**Calls:** none.

### _tween
`static func _tween(node: Node, key: StringName) -> Tween:` · `Scripts/Hall/Style/hall_fx.gd:60`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | Node the tween is created on | the animated node |
| `key` | `StringName` | Meta key naming one kind of motion (`fx_scale`, `fx_alpha`, `fx_move`, `fx_swing`, `fx_count`, `fx_flash`) | literal in each helper |

**Returns:** the new `Tween` (the previous one under `key`, if valid, is killed).

**Side effects:** creates a tween and stores it in the node's meta `key`.

**Called by:** [[hall_fx#pop]] (`hall_fx.gd:92`), [[hall_fx#pulse]] (`hall_fx.gd:106`), [[hall_fx#appear]] (`hall_fx.gd:127`), [[hall_fx#fade_in]] (`hall_fx.gd:146`), [[hall_fx#slide_in]] (`hall_fx.gd:163`), [[hall_fx#swing_in]] (`hall_fx.gd:184`), [[hall_fx#shake]] (`hall_fx.gd:200`), [[hall_fx#squash]] (`hall_fx.gd:214`), [[hall_fx#flip]] (`hall_fx.gd:231`), [[hall_fx#count]] (`hall_fx.gd:247`), [[hall_fx#flash_text]] (`hall_fx.gd:265`), [[hall_fx#_press_page]] (`hall_fx.gd:457`)

**Calls:** none.

### _center_pivot
`static func _center_pivot(node: Control) -> void:` · `Scripts/Hall/Style/hall_fx.gd:70`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to pivot about its centre | animated node |

**Returns:** nothing

**Side effects:** sets `node.pivot_offset`.

**Called by:** [[hall_fx#pop]] (`hall_fx.gd:91`), [[hall_fx#pulse]] (`hall_fx.gd:105`), [[hall_fx#appear]] (`hall_fx.gd:125`), [[hall_fx#flip]] (`hall_fx.gd:230`), [[hall_fx#fly_away]] (`hall_fx.gd:372`), [[hall_fx#_press_page]] (`hall_fx.gd:456`)

**Calls:** none.

### _resting_alpha
`static func _resting_alpha(node: CanvasItem) -> float:` · `Scripts/Hall/Style/hall_fx.gd:79`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `CanvasItem` | Node being faded in | animated node |

**Returns:** `float`, the alpha the node should fade up to (cached in meta `fx_resting_alpha`).

**Side effects:** first call stores meta `fx_resting_alpha`.

**Called by:** [[hall_fx#appear]] (`hall_fx.gd:121`), [[hall_fx#fade_in]] (`hall_fx.gd:144`), [[hall_fx#slide_in]] (`hall_fx.gd:157`), [[hall_fx#swing_in]] (`hall_fx.gd:178`)

**Calls:** none.

> [!note] How it works
> A fade that begins while another is still running would otherwise take the half-faded alpha as its target and leave the node see-through.

### pop
`static func pop(node: Control, peak := 1.15, delay := 0.0, duration := 0.3) -> void:` · `Scripts/Hall/Style/hall_fx.gd:88`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to bounce | the row, counter box or tile that just changed |
| `peak` | `float` | Scale at the top of the bounce (default 1.15) | per-call constants such as `HallNav.BADGE_POP`, `COUNTER_POP`, `ODDS_POP`, or literals like 1.03 / 1.08 |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | `HIRE_FLY_SECONDS` (hall_main.gd:1121), `NEW_PIP_DELAY` (upgrade_card.gd:65), literals 0.1 / 0.12 elsewhere |
| `duration` | `float` | Total seconds (default 0.3) | never passed by callers |

**Returns:** nothing

**Side effects:** tween on `fx_scale` (no-op under `reduce_motion`).

**Called by:** [[hall_main#_fly_hired_letter]] (`hall_main.gd:1121`), [[upgrade_card#_play_built]] (`upgrade_card.gd:65, 66`), [[party_slot#setup]] (`party_slot.gd:47`), [[quest_row#setup]] (`quest_row.gd:81`), [[screen_assign#_show_odds_change]] (`screen_assign.gd:297`), [[screen_character#_show_stats]] (`screen_character.gd:245`), [[hall_nav#refresh]] (`hall_nav.gd:84`), [[hall_header#_update_counter]] (`hall_header.gd:307`), [[tab_pack#_show_grid]] (`tab_pack.gd:148`), [[tab_shop#_show_goods]] (`tab_shop.gd:96, 98`)

**Calls:** [[hall_fx#_wait_for_layout]], [[hall_fx#_center_pivot]], [[hall_fx#_tween]]

### pulse
`static func pulse(node: Control, times := 3, peak := 1.12, delay := 0.0) -> void:` · `Scripts/Hall/Style/hall_fx.gd:102`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to pulse | `_drake_note` in [[hall_header#_refresh_day_tile]] |
| `times` | `int` | Number of pops (default 3) | `DRAKE_PULSES` (hall_header.gd:229) |
| `peak` | `float` | Scale at each peak | literal 1.08 (hall_header.gd:229) |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | `HallMain.DUSK_OUT_SECONDS` (hall_header.gd:229) |

**Returns:** nothing

**Side effects:** tween on `fx_scale`; repeats pop `times` times (no-op under `reduce_motion`).

**Called by:** [[hall_header#_refresh_day_tile]] (`hall_header.gd:229`)

**Calls:** [[hall_fx#_wait_for_layout]], [[hall_fx#_center_pivot]], [[hall_fx#_tween]]

### appear
`static func appear(node: Control, from_scale := 0.85, delay := 0.0, duration := 0.28) -> void:` · `Scripts/Hall/Style/hall_fx.gd:118`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to bring in | toast, home row, crawl footer |
| `from_scale` | `float` | Scale it settles from (default 0.85) | literals 0.8 (hall_toast.gd:33), 0.9 (home_row.gd:83), 0.85 (crawl_roll.gd:110) |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | literal 0.0 or omitted |
| `duration` | `float` | Seconds (default 0.28) | 0.25 in hall_toast.gd:33; omitted elsewhere |

**Returns:** nothing

**Side effects:** sets `modulate.a` to 0 at once, then tweens alpha and scale (`fx_scale`); no-op under `reduce_motion`.

**Called by:** [[crawl_roll#_on_scrolled]] (`crawl_roll.gd:110`), [[home_row#_pop_in]] (`home_row.gd:83`), [[hall_toast#show_message]] (`hall_toast.gd:33`), [[hall_fx#stamp_in]] (`hall_fx.gd:137`)

**Calls:** [[hall_fx#_resting_alpha]], [[hall_fx#_wait_for_layout]], [[hall_fx#_center_pivot]], [[hall_fx#_tween]]

### stamp_in
`static func stamp_in(node: Control, from_scale := 1.8, delay := 0.0) -> void:` · `Scripts/Hall/Style/hall_fx.gd:136`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node that slams down | the chip, stamp, tile or portrait being revealed |
| `from_scale` | `float` | Starting scale (default 1.8) | literals 1.2 to 2.4 at each call site |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | reveal time `at` in [[report_entry#reveal]] / [[overlay_report#_play_reveal]]; usually omitted |

**Returns:** nothing

**Side effects:** see [[hall_fx#appear]].

**Called by:** [[overlay_report#_play_reveal]] (`overlay_report.gd:184`), [[upgrade_card#_play_built]] (`upgrade_card.gd:64`), [[report_entry#reveal]] (`report_entry.gd:288, 294, 300`), [[party_slot#setup]] (`party_slot.gd:46`), [[pick_row#_show_pick_state]] (`pick_row.gd:107`), [[quest_row#setup]] (`quest_row.gd:80`), [[quest_tab#setup]] (`quest_tab.gd:46`), [[screen_character#_show_gear]] (`screen_character.gd:272`), [[tab_pack#_show_grid]] (`tab_pack.gd:146`), [[tab_shop#_show_goods]] (`tab_shop.gd:95`)

**Calls:** [[hall_fx#appear]]

> [!note] How it works
> Wrapper: `appear(node, from_scale, delay, 0.24)`. It isn't awaited, so it returns at once.

### fade_in
`static func fade_in(node: Control, delay := 0.0, duration := 0.22) -> void:` · `Scripts/Hall/Style/hall_fx.gd:141`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to fade in | the view, overlay, seat or beat being shown |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | reveal time `at` in [[report_entry#reveal]] / [[overlay_report#_play_reveal]]; else 0.0 |
| `duration` | `float` | Seconds (default 0.22) | `VIEW_FADE_SECONDS`, `FADE_IN_SECONDS`, `UNFOLD_SECONDS`, `REVEAL_LETTER_SECONDS` or literal 0.15 |

**Returns:** nothing

**Side effects:** sets `modulate.a` to 0, tween on `fx_alpha`; no-op under `reduce_motion`.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1824`), [[overlay_move_confirm#open]] (`overlay_move_confirm.gd:70`), [[overlay_report#_play_reveal]] (`overlay_report.gd:189`), [[overlay_equip_picker#open]] (`overlay_equip_picker.gd:58`), [[overlay_gear_confirm#_show]] (`overlay_gear_confirm.gd:85`), [[overlay_update_confirm#open]] (`overlay_update_confirm.gd:68`), [[report_entry#toggle_folded]] (`report_entry.gd:273`), [[report_entry#reveal]] (`report_entry.gd:286, 315, 317`), [[screen_assign#_show_party]] (`screen_assign.gd:252`), [[screen_character#_show_gear]] (`screen_character.gd:285`), [[header_popup#open]] (`header_popup.gd:75`)

**Calls:** [[hall_fx#_resting_alpha]], [[hall_fx#_tween]]

### slide_in
`static func slide_in(node: Control, offset: Vector2, delay := 0.0, duration := 0.3) -> void:` · `Scripts/Hall/Style/hall_fx.gd:154`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to slide | `_card` in [[header_popup#open]], `top_card` in [[tab_guild#_show_for_hire]] |
| `offset` | `Vector2` | How far away it starts | `Vector2(0, -DROP_DISTANCE)` (header_popup.gd:76), `NEXT_LETTER_SLIDE` (tab_guild.gd:189) |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | 0.0 |
| `duration` | `float` | Seconds (default 0.3) | `OPEN_SECONDS` (header_popup.gd:76) |

**Returns:** nothing

**Side effects:** moves `node.position`, tween on `fx_move`.

**Called by:** [[header_popup#open]] (`header_popup.gd:76`), [[tab_guild#_show_for_hire]] (`tab_guild.gd:189`)

**Calls:** [[hall_fx#_resting_alpha]], [[hall_fx#_wait_for_layout]], [[hall_fx#_tween]]

### swing_in
`static func swing_in(node: Control, nail_y := 0.0, delay := 0.0) -> void:` · `Scripts/Hall/Style/hall_fx.gd:175`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | The hanging sign | `_hanging_sign` in [[overlay_report#_play_reveal]] |
| `nail_y` | `float` | Pixels down the node's top middle where the nail is | `SIGN_NAIL_Y` (overlay_report.gd:193) |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | `minf(at, REVEAL_BUTTON_LATEST)` (overlay_report.gd:193) |

**Returns:** nothing

**Side effects:** sets `pivot_offset` and `rotation`, tween on `fx_swing`; rotation ends at 0.

**Called by:** [[overlay_report#_play_reveal]] (`overlay_report.gd:193`)

**Calls:** [[hall_fx#_resting_alpha]], [[hall_fx#_wait_for_layout]], [[hall_fx#_tween]]

> [!note] How it works
> A damped pendulum: `rotation = SWING_START_ANGLE * (1-t)^2 * cos(t * PI * SWING_CROSSINGS)`, over `SWING_SECONDS`, ending at 0.

### shake
`static func shake(node: Control, strength := 10.0, delay := 0.0, duration := 0.35) -> void:` · `Scripts/Hall/Style/hall_fx.gd:196`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to shake | `self` in [[report_entry#reveal]], `_writ`-card in [[screen_assign#shake_writ]] |
| `strength` | `float` | Peak sideways swing in px (default 10) | `REVEAL_DEATH_SHAKE` (report_entry.gd:304), `DENY_SHAKE` (screen_assign.gd:336) |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | reveal time `at` (report_entry.gd:304); 0.0 otherwise |
| `duration` | `float` | Seconds (default 0.35) | never passed |

**Returns:** nothing

**Side effects:** tween on `fx_move`, restores `position.x`.

**Called by:** [[report_entry#reveal]] (`report_entry.gd:304`), [[screen_assign#shake_writ]] (`screen_assign.gd:336`)

**Calls:** [[hall_fx#_wait_for_layout]], [[hall_fx#_tween]]

### squash
`static func squash(node: Control, delay := 0.0) -> void:` · `Scripts/Hall/Style/hall_fx.gd:210`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node that was built | `_icon.get_parent()` in [[upgrade_card#_play_built]] |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | omitted |

**Returns:** nothing

**Side effects:** sets `pivot_offset` (bottom middle), tween on `fx_scale`.

**Called by:** [[upgrade_card#_play_built]] (`upgrade_card.gd:62`)

**Calls:** [[hall_fx#_wait_for_layout]], [[hall_fx#_tween]]

### flip
`static func flip(node: Control, delay := 0.0, on_hidden := Callable()) -> void:` · `Scripts/Hall/Style/hall_fx.gd:225`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Node to flip | `_day_tile` in [[hall_header#_refresh_day_tile]] |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | `HallMain.DUSK_OUT_SECONDS * 0.5` (hall_header.gd:226) |
| `on_hidden` | `Callable` | Runs when the node is edge-on (swap the text there) | lambda setting `_day_value.text` (hall_header.gd:226) |

**Returns:** nothing

**Side effects:** tween on `fx_scale`; under `reduce_motion` calls `on_hidden` at once.

**Called by:** [[hall_header#_refresh_day_tile]] (`hall_header.gd:226`)

**Calls:** [[hall_fx#_wait_for_layout]], [[hall_fx#_center_pivot]], [[hall_fx#_tween]]

### count
`static func count(label: Label, from: int, to: int, duration := 0.45, fmt := "%d", delay := 0.0) -> void:` · `Scripts/Hall/Style/hall_fx.gd:241`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `label` | `Label` | Label to roll | `_odds_value` (screen_assign.gd:301), the counter label (hall_header.gd:306), the total gold label (overlay_report.gd:186) |
| `from` | `int` | Start number | previous value (`old_value`, `old_chance`, or 0) |
| `to` | `int` | End number | the new value |
| `duration` | `float` | Seconds (default 0.45) | `COUNTER_ROLL_SECONDS`, `ODDS_ROLL_SECONDS`, `REVEAL_GOLD_SECONDS` |
| `fmt` | `String` | Format taking one int, e.g. `"+%d gold"` | `TEXT_ODDS`, `_gold_format`, or default `%d` |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | `REVEAL_START` (overlay_report.gd:186); else 0.0 |

**Returns:** nothing

**Side effects:** writes `label.text`; tween on `fx_count`; under `reduce_motion` or `from == to` sets the final text at once.

**Called by:** [[overlay_report#_play_reveal]] (`overlay_report.gd:186`), [[screen_assign#_show_odds_change]] (`screen_assign.gd:301`), [[hall_header#_update_counter]] (`hall_header.gd:306`)

**Calls:** [[hall_fx#_tween]]

### flash_text
`static func flash_text(label: Control, color: Color, duration := 0.6) -> void:` · `Scripts/Hall/Style/hall_fx.gd:255`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `label` | `Control` | Control whose `font_color` flashes | counter label (hall_header.gd:308), `value_label` (screen_character.gd:246) |
| `color` | `Color` | Flash colour | `COUNTER_GAIN_INK` / `COUNTER_LOSS_INK`, `STAT_CHANGE_INK` |
| `duration` | `float` | Seconds to ease back (default 0.6) | `COUNTER_ROLL_SECONDS + 0.3` (hall_header.gd:308) |

**Returns:** nothing

**Side effects:** overrides the label's `font_color` then restores it; stores meta `fx_flash_base`.

**Called by:** [[screen_character#_show_stats]] (`screen_character.gd:246`), [[hall_header#_update_counter]] (`hall_header.gd:308`)

**Calls:** [[hall_fx#_tween]]

### float_text
`static func float_text(layer: Control, at: Vector2, text: String, color: Color, font_size := 34, delay := 0.0) -> void:` · `Scripts/Hall/Style/hall_fx.gd:278`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `layer` | `Control` | The hall's FX layer the effect is built on | `hall.fx_layer` / `fx_layer` (set up by [[hall_main]]) |
| `at` | `Vector2` | Global centre point to rise from | `hall.tap_point()` (screen_assign.gd:305), a point beside the counter (hall_header.gd:309-310) |
| `text` | `String` | e.g. `"+40"` | `DELTA_GAIN` / `DELTA_LOSS` formatted with the change (hall_header.gd:310), odds change text (screen_assign.gd:305) |
| `color` | `Color` | Ink colour | gain/loss ink constants |
| `font_size` | `int` | Design px (default 34), scaled by [[hall_font_scale#set_size]] | omitted |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | omitted |

**Returns:** nothing

**Side effects:** adds a `Label` to `layer`; frees it at the end.

**Called by:** [[screen_assign#_show_odds_change]] (`screen_assign.gd:305`), [[hall_header#_update_counter]] (`hall_header.gd:310`)

**Calls:** [[hall_font_scale#set_size]]

### fly
`static func fly(layer: Control, texture: Texture2D, from: Vector2, to: Vector2, icon_size := 44.0, delay := 0.0, duration := 0.5, on_land := Callable()) -> void:` · `Scripts/Hall/Style/hall_fx.gd:310`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `layer` | `Control` | The hall's FX layer the effect is built on | `hall.fx_layer` / `fx_layer` (set up by [[hall_main]]) |
| `texture` | `Texture2D` | Icon to fly (null = skip, run `on_land`) | `_counter_art(kind).texture` (hall_header.gd:262), `art.texture` (hall_header.gd:271) |
| `from` | `Vector2` | Global start point | `start` / `art.get_global_rect().get_center()` in [[hall_header#land_earnings]] / [[hall_header#pay_fx]] |
| `to` | `Vector2` | Global end point | `target` / `hall.tap_point()` |
| `icon_size` | `float` | Square size in px (default 44) | `FLY_ICON_SIZE` |
| `delay` | `float` | Seconds to wait before the motion starts (default 0) | per-icon `delay` |
| `duration` | `float` | Seconds (default 0.5) | `FLY_SECONDS` |
| `on_land` | `Callable` | Runs on arrival (or at once under Reduced Motion) | `land`: `_release_counter.bind(kind)` for the last coin, else an empty Callable ([[hall_header#land_earnings]]); omitted in [[hall_header#pay_fx]] |

**Returns:** nothing

**Side effects:** adds a `TextureRect` to `layer`; frees it after landing; under `reduce_motion` runs `on_land` at once.

**Called by:** [[hall_header#land_earnings]] (`hall_header.gd:262`), [[hall_header#pay_fx]] (`hall_header.gd:271`)

**Calls:** none.

> [!note] How it works
> Quadratic Bezier through a control point `bend` raised by `min(160, 60 + distance * 0.25)`.

### detach
`static func detach(node: Control, layer: Control) -> void:` · `Scripts/Hall/Style/hall_fx.gd:348`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Row or card to lift out of its list | `card` in [[hall_main#send_hired_letter]]; `node` of [[hall_fx#fly_away]] |
| `layer` | `Control` | The FX layer to reparent onto | `fx_layer` |

**Returns:** nothing

**Side effects:** reparents `node` to `layer`, keeps its screen rect, sets mouse filter IGNORE on the subtree.

**Called by:** [[hall_main#send_hired_letter]] (`hall_main.gd:1110`), [[hall_fx#fly_away]] (`hall_fx.gd:371`)

**Calls:** [[hall_fx#_ignore_mouse]]

### _ignore_mouse
`static func _ignore_mouse(node: Node) -> void:` · `Scripts/Hall/Style/hall_fx.gd:359`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | Subtree whose Controls get `MOUSE_FILTER_IGNORE` | the node or one of its children (recursion) |

**Returns:** nothing

**Side effects:** sets `mouse_filter` on the subtree.

**Called by:** [[hall_fx#detach]] (`hall_fx.gd:349`)

**Calls:** none.

### fly_away
`static func fly_away(node: Control, layer: Control, to: Vector2, duration := 0.5) -> void:` · `Scripts/Hall/Style/hall_fx.gd:368`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Control` | Card to send off; freed at the end | `card` in [[hall_main#_fly_hired_letter]] |
| `layer` | `Control` | FX layer | `fx_layer` |
| `to` | `Vector2` | Global target point | `roster_button.get_global_rect().get_center()` (hall_main.gd:1120) |
| `duration` | `float` | Seconds (default 0.5) | `HIRE_FLY_SECONDS` |

**Returns:** nothing

**Side effects:** detaches `node`, tweens it to `to`, then `queue_free`.

**Called by:** [[hall_main#_fly_hired_letter]] (`hall_main.gd:1120`)

**Calls:** [[hall_fx#detach]], [[hall_fx#_center_pivot]]

### _make_stamp
`static func _make_stamp(text: String, ink: Color, font_size: int) -> PanelContainer:` · `Scripts/Hall/Style/hall_fx.gd:386`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Stamp word | caller's `text` |
| `ink` | `Color` | Stamp colour (box and text) | caller's `ink` |
| `font_size` | `int` | Design px | caller's `font_size`, or 64 from [[hall_fx#stamp_mark]] |

**Returns:** the new stamp `PanelContainer` (not yet added to a parent).

**Side effects:** none

**Called by:** [[hall_fx#stamp_onto]] (`hall_fx.gd:420`), [[hall_fx#stamp_mark]] (`hall_fx.gd:467`)

**Calls:** [[hall_font_scale#set_size]]

### stamp_onto
`static func stamp_onto(target: Control, text: String, ink: Color, at := Vector2(0.72, 0.45), font_size := 52, tilt := -0.16, animate := true) -> Control:` · `Scripts/Hall/Style/hall_fx.gd:413`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `target` | `Control` | Card or row (PanelContainer) the ink sits on | `card` (hall_main.gd:1111), `self` (quest_row.gd:77), `_quest_card` (screen_assign.gd:321) |
| `text` | `String` | Stamp word | `STAMP_HIRED`, `TEXT_SENT_STAMP`, `TEXT_STAMP_SENT` |
| `ink` | `Color` | Ink | `HallStyle.GREEN_TEXT` |
| `at` | `Vector2` | Stamp centre as a fraction of the target size (default (0.72, 0.45)) | `HIRE_STAMP_AT`, `SENT_STAMP_AT` |
| `font_size` | `int` | Design px (default 52) | `HIRE_STAMP_FONT_SIZE` |
| `tilt` | `float` | Rotation in radians (default -0.16) | `HIRE_STAMP_TILT` |
| `animate` | `bool` | False = just leave the ink (a quest sent earlier) | `is_just_decided` (quest_row.gd:77), `is_just_sent` (screen_assign.gd:321); omitted (true) in hall_main.gd:1111 |

**Returns:** `Control`, the `StampInk` layer holding the stamp; free it to lift the ink off. The return value is kept by [[screen_assign#_show_writ_stamp]] as `_writ_stamp`; other callers ignore it.

**Side effects:** adds a `StampInk` Control with a stamp child to `target`; animates unless `animate` is false or `reduce_motion`; the page dips via [[hall_fx#_press_page]].

**Called by:** [[hall_main#send_hired_letter]] (`hall_main.gd:1111`), [[quest_row#setup]] (`quest_row.gd:77`), [[screen_assign#_show_writ_stamp]] (`screen_assign.gd:321`)

**Calls:** [[hall_fx#_make_stamp]], [[hall_fx#_press_page]]

> [!note] How it works
> Phases: fall (alpha in, scale `STAMP_DROP_SCALE` to `STAMP_IMPACT_SCALE`), impact (`_press_page`), settle (scale to 1).

### _press_page
`static func _press_page(page: Control) -> void:` · `Scripts/Hall/Style/hall_fx.gd:453`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `page` | `Control` | Card dipped under the stamp | bound as `_press_page.bind(target)` in [[hall_fx#stamp_onto]] |

**Returns:** nothing

**Side effects:** tween on `fx_scale` of the page.

**Called by:** [[hall_fx#stamp_onto]] (`hall_fx.gd:445`)

**Calls:** [[hall_fx#_center_pivot]], [[hall_fx#_tween]]

### stamp_mark
`static func stamp_mark(layer: Control, at: Vector2, text: String, ink: Color, hold := 0.45) -> void:` · `Scripts/Hall/Style/hall_fx.gd:464`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `layer` | `Control` | The hall's FX layer the effect is built on | `hall.fx_layer` / `fx_layer` (set up by [[hall_main]]) |
| `at` | `Vector2` | Global centre point | `_screens[SCREEN_ASSIGN].stamp_point()` (hall_main.gd:1017) |
| `text` | `String` | Word | `STAMP_DENIED` |
| `ink` | `Color` | Ink | `HallStyle.RED` |
| `hold` | `float` | Seconds it stays before fading (default 0.45) | `STAMP_HOLD_SECONDS` |

**Returns:** nothing

**Side effects:** adds a stamp to `layer`, frees it after fading (no-op under `reduce_motion`).

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1017`)

**Calls:** [[hall_fx#_make_stamp]]

### block_input
`static func block_input(layer: Control, seconds: float) -> void:` · `Scripts/Hall/Style/hall_fx.gd:486`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `layer` | `Control` | The hall's FX layer the effect is built on | `hall.fx_layer` / `fx_layer` (set up by [[hall_main]]) |
| `seconds` | `float` | How long taps are swallowed | `STAMP_HOLD_SECONDS` (hall_main.gd:1055) |

**Returns:** nothing

**Side effects:** adds a full-rect `MOUSE_FILTER_STOP` Control to `layer` for `seconds` (no-op under `reduce_motion`).

**Called by:** [[hall_main#_hold_then_move_on]] (`hall_main.gd:1055`)

**Calls:** none.

### curtain
`static func curtain(layer: Control, color: Color, at_peak: Callable, peak_alpha := 0.92, fade_in_seconds := 0.3, fade_out_seconds := 0.4) -> void:` · `Scripts/Hall/Style/hall_fx.gd:499`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `layer` | `Control` | The hall's FX layer the effect is built on | `hall.fx_layer` / `fx_layer` (set up by [[hall_main]]) |
| `color` | `Color` | Wash colour | `DUSK_INK` |
| `at_peak` | `Callable` | Runs while the screen is covered | `show_report`, `show_credits`, `begin`, `start_new_day` |
| `peak_alpha` | `float` | Opacity at the peak (default 0.92) | 0.92, or 1.0 for defeat (hall_main.gd:1589) |
| `fade_in_seconds` | `float` | Fade-in length (default 0.3) | `DUSK_IN_SECONDS` / `DEFEAT_DUSK_IN_SECONDS` |
| `fade_out_seconds` | `float` | Fade-out length (default 0.4) | `DUSK_OUT_SECONDS` / `DEFEAT_DUSK_OUT_SECONDS` |

**Returns:** nothing

**Side effects:** adds a full-screen `ColorRect` wash to `layer`; calls `at_peak` at the peak (at once under `reduce_motion`); frees the wash at the end.

**Called by:** [[hall_main#end_day]] (`hall_main.gd:1557`), [[hall_main#_show_final_credits]] (`hall_main.gd:1587, 1589`), [[hall_main#start_freeplay]] (`hall_main.gd:1717`), [[hall_main#close_report]] (`hall_main.gd:1731`)

**Calls:** none.

## Suspected issues
- None found. `_press_page` has no `HallFx._press_page(` caller in the index only because it is used as `_press_page.bind(target)` (`hall_fx.gd:445`).
