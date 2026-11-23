---
source: Scripts/UI/Rows/Day End/report_entry.gd
class_name: ""
extends: TapPanel
scene: "[[report_entry (scene)]]"
systems: ["[[Quest Resolution and Injuries]]", "[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# report_entry.gd

## Purpose
One quest in the Day Report, written as a letter home: type seal, title, who sent it and at what odds, a Success / Failed stamp, who got hurt or died, what equipment was found, the standing lost, the story one line per beat, and a closing line signed by whoever came back. Everyday letters start folded (head, tags and a down caret); tapping one reads it and flips the caret up, tapping again folds it. Story quests (`HallStyle.is_story_quest`) never fold: they get gilt paper, a "Story Quest" ribbon and a star beside the lines of the written story. Extends [[tap_panel]]. Scene: [[report_entry (scene)]]. Created by [[overlay_report#_show_entries]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `opened` | signal | A folded letter was tapped open. Listener: `entry.opened.connect(hall.report_letter_opened)` ([[hall_main#report_letter_opened]]) in [[overlay_report#_show_entries]] (`overlay_report.gd:289`). |
| `BeatRowScene` | preload | `Scenes/Rows/Day End/beat_row.tscn` ([[beat_row (scene)]]), one per story line. |
| `ChipScene` | preload | `Scenes/Components/chip.tscn` ([[chip (scene)]]), the story ribbon. |
| `REVEAL_LETTER_SECONDS`, `REVEAL_STAMP_DELAY` | const | Seconds the letter takes to fade up, then before its stamp slams down (0.25, 0.18). |
| `REVEAL_TAG_GAP` | const | Seconds between each tag (Hurt, Died, Found) stamping in (0.14). |
| `REVEAL_DEATH_PAUSE`, `REVEAL_DEATH_SHAKE` | const | A death holds the letter this long (0.45 s) and shakes it this hard (9 px). |
| `REVEAL_BEAT_GAP`, `REVEAL_BEATS_MAX` | const | Seconds between story lines (0.06); a long story squeezes them into 0.7 s total. |
| `STAMP_ROOM_SIZE` | const | Room (design px) kept clear right of the title for the Success / Failed stamp, grown with the font scale. |
| `STORY_RECOLORS` | const | Dictionary of BBCode colour tags. `CreatedQuest.generateResults` writes bright colours meant for a dark screen; this swaps them for inks that read on parchment: `[color=FFE700]` and `[color=gold]` to `#6B5A1E`, `[color=green]` to `#3D5A2A`, `[color=FD0000]` and `[color=red]` to `#8B2E2A`, `[color=4FC3F7]` (equipment found, `CreatedQuest._find_equipment`) to `#2F4A66`. A new story colour needs an entry here. Applied in [[report_entry#_build_story_beats]]. |
| `SKIPPED_LINE_STARTS` | const | Story lines the letter says in its own words instead: "Summary", "However", "Equipment found". |
| `BEAT_ICON_RULES`, `BEAT_ICON_DEFAULT`, `BEAT_ICON_STORY` | const | Icon for a story line by its plain text (first matching rule wins: skull, swords, chest), default "scroll"; "star" for a written-story line. |
| `FOLD_HINT_FONT_SIZE`, `FOLD_HINT_MIN_WIDTH` | const | Text size of the "tap to read" hint, and the narrowest (px) before it wraps. |
| `UNFOLD_SECONDS` | const | Seconds the story takes to fade in when a folded letter is opened (0.18). |
| `FOLD_CARET_FONT_SIZE`, `FOLD_CARET_BOX_SIZE`, `FOLD_CARET_GAP`, `FOLD_CARET_TURN_SECONDS`, `TEXT_FOLD_CARET` | const | The caret before the hint: text size, the square box it turns in (design px), gap to the hint (px), flip time, and the glyph. |
| `TEXT_*` | const | UI strings: result stamp, from line, Hurt / Died / Found / standing tags, the win / loss sign-offs (gold, items, Pluck, trained-stat variants), ribbon, tap hints. |
| `_type_seal` ... `_standing_text`, `_beat_list`, `_closing_line`, `_head_text` | onready | Scene nodes `%TypeSeal`, `%TypeTag`, `%TypeIcon`, `%Title`, `%From`, `%Stamp`, `%StampText`, `%StampRoom`, `%HurtTag`, `%HurtText`, `%DiedTag`, `%DiedText`, `%FoundTag`, `%FoundText`, `%StandingTag`, `%StandingText`, `%Beats`, `%Closing`; `_head_text` is `%Title`'s parent. |
| `_foldable` | onready | `[$Col/Divider, _beat_list, $Col/Divider2, _closing_line]`: what a folded letter hides. |
| `is_story` | var | True for a story quest's letter (never folds). Read by `overlay_tutorial.gd:937` ([[overlay_tutorial#_report_letter]]). |
| `is_folded` | var | True while the story and sign-off are hidden. Read by `overlay_tutorial.gd:937`. |
| `_story_ribbon`, `_fold_hint`, `_fold_caret` | var | The story ribbon chip, the hint label, and the caret label (each null when not used). |
| `_is_success` | var | Whether the quest succeeded; picks the reveal sound. |

## Functions

### setup
`func setup(result: Dictionary, start_folded: bool = true) -> void` · `Scripts/UI/Rows/Day End/report_entry.gd:149`

Fills the whole letter from one quest result (`succeeded`, `quest`, `party`, `chance`, `died`, `injured`, `items`, `standing`, `story`, plus fields read by [[report_entry#_closing_text]]). The stamp is inked green on a success with no deaths, red otherwise. Story quests get the gilt look; everyday ones get the fold hint, `pressed` connected to [[report_entry#toggle_folded]], and start folded as asked.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `Dictionary` | One quest result from `hall_main._run_quest` ([[hall_main#_run_quest]]) | `results` passed to [[overlay_report#_show_entries]] |
| `start_folded` | `bool` | Whether an everyday letter starts folded | literal `true` in [[overlay_report#_show_entries]] |

**Returns:** nothing.

**Side effects:** connects `pressed` to [[report_entry#toggle_folded]] (everyday letters); adds hint nodes to the head.

**Called by:** [[overlay_report#_show_entries]] (`overlay_report.gd:287`).

**Calls:** [[hall_style#is_story_quest]], [[hall_font_scale#px_vec]], [[hall_style#quest_type_info]], [[hall_style#style_icon_tag]], [[hall_style#join_names]], [[hall_style#tint_art]], [[hall_style#set_font_color]], [[hall_style#story_lines]], [[report_entry#_build_story_beats]], [[report_entry#_closing_text]], [[report_entry#_show_story_look]], [[report_entry#_add_fold_hint]], [[report_entry#set_folded]].

### _show_story_look
`func _show_story_look() -> void` · `Scripts/UI/Rows/Day End/report_entry.gd:200`

Gilt paper and a "Story Quest" ribbon above the title, added as the first child of the head text.

**Parameters:** none. **Returns:** nothing.

**Called by:** [[report_entry#setup]] (`report_entry.gd:192`).

**Calls:** [[hall_style#style_panel]], [[chip#set_box]].

### _add_fold_hint
`func _add_fold_hint() -> void` · `Scripts/UI/Rows/Day End/report_entry.gd:211`

Builds, in code, the soft "Tap to read the letter" line under the From line, led by a caret (in a plain box so the row does not undo its turn); sets `_fold_hint` and `_fold_caret`. The hint wraps, because unwrapped it pushed the letter off screen at the biggest Text sizes.

**Parameters:** none. **Returns:** nothing.

**Called by:** [[report_entry#setup]] (`report_entry.gd:194`).

**Calls:** [[hall_font_scale#px]], [[hall_font_scale#set_size]], [[hall_style#set_font_color]].

### set_folded
`func set_folded(folded: bool) -> void` · `Scripts/UI/Rows/Day End/report_entry.gd:256`

Fold (hide the story and sign-off) or unfold an everyday letter; story letters stay open. Updates the hint text and flips the caret.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `folded` | `bool` | Wanted state (forced false for story letters) | `start_folded` in [[report_entry#setup]]; `not is_folded` in [[report_entry#toggle_folded]] |

**Returns:** nothing.

**Called by:** [[report_entry#setup]] (`report_entry.gd:196`), [[report_entry#toggle_folded]] (`report_entry.gd:270`).

**Calls:** [[hall_style#turn_caret]].

### toggle_folded
`func toggle_folded() -> void` · `Scripts/UI/Rows/Day End/report_entry.gd:269`

Flips the fold. When it opens, the foldable parts fade in over `UNFOLD_SECONDS` and `opened` is emitted.

**Parameters:** none. **Returns:** nothing.

**Side effects:** emits `opened`; [[hall_fx#fade_in]] tweens.

**Called by:** signal `pressed` on the letter (connected at `report_entry.gd:195`).

**Calls:** [[report_entry#set_folded]], [[hall_fx#fade_in]].

### reveal
`func reveal(delay: float) -> float` · `Scripts/UI/Rows/Day End/report_entry.gd:282`

Plays this letter in, starting `delay` seconds from now: fade up, the Success / Failed stamp slams down with its sound, the Hurt / Died / Found tags stamp in (a death holds and shakes the letter), then the story fills in line by line and the sign-off appears. A folded letter stops at its head. Does nothing when `HallFx.reduce_motion` is on.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `delay` | `float` | Seconds from now to start | running total `at` in [[overlay_report#_play_reveal]] |

**Returns:** `float`, how long the reveal takes in seconds (0.0 with reduced motion), so the report can start the next letter. [[overlay_report#_play_reveal]] adds `reveal(at) * REVEAL_LETTER_OVERLAP` to its clock (`overlay_report.gd:196`).

**Side effects:** [[hall_fx#fade_in]], [[hall_fx#stamp_in]], [[hall_fx#shake]] tweens; scheduled sounds `letter_success` / `letter_fail`, `hero_hurt`, `hero_died`, `item_found` via [[sound_effects#play_after]].

**Called by:** [[overlay_report#_play_reveal]] (`overlay_report.gd:196`).

**Calls:** [[hall_fx#fade_in]], [[hall_fx#stamp_in]], [[sound_effects#play_after]], [[hall_fx#shake]].

### _build_story_beats
`func _build_story_beats(story: String, story_lines: PackedStringArray = PackedStringArray()) -> void` · `Scripts/UI/Rows/Day End/report_entry.gd:324`

One [[beat_row (scene)]] per story line. First recolours the story text with `STORY_RECOLORS`; skips empty lines and ones starting with `SKIPPED_LINE_STARTS`; a line containing one of `story_lines` gets a gilt star, others an icon from `BEAT_ICON_RULES`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `story` | `String` | The quest's BBCode story | `result.story` in [[report_entry#setup]] |
| `story_lines` | `PackedStringArray` | A story quest's written story | `HallStyle.story_lines(result)` for story letters, else empty |

**Returns:** nothing.

**Called by:** [[report_entry#setup]] (`report_entry.gd:188`).

**Calls:** [[hall_style#strip_bbcode]], [[hall_style#add_row]], [[beat_row#setup]], [[report_entry#_is_story_line]], [[report_entry#_icon_for_beat]].

### _is_story_line
`func _is_story_line(plain_text: String, story_lines: PackedStringArray) -> bool` · `Scripts/UI/Rows/Day End/report_entry.gd:340`

True when a beat's plain text holds a line of the written story.

**Parameters:** `plain_text` (a line with BBCode stripped) and `story_lines` from [[report_entry#_build_story_beats]].

**Returns:** `bool`, used by [[report_entry#_build_story_beats]] (`report_entry.gd:333`) to choose the star icon.

**Called by:** [[report_entry#_build_story_beats]] (`report_entry.gd:333`).

### _icon_for_beat
`func _icon_for_beat(plain_text: String) -> String` · `Scripts/UI/Rows/Day End/report_entry.gd:347`

First `BEAT_ICON_RULES` entry whose text the line contains, else `BEAT_ICON_DEFAULT`.

**Parameters:** `plain_text` from [[report_entry#_build_story_beats]].

**Returns:** `String` icon name, passed to [[beat_row#setup]].

**Called by:** [[report_entry#_build_story_beats]] (`report_entry.gd:336`).

### _closing_text
`func _closing_text(result: Dictionary) -> String` · `Scripts/UI/Rows/Day End/report_entry.gd:355`

"Sorry, master. ... — M." signed with the initials of survivors. Picks among the win text (gold, gold plus Pluck, gold plus trained stat, item quest variants), the lost texts (with or without brought-back gold) and "Nobody came back to write this letter." Old results lack the `pluck`, `trained_stat`, `stat_gain`, `reward_items` keys, which default to none.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `Dictionary` | Quest result (`died`, `party`, `succeeded`, `gold`, `pluck`, `trained_stat`, `stat_gain`, `reward_items`) | `result` in [[report_entry#setup]] |

**Returns:** `String`, set as `%Closing` text in [[report_entry#setup]] (`report_entry.gd:189`).

**Called by:** [[report_entry#setup]] (`report_entry.gd:189`).

## Suspected issues
- None found.
