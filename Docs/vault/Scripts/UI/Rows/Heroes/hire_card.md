---
source: Scripts/UI/Rows/Heroes/hire_card.gd
class_name: ""
extends: PanelContainer
scene: "[[hire_card (scene)]]"
systems: ["[[Hiring Characters]]", "[[UI Architecture and Refresh]]"]
last_verified: 2fae2e0b444f59e9c76be8bda1b39c0f01fc4ea2
tags: [script]
---

# hire_card.gd

## Purpose
One applicant on the Guild tab, written as a letter of introduction: who they are, all five stats in boxes, a wax-sealed Hire button with their price, and their whole backstory under it (applicants have no Details page). Scene: [[hire_card (scene)]]. Created by [[tab_guild#_show_for_hire]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TEXT_HIRE` | const | "Hire · %dg": hiring costs the recruit's price in gold ([[character_container#hire_price]]: the base `GuildCharacter.cost` plus the roster-size surcharge). |
| `TEXT_HIRE_FREE` | const | Shown when cost is 0 (free on the first days). |
| `TEXT_NO_BEDS` | const | Shown, with the button disabled, when the roster is full. |
| `TEXT_TITLE` | const | `"%s the %s"`, the title line ("Juan the Priest"), like `GuildCharacter.title`. |
| `_portrait`, `_title`, `_stat_columns`, `_total`, `_drop_cap`, `_blurb`, `_hire_button` | onready | Scene nodes `%Portrait` ([[portrait]]), `%Name` (name and role in one label), `%Stats`, `%Total`, `%DropCap`, `%Blurb`, `%HireButton` ([[seal_button (scene)]]). |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Rows/Heroes/hire_card.gd:27`

The scene has one stat column (`StatTemplate`); this duplicates it `HallStyle.STAT_COUNT - 1` times so there is one per stat. Called by the engine.

**Called by:** the engine, when the card enters the tree.

**Calls:** none in the project (Node `duplicate`, `add_child`).

### setup
`func setup(hall: HallMain, recruit: GuildCharacter, _letter_index: int = 0) -> void` · `Scripts/UI/Rows/Heroes/hire_card.gd:35`

Writes the letter: portrait, one title line (`TEXT_TITLE % [recruit.name, role]`), the five stat boxes and their quest-stat total, the backstory with a red drop cap, and the Hire button (price, "free", or "No beds left" and disabled when `hall.is_roster_full()`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[tab_guild]] |
| `recruit` | `GuildCharacter` | The applicant | `recruits[_top_letter]`, with `recruits = CharacterContainer.hireable_characters`, in [[tab_guild#_show_for_hire]] |
| `_letter_index` | `int` | Unused since letters have no number; kept so callers don't change | `_top_letter` in [[tab_guild#_show_for_hire]] |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%HireButton` to [[hire_card#_on_hire_pressed]] bound with `hall` and `recruit`.

**Called by:** [[tab_guild#_show_for_hire]] (`tab_guild.gd:186`, `top_card.setup(hall, recruits[_top_letter], _top_letter)`).

**Calls:** [[portrait#show_character]], [[hall_style#role_name]], [[hall_style#stat_value]], [[hall_style#quest_stat_total]], [[hall_style#clean_backstory]], [[hall_main#is_roster_full]], [[character_container#hire_price]] (button text: price in gold, or "Hire · free" when 0).

### _on_hire_pressed
`func _on_hire_pressed(hall: HallMain, recruit: GuildCharacter) -> void` · `Scripts/UI/Rows/Heroes/hire_card.gd:65`

Hire, and if they joined, this letter flies off to the roster.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | bound in [[hire_card#setup]] |
| `recruit` | `GuildCharacter` | The applicant | bound in [[hire_card#setup]] |

**Returns:** nothing.

**Side effects:** [[hall_main#hire]] changes the roster and gold; on success [[hall_main#send_hired_letter]] animates the card away.

**Called by:** signal `pressed` on `%HireButton` (connected at `hire_card.gd:37`).

**Calls:** [[hall_main#hire]], [[hall_main#send_hired_letter]].

## Suspected issues
- `_letter_index` is unused (kept for callers, per its comment).
