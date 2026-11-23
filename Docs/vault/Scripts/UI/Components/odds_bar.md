---
source: Scripts/UI/Components/odds_bar.gd
class_name: ""
extends: TextureProgressBar
scene: "[[odds_bar (scene)]]"
systems: ["[[Success Chance]]", "[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# odds_bar.gd

## Purpose
Success-chance bar: a hatched fill in the odds ink over a paper track, with quarter ticks on top. Art: `odds_track.png` (under), `odds_fill.png` (white so it can be tinted), `odds_over.png` (border and ticks on top), all in `Sprites/UI Textures/`. Scene: [[odds_bar (scene)]], placed once in [[screen_assign (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SLIDE_SECONDS` | const | Seconds the fill takes to slide to a new chance when animated (0.4). |
| `_slide_tween` | var | The running slide tween, killed when a new chance arrives. |

## Functions

### set_chance
`func set_chance(chance: int, animate := false) -> void` · `Scripts/UI/Components/odds_bar.gd:17`

Sets the bar to `chance` (0 to 100, or -1 for "no party yet", an empty bar), tints the fill with `HallStyle.odds_look(chance).bar_color`, and either jumps there or slides with an overshoot (back/out). With `HallFx.reduce_motion` it always jumps.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `chance` | `int` | 0..100, or -1 for no party | `shown` in [[screen_assign#_show_odds_change]], the success chance of the picked party |
| `animate` | `bool` | Slide the fill there | `true` in [[screen_assign#_show_odds_change]] when the same quest's chance changed; default false |

**Returns:** nothing.

**Side effects:** sets `tint_progress` and `value`; may start a tween.

**Called by:** [[screen_assign#_show_odds_change]] (`screen_assign.gd:293` without animation, `screen_assign.gd:296` with).

**Calls:** [[hall_style#odds_look]].

## Suspected issues
- None found.
