---
source: Globals/guild_upgrades.gd
class_name: null
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# guild_upgrades.gd

## Purpose
Autoload `GuildUpgrades`. Owns building levels, upgrade costs and the gold / standing wallet, and applies upgrade effects to the rest of the game:
- Armory adds STRENGTH / DEFENSE to every hero.
- Barracks sets `CharacterContainer.max_characters`.
- Training Yard: heroes in a slot gain a stat each night.
- Hospital: injuries heal over the nights, faster for patients. `run_night()` applies both. The hall calls it at End Day.

`GameState.gold` / `standing` read from here. It has no scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `upgrades_changed` | signal | A level changed (`try_upgrade`, `max_all_buildings`, `reset`). |
| `resources_changed` | signal | Gold or standing changed. [[game_state#_ready]] re-emits it. |
| `home_changed` | signal | Someone started or stopped training, was admitted or discharged, or the night ran. |
| `Building` | enum | `OFFICE, TRAINING_YARD, HOSPITAL, ARMORY, BARRACKS`. |
| `UpgradeStatus` | enum | `READY, STANDING_TOO_LOW, NOT_ENOUGH_GOLD, MAX_LEVEL, NOT_IMPLEMENTED`. |
| `MAX_LEVEL` | const | 5. |
| `ARMORY_META` | const | Character metadata key `"armory_bonus_applied"` (the Vector2i already given). |
| `BUILDING_INFO` | const | Per building: `name`, `implemented` flag (Office is false), `color`. |
| `OFFICE_QUESTS_PER_DAY`, `OFFICE_REROLLS_PER_DAY`, `OFFICE_HIGHEST_RANK` | const | Office level tables (index 0 = level 1). Only used for the effect text (Office isn't implemented). |
| `TRAINING_SLOTS`, `TRAINING_STAT_GAIN` | const | Slots and stat gained per night by Training Yard level. |
| `HOSPITAL_STAGES_PER_NIGHT` | const | Injury stages a patient heals each night by Hospital level (`[1,1,2,2,2]`). |
| `ARMORY_BONUS` | const | `Vector2i(strength, defense)` bonus by Armory level. |
| `BARRACKS_MAX_HEROES` | const | Hero cap by Barracks level (4, 6, 8, 10, 12). |
| `UNLOCK_DAY` | const | The day the Guild tab opens (10, the Bone Drake's day). Locked before it whether or not the tutorial is on. |
| `UPGRADE_GOLD_COST` | const | Gold to reach level N is `[N - 1]` (`[0, 2000, 4000, 7000, 12000]`). The code comment explains the pacing target (about 25,000 gold per building). |
| `UPGRADE_STANDING_REQ` | const | Standing needed to buy level N (`[0, 5, 15, 30, 50]`). |
| `STARTING_GOLD`, `STARTING_STANDING`, `MINIMUM_STANDING` | const | Wallet at run start (0, 1) and the standing floor for recruits (-10). Used by [[character_container#refresh_hireable_characters]]. |
| `SHOW_DEBUG_BUTTONS` | const | Shows the Menu's Debug tools button and the prototype upgrade page's test buttons. |
| `HOME_HEAL_NIGHTS` | const | Nights at home to heal one injury level, indexed by `InjuryLevel` (`[0, 2, 4, 6, 0]`). |
| `TRAINING_MAX_INJURY` | const | Worst injury a hero can still train with (`SORE`). |
| `REVIVE_LEVEL`, `REVIVES_PER_RUN` | const | Hospital level that unlocks reviving (5) and revives per run (1). |
| `RECOVERY_META` | const | Character metadata key `"recovery_nights"`: `Vector2i(injury level, nights spent healing it)`. |
| `gold`, `standing` | var (int) | The wallet. |
| `levels` | var (Dictionary) | `Building -> level`, set to 1 each in `_ready`. |
| `training` | var (Dictionary) | Hero -> the `GuildCharacter.StatType` they drill. |
| `patients` | var (`Array[GuildCharacter]`) | Heroes in a Hospital bed. |
| `revives_used` | var (int) | Revives used this run. |
| `_last_character_count` | var (int) | Last roster size seen by `_process` (-1 = none yet). |

## Functions

### _ready
`func _ready() -> void` · `Globals/guild_upgrades.gd:113`

Engine callback. Sets every building to level 1, connects `CharacterContainer.on_character_added` to `sync_characters`, and applies the effects.

**Calls:** [[guild_upgrades#sync_characters]], [[guild_upgrades#_apply_effects]].

### _process
`func _process(_delta: float) -> void` · `Globals/guild_upgrades.gd:121`

Engine callback, every frame. Re-syncs the Armory bonus whenever the roster size changes (heroes can join without `on_character_added` firing, for example via `generate_new_character`).

**Calls:** [[guild_upgrades#sync_characters]].

### get_level
`func get_level(building: int) -> int` · `Globals/guild_upgrades.gd:132`

`levels.get(building, 1)`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `building` | `int` | A `Building` value | the card or tab the caller draws |

**Returns:** `int`, the level 1-5. Used for display and effect lookups.

**Called by:** this script (lines 149, 155, 161, 203, 207, 217, 273, 277, 323, 370), [[hall_main#upgrade_building]] (`hall_main.gd:1159`), [[hall_ledger#build_run_records]] (`hall_ledger.gd:119`), [[agent_bridge_actions#_upgrade]] (`:191`, `:193`), [[agent_bridge_state#_building]] (`:142`), [[home_row#show_fallen]] (`:209`), [[home_section#refresh]] (`:64`), [[upgrade_card#setup]] (`:50`), [[suggest_row#setup]] (`:21`), [[tab_guild#_show_beds]] (`:135`).

### get_building_name
`func get_building_name(building: int) -> String` · `Globals/guild_upgrades.gd:136`

The display name from `BUILDING_INFO`.

**Called by:** [[hall_main#upgrade_building]] (`hall_main.gd:1159`), [[hall_ledger#build_run_records]] (`:119`), [[agent_bridge_state#_building]] (`:141`), [[home_section#setup]] (`:58`), [[upgrade_card#_show_name_and_level]] (`:72`), [[suggest_row#setup]] (`:25`), [[tab_upgrades#_show_coming_soon]] (`:123`).

### get_building_color
`func get_building_color(building: int) -> Color` · `Globals/guild_upgrades.gd:140`

The accent color from `BUILDING_INFO`.

**Called by:** [[home_section#setup]] (`home_section.gd:54`), [[suggest_row#setup]] (`suggest_row.gd:22`).

### is_implemented
`func is_implemented(building: int) -> bool` · `Globals/guild_upgrades.gd:144`

Whether the building's effect does anything yet (false for the Office).

**Called by:** [[guild_upgrades#get_upgrade_status]] (line 165), [[guild_upgrades#max_all_buildings]] (line 229), [[hall_ledger#build_run_records]] (`:118`), [[hall_wallet#cheapest_upgrade]] (`:146`), [[hall_style#buildings_in_order]] (`hall_style.gd:482`), [[tab_upgrades#_show_building_cards]] (`:110`), [[tab_upgrades#_show_coming_soon]] (`:121`).

### is_max_level
`func is_max_level(building: int) -> bool` · `Globals/guild_upgrades.gd:148`

`get_level(building) >= MAX_LEVEL`.

**Called by:** [[guild_upgrades#get_next_gold_cost]] (153), [[guild_upgrades#get_next_standing_req]] (159), [[guild_upgrades#get_upgrade_status]] (167), [[hall_wallet#cheapest_upgrade]] (`:146`), [[upgrade_card#setup]] (`:51`).

**Calls:** [[guild_upgrades#get_level]].

### get_next_gold_cost
`func get_next_gold_cost(building: int) -> int` · `Globals/guild_upgrades.gd:152`

Gold for the next level (`UPGRADE_GOLD_COST[current level]`), or 0 at max level.

**Returns:** `int` gold. Used to charge and to display.

**Called by:** [[guild_upgrades#get_upgrade_status]] (172), [[guild_upgrades#try_upgrade]] (216), [[hall_wallet#cheapest_upgrade]] (`:148`), [[agent_bridge_state#_building]] (`:143`), [[upgrade_card#_show_status]] (`:98`, `:107`), [[suggest_row#setup]] (`:28`).

**Calls:** [[guild_upgrades#is_max_level]], [[guild_upgrades#get_level]].

### get_next_standing_req
`func get_next_standing_req(building: int) -> int`  · `Globals/guild_upgrades.gd:158`

Standing needed for the next level (`UPGRADE_STANDING_REQ[current level]`), or 0 at max level.

**Called by:** [[guild_upgrades#get_upgrade_status]] (170), [[upgrade_card#_show_status]] (`:110`).

**Calls:** [[guild_upgrades#is_max_level]], [[guild_upgrades#get_level]].

### get_upgrade_status
`func get_upgrade_status(building: int) -> UpgradeStatus` · `Globals/guild_upgrades.gd:164`

Order of checks: not implemented, max level, standing too low (checked before gold, "more gold can't fix it"), not enough gold, else `READY`.

**Returns:** `UpgradeStatus`. [[guild_upgrades#try_upgrade]] needs `READY`. The hall and cards use it to enable the Buy button and pick the status text.

**Called by:** [[guild_upgrades#try_upgrade]] (213), [[hall_main#affordable_buildings]] (`hall_main.gd:712`), [[hall_wallet#cheapest_upgrade]] (`:150`), [[upgrade_card#_show_status]] (`:92`).

**Calls:** [[guild_upgrades#is_implemented]], [[guild_upgrades#is_max_level]], [[guild_upgrades#get_next_standing_req]], [[guild_upgrades#get_next_gold_cost]].

### get_effect_text
`func get_effect_text(building: int, level: int) -> String` · `Globals/guild_upgrades.gd:178`

Short description of what a building does at a level (level clamped to 1-5). The Office text adds "+ Priority Quest" and the Hospital text adds "+ revive 1 hero" at level 5.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `building` | `int` | A `Building` value | the card's building |
| `level` | `int` | The level to describe | current level and next level in [[upgrade_card#_show_effects]] |

**Returns:** `String`, `""` for an unknown building.

**Called by:** [[upgrade_card#_show_effects]] (`upgrade_card.gd:83`, `:87`), [[suggest_row#setup]] (`suggest_row.gd:26`).

### get_armory_bonus
`func get_armory_bonus() -> Vector2i` · `Globals/guild_upgrades.gd:202`

`ARMORY_BONUS` for the current Armory level (x = strength, y = defense).

**Called by:** [[guild_upgrades#sync_characters]] (464).

**Calls:** [[guild_upgrades#get_level]].

### get_max_heroes
`func get_max_heroes() -> int` · `Globals/guild_upgrades.gd:206`

The Barracks cap for the current level.

**Called by:** [[guild_upgrades#_apply_effects]] (456), [[hall_save#apply_snapshot]] (`hall_save.gd:347`).

**Calls:** [[guild_upgrades#get_level]].

### try_upgrade
`func try_upgrade(building: int) -> bool` · `Globals/guild_upgrades.gd:212`

Buys the next level if the status is `READY`: subtracts the gold, raises the level, applies effects.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `building` | `int` | A `Building` value | the card pressed, via [[hall_main#upgrade_building]] |

**Returns:** `bool`, false if not `READY`. [[hall_main#upgrade_building]] uses it to toast and play a sound.

**Side effects:** changes `gold` and `levels`, emits `resources_changed` and `upgrades_changed`.

**Called by:** [[hall_main#upgrade_building]] (`hall_main.gd:1154`).

**Calls:** [[guild_upgrades#get_upgrade_status]], [[guild_upgrades#get_next_gold_cost]], [[guild_upgrades#get_level]], [[guild_upgrades#_apply_effects]].

### max_all_buildings
`func max_all_buildings() -> void` · `Globals/guild_upgrades.gd:227`

Debug tool: every implemented building jumps to `MAX_LEVEL` for free, and effects apply now.

**Side effects:** changes `levels`, emits `resources_changed`, `upgrades_changed`.

**Called by:** [[hall_debug#max_buildings]] (`hall_debug.gd:114`).

**Calls:** [[guild_upgrades#is_implemented]], [[guild_upgrades#_apply_effects]].

### add_gold
`func add_gold(amount: int) -> void` · `Globals/guild_upgrades.gd:236`

`gold = max(gold + amount, 0)` (gold can't go negative), then emits `resources_changed`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `amount` | `int` | Gold, negative to spend | price in [[item_shop#buy]]; forwarded from [[game_state#add_gold]]; debug amount in [[hall_main#debug_add_gold]] |

**Called by:** [[game_state#add_gold]] (`game_state.gd:58`), [[item_shop#buy]] (`item_shop.gd:96`), [[hall_main#debug_add_gold]] (`hall_main.gd:1422`).

### add_standing
`func add_standing(amount: int) -> void` · `Globals/guild_upgrades.gd:241`

Adds to `standing` and emits `resources_changed`. There is no floor.

**Called by:** [[game_state#add_standing]] (`game_state.gd:62`), [[hall_main#debug_add_standing]] (`hall_main.gd:1428`).

### reduce_standing
`func reduce_standing(amount: int) -> void` · `Globals/guild_upgrades.gd:246`

Subtracts from `standing` and emits `resources_changed`. Standing can go negative (the recruit floor is `MINIMUM_STANDING`).

**Called by:** [[game_state#reduce_standing]] (`game_state.gd:66`).

### reset
`func reset() -> void` · `Globals/guild_upgrades.gd:253`

Back to a fresh guild: all levels 1, starting wallet, training and patients cleared, `revives_used = 0`. The Armory bonus is removed from heroes again by the re-sync.

**Side effects:** emits `home_changed`, `resources_changed`, `upgrades_changed`.

**Called by:** [[hall_main#reset_upgrades]] (`hall_main.gd:1402`), [[hall_main#reset_autoloads]] (`hall_main.gd:1690`), [[playtest_scenario#_enter_tree]] (`playtest_scenario.gd:46`).

**Calls:** [[guild_upgrades#_apply_effects]].

### get_training_slots
`func get_training_slots() -> int` · `Globals/guild_upgrades.gd:272`

Slots at the current Training Yard level.

**Called by:** [[guild_upgrades#has_free_training_slot]] (290), [[home_section#_show_training]] (`home_section.gd:83`).

### get_training_gain
`func get_training_gain() -> int` · `Globals/guild_upgrades.gd:276`

Stat points gained per night at the current Training Yard level.

**Called by:** [[guild_upgrades#run_night]] (400), [[home_row#show_training_slot]] (`home_row.gd:124`), [[home_section#_show_training]] (`:86`), [[screen_character#_show_task]] (`screen_character.gd:192`).

### is_training
`func is_training(character: GuildCharacter) -> bool` · `Globals/guild_upgrades.gd:280`

True if the hero is in `training`.

**Called by:** [[guild_upgrades#set_training]] (303), [[hall_main#can_go_on_quests]] (`:616`), [[hall_main#toggle_in_party]] (`:942`), [[hall_main#train]] (`:1251`), [[agent_bridge_actions#plan]] (`:80`), [[agent_bridge_actions#_train]] (`:174`), [[agent_bridge_state#_hero]] (`:62`), [[overlay_tutorial#_anyone_can_train]] (`:956`), [[home_row#show_needs_care]] (`:193`), [[home_section#_show_training]] (`:85`, `:96`), [[member_card#_show_status]] (`:81`), [[member_card#_show_task]] (`:102`), [[pick_row#_show_elsewhere]] (`:75`), [[screen_character#_show_task]] (`:190`).

### get_training_stat
`func get_training_stat(character: GuildCharacter) -> int` · `Globals/guild_upgrades.gd:285`

The `GuildCharacter.StatType` a hero is drilling, or -1 if they aren't training.

**Called by:** [[home_row#show_training_slot]] (`:122`), [[member_card#_show_status]] (`:82`), [[member_card#_show_task]] (`:103`), [[pick_row#_show_elsewhere]] (`:77`), [[screen_character#_show_task]] (`:191`).

### has_free_training_slot
`func has_free_training_slot() -> bool` · `Globals/guild_upgrades.gd:289`

`training.size() < get_training_slots()`.

**Called by:** [[guild_upgrades#set_training]] (303), [[hall_main#train]] (`:1252`, `:1262`), [[overlay_tutorial#_day_three]] (`:1079`), [[home_row#show_can_train]] (`:160`), [[home_section#_show_training]] (`:88`, `:93`, `:111`).

**Calls:** [[guild_upgrades#get_training_slots]].

### can_train
`func can_train(character: GuildCharacter) -> bool` · `Globals/guild_upgrades.gd:294`

Alive, no worse than Sore (`TRAINING_MAX_INJURY`), and not in the Hospital.

**Called by:** [[guild_upgrades#set_training]] (301), [[guild_upgrades#_forget_missing_heroes]] (446), [[hall_main#train]] (`:1248`), [[overlay_tutorial#_anyone_can_train]] (`:956`), [[home_section#_show_training]] (`:96`, `:98`).

**Calls:** [[guild_upgrades#is_patient]].

### set_training
`func set_training(character: GuildCharacter, stat: int) -> bool` · `Globals/guild_upgrades.gd:300`

Puts a hero in a training slot, or changes the stat they drill. False when they can't train or every slot is taken.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | the hero chosen in [[hall_main#train]] |
| `stat` | `int` | A `GuildCharacter.StatType` | the stat button chosen in the UI |

**Returns:** `bool`. [[hall_main#train]] uses it for the toast and sound.

**Side effects:** writes `training`, emits `home_changed`.

**Called by:** [[hall_main#train]] (`hall_main.gd:1256`).

**Calls:** [[guild_upgrades#can_train]], [[guild_upgrades#is_training]], [[guild_upgrades#has_free_training_slot]].

### stop_training
`func stop_training(character: GuildCharacter) -> void` · `Globals/guild_upgrades.gd:310`

Removes the hero from `training` (emits `home_changed` only if they were in it).

**Called by:** [[character_container#remove_character_from_guild]] (`character_container.gd:149`), [[hall_main#stop_training]] (`hall_main.gd:1269`).

### get_hospital_stages
`func get_hospital_stages() -> int` · `Globals/guild_upgrades.gd:322`

Injury stages a patient heals tonight at the Hospital's current level.

**Called by:** [[guild_upgrades#get_nights_until_healthy]] (346), [[guild_upgrades#run_night]] (414).

### is_patient
`func is_patient(character: GuildCharacter) -> bool` · `Globals/guild_upgrades.gd:326`

True if the hero is in `patients`.

**Called by:** [[guild_upgrades#can_train]] (295), [[guild_upgrades#admit]] (354), [[guild_upgrades#run_night]] (412), [[hall_main#can_go_on_quests]] (`:615`), [[hall_main#hurt_waiting_count]] (`:622`), [[hall_main#toggle_in_party]] (`:939`), [[agent_bridge_actions#plan]] (`:83`, `:86`), [[home_row#show_cant_train]] (`:172`), [[home_section#_show_hospital]] (`:126`, `:128`), [[member_card#_show_status]] (`:78`), [[member_card#_show_task]] (`:98`), [[pick_row#_show_pick_state]] (`:112`), [[screen_character#_show_task]] (`:186`).

### needs_care
`func needs_care(character: GuildCharacter) -> bool` · `Globals/guild_upgrades.gd:331`

Hurt but alive (Sore, Hurt or Gravely hurt).

**Called by:** [[guild_upgrades#get_nights_until_healthy]] (343), [[guild_upgrades#admit]] (354), [[guild_upgrades#run_night]] (409, 428), [[guild_upgrades#_forget_missing_heroes]] (449), [[hall_main#hurt_waiting_count]] (`:622`), [[home_section#_show_hospital]] (`:128`).

### get_heal_nights
`func get_heal_nights(level: int) -> int` · `Globals/guild_upgrades.gd:337`

Nights at home to heal one level down from injury `level` (`HOME_HEAL_NIGHTS`, index clamped to the table).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `level` | `int` | An injury level value | the hero's `injury_level` in the loops of the two callers |

**Called by:** [[guild_upgrades#get_nights_until_healthy]] (349), [[guild_upgrades#run_night]] (420).

### get_nights_until_healthy
`func get_nights_until_healthy(character: GuildCharacter, in_hospital: bool) -> int` · `Globals/guild_upgrades.gd:342`

Nights until a hero is Healthy again, counting progress already made. 0 when they need no care. In the hospital: `ceil(injury_level / stages per night)`. At home: the sum of `get_heal_nights` for each level down to 1, minus recorded progress, never less than 1.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | the row's hero |
| `in_hospital` | `bool` | Estimate for a bed or for home | caller chooses: `true` in [[home_row#show_patient]] |

**Returns:** `int` nights, shown in the Guild tab rows and the hero screen.

**Called by:** [[home_row#show_patient]] (`home_row.gd:182`), [[home_row#show_needs_care]] (`:190`, `:191`), [[screen_character#_show_task]] (`screen_character.gd:187`).

**Calls:** [[guild_upgrades#needs_care]], [[guild_upgrades#get_hospital_stages]], [[guild_upgrades#get_heal_nights]], [[guild_upgrades#_recovery_progress]].

### admit
`func admit(character: GuildCharacter) -> bool` · `Globals/guild_upgrades.gd:353`

Puts a hurt hero in a Hospital bed. False if they don't need care or are already a patient. They also leave training. There is no bed-count limit in this function.

**Returns:** `bool`. [[hall_main#admit]] uses it for the toast.

**Side effects:** edits `patients`, `training`, emits `home_changed`.

**Called by:** [[hall_main#admit]] (`hall_main.gd:1277`).

**Calls:** [[guild_upgrades#needs_care]], [[guild_upgrades#is_patient]].

### discharge
`func discharge(character: GuildCharacter) -> void` · `Globals/guild_upgrades.gd:362`

Sends a patient home (emits `home_changed` only if they were one).

**Called by:** [[character_container#remove_character_from_guild]] (`character_container.gd:150`), [[hall_main#discharge]] (`hall_main.gd:1286`).

### can_revive
`func can_revive() -> bool` · `Globals/guild_upgrades.gd:369`

Hospital level 5 brings back one fallen hero per run: true when the Hospital is at `REVIVE_LEVEL` and `revives_used < REVIVES_PER_RUN`.

**Called by:** [[guild_upgrades#revive]] (374), [[home_row#show_fallen]] (`home_row.gd:200`, `:203`).

**Calls:** [[guild_upgrades#get_level]].

### revive
`func revive(character: GuildCharacter) -> bool` · `Globals/guild_upgrades.gd:373`

Brings back a dead hero as Gravely hurt, in a bed. False if reviving isn't allowed, the hero isn't dead, or there's no free bed (the dead take no bed, so coming back needs one).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The dead hero | the chosen hero in [[hall_main#revive]] |

**Returns:** `bool`. [[hall_main#revive]] uses it.

**Side effects:** sets `injury_level`, clears `died_on_day` (-1) and `died_on_quest` (`""`), writes `RECOVERY_META`, increments `revives_used`, adds to `patients`, emits `home_changed`.

**Called by:** [[hall_main#revive]] (`hall_main.gd:1295`).

**Calls:** [[guild_upgrades#can_revive]], [[character_container#has_free_bed]].

### run_night
`func run_night() -> Dictionary` · `Globals/guild_upgrades.gd:396`

Tonight at home: heroes in training gain their stat (`stats[stat] += gain`, `total_points += gain`) and injured heroes heal (patients heal whole stages, others progress one night and drop a level once `get_heal_nights` is reached). Call once when the day ends, before the quests are played out, so nobody heals the night they get hurt. Healed patients go home.

**Returns:** `Dictionary` `{trained: [{character, stat, gain}], healed: [{character, from, to, in_hospital}]}`. [[hall_main#end_day]] puts it in the Day Report.

**Side effects:** changes hero stats and injuries, `RECOVERY_META`, `patients`, emits `home_changed`.

**Called by:** [[hall_main#end_day]] (`hall_main.gd:1522`), [[hall_debug#skip_day]] (`hall_debug.gd:38`).

**Calls:** [[guild_upgrades#_forget_missing_heroes]], [[guild_upgrades#get_training_gain]], [[guild_upgrades#needs_care]], [[guild_upgrades#is_patient]], [[guild_upgrades#get_hospital_stages]], [[guild_upgrades#_recovery_progress]], [[guild_upgrades#get_heal_nights]].

### _recovery_progress
`func _recovery_progress(character: GuildCharacter) -> int` · `Globals/guild_upgrades.gd:437`

Nights already spent healing the hero's current level. It's stored with the level it belongs to, so a new injury restarts the count (0 if the stored level differs).

**Called by:** [[guild_upgrades#get_nights_until_healthy]] (350), [[guild_upgrades#run_night]] (419).

### _forget_missing_heroes
`func _forget_missing_heroes() -> void` · `Globals/guild_upgrades.gd:443`

Drops heroes who left the roster, died, or got too hurt for their slot, from `training` and `patients`.

**Called by:** [[guild_upgrades#run_night]] (397).

**Calls:** [[guild_upgrades#can_train]], [[guild_upgrades#needs_care]].

### _apply_effects
`func _apply_effects() -> void` · `Globals/guild_upgrades.gd:455`

Sets `CharacterContainer.max_characters` from the Barracks level and re-syncs the Armory bonus.

**Called by:** [[guild_upgrades#_ready]] (118), [[guild_upgrades#try_upgrade]] (218), [[guild_upgrades#max_all_buildings]] (231), [[guild_upgrades#reset]] (261).

**Calls:** [[guild_upgrades#get_max_heroes]], [[guild_upgrades#sync_characters]].

### sync_characters
`func sync_characters() -> void` · `Globals/guild_upgrades.gd:463`

Makes every hero's `stats` include exactly the current Armory bonus. The amount already given is stored as `ARMORY_META` on the character, so it is safe to call any number of times: only the difference is applied to STRENGTH and DEFENSE.

**Side effects:** edits `stats`, sets `ARMORY_META`.

**Called by:** signal `CharacterContainer.on_character_added` (connected at line 117), [[guild_upgrades#_process]] (127), [[guild_upgrades#_apply_effects]] (457), [[hall_main#_add_starting_hero]] (`hall_main.gd:491`), [[hall_save#apply_snapshot]] (`hall_save.gd:348`), [[playtest_scenario#_ready]] (`playtest_scenario.gd:69`).

**Calls:** [[guild_upgrades#get_armory_bonus]].

### get_stat_bonus
`func get_stat_bonus(character: GuildCharacter, stat: GuildCharacter.StatType) -> int` · `Globals/guild_upgrades.gd:478`

How much of a hero's stat comes from upgrades (currently just the Armory): `ARMORY_META` x for STRENGTH, y for DEFENSE, else 0.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | the hero being shown or scored |
| `stat` | `GuildCharacter.StatType` | The stat | loop over stats in the caller |

**Returns:** `int`. Shown as the upgrade part of a stat, and counted in the guild power calculation.

**Called by:** [[hire_scaling#guild_power]] (`hire_scaling.gd:48`), [[hall_style#stat_bonus]] (`hall_style.gd:398`), [[screen_character#_show_stats]] (`screen_character.gd:218`).

## Suspected issues
- `Globals/guild_upgrades.gd:353` `admit` doesn't check any bed limit (the Hospital has no capacity constant here). Any limit would be in `HallMain.admit` (not checked).
- `Globals/guild_upgrades.gd:25` the Office is `implemented: false`, so the Office tables (`:34-36`) are used only for text.
- Most functions have no `##` comment.
