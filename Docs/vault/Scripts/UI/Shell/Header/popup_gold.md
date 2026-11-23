---
source: Scripts/UI/Shell/Header/popup_gold.gd
class_name: ""
extends: HeaderPopup
scene: "[[popup_gold (scene)]]"
systems: ["[[Economy and Wallet]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# popup_gold.gd

## Purpose
The gold popup that drops from the header's coin ([[header_popup]]). It shows the guild's gold, what gold is, what tonight's quests could pay (if all win, and about how much at today's odds), and where gold can be spent (hiring, gear, building upgrades), each with a price tag that is green when the guild can pay it. A red note shows when tomorrow's recruits cost more than the gold in hand ([[hall_ledger#is_short_of_recruit_gold]]). Scene: [[popup_gold (scene)]]. No `class_name`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TITLE`, `DESCRIPTION`, `EARN_*`, `SPEND_HEADING`, `HIRE_*`, `GEAR_*`, `UPGRADE_*`, `PRICE*`, `WARNING_SHORT` | const | Text strings and price formats (see the script's TEXT section). |
| `_title`, `_value`, `_description`, `_earn_*`, `_warning*`, `_spend_heading`, `_hire_*`, `_gear_*`, `_upgrade_*` | var | `@onready` nodes by unique name, see [[popup_gold (scene)]]. |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Shell/Header/popup_gold.gd:66`

Called by the engine. Runs `super()` ([[header_popup#_ready]]), writes the fixed texts, and styles the earnings box (neutral) and the warning (red).

**Called by:** the engine. **Calls:** [[header_popup#_ready]], [[hall_style#flat_box]], [[hall_style#set_font_color]].

### refresh
`func refresh() -> void` · `Scripts/UI/Shell/Header/popup_gold.gd:79`

Fills the card from the game: gold, the earnings box, the red recruit warning, and the three spending rows (hire: today's recruit price, blocked when none will come; gear: cheapest item in today's stock, or sold out; upgrade: cheapest next building level, or maxed / needs standing).

**Returns:** nothing.

**Side effects:** sets label texts and price tag styles.

**Called by:** [[header_popup#open]] (`header_popup.gd:72`), [[hall_header#refresh]] (`hall_header.gd:179`, while open).

**Calls:** [[popup_gold#_refresh_earnings]], [[hall_wallet#recruit_price]], [[character_resource#recruit_cost_for_day]], [[hall_ledger#is_short_of_recruit_gold]], [[hall_wallet#are_recruits_blocked]], [[hall_wallet#cheapest_gear_price]], [[hall_wallet#cheapest_upgrade]], [[popup_gold#_set_price]].

### _refresh_earnings
`func _refresh_earnings() -> void` · `Scripts/UI/Shell/Header/popup_gold.gd:111`

The earnings box: what the sent quests pay if they all win, about how much at today's odds, and how many quests still wait on the board.

**Returns:** nothing. Reads `hall.quest_entries` through [[hall_wallet#tonight_earnings]] (keys `sent_count`, `best`, `expected`, `open_count`, `open_best`).

**Called by:** [[popup_gold#refresh]] (`popup_gold.gd:82`). **Calls:** [[hall_wallet#tonight_earnings]], [[hall_style#set_font_color]], [[hall_style#count_text]].

### _set_price
`func _set_price(tag: Label, text: String, can_pay: bool) -> void` · `Scripts/UI/Shell/Header/popup_gold.gd:129`

A price tag: green when the guild can pay it, plain otherwise.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tag` | `Label` | The price label (its parent `PanelContainer` is restyled) | `_hire_price`, `_gear_price`, `_upgrade_price` in [[popup_gold#refresh]] |
| `text` | `String` | Price text (`"free"`, `"from 40"`, `"—"`) | built in [[popup_gold#refresh]] |
| `can_pay` | `bool` | True when gold covers it | comparisons with `gold` in [[popup_gold#refresh]] |

**Called by:** [[popup_gold#refresh]] (`popup_gold.gd:92`, `:97`, `:103`, `:106`). **Calls:** [[hall_style#flat_box]], [[hall_style#set_font_color]].

## Suspected issues
- `WARNING_SHORT` ("Lose your last hero and the guild falls.") is shown on `is_short_of_recruit_gold()` alone, while the header strip ([[hall_header#_refresh_danger_strip]]) also requires the roster to be down to one hero; the popup text can therefore appear with several heroes. Not traced further.
