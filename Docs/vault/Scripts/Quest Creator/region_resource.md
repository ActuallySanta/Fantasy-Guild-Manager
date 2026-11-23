---
source: Scripts/Quest Creator/region_resource.gd
class_name: Region
extends: Resource
scene: null
systems: ["[[Quest Generation and Difficulty]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, resource]
---

# region_resource.gd

## Purpose
`Region`: one world region (Windswept Meadows, Boglands, Ashen Wastes, Glass Mountains, Capital City). It loads that region's location lists and its monsters from the text files in `External Content/Quest Stuff (Test)/` and hands out random names. [[quest_Manager]] builds the five regions; [[quest_resource]] reads them. The file paths stay `res://` paths (text data has no UID).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `dunegon_locations_test_path`, `monsters_2D_test_path` | export var (String) | Test data paths. `monsters_2D_test_path` (`2D Monster Test.txt`) is used for `regionMonsters`; the dungeon path is unused here. |
| `meadows_location_path`, `boglands_location_path`, `wastes_location_path`, `mountains_location_path`, `city_locations_path` | export var (String) | One location file per region. |
| `RegionType` | enum | `theWindsweptMeadows=0, theBoglands, theAshenWastes, theGlassMountains, theCapitalCity=4`. |
| `dungeonNames`, `escortLocations`, `explorationAreas`, `intelTargets` | var (`Array[String]`) | Columns 0-3 of the region's location file. |
| `regionNumber` | var (`RegionType`) | Which region this is. |
| `regionMonsters` | var (`Array[String]`) | Column `regionNum` of the monsters file (column 0 when the number is negative). |

## Functions

### _init
`func _init(regionNum := 0) -> void` · `Scripts/Quest Creator/region_resource.gd:43`

Constructor. Sets `regionNumber`, loads the four location columns from the file for `regionNum` (0-4), and loads the monster column. A `regionNum` outside 0-4 leaves the location lists empty.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `regionNum` | `int` | Region index 0-4 | literals `0` to `4` in [[quest_Manager]] (`quest_Manager.gd:9-13`) |

**Returns:** nothing (constructor).

**Side effects:** reads text files through [[multicolumn_procedural_loader]].

**Called by:** `Region.new(...)` for the five region variables of [[quest_Manager]] (`quest_Manager.gd:9`, `:10`, `:11`, `:12`, `:13`).

**Calls:** [[multicolumn_procedural_loader#_load_info_from_file]].

### returnName
`func returnName(questType: int) -> String` · `Scripts/Quest Creator/region_resource.gd:78`

A random location for a quest type: dungeon names for types 1 and 5, escort locations for 2, 6 and 8, exploration areas for 3 and 7, intel targets for 4. Type 0 (or anything else) uses the dungeon names.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `questType` | `int` | A `CreatedQuest.QuestType` | `type` read from the story file in [[quest_resource]] |

**Returns:** `String` location, stored in the quest's `location`.

**Side effects:** consumes the RNG.

**Called by:** [[quest_resource#_init]] (`quest_resource.gd:159`), [[quest_resource#_init_boss_vars]] (`:823`), [[quest_resource#_initMilestoneVars]] (`:839`, `:851`, `:863`, `:938`). Each is `QuestManager.world_regions[regionNum].returnName(type)`, a `Region`.

**Calls:** none.

### returnMonster
`func returnMonster() -> String` · `Scripts/Quest Creator/region_resource.gd:94`

A random monster name from `regionMonsters`.

**Parameters:** none.

**Returns:** `String`, used in the fight line by [[quest_resource#_combatEncounter]].

**Side effects:** consumes the RNG.

**Called by:** [[quest_resource#_combatEncounter]] (`quest_resource.gd:569`, `QuestManager.world_regions[regionNum].returnMonster()`).

**Calls:** none.

## Suspected issues
- `region_resource.gd:43`: `_init` has no case for a negative `regionNum`, although the monster line handles it (column 0).
- `region_resource.gd:8` `dunegon_locations_test_path` (sic) is never read.
