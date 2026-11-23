---
source: Scripts/Hall/Save/hall_save.gd
class_name: HallSave
extends: null
scene: null
systems: ["[[Saving Migration and Backup Codes]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_save.gd

## Purpose
`HallSave`: the run on disk (`user://run_save.dat`; IndexedDB on the web). Static functions only, no nodes. [[hall_main#save_now]] calls `save_run` after refreshes (an unchanged run isn't rewritten) and [[hall_main#_ready]] calls `load_run` once at start-up.

A run is a web of shared objects, so each `GuildCharacter`, `StandardItem` and `CreatedQuest` is written once in a numbered table (`characters`, `items`, `quests`) and referenced elsewhere as `{"$character": 3}`. Loading builds every object first, then swaps references back for the objects. A `Region` is stored as its index in `QuestManager.world_regions`, a `Texture2D` as its resource path. The snapshot is written with `var_to_bytes` to a temp file that's then renamed over the real one; the previous save is kept as a backup.

Old saves keep loading: additions need nothing (objects are built with `.new()` and `apply_snapshot` reads with `.get(key, default)`); a breaking change bumps `SAVE_VERSION` and adds a migration step; a save from a NEWER version is ignored.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `PATH` | const | `"user://run_save.dat"`, the save file. |
| `TEMP_PATH` | const | `"user://run_save.tmp"`, written first, then renamed over `PATH`. |
| `BACKUP_PATH` | const | `"user://run_save.bak"`, the save before the last write. |
| `SAVE_VERSION` | const | `1`. Layout version of the file. Bump only for a breaking change and add a step to `_migration_steps`. |
| `SNAPSHOT_KEYS` | const | `["game", "upgrades", "roster", "gear", "hall", "tutorial", "characters", "items", "quests"]`, the top-level sections `has_snapshot_shape` checks. |
| `CHARACTER_FIELDS` | const | GuildCharacter properties saved: `name, hometown, description, role, gender, title, icon, injury_level, injury_count, died_on_day, died_on_quest, joined_on_day, stats, pluck, total_points, status, cost, equipped_items, max_items`. `temp_stats` is left out (rebuilt by `reset_temp_stats`). |
| `ITEM_FIELDS` | const | StandardItem properties saved: `name, description, mean_cost, icon, role, rarity, cost, curr_user`. |
| `PASSIVE_ITEM_FIELDS` | const | Extra PassiveItem properties: `affected_stat, stat_amount`. |
| `QUEST_FIELDS` | const | CreatedQuest properties saved: `numAdventurers, maxAdventurers, goldReward, location, regionNum, difficulty, type, favStat, questTitle, questSummary, questNum, dead_adventurers, requirement_multiplier, found_items, reward_items`. Tuning numbers are left out so retuning reaches saved quests. |
| `ITEM_KIND_PASSIVE` | const | `"passive"`, the item `kind` written to the save. |
| `REF_CHARACTER` / `REF_ITEM` / `REF_QUEST` / `REF_REGION` / `REF_TEXTURE` | const | Reference keys `"$character"`, `"$item"`, `"$quest"`, `"$region"`, `"$texture"`. A Dictionary with exactly one of these keys stands for an object. |
| `REF_PAIRS` | const | `"$pairs"`: a Dictionary keyed by objects (`GuildUpgrades.training`) is written as `{"$pairs": [[key, value], ...]}`. |
| `_last_saved_bytes` | static var | Bytes last written, so an unchanged run isn't rewritten. Cleared by `forget_cache`. |
| `RefWriter` | inner class | Encodes values, fills the tables. |
| `RefReader` | inner class | Decodes values, builds objects. |

**Migration steps recorded:** none yet. `_migration_steps()` returns `{}` and `SAVE_VERSION` is 1, so there is no `_migrate_N_to_N+1` function.

## Functions

### save_run
`static func save_run(hall: HallMain) -> void` · `Scripts/Hall/Save/hall_save.gd:96`

Write the whole run to `PATH` unless it equals the last write. While the night plays out, `hall.night_save` holds the report or credits about to show; they're saved as already showing, so closing the game during the dusk can't replay the night with new dice.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The hall whose run it is | `self` in [[hall_main#save_now]] |

**Returns:** nothing.

**Side effects:** writes the save file via `write_bytes`; updates `_last_saved_bytes` on success.

**Called by:** [[hall_main#save_now]] (`hall_main.gd:1785`, only when `uses_save_file`, `is_save_enabled`, not `is_debug_run`, in tree).

**Calls:** [[hall_save#build_snapshot]], [[hall_save#write_bytes]].

### build_snapshot
`static func build_snapshot(hall: HallMain) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:106`

The run as one Dictionary of plain values: `version`, `game` (day, is_freeplay), `upgrades` (gold, standing, levels, training, patients, revives_used), `roster` (active, hireable, released, max_hireable), `gear` (owned, stock), `hall` (quest_entries, run_stats, released_today, previous_report, shown_report, shown_credits, run_over_stats, final_battle_lost, for_hire_last_seen_day, show_busy_adventurers, is_intro_seen, plus each `hall.night_save` key), `tutorial` (`is_skipped`, `done`), then the `characters`, `items`, `quests` tables.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The hall whose run it is | passed through from [[hall_save#save_run]], [[hall_save#load_run]], [[hall_save_transfer#build_code]] |

**Returns:** `Dictionary`, the snapshot. Used by `save_run` and `load_run` (via `var_to_bytes`) and by `build_code` (to make a save code).

**Side effects:** none (reads autoloads and `hall`).

**Called by:** [[hall_save#save_run]] (`hall_save.gd:97`), [[hall_save#load_run]] (`hall_save.gd:213`), [[hall_save_transfer#build_code]] (`hall_save_transfer.gd:43`).

**Calls:** `RefWriter.encode` ([[hall_save#RefWriter.encode]]).

> [!note] How it works
> The tables are attached last, so every reference above has its number by then.

### write_bytes
`static func write_bytes(bytes: PackedByteArray) -> bool` · `Scripts/Hall/Save/hall_save.gd:163`

Write bytes to `TEMP_PATH`, copy the old save to `BACKUP_PATH`, rename the temp file over `PATH`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `bytes` | `PackedByteArray` | A snapshot as `var_to_bytes` | `var_to_bytes(build_snapshot(hall))` in [[hall_save#save_run]]; `var_to_bytes(snapshot)` in [[hall_save_transfer#import_snapshot]] |

**Returns:** `bool`, false (with a warning) if the temp file can't be opened or the rename fails. `save_run` only updates its cache on true; `import_snapshot` returns false when this does.

**Side effects:** writes/renames files in `user://`.

**Called by:** [[hall_save#save_run]] (`hall_save.gd:100`), [[hall_save_transfer#import_snapshot]] (`hall_save_transfer.gd:90`).

**Calls:** nothing in the project.

### has_save
`static func has_save() -> bool` · `Scripts/Hall/Save/hall_save.gd:182`

True when `PATH` or `BACKUP_PATH` exists.

**Returns:** `bool`. No caller found in `Globals/`, `Scripts/`, `Scenes/` (see Suspected issues).

**Side effects:** none.

**Called by:** none found.

**Calls:** nothing.

### delete_save
`static func delete_save() -> void` · `Scripts/Hall/Save/hall_save.gd:188`

Forget the saved run (Found a New Guild / Abandon run). Removes `PATH`, `TEMP_PATH`, `BACKUP_PATH` if present. Settings live in another file ([[hall_settings]]) and stay.

**Returns:** nothing.

**Side effects:** deletes files; clears the write cache.

**Called by:** [[hall_main#start_new_run]] (`hall_main.gd:1678`).

**Calls:** [[hall_save#forget_cache]].

### forget_cache
`static func forget_cache() -> void` · `Scripts/Hall/Save/hall_save.gd:197`

Clear `_last_saved_bytes` so the next `save_run` writes even if the run looks unchanged.

**Returns:** nothing.

**Side effects:** resets `_last_saved_bytes`.

**Called by:** [[hall_save#delete_save]] (`hall_save.gd:192`), [[hall_save_transfer#import_snapshot]] (`hall_save_transfer.gd:94`).

**Calls:** nothing.

### load_run
`static func load_run(hall: HallMain) -> bool` · `Scripts/Hall/Save/hall_save.gd:207`

Read the save (`PATH`, or `BACKUP_PATH` if that can't be read) and put it into the autoloads and the hall. `hall.tutorial` must already exist (not set up yet).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The hall to fill | `self` in [[hall_main#_ready]] |

**Returns:** `bool`, true if a run was loaded; false (nothing changed) if no usable save. [[hall_main#_ready]] stores it in `is_resumed_run`.

**Side effects:** changes `GameState`, `GuildUpgrades`, `CharacterContainer`, `ItemContainer`, `ItemShop` and `hall` through `apply_snapshot`; refreshes `_last_saved_bytes` from the loaded run.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:455`).

**Calls:** [[hall_save#_read_file]], [[hall_save#apply_snapshot]], [[hall_save#build_snapshot]].

### _read_file
`static func _read_file(path: String) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:220`

The snapshot at `path` (migrated up to `SAVE_VERSION`), or `{}` if missing, empty, unreadable or from a newer version. Uses `bytes_to_var` (not `_with_objects`), so a save only ever holds plain values.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `path` | `String` | File to read | `PATH` then `BACKUP_PATH` in [[hall_save#load_run]] |

**Returns:** `Dictionary`; `{}` makes `load_run` try the next path. Warns when a file exists but gives `{}`.

**Side effects:** none.

**Called by:** [[hall_save#load_run]] (`hall_save.gd:209`).

**Calls:** [[hall_save#migrate]].

### has_snapshot_shape
`static func has_snapshot_shape(snapshot: Variant) -> bool` · `Scripts/Hall/Save/hall_save.gd:236`

True when `snapshot` is a Dictionary with an int `version` and every `SNAPSHOT_KEYS` section as a Dictionary or Array. Doesn't check the version number.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `snapshot` | `Variant` | Any value | `bytes_to_var` result in [[hall_save#migrate]]; in [[hall_save_transfer#parse_code]] the decoded code |

**Returns:** `bool`. Used by `migrate` and `parse_code` to reject bad data.

**Side effects:** none.

**Called by:** [[hall_save#migrate]] (`hall_save.gd:271`), [[hall_save_transfer#parse_code]] (`hall_save_transfer.gd:76`).

**Calls:** nothing.

### is_from_newer_version
`static func is_from_newer_version(snapshot: Variant) -> bool` · `Scripts/Hall/Save/hall_save.gd:248`

True when `snapshot` is a Dictionary whose int `version` is greater than `SAVE_VERSION` (an older cached build opening a newer backup).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `snapshot` | `Variant` | Any value | as for `has_snapshot_shape` |

**Returns:** `bool`. `migrate` returns `{}` on true; `parse_code` turns it into `ParseError.NEWER_VERSION`.

**Side effects:** none.

**Called by:** [[hall_save#migrate]] (`hall_save.gd:271`), [[hall_save_transfer#parse_code]] (`hall_save_transfer.gd:76`).

**Calls:** nothing.

### migrate
`static func migrate(snapshot: Variant) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:270`

Bring `snapshot` up to `SAVE_VERSION` by running each step in turn (1->2, 2->3, ...). The doc comment explains how to add a step: bump `SAVE_VERSION`, write `_migrate_N_to_N+1(snapshot: Dictionary) -> void` that rewrites plain data in place, list it in `_migration_steps()`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `snapshot` | `Variant` | A value from `bytes_to_var` | file bytes in [[hall_save#_read_file]]; decoded code bytes in [[hall_save_transfer#parse_code]] |

**Returns:** `Dictionary`, the migrated snapshot, or `{}` if it isn't a snapshot, is from a newer version, or a step is missing (warning).

**Side effects:** mutates `snapshot` in place (`version` incremented per step).

**Called by:** [[hall_save#_read_file]] (`hall_save.gd:227`), [[hall_save_transfer#parse_code]] (`hall_save_transfer.gd:78`).

**Calls:** [[hall_save#has_snapshot_shape]], [[hall_save#is_from_newer_version]], [[hall_save#_migration_steps]].

### _migration_steps
`static func _migration_steps() -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:288`

Maps "version a step upgrades FROM" to a `Callable(snapshot: Dictionary)`. Returns `{}` for now (layout still at version 1).

**Returns:** `Dictionary`. Read by `migrate`.

**Side effects:** none.

**Called by:** [[hall_save#migrate]] (`hall_save.gd:274`).

**Calls:** nothing.

### apply_snapshot
`static func apply_snapshot(hall: HallMain, snapshot: Dictionary) -> void` · `Scripts/Hall/Save/hall_save.gd:294`

Put a snapshot back into the autoloads and the hall. Every read uses `.get(key, <current value>)` so older saves load. `is_intro_seen` defaults to `true` instead (a save from before the intro crawl is a started run). Building levels are merged over the fresh ones. At the end every character gets `reset_temp_stats()`, `CharacterContainer.max_characters` is set from `GuildUpgrades.get_max_heroes()`, and `GuildUpgrades.sync_characters()` runs.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | Hall to fill (its tutorial must exist) | `hall` in [[hall_save#load_run]] |
| `snapshot` | `Dictionary` | Migrated snapshot | [[hall_save#_read_file]] result in `load_run` |

**Returns:** nothing.

**Side effects:** sets `GameState.day/is_freeplay`, `GuildUpgrades` (gold, standing, levels, training, patients, revives_used), `CharacterContainer` lists and `max_hireable_characters`, `ItemContainer.owned_items`, `ItemShop.stock`, many `hall` fields, `hall.tutorial.is_skipped/done`.

**Called by:** [[hall_save#load_run]] (`hall_save.gd:211`).

**Calls:** [[hall_save#RefReader._init]], [[hall_save#RefReader.decode]], [[character_resource#reset_temp_stats]], [[guild_upgrades#get_max_heroes]], [[guild_upgrades#sync_characters]].

### request_persistent_storage
`static func request_persistent_storage() -> void` · `Scripts/Hall/Save/hall_save.gd:356`

Web only: asks the browser to keep this site's storage (the save) when space runs low via `navigator.storage.persist()`. The browser may refuse.

**Returns:** nothing.

**Side effects:** runs JavaScript via `JavaScriptBridge.eval`. Does nothing off the web.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:454`, before `load_run`).

**Calls:** nothing in the project.

### RefWriter.encode
`func encode(value: Variant) -> Variant` · `Scripts/Hall/Save/hall_save.gd:377`

Turn `value` into plain data: characters/items/quests become `{REF_*: id}` (table entries added the first time), `Region` becomes its index in `QuestManager.world_regions`, `Texture2D` its `resource_path` (null if empty), Arrays are mapped, Dictionaries go to `_encode_dictionary`. Any other Object is dropped (null) with a warning.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `value` | `Variant` | Any run value | autoload and hall fields in [[hall_save#build_snapshot]]; field values in `_encode_fields` |

**Returns:** `Variant`, plain data. Used by `build_snapshot` to fill each section.

**Side effects:** fills the writer's `characters`, `items`, `quests` tables and `_ids`.

**Called by:** [[hall_save#build_snapshot]] (`hall_save.gd:109-115, 123, 136-137, 141-143, 147-148`), itself (`hall_save.gd:403, 407`, array `map` at `389`), [[hall_save#RefWriter._encode_fields]] (`hall_save.gd:444, 447`).

**Calls:** [[hall_save#RefWriter._id_for]], [[hall_save#RefWriter._encode_dictionary]].

### RefWriter._encode_dictionary
`func _encode_dictionary(dictionary: Dictionary) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:398`

A Dictionary with its values encoded. If any key is an Object, it becomes `{REF_PAIRS: [[key, value], ...]}` with keys encoded as references.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `dictionary` | `Dictionary` | Dictionary to encode | `value` in `encode` |

**Returns:** `Dictionary`, returned by `encode`.

**Side effects:** same as `encode`.

**Called by:** [[hall_save#RefWriter.encode]] (`hall_save.gd:391`).

**Calls:** [[hall_save#RefWriter.encode]].

### RefWriter._id_for
`func _id_for(object: Object, table: Array, encode_fields: Callable) -> int` · `Scripts/Hall/Save/hall_save.gd:413`

The object's number in `table`, adding it (built by `encode_fields`) the first time. The number is taken and a placeholder `{}` appended before the fields are encoded, so an object pointing back (`curr_user`) finds it.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `object` | `Object` | Character, item or quest | `value` in `encode` |
| `table` | `Array` | `characters`, `items` or `quests` | members of the writer |
| `encode_fields` | `Callable` | `_encode_character`, `_encode_item` or `_encode_quest` | `encode` |

**Returns:** `int`, the table index used in the reference.

**Side effects:** appends to `table`, records in `_ids`.

**Called by:** [[hall_save#RefWriter.encode]] (`hall_save.gd:379, 381, 383`).

**Calls:** the `encode_fields` callable ([[hall_save#RefWriter._encode_character]], [[hall_save#RefWriter._encode_item]], [[hall_save#RefWriter._encode_quest]]).

### RefWriter._encode_character
`func _encode_character(character: GuildCharacter) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:422`

Encodes a hero with `CHARACTER_FIELDS`.

**Returns:** `{"fields", "meta"}` Dictionary stored in the `characters` table.

**Side effects:** none beyond `encode`'s.

**Called by:** [[hall_save#RefWriter._id_for]] as a Callable (passed at `hall_save.gd:379`).

**Calls:** [[hall_save#RefWriter._encode_fields]].

### RefWriter._encode_item
`func _encode_item(item: StandardItem) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:425`

Encodes an item with `ITEM_FIELDS` (plus `PASSIVE_ITEM_FIELDS` for a `PassiveItem`) and sets `kind = ITEM_KIND_PASSIVE`. A non-PassiveItem gets a warning and still gets `kind` "passive".

**Returns:** Dictionary stored in the `items` table.

**Side effects:** push_warning for non-passive items.

**Called by:** [[hall_save#RefWriter._id_for]] as a Callable (`hall_save.gd:381`).

**Calls:** [[hall_save#RefWriter._encode_fields]].

### RefWriter._encode_quest
`func _encode_quest(quest: CreatedQuest) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:435`

Encodes a quest with `QUEST_FIELDS`.

**Returns:** Dictionary stored in the `quests` table.

**Side effects:** none beyond `encode`'s.

**Called by:** [[hall_save#RefWriter._id_for]] as a Callable (`hall_save.gd:383`).

**Calls:** [[hall_save#RefWriter._encode_fields]].

### RefWriter._encode_fields
`func _encode_fields(object: Object, field_names: Array) -> Dictionary` · `Scripts/Hall/Save/hall_save.gd:441`

`{"fields": {name: value}, "meta": {name: value}}` for one object, with every value encoded. Metadata is saved because GuildUpgrades keeps healing progress and the Armory bonus on heroes, and ItemShop each item's bonus, as metadata.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `object` | `Object` | The object to read | the `_encode_*` caller |
| `field_names` | `Array` | Property names | `CHARACTER_FIELDS`, `ITEM_FIELDS` (+ passive), `QUEST_FIELDS` |

**Returns:** `Dictionary`, read back by `RefReader._apply_fields`.

**Side effects:** none beyond `encode`'s.

**Called by:** [[hall_save#RefWriter._encode_character]] (`hall_save.gd:423`), [[hall_save#RefWriter._encode_item]] (`hall_save.gd:431`), [[hall_save#RefWriter._encode_quest]] (`hall_save.gd:436`).

**Calls:** [[hall_save#RefWriter.encode]].

### RefReader._init
`func _init(snapshot: Dictionary) -> void` · `Scripts/Hall/Save/hall_save.gd:459`

Builds every character (`GuildCharacter.new()`), item (`PassiveItem.new(role)`) and quest (`CreatedQuest.new()`) up front, then applies the saved fields to each so references can resolve in any order.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `snapshot` | `Dictionary` | Snapshot with the three tables | `RefReader.new(snapshot)` in [[hall_save#apply_snapshot]] |

**Returns:** nothing (constructor).

**Side effects:** fills `characters`, `items`, `quests`. Random values rolled by the objects' own `_init` are overwritten by the saved fields.

**Called by:** [[hall_save#apply_snapshot]] (`hall_save.gd:295`), via `RefReader.new`.

**Calls:** [[hall_save#RefReader._apply_fields]].

### RefReader.decode
`func decode(value: Variant) -> Variant` · `Scripts/Hall/Save/hall_save.gd:476`

A plain value back as a run value. Arrays are mapped; a single-key Dictionary with a `REF_*` key becomes its object (an out-of-range region index becomes a random region; a missing texture path becomes null); `REF_PAIRS` becomes a Dictionary keyed by objects; other Dictionaries are copied with values decoded.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `value` | `Variant` | Plain data from the snapshot | `upgrades`, `roster`, `gear`, `hall` entries in [[hall_save#apply_snapshot]] |

**Returns:** `Variant`, assigned by `apply_snapshot` to autoload or hall fields.

**Side effects:** `load()` of icon textures.

**Called by:** [[hall_save#apply_snapshot]] (`hall_save.gd:310-331`), itself (`hall_save.gd:499, 503`, array `map` at `478`), [[hall_save#RefReader._apply_fields]] (`hall_save.gd:512`, and `523` for metadata).

**Calls:** nothing else in the project.

### RefReader._apply_fields
`func _apply_fields(object: Object, entry: Dictionary) -> void` · `Scripts/Hall/Save/hall_save.gd:509`

Set the object's saved fields and metadata from an entry written by `_encode_fields`. Typed Arrays and Dictionaries (`equipped_items`, `stats`) are filled in place with `assign()` so they keep their element types.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `object` | `Object` | The freshly built object | `characters[i]`, `items[i]`, `quests[i]` in `_init` |
| `entry` | `Dictionary` | `{"fields", "meta"}` | `snapshot.characters/items/quests[i]` |

**Returns:** nothing.

**Side effects:** changes the object's properties and metadata.

**Called by:** [[hall_save#RefReader._init]] (`hall_save.gd:469, 471, 473`).

**Calls:** [[hall_save#RefReader.decode]].

## Suspected issues
- `has_save` (`hall_save.gd:182`) has no caller in `Globals/`, `Scripts/`, `Scenes/`: dead code.
- `RefWriter._encode_item` (`hall_save.gd:425`) tags every item `kind = "passive"`, even after warning that it isn't a PassiveItem; on load `RefReader._init` builds a `PassiveItem` for all items, so a non-passive item would come back as the wrong class.
- `RefReader.decode` (`hall_save.gd:492`) quietly swaps a bad region index for a random region; fine, but means a corrupted region ref changes a quest's region.
