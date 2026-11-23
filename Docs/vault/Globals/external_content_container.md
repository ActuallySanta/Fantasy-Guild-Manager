---
source: Globals/external_content_container.gd
class_name: null
extends: Node
scene: null
systems: ["[[Boot and Autoload Order]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# external_content_container.gd

## Purpose
Autoload `ExternalContentContainer`. Loads every text asset at startup (hero names, backstories, monster and location names, quest story parts) from `External Content/` into arrays, and serves them to character, item and quest generation. It is the first autoload, so `GuildCharacter.new()` and item naming fail if it hasn't run. The file paths stay `res://` strings because text files have no UID (comment at `external_content_container.gd:3-5`). It has no class doc comment. It has no scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `character_m_names_file_path`, `character_f_names_file_path`, `character_a_names_file_path` | var (`@export`, String) | CSV files of male, female and androgynous names (lines 6-8). |
| `location_names_file_path` | var (`@export`, String) | Declared with no default and never read (line 9). |
| `knight_`, `priest_`, `pathfinder_`, `mage_`, `random_backstories_file_path` | var (`@export`, String) | CSV backstory templates per role, plus the random pool (lines 11-15). |
| `dunegon_locations_test_path` | var (`@export`, String) | Pipe-delimited location names, 4 columns (line 17, the name's spelling is as in code). |
| `monsters_2D_test_path` | var (`@export`, String) | Pipe-delimited monster names, 3 columns (line 18). |
| `quest_story_test_path` | var (`@export`, String) | `Story Parts.txt`, 16 rows (line 19). |
| `milestone_story_path` | var (`@export`, String) | Boss story rows (line 20). |
| `boglands_location_path` | var (`@export`, String) | Declared (line 21), not read here. |
| `minor_story_path`, `minor_variable_path` | var (`@export`, String) | Minor quest story rows and their variable rows (lines 22-23). |
| `male_character_names`, `female_character_names`, `andro_character_names` | var (`Array[String]`) | Loaded names per gender (lines 26-28). |
| `knight_backstories`, `mage_backstories`, `pathfinder_backstories`, `priest_backstories`, `random_backstories` | var (`Array[String]`) | Loaded backstory templates (lines 31-35). |
| `monster_test_names` | var (Array) | 3 arrays (one per column of the monsters file) (line 37). |
| `location_names` | var (Array) | 4 arrays (one per column) (line 38). |
| `quest_story` | var (Array) | 16 rows, each an `Array[String]` of `type\|intro\|middle\|fail\|success` parts (line 39). |
| `milestone_story` | var (Array) | 7 rows, one per boss story (days 10, 20 x2, 30, 40 x2, 50) (line 40). |
| `minor_story` | var (Array) | 22 rows: the day 1-18 minor quests (0-8) and the lead-up quests (9-21) (line 41). |
| `minor_vars` | var (Array) | 22 rows of variables for the minor stories (line 42). |
| `child_gender`, `pronoun_possesive`, `pronoun_object`, `pronoun_personal_object` | var (`Array[String]`) | Text replacements indexed by `GuildCharacter.CharacterGender` (daughter/son/child etc.) (lines 45-67). |
| `knight_icons`, `priest_icons`, `pathfinder_icons`, `mage_icons` | var (`Array[Texture2D]`) | 3 preloaded portraits per role, by uid (lines 71-93). |
| `knight_item_names`, `pathfinder_item_names`, `mage_item_names`, `priest_item_names` | var (`Array[String]`) | Item title pools per role (lines 95-98). |

## Functions

### _ready
`func _ready() -> void` · `Globals/external_content_container.gd:102`

Engine callback. Loads everything: names and backstories with [[procedural_content_loader#_load_info_from_file]] (lines 103-112), monsters and locations with [[multicolumn_procedural_loader#_load_info_from_file]] (lines 114-116 and 129-130), and the story tables with [[multicolumn_procedural_loader#_load_info_from_rows]] (16 quest rows, 7 milestone rows, 22 minor rows, 22 variable rows).

**Side effects:** fills every array above.

**Calls:** [[procedural_content_loader#_load_info_from_file]], [[multicolumn_procedural_loader#_load_info_from_file]], [[multicolumn_procedural_loader#_load_info_from_rows]].

### get_character_name
`func get_character_name(gender: GuildCharacter.CharacterGender) -> String` · `Globals/external_content_container.gd:138`

A random name from the list for that gender. Returns `""` for an unknown gender.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `gender` | `GuildCharacter.CharacterGender` | Which list to pick from | the hero's rolled gender in [[character_resource#_init]] (`character_resource.gd:106`) |

**Returns:** `String`, the name. Used as the new hero's name.

**Called by:** [[character_resource#_init]].

### get_Monster_Name
`func get_Monster_Name(col_idx: int) -> String` · `Globals/external_content_container.gd:151`

A random entry (index 0-5, fixed) from `monster_test_names[col_idx]`. A test function. Columns hold at least 6 rows or this errors.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `col_idx` | `int` | Monster file column 0-2 | not traced |

**Called by:** nothing found.

### get_Location_Name
`func get_Location_Name(col_idx: int) -> String` · `Globals/external_content_container.gd:156`

A random entry (index 0-5, fixed) from `location_names[col_idx]`. A test function.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `col_idx` | `int` | Location column 0-3 | not traced |

**Called by:** nothing found.

### get_Quest_Story
`func get_Quest_Story(quest_idx: int, story_part: int) -> String` · `Globals/external_content_container.gd:161`

`quest_story[quest_idx][story_part]`. `story_part` is the column of `type|intro|middle|fail|success`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest_idx` | `int` | Row of `Story Parts.txt` | the quest's `questNum` |
| `story_part` | `int` | Column | constants in the caller |

**Returns:** `String`, with `{location}` placeholders still in it (the caller fills them).

**Called by:** [[quest_resource#_init]] (`quest_resource.gd:158`), [[quest_resource#generateResults]] (`:362`, `:402`, `:420`, `:454`, `:478`).

### get_Milestone_story
`func get_Milestone_story(quest_idx: int, story_part: int) -> String` · `Globals/external_content_container.gd:165`

`milestone_story[quest_idx][story_part]` for boss quests.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest_idx` | `int` | Boss story row 0-6 | the boss quest's number in [[quest_resource#_init_boss_vars]] and the milestone init |
| `story_part` | `int` | Column | constants in the caller |

**Returns:** `String`.

**Called by:** [[quest_resource#generateResults]] (`:366`, `:412`, `:430`, `:458`, `:482`), [[quest_resource#_init_boss_vars]] (`:821`), [[quest_resource#_initMilestoneVars]] (`:837`, `:849`, `:861`).

### get_Minor_Story
`func get_Minor_Story(quest_idx: int, story_part: int) -> String` · `Globals/external_content_container.gd:168`

`minor_story[quest_idx][story_part]` for minor quests (rows 0-21).

**Returns:** `String`.

**Called by:** [[quest_resource#generateResults]] (`:364`, `:407`, `:425`, `:456`, `:480`), [[quest_resource#_initMilestoneVars]] (`:936`).

### get_Minor_Story_Variables
`func get_Minor_Story_Variables(quest_idx: int, varNum: int) -> String` · `Globals/external_content_container.gd:171`

`minor_vars[quest_idx][varNum]`. The variable text that fills a minor story.

**Returns:** `String`.

**Called by:** [[quest_resource#_initMilestoneVars]] (`quest_resource.gd:933-945`, eight calls).

### get_character_icon
`func get_character_icon(_role: GuildCharacter.CharacterRole) -> Texture2D` · `Globals/external_content_container.gd:174`

A random portrait from the role's icon list. null for an unknown role.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_role` | `GuildCharacter.CharacterRole` | The hero's role | the hero's role in [[character_resource#_init]], [[hall_rules#make_starting_hero]] and [[portrait#show_character]] |

**Returns:** `Texture2D` (or null).

**Called by:** [[character_resource#_init]] (`character_resource.gd:110`), [[hall_rules#make_starting_hero]] (`hall_rules.gd:100`), [[portrait#show_character]] (`portrait.gd:50`).

### get_role_backstory
`func get_role_backstory(_char: GuildCharacter) -> String`  · `Globals/external_content_container.gd:188`

Picks a random template for the hero's role, then fills the stand-ins with [[external_content_container#replace_standins]]. An unmatched role gives `""`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_char` | `GuildCharacter` | The hero (needs role, name, gender) | `self` in [[character_resource#generate_description]] |

**Returns:** `String`, the finished backstory.

**Called by:** [[character_resource#generate_description]] (`character_resource.gd:193`).

**Calls:** [[external_content_container#replace_standins]].

### get_random_backstory
`func get_random_backstory(_char: GuildCharacter) -> String`  · `Globals/external_content_container.gd:209`

Picks a template from `random_backstories` and fills the stand-ins. The comment says "Pick a random backstory, sanitize it, and return it, based on the character".

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_char` | `GuildCharacter` | The hero | `self` in [[character_resource#generate_description]] |

**Returns:** `String`.

**Called by:** [[character_resource#generate_description]] (`character_resource.gd:196`).

**Calls:** [[external_content_container#replace_standins]].

### replace_standins
`func replace_standins(_backstory: String, _char: GuildCharacter) -> String` · `Globals/external_content_container.gd:215`

Replaces `[NAME]`, `[GENDER_CHILD]`, `[PRONOUN_OBJ]`, `[PRONOUN_POS]` and `[PRONOUN_PERS_OBJ]` using the hero's name and the gender-indexed arrays.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_backstory` | `String` | A template | picked in the two functions above |
| `_char` | `GuildCharacter` | Supplies `name` and `gender` (used as an index) | passed through |

**Returns:** `String`, the filled text.

**Called by:** [[external_content_container#get_role_backstory]] (line 203), [[external_content_container#get_random_backstory]] (line 211).

### get_item_title
`func get_item_title(_role: GuildCharacter.CharacterRole) -> String` · `Globals/external_content_container.gd:226`

A random item name from the role's pool (for example Sword, Staff, Idol). `""` for an unknown role.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_role` | `GuildCharacter.CharacterRole` | Item's role | the role passed to [[standard_item#_init]] |

**Returns:** `String`.

**Called by:** [[standard_item#_init]] (`standard_item.gd:74`).

## Suspected issues
- `Globals/external_content_container.gd:9` `location_names_file_path` and `:21` `boglands_location_path` are declared and never read here.
- `Globals/external_content_container.gd:151`, `:156` `get_Monster_Name` and `get_Location_Name` have no callers found, and are hard-coded to index 0-5.
- Most functions have no `##` comments, and the `_ready` end has a leftover `pass # Replace with function body.` (line 134).
