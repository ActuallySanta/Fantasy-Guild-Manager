---
source: Scripts/Quest Creator/quest_scoring.gd
class_name: QuestScoring
extends: RefCounted
scene: null
systems: ["[[Party Drafting and Assignment]]", "[[Success Chance]]", "[[Quest Resolution and Injuries]]", "[[Economy and Wallet]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# quest_scoring.gd

## Purpose
Static scoring rules for a quest: its odds, whether a played-out story was a win, what it pays, and how many heroes it takes. No nodes, no state. Used by [[hall_rules#play_quest]], [[hall_wallet#tonight_earnings]] (the expected-gold forecast) and [[hall_main]]'s party drafting. The quest itself is a [[quest_resource]] (`CreatedQuest`).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `DEFAULT_PARTY_SIZE` | const | 2 heroes. Used when a quest doesn't set `maxAdventurers`. |
| `FAIL_MARKER` | const | `"NOT SUCCESSFUL"`. The text [[quest_resource#generateResults]] writes into a failed quest's story. A loss must always contain it, since success is detected by searching for it. |

## Functions

### get_success_chance
`static func get_success_chance(quest: CreatedQuest, party: Array[GuildCharacter]) -> float` · `Scripts/Quest Creator/quest_scoring.gd:21`

The party's chance to win the quest, in percent. Forwards to [[quest_resource#calcSuccessChance]].

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest attempted | `entry.quest` in [[hall_rules#play_quest]]; `entry.quest` in [[hall_wallet#tonight_earnings]] |
| `party` | `Array[GuildCharacter]` | The heroes going | `entry.party` copied into a typed array in both callers |

**Returns:** `float` percent (0-100, can run past 100). [[hall_rules#play_quest]] passes it to `generateResults` and to the Pluck/training rules; [[hall_wallet#tonight_earnings]] clamps it to 0..1 and uses it as a win weight.

**Side effects:** none directly (`calcSuccessChance` rebuilds the party's temp stats).

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:362`), [[hall_wallet#tonight_earnings]] (`hall_wallet.gd:112`).

**Calls:** [[quest_resource#calcSuccessChance]].

### did_succeed
`static func did_succeed(story: String) -> bool` · `Scripts/Quest Creator/quest_scoring.gd:29`

Whether a played-out quest was won: `not story.contains(FAIL_MARKER)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `story` | `String` | The BBCode text `generateResults` returned | `story` local in [[hall_rules#play_quest]] |

**Returns:** `bool`, true on a win. [[hall_rules#play_quest]] uses it to pick gold, standing and training.

**Side effects:** none.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:373`).

**Calls:** none.

### get_gold_earned
`static func get_gold_earned(quest: CreatedQuest, succeeded: bool) -> int` · `Scripts/Quest Creator/quest_scoring.gd:40`

How much gold the guild actually gets. A win pays the full `goldReward`. A loss keeps only the bonus gold found along the way, `goldReward - startingGoldReward`. Item quests start at 0 gold, so they only ever pay that bonus.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest after `generateResults` has run (or before, for the forecast) | `entry.quest` |
| `succeeded` | `bool` | Whether it was won | [[quest_scoring#did_succeed]] in `play_quest`; `true` and `false` in the forecast |

**Returns:** `int` gold. [[hall_rules#play_quest]] pays it into `GameState`; [[hall_wallet#tonight_earnings]] weights the win and loss values by the odds.

**Side effects:** none.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:374`), [[hall_wallet#tonight_earnings]] (`hall_wallet.gd:114`, twice).

**Calls:** none.

### get_slot_count
`static func get_slot_count(quest: CreatedQuest) -> int` · `Scripts/Quest Creator/quest_scoring.gd:49`

How many heroes a quest takes: its `maxAdventurers`, or `DEFAULT_PARTY_SIZE` when that isn't above 0.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` in [[hall_main#party_size_limit]]; `self` in [[quest_resource#calcSuccessChance]] |

**Returns:** `int`. [[hall_main#party_size_limit]] returns it to the Assign Party screen; `calcSuccessChance` scales the requirement by it.

**Side effects:** none.

**Called by:** [[hall_main#party_size_limit]] (`hall_main.gd:641`), [[quest_resource#calcSuccessChance]] (`quest_resource.gd:264`).

**Calls:** none.

## Suspected issues
None found.
