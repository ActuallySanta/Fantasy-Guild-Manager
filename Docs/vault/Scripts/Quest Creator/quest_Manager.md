---
source: Scripts/Quest Creator/quest_Manager.gd
class_name: null
extends: Node
scene: null
systems: ["[[Boot and Autoload Order]]", "[[Quest Generation and Difficulty]]", "[[Quest Resolution and Injuries]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# quest_Manager.gd

## Purpose
Autoload `QuestManager` (`project.godot` line 24). Holds the five `Region` objects in `world_regions`, which quests and heroes pull locations, monsters and hometowns from, plus the story monsters used by minor and milestone quests. `_ready` also runs a leftover debug quest. No scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `thisQuest` | var | Debug quest made in `_ready` (declared as `= CreatedQuest`, the class). |
| `acceptedQuests` | var (`Array[CreatedQuest]`) | Declared, not used elsewhere. |
| `acceptedQuestResults` | var (`Array[String]`) | Story text of the debug quest, appended in `_ready`. |
| `monsters_2D_test_path` | export var (String) | `res://External Content/Quest Stuff (Test)/QuestMonsters.txt`, the story monsters file. |
| `theWindsweptMeadows`, `theBoglands`, `theAshenWastes`, `theGlassMountains`, `theCapitalCity` | var (`Region`) | `Region.new(0..4)` ([[region_resource#_init]]). |
| `world_regions` | var (Array) | The five regions in index order. Read as `QuestManager.world_regions[regionNum]` in [[quest_resource]] and `.pick_random()` in [[character_resource#_init]]. |
| `total_regions` | var (int) | 4. |
| `dayNum` | var | 0. Unused here. |
| `testQuestNumber` | var | Counter bumped in `_ready`. |
| `questMonsters` | var (Array) | Four columns of `monsters_2D_test_path`, loaded by [[multicolumn_procedural_loader]]. [[quest_Manager#_returnQuestMonster]] reads them. |

## Functions

### _ready
`func _ready() -> void` · `Scripts/Quest Creator/quest_Manager.gd:31`

Engine callback. Makes a debug quest (`CreatedQuest.new()`), a duo of random heroes, computes the success chance, plays the quest with one hero and stores the story in `acceptedQuestResults`; increments `testQuestNumber`. The result isn't shown anywhere.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** creates heroes and a quest, consumes the RNG, prints debug lines, may modify the throwaway heroes.

**Called by:** the engine (autoload `QuestManager` entering the tree).

**Calls:** [[quest_resource#_init]], [[quest_resource#generatePartyDuo]], [[quest_resource#calcSuccessChance]], [[quest_resource#generateResults]].

### _returnQuestMonster
`func _returnQuestMonster(col_idx: int) -> String` · `Scripts/Quest Creator/quest_Manager.gd:48`

A random monster (index 0 or 1) from the story-monster column `col_idx`. Also prints `col_idx`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `col_idx` | `int` | Column of `QuestMonsters.txt` (0-3) | literal `1`, `0`, `2` in [[quest_resource#_combatEncounter]] |

**Returns:** `String`, the monster name that [[quest_resource#_combatEncounter]] puts in the fight line.

**Side effects:** prints to the console.

**Called by:** [[quest_resource#_combatEncounter]] (`quest_resource.gd:573`, `:577`, `:579`).

**Calls:** none.

### _process
`func _process(delta: float) -> void` · `Scripts/Quest Creator/quest_Manager.gd:53`

Engine callback, every frame. Empty (`pass`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `delta` | `float` | Seconds since last frame | the engine |

**Returns:** nothing.

**Side effects:** none.

**Called by:** the engine.

**Calls:** none.

## Suspected issues
- `quest_Manager.gd:31` `_ready` builds a debug quest and heroes every launch (CLAUDE.md also notes it prints debug quests). `acceptedQuests`, `dayNum` and `total_regions` are unused.
- `quest_Manager.gd:48` `_returnQuestMonster` always picks index 0 or 1 of a column and prints the column index on every fight.
