---
source: Scripts/UI/Rows/Buildings/home_row.gd
class_name: ""
extends: PanelContainer
scene: "[[home_row (scene)]]"
systems: ["[[Night - Training Hospital Revive]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# home_row.gd

## Purpose
One hero in a Training Yard or Hospital card (Upgrades > Facilities, see [[home_section]]). The card picks one of the `show_*` functions, and each fills the same row differently: training slot (stat picker and Remove), can train (Add, or "Move here" if they're in a quest's party), can't train (faded, with the reason), patient (nights left and Discharge), needs care (nights at home vs in a bed, and Admit), fallen (Revive at Hospital level 5). Scene: [[home_row (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `FADED_OPACITY` | const | Rows for heroes who can't do anything here fade back (0.6). |
| `TRAINING_CARD_BG`, `HOSPITAL_CARD_BG`, `HOSPITAL_BORDER` | const | Card colours for heroes in a slot / bed. |
| `SHOW_FREE_TASK` | const | SIMPLIFIED: the "Free today" chip (false; no chip already means free). |
| `TEXT_*`, `BUTTON_*` | const | UI strings (gain line, task chips, nights, revive notes, Remove / Add / Move here / Full / Discharge / Admit / Pull & admit / Revive). |
| `_portrait`, `_name`, `_role`, `_health_chip`, `_task_chip`, `_note`, `_side_button`, `_main_button`, `_stat_picker` | onready | `%Portrait` ([[portrait]]), `%Name`, `%Role`, `%HealthChip`, `%TaskChip` ([[chip]]), `%Note`, `%SideButton`, `%MainButton`, `%StatPicker`. |
| `hall` | var | The `HallMain`, set in [[home_row#_fill]]. |
| `character` | var | The hero shown, set in [[home_row#_fill]]. |

## Functions

### _fill
`func _fill(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:61`

Common part of every `show_*`: stores `hall` and `character`, fills portrait, name, role, health and task chip, resets the note, buttons, picker, opacity and card paper. If `hall.pending_fx["home_row"] == hero` the row pops in, deferred so a faded row fades up to faded and not solid.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The main hall | the `main` argument of each `show_*` |
| `hero` | `GuildCharacter` | The hero | the `hero` argument of each `show_*` |

**Returns:** nothing.

**Side effects:** sets `hall`, `character`; may defer [[home_row#_pop_in]].

**Called by:** [[home_row#show_training_slot]], [[home_row#show_can_train]], [[home_row#show_cant_train]], [[home_row#show_patient]], [[home_row#show_needs_care]], [[home_row#show_fallen]] (`home_row.gd:121`, `154`, `170`, `180`, `189`, `198`).

**Calls:** [[portrait#show_character]], [[hall_style#role_name]], [[chip#set_health]], [[home_row#_show_task_chip]], [[hall_style#style_panel]], [[home_row#_pop_in]].

### _pop_in
`func _pop_in() -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:82`

Fades the row in with a pop.

**Parameters:** none. **Returns:** nothing. **Side effects:** [[hall_fx#appear]] tween on the row.

**Called by:** [[home_row#_fill]] via `call_deferred` (`home_row.gd:79`).

**Calls:** [[hall_fx#appear]].

### _show_task_chip
`func _show_task_chip() -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:87`

"Free today" (visible only if `SHOW_FREE_TASK`), "Picked for #2" or "Sent on #2".

**Parameters:** none (reads `hall` and `character`). **Returns:** nothing. **Side effects:** sets `%TaskChip`.

**Called by:** [[home_row#_fill]] (`home_row.gd:68`).

**Calls:** [[hall_main#quest_index_of]], [[chip#set_chip]].

### _set_note
`func _set_note(text: String, color: Color = HallStyle.TEXT_SOFT) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:98`

Shows `%Note` with the text in the given ink.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Note text | built from `TEXT_*` constants in each `show_*` |
| `color` | `Color` | Ink; default `HallStyle.TEXT_SOFT` | e.g. `HallStyle.GREEN_TEXT` in [[home_row#show_training_slot]] |

**Returns:** nothing.

**Called by:** [[home_row#show_training_slot]], [[home_row#show_cant_train]], [[home_row#show_patient]], [[home_row#show_needs_care]], [[home_row#show_fallen]].

**Calls:** [[hall_style#set_font_color]].

### _set_button
`func _set_button(button: Button, text: String, kind: String, action: Callable) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:104`

Shows and enables a button, styles it (`kind`: "paper", "blue", "green"), drops its old `pressed` connections and connects `action`. (Rows are rebuilt each refresh, but the disconnect keeps a reused button from double-firing.)

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `button` | `Button` | `_side_button` or `_main_button` | the `show_*` functions |
| `text` | `String` | Button label | `BUTTON_*` constants |
| `kind` | `String` | Style kind for `HallStyle.style_button` | the `show_*` functions |
| `action` | `Callable` | What a tap does | `hall.train` / `stop_training` / `discharge` / `admit` / `revive` bound with `character` |

**Returns:** nothing.

**Side effects:** rewires `pressed` on the button.

**Called by:** [[home_row#show_training_slot]], [[home_row#show_can_train]], [[home_row#show_patient]], [[home_row#show_needs_care]], [[home_row#show_fallen]].

**Calls:** [[hall_style#style_button]].

### _nights_text
`func _nights_text(nights: int) -> String` · `Scripts/UI/Rows/Buildings/home_row.gd:114`

"1 night" / "3 nights".

**Parameters:** `nights` (`int`), from `GuildUpgrades.get_nights_until_healthy` in [[home_row#show_patient]] and [[home_row#show_needs_care]].

**Returns:** `String`, used inside the note text.

**Called by:** [[home_row#show_patient]] (`home_row.gd:183`), [[home_row#show_needs_care]] (`home_row.gd:192`).

**Calls:** [[hall_style#count_text]].

### show_training_slot
`func show_training_slot(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:120`

A hero in a Training Yard slot: note "Pow 12 → 13 tonight" in green, Remove button, green paper and the stat picker.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The main hall | `hall` in [[home_section]] |
| `hero` | `GuildCharacter` | A trainee | `trainees` in [[home_section#_show_training]] |

**Returns:** nothing.

**Side effects:** Remove calls `hall.stop_training` ([[hall_main#stop_training]]).

**Called by:** [[home_section#_show_training]] (`home_section.gd:91`).

**Calls:** [[home_row#_fill]], [[guild_upgrades#get_training_stat]], [[hall_style#stat_value]], [[guild_upgrades#get_training_gain]], [[home_row#_set_note]], [[home_row#_set_button]], [[hall_style#style_panel]], [[home_row#_show_stat_picker]].

### _show_stat_picker
`func _show_stat_picker(selected_stat: int) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:133`

One paper button per quest stat in that stat's ink; the one being drilled is tinted and has a check mark. Each button's `pressed` is rewired to `hall.train(character, stat_index)` ([[hall_main#train]]).

**Parameters:** `selected_stat` (`int`), the stat being trained from `GuildUpgrades.get_training_stat` in [[home_row#show_training_slot]].

**Returns:** nothing.

**Called by:** [[home_row#show_training_slot]] (`home_row.gd:128`).

**Calls:** [[hall_style#style_button]], [[hall_style#tint_art]], [[hall_style#icon_texture]].

### show_can_train
`func show_can_train(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:153`

A hero who can be added to the Training Yard. New trainees drill their best quest stat until the player picks another. The button is "Full" (disabled) with no free slot, "Move here" if they're in a quest's party, else "Add".

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The main hall | `hall` in [[home_section]] |
| `hero` | `GuildCharacter` | Candidate | `can_train` in [[home_section#_show_training]] |

**Returns:** nothing.

**Side effects:** the button calls `hall.train(character, best_stat)` ([[hall_main#train]]).

**Called by:** [[home_section#_show_training]] (`home_section.gd:101`).

**Calls:** [[home_row#_fill]], [[hall_style#stat_value]], [[guild_upgrades#has_free_training_slot]], [[home_row#_set_button]], [[hall_main#quest_index_of]].

### show_cant_train
`func show_cant_train(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:169`

A hero who can't train: faded, with "In a Hospital bed" or "Too hurt to train".

**Parameters:** `main` and `hero` as in [[home_row#show_can_train]]; `hero` comes from `cant_train` in [[home_section#_show_training]].

**Returns:** nothing.

**Called by:** [[home_section#_show_training]] (`home_section.gd:105`).

**Calls:** [[home_row#_fill]], [[home_row#_set_note]], [[guild_upgrades#is_patient]], [[hall_style#style_panel]].

### show_patient
`func show_patient(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:179`

A hero in a Hospital bed: "Healthy in N nights", orange paper, Discharge button (`hall.discharge`, [[hall_main#discharge]]).

**Parameters:** `main`, `hero` as above; `hero` from `patients` in [[home_section#_show_hospital]].

**Returns:** nothing.

**Called by:** [[home_section#_show_hospital]] (`home_section.gd:147`).

**Calls:** [[home_row#_fill]], [[guild_upgrades#get_nights_until_healthy]], [[home_row#_set_note]], [[home_row#_nights_text]], [[home_row#_set_button]], [[hall_style#style_panel]].

### show_needs_care
`func show_needs_care(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:188`

A hurt hero not in a bed: nights to heal at home vs in a bed, and Admit (`hall.admit`, [[hall_main#admit]]). If they're in a quest's party or training the button reads "Pull & admit" in paper style.

**Parameters:** `main`, `hero` as above; `hero` from `waiting` in [[home_section#_show_hospital]].

**Returns:** nothing.

**Called by:** [[home_section#_show_hospital]] (`home_section.gd:151`).

**Calls:** [[home_row#_fill]], [[guild_upgrades#get_nights_until_healthy]], [[home_row#_set_note]], [[home_row#_nights_text]], [[hall_main#quest_index_of]], [[guild_upgrades#is_training]], [[home_row#_set_button]].

### show_fallen
`func show_fallen(main: HallMain, hero: GuildCharacter) -> void` · `Scripts/UI/Rows/Buildings/home_row.gd:197`

A fallen hero. Revive button (`hall.revive`, [[hall_main#revive]]) when `GuildUpgrades.can_revive()` and the roster isn't full; otherwise a faded row with the reason (no free bed, revive used up, or "Revive at Hospital Lv N").

**Parameters:** `main`, `hero` as above; `hero` from `fallen` in [[home_section#_show_hospital]].

**Returns:** nothing.

**Called by:** [[home_section#_show_hospital]] (`home_section.gd:155`).

**Calls:** [[home_row#_fill]], [[guild_upgrades#can_revive]], [[hall_main#is_roster_full]], [[home_row#_set_note]], [[home_row#_set_button]], [[hall_style#style_panel]], [[guild_upgrades#get_level]].

## Suspected issues
- The file's header comment block says stat picker buttons are "Str / Def / Wis / Slz"; the scene's buttons are named `Pow`, `Def`, `Wis`, `Slz` (the labels come from `HallStyle.STATS[i].short`, so the header may be out of date).
- `_set_button` and `_show_stat_picker` disconnect `pressed` before connecting; harmless on a fresh row.
