---
source: Scripts/Hall/Rules/hall_wallet.gd
class_name: HallWallet
extends: null
scene: null
systems: ["[[Success Chance]]", "[[Economy and Wallet]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_wallet.gd

## Purpose
The numbers behind the header's gold and standing popups ([[popup_gold]], [[popup_standing]]): what standing unlocks next and how far it is from the floor where recruits stop coming; what tonight's quests could pay and what gold can buy right now. No state and no nodes. Every function is static and reads the autoloads or takes what it needs.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `LOSS_WINDOW` | const | 20 standing above `GuildUpgrades.MINIMUM_STANDING` at which the popup's red "loss" half reads empty. Closer to the floor than this, it fills up. |

## Functions

### standing_milestones
`static func standing_milestones() -> Array[Dictionary]` · `Scripts/Hall/Rules/hall_wallet.gd:24`

Every standing milestone, lowest first: `{at: int, kind: String, value: int}`.
- `"rank_appears"`: quests of rank `value` (1) start to show up, at `HallRules.STARTER_STANDING + 1`.
- `"rank"`: quests center on rank `value` (1 to `TOP_STANDING_RANK`), at `STANDING_PER_RANK * rank + 1`.
- `"upgrade"`: buildings can be upgraded to level `value`, at each non-zero `GuildUpgrades.UPGRADE_STANDING_REQ`.

Built from [[hall_rules]] and [[guild_upgrades]] tuning, so it follows them.

**Parameters:** none.

**Returns:** `Array[Dictionary]`, sorted by `at`. Used by [[hall_wallet#next_standing_milestone]] and [[hall_wallet#previous_standing_mark]].

**Side effects:** none.

**Called by:** [[hall_wallet#next_standing_milestone]] (`hall_wallet.gd:42`), [[hall_wallet#previous_standing_mark]] (`hall_wallet.gd:52`).

**Calls:** none (reads constants of [[hall_rules]] and [[guild_upgrades]]).

### next_standing_milestone
`static func next_standing_milestone(standing: int) -> Dictionary` · `Scripts/Hall/Rules/hall_wallet.gd:41`

The first milestone above `standing`, or `{}` once every one is reached.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | Guild standing | `standing` local in [[popup_standing#refresh]] |

**Returns:** `Dictionary` (a milestone, or `{}`). [[popup_standing#refresh]] builds the "next unlock" text from it; [[hall_wallet#gain_fill]] uses it as the bar's end.

**Side effects:** none.

**Called by:** [[hall_wallet#gain_fill]] (`hall_wallet.gd:61`), [[popup_standing#refresh]] (`popup_standing.gd:78`).

**Calls:** [[hall_wallet#standing_milestones]].

### previous_standing_mark
`static func previous_standing_mark(standing: int) -> int` · `Scripts/Hall/Rules/hall_wallet.gd:50`

Where the green "gain" half starts: the last milestone reached, or `GuildUpgrades.MINIMUM_STANDING` (the recruit floor) when none has been reached.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | Guild standing | argument of [[hall_wallet#gain_fill]] |

**Returns:** `int` standing value. Used by [[hall_wallet#gain_fill]] as the start of the bar.

**Side effects:** none.

**Called by:** [[hall_wallet#gain_fill]] (`hall_wallet.gd:64`).

**Calls:** [[hall_wallet#standing_milestones]].

### gain_fill
`static func gain_fill(standing: int) -> float` · `Scripts/Hall/Rules/hall_wallet.gd:60`

How full the gain half is (0..1): progress from [[hall_wallet#previous_standing_mark]] to the next milestone. 1.0 once every milestone is reached.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | Guild standing | `standing` local in [[popup_standing#refresh]] |

**Returns:** `float` 0..1. [[popup_standing#refresh]] assigns it to `_gain_bar.value`.

**Side effects:** none.

**Called by:** [[popup_standing#refresh]] (`popup_standing.gd:79`).

**Calls:** [[hall_wallet#next_standing_milestone]], [[hall_wallet#previous_standing_mark]].

### standing_above_floor
`static func standing_above_floor(standing: int) -> int` · `Scripts/Hall/Rules/hall_wallet.gd:69`

Standing left before recruits stop coming (0 or less means they already have): `standing - GuildUpgrades.MINIMUM_STANDING`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | Guild standing | `standing` local in [[popup_standing#refresh]] |

**Returns:** `int`. [[popup_standing#refresh]] stores it as `room`; [[hall_wallet#loss_fill]] derives the bar from it.

**Side effects:** none.

**Called by:** [[hall_wallet#loss_fill]] (`hall_wallet.gd:76`), [[popup_standing#refresh]] (`popup_standing.gd:72`).

**Calls:** none.

### loss_fill
`static func loss_fill(standing: int) -> float` · `Scripts/Hall/Rules/hall_wallet.gd:75`

How full the loss half is (0..1): empty at `LOSS_WINDOW` or more above the floor, full at the floor.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | Guild standing | `standing` local in [[popup_standing#refresh]] |

**Returns:** `float` 0..1. [[popup_standing#refresh]] assigns it to `_loss_bar.value`.

**Side effects:** none.

**Called by:** [[popup_standing#refresh]] (`popup_standing.gd:73`).

**Calls:** [[hall_wallet#standing_above_floor]].

### standing_rank_letter
`static func standing_rank_letter(standing: int) -> String` · `Scripts/Hall/Rules/hall_wallet.gd:80`

Letter of the rank this much standing centers quests on ("F", "D", ...).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | Guild standing | `standing` local in [[popup_standing#refresh]] |

**Returns:** `String`, put into the popup's rank line (`RANK_LINE`).

**Side effects:** none.

**Called by:** [[popup_standing#refresh]] (`popup_standing.gd:69`).

**Calls:** [[hall_wallet#rank_name]], [[hall_rules#standing_rank_for]].

### rank_name
`static func rank_name(rank: int) -> String` · `Scripts/Hall/Rules/hall_wallet.gd:85`

A `CreatedQuest.QuestDifficulty` value as its letter (`QuestDifficulty.find_key(rank)`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `rank` | `int` | A quest difficulty | `milestone.value` in [[popup_standing#_milestone_text]], or [[hall_rules#standing_rank_for]] |

**Returns:** `String` letter, used inside milestone sentences.

**Side effects:** none.

**Called by:** [[hall_wallet#standing_rank_letter]] (`hall_wallet.gd:81`), [[popup_standing#_milestone_text]] (`popup_standing.gd:94`, `popup_standing.gd:96`).

**Calls:** none.

### tonight_earnings
`static func tonight_earnings(entries: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_wallet.gd:96`

What tonight's quests could pay. Open entries add to `open_*`; sent entries add to `best` and, weighted by the party's odds (clamped 0..1), to `expected`. A loss still pays what [[quest_scoring#get_gold_earned]] says (gold found along the way).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entries` | `Array` | Quest entries ([[hall_rules#new_entry]] dictionaries) | `hall.quest_entries` ([[hall_main]]) in [[popup_gold#_refresh_earnings]] |

**Returns:** `Dictionary` `{best: int (every sent quest wins), expected: int (each weighted by its odds), sent_count: int, open_count: int (still waiting for Send or Deny), open_best: int (what those open ones pay on a win)}`. [[popup_gold#_refresh_earnings]] shows them.

**Side effects:** none.

**Called by:** [[popup_gold#_refresh_earnings]] (`popup_gold.gd:112`).

**Calls:** [[quest_scoring#get_success_chance]], [[quest_scoring#get_gold_earned]].

### recruit_price
`static func recruit_price() -> int` · `Scripts/Hall/Rules/hall_wallet.gd:120`

What a new recruit costs to hire today: [[character_resource#recruit_cost_for_day]] of `GameState.day`. This is the base price (the cheapest a recruit can be); [[hire_scaling#recruit_cost]] may add to it per recruit.

**Parameters:** none.

**Returns:** `int` gold, shown in the gold popup's recruit line.

**Side effects:** none.

**Called by:** [[popup_gold#refresh]] (`popup_gold.gd:84`).

**Calls:** [[character_resource#recruit_cost_for_day]].

### are_recruits_blocked
`static func are_recruits_blocked() -> bool` · `Scripts/Hall/Rules/hall_wallet.gd:125`

Whether standing is too low for any recruit to come (`GameState.standing <= GuildUpgrades.MINIMUM_STANDING`).

**Parameters:** none.

**Returns:** `bool`, used by [[popup_gold#refresh]] to pick the recruit line's state.

**Side effects:** none.

**Called by:** [[popup_gold#refresh]] (`popup_gold.gd:90`).

**Calls:** none.

### cheapest_gear_price
`static func cheapest_gear_price() -> int` · `Scripts/Hall/Rules/hall_wallet.gd:130`

The cheapest gear still on sale in the shop today, or -1 if it's sold out.

**Parameters:** none.

**Returns:** `int` gold, -1 when every item is sold. [[popup_gold#refresh]] shows it in the gear line.

**Side effects:** none.

**Called by:** [[popup_gold#refresh]] (`popup_gold.gd:95`).

**Calls:** [[item_shop#is_sold]], [[item_shop#get_item]].

### cheapest_upgrade
`static func cheapest_upgrade() -> Dictionary` · `Scripts/Hall/Rules/hall_wallet.gd:143`

The cheapest building upgrade (implemented, not max level), or `{}` when every building is maxed: `{gold: int, standing_short: bool}` (standing is too low to buy it yet).

**Parameters:** none.

**Returns:** `Dictionary`. [[popup_gold#refresh]] shows it in the upgrade line.

**Side effects:** none.

**Called by:** [[popup_gold#refresh]] (`popup_gold.gd:100`).

**Calls:** [[guild_upgrades#is_implemented]], [[guild_upgrades#is_max_level]], [[guild_upgrades#get_next_gold_cost]], [[guild_upgrades#get_upgrade_status]].

## Suspected issues
None found.
