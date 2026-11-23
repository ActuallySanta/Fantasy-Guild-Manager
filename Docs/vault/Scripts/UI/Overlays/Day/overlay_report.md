---
source: Scripts/UI/Overlays/Day/overlay_report.gd
class_name: ""
extends: Control
scene: "[[overlay_report (scene)]]"
systems: ["[[Day Cycle]]", "[[UI Motion and Feedback]]", "[[Quest Resolution and Injuries]]", "[[Night - Training Hospital Revive]]", "[[UI Architecture and Refresh]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# overlay_report.gd

## Purpose
The Day Report: the night's results as letters home. A torn strip of totals (wins, gold, hurt, dead chips), a line for what happened at home (training, healing), a line for the night's Hospital bill and anyone sent home unpaid, a line for heroes released that day, then one [[report_entry]] letter per quest. Story quests' letters come first and stay open; everyday letters start folded. After End Day it plays a reveal animation and its button starts the next day; opened from the Menu it just closes. Reads `HallMain.shown_report`. Scene: [[overlay_report (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `ReportEntryScene` | preload | [[report_entry (scene)]], one per letter. |
| `REVEAL_START` | const | Seconds after the report opens before the reveal starts. |
| `REVEAL_CHIP_GAP`, `REVEAL_GOLD_SECONDS` | const | Seconds between chips stamping in; the gold count-up duration. |
| `REVEAL_LETTER_OVERLAP` | const | Share of a letter after which the next one starts. |
| `REVEAL_BUTTON_LATEST` | const | Latest second at which the hanging sign swings in. |
| `SIGN_NAIL_Y` | const | Pixels below the top of the strings where the sign's nail sits. |
| `TOTALS_FONT_SIZE` | const | Chip text size on the totals strip. |
| `SCROLL_ARROW_HIDE_WITHIN`, `SCROLL_ARROW_MARGIN`, `SCROLL_ARROW_BOB_HEIGHT`, `SCROLL_ARROW_BOB_SPEED`, `SCROLL_ARROW_MIN_ALPHA`, `SCROLL_ARROW_FLASH_SPEED` | const | The "more letters below" arrow: hide threshold (px), gap (px), bob height (px) and speed (rad/s), lowest alpha (0..1) and flash speed (rad/s). |
| `SHOW_LETTERS_NOTE`, `SHOW_HOME_NOTE` | const | SIMPLIFIED switches (both false) for the "N letters tonight" and "At home: ..." lines. |
| `TEXT_HOSPITAL_BILL`, `TEXT_SENT_HOME_UNPAID` | const | "Hospital: −%d gold" and "%s went home: no gold for a bed", the lines [[overlay_report#_show_hospital]] builds. |
| `TEXT_*`, `BUTTON_START_DAY`, `BUTTON_CLOSE` | const | UI strings. `TEXT_GOLD_AND_ITEMS` keeps a `%d` for the gold so the reveal can count it up. |
| `hall` | var | The [[hall_main]] node. |
| `_built_report` | var | The report built on screen (skips identical rebuilds). |
| `_total_gold` | var | Night's gold, for the count-up. |
| `_gold_format` | var | Gold chip format tonight (`TEXT_GOLD` or the items variant). |
| `_arrow_time` | var | Seconds the scroll arrow has animated. |
| `_title`, `_letters_note`, `_succeeded_chip`, `_gold_chip`, `_injured_chip`, `_dead_chip`, `_home_note`, `_hospital_note`, `_released_note`, `_scroll`, `_entry_list`, `_empty_label`, `_action_button`, `_hanging_sign`, `_scroll_arrow` | onready | `%Title`, `%Sub`, `%WinsChip`, `%GoldChip`, `%HurtChip`, `%DeadChip` ([[chip]]), `%HomeNote`, `%HospitalNote`, `%ReleasedNote`, `%Scroll`, `%Entries`, `%Empty`, `%ActionButton`, its parent (the sign), `%ScrollArrow`. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:106`

Stores the hall, connects the action button, tints the scroll arrow gold.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] (`hall_main.gd:427`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%ActionButton` to [[hall_main#close_report]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_style#tint_art]].

### _process
`func _process(delta: float) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:112`

Engine callback each frame; drives the scroll arrow.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `delta` | `float` | Seconds since last frame | the engine |

**Returns:** nothing.

**Called by:** the engine.

**Calls:** [[overlay_report#_update_scroll_arrow]].

### _update_scroll_arrow
`func _update_scroll_arrow(delta: float) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:120`

Shows a bobbing, flashing arrow just above the bottom edge of the scroll area while more than `SCROLL_ARROW_HIDE_WITHIN` px of letters are hidden below. It holds still with `HallFx.reduce_motion`. When hidden it resets `_arrow_time`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `delta` | `float` | Seconds since last frame | `_process` |

**Returns:** nothing.

**Side effects:** sets `_scroll_arrow` visibility, `modulate.a` and position; also (see issues) sets the chips' font size.

**Called by:** [[overlay_report#_process]].

**Calls:** [[hall_font_scale#set_size]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:148`

Rebuilds the report only when a different one opened (compares `results`, `starts_next_day`, `day`, `home`, `released` of `hall.shown_report` with `_built_report`). Fills title, notes, totals, letters, and sets the button text ("Open the doors · Day N+1" when it starts the next day, else "Close"). Plays the reveal when `starts_next_day`.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`) while visible.

**Calls:** [[hall_style#count_text]], [[overlay_report#_show_totals]], [[overlay_report#_show_home]], [[overlay_report#_show_hospital]], [[overlay_report#_show_released]], [[overlay_report#_show_entries]], [[overlay_report#_play_reveal]].

### _play_reveal
`func _play_reveal() -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:182`

The night unfolds: chips stamp in, the gold counts up, notes (home, hospital, released) fade in, each letter reveals in turn, and the sign swings in. Skipped with Reduce Motion.

**Returns:** nothing.

**Side effects:** starts tweens through [[hall_fx]]; calls `reveal` on each letter.

**Called by:** [[overlay_report#refresh]].

**Calls:** [[hall_fx#stamp_in]], [[hall_fx#count]], [[hall_fx#fade_in]], [[hall_fx#swing_in]], [[report_entry#reveal]].

### _show_totals
`func _show_totals(results: Array) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:202`

Totals strip: successes of total, gold (plus item count if equipment was gained), hurt count (or "nobody hurt", hidden when someone died), death count.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `results` | `Array` | Per-quest result dictionaries | `report.results` in [[overlay_report#refresh]], built by [[hall_rules#play_quest]] |

**Returns:** nothing.

**Side effects:** sets `_total_gold`, `_gold_format` and the four chips.

**Called by:** [[overlay_report#refresh]].

**Calls:** [[chip#set_box]], [[hall_style#count_text]].

### _show_home
`func _show_home(home: Dictionary) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:239`

One line for who trained and who healed at home (see [[guild_upgrades#run_night]]); visible only with `SHOW_HOME_NOTE`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `home` | `Dictionary` | `{trained, healed}` lists | `report.get("home", {})` in [[overlay_report#refresh]] |

**Returns:** nothing.

**Called by:** [[overlay_report#refresh]].

### _show_hospital
`func _show_hospital(home: Dictionary) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:253`

The night's Hospital bill and anyone sent home because gold ran out. Builds one line per item into `%HospitalNote` (`TEXT_HOSPITAL_BILL` when `hospital_bill > 0`, then `TEXT_SENT_HOME_UNPAID` for each hero in `sent_home_unpaid`), joined by newlines, and shows the label only when there is at least one line.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `home` | `Dictionary` | The report's `home` dictionary, with `hospital_bill` (int) and `sent_home_unpaid` (Array of `GuildCharacter`) | `report.get("home", {})` in [[overlay_report#refresh]], from [[guild_upgrades#run_night]] via [[hall_main#end_day]] |

**Returns:** nothing.

**Side effects:** sets `_hospital_note.text` and visibility. [[overlay_report#_play_reveal]] fades the note in when visible.

**Called by:** [[overlay_report#refresh]] (`overlay_report.gd:166`).

**Calls:** none.

### _show_released
`func _show_released(released: Array) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:267`

One line for heroes released today, with the standing each cost; fallen heroes are marked "(fallen)".

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `released` | `Array` | `{character, fallen, standing}` entries | `report.get("released", [])` in [[overlay_report#refresh]] |

**Returns:** nothing.

**Called by:** [[overlay_report#refresh]].

### _show_entries
`func _show_entries(results: Array) -> void` · `Scripts/UI/Overlays/Day/overlay_report.gd:281`

Adds one [[report_entry]] letter per result (story quests first), shows the "Nobody went out" note when empty, scrolls to top.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `results` | `Array` | Per-quest results | `report.results` in [[overlay_report#refresh]] |

**Returns:** nothing.

**Side effects:** rebuilds `%Entries`; connects each letter's `opened` signal to [[hall_main#report_letter_opened]] (which emits `tutorial_event("read_letter")` for [[overlay_tutorial]]).

**Called by:** [[overlay_report#refresh]].

**Calls:** [[hall_style#clear_children]], [[hall_style#is_story_quest]], [[hall_style#add_row]] (passes `ReportEntryScene`), [[report_entry#setup]].

## Suspected issues
- `overlay_report.gd:142-142`: the loop that sets the chips' font size (`HallFontScale.set_size` and `TitleLabel` variation) sits at the end of `_update_scroll_arrow`, after the early `return`. It runs every frame while the arrow is visible and never while it is hidden, so the chip text is unscaled when there is no arrow. It looks like it belongs in `setup`.
