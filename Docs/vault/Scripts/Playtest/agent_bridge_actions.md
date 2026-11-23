---
source: Scripts/Playtest/agent_bridge_actions.gd
class_name: AgentBridgeActions
extends: RefCounted
scene: ""
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# agent_bridge_actions.gd

## Purpose
Rules-mode actions of the agent bridge: `plan`, `end_day` and the test-only hooks (`debug`, `kill_all`). Static functions only. Every change goes through `HallMain`'s public actions, except the test hooks (offered only with `--test-hooks`). Ids are the strings from [[agent_bridge_state]]. Used by [[agent_bridge]]. No scene. Excluded from exports.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `MAX_SETTLE_SECONDS` | const | Longest `end_day` waits for the night to settle (20 s). |
| `DEBUG_PREFIX` | const | A `debug` call must name a `debug_` method of the hall. |
| `REASON_GAME_OVER`, `REASON_FINAL_WON`, `REASON_FINAL_LOST` | const | `run_over_reason` values: `game_over`, `final_won`, `final_lost`. |
| `BBCODE_TAG_PATTERN` | const | Regex matching `[b]`, `[/color]`, `[color=#fff]`. |

## Functions

### is_run_over
`static func is_run_over(hall: HallMain) -> bool` · `Scripts/Playtest/agent_bridge_actions.gd:28`

True once the Game Over ledger or the final battle's credits are showing (`run_over_stats` or `shown_credits` not empty).

**Called by:** [[agent_bridge#_dispatch]] (`agent_bridge.gd:185`, refuses `ACTION_COMMANDS`), [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:258`, the `run_over` field), [[agent_bridge_state#build]] (`agent_bridge_state.gd:33`).

### run_over_reason
`static func run_over_reason(hall: HallMain) -> Variant` · `Scripts/Playtest/agent_bridge_actions.gd:33`

**Returns:** `REASON_FINAL_WON` / `REASON_FINAL_LOST` (by `hall.run_stats.final_result`) when credits show, `REASON_GAME_OVER` when the ledger shows, else null. Used by [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:259`).

### use_rules_motion
`static func use_rules_motion(hall: HallMain) -> void` · `Scripts/Playtest/agent_bridge_actions.gd:43`

Turns reduce motion on if it is off, so the night settles in a few frames.

**Side effects:** [[hall_main#set_reduce_motion]].

**Called by:** [[agent_bridge_actions#plan]] (`:56`), [[agent_bridge_actions#end_day]] (`:242`).

### plan
`static func plan(hall: HallMain, plan_args: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:55`

Runs one day plan. Keys run in this order, any may be missing: hire, release, buy, equip, unequip, train, stop_training, admit, discharge, revive, upgrade, assign, deny.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | Running hall | `_hall` in [[agent_bridge#_dispatch]] |
| `plan_args` | `Dictionary` | Lists of ids / pairs / indices per key | the `plan` command's `args` |

**Returns:** `{ok, applied: [String], rejected: [{step, reason}], state}`. Sent to the client by [[agent_bridge#_dispatch]] (`agent_bridge.gd:205`).

**Side effects:** many hall actions (hire, gold spent, equip, training, upgrades, party assignments, denied quests).

**Called by:** [[agent_bridge#_dispatch]] (`agent_bridge.gd:205`), command `plan`.

**Calls:** [[agent_bridge_actions#use_rules_motion]], [[agent_bridge_actions#_list]], [[agent_bridge_actions#_hire]], [[agent_bridge_actions#_release]], [[agent_bridge_actions#_buy]], [[agent_bridge_actions#_equip]], [[agent_bridge_actions#_unequip]], [[agent_bridge_actions#_train]], [[agent_bridge_actions#_hero_step]], [[agent_bridge_actions#_upgrade]], [[agent_bridge_actions#_assign]], [[agent_bridge_actions#_deny]], [[agent_bridge_state#build]], [[guild_upgrades#is_training]], [[guild_upgrades#is_patient]], [[hall_style#is_dead]].

> [!note] How it works
> A local lambda `record(step, reason)` files each step as applied (empty reason) or rejected. `stop_training`, `admit`, `discharge` and `revive` go through `_hero_step` with the hall's `stop_training`, `admit`, `discharge`, `revive` actions and a check lambda. `assign` takes `{quest, party: [ids]}`; a non-dictionary entry is rejected with "expected {quest, party}".

### _list
`static func _list(plan_args: Dictionary, key: String) -> Array` · `Scripts/Playtest/agent_bridge_actions.gd:107`

`plan_args[key]` as an Array, empty when missing or not a list. Called by [[agent_bridge_actions#plan]] for each key (`:66`-`:100`).

### _hire
`static func _hire(hall: HallMain, id: String) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:113`

Hires the For Hire applicant with this id (from `CharacterContainer.hireable_characters`). **Returns:** "" on success, else "locked", "no such applicant" or "cannot hire (gold or roster full)". Called by [[agent_bridge_actions#plan]] (`:67`); the string becomes the `reason`.

**Calls:** [[hall_main#is_locked]], [[agent_bridge_state#find_by_id]], [[hall_main#hire]].

### _release
`static func _release(hall: HallMain, id: String) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:123`

Lets a roster hero go. **Returns:** "" or "no such hero" / "could not release". Called by [[agent_bridge_actions#plan]] (`:69`).

**Calls:** [[agent_bridge_state#find_by_id]], [[hall_main#release]].

### _buy
`static func _buy(hall: HallMain, index: int) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:132`

Buys a shop item by stock index. **Returns:** "" or "locked" / "no such shop item" / "already sold" / "cannot afford". Called by [[agent_bridge_actions#plan]] (`:71`).

**Calls:** [[hall_main#is_locked]], [[item_shop#get_item]], [[item_shop#is_sold]], [[hall_main#buy_item]].

### _equip
`static func _equip(hall: HallMain, pair: Variant) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:144`

`pair` is `[item_id, hero_id]`. **Returns:** "" or "expected [item_id, hero_id]" / "no such item or hero" / "cannot equip (role, slots or dead)". Called by [[agent_bridge_actions#plan]] (`:73`).

**Calls:** [[agent_bridge_state#find_by_id]], [[hall_main#equip_item]].

### _unequip
`static func _unequip(hall: HallMain, id: String) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:156`

Takes an owned item off its wearer. **Returns:** "" or "no such item" / "not worn" / "could not unequip". Called by [[agent_bridge_actions#plan]] (`:75`).

**Calls:** [[agent_bridge_state#find_by_id]], [[hall_main#unequip_item]].

### _train
`static func _train(hall: HallMain, pair: Variant) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:167`

`pair` is `[hero_id, stat]` (stat as a `StatType` int). **Returns:** "" or "expected [hero_id, stat]" / "no such hero" / "cannot train (hurt or no free slot)". Called by [[agent_bridge_actions#plan]] (`:77`).

**Calls:** [[agent_bridge_state#find_by_id]], [[hall_main#train]], [[guild_upgrades#is_training]].

### _hero_step
`static func _hero_step(hall: HallMain, id: String, action: Callable, check: Callable) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:179`

Runs a one-hero hall action then a check. `action`: the hall's Callable (`hall.stop_training`, `hall.admit`, ...); `check`: returns "" when the result is right, else a reason. **Returns:** "" or "no such hero" or the check's reason. Called by [[agent_bridge_actions#plan]] (`:79`, `:82`, `:85`, `:88`).

**Calls:** [[agent_bridge_state#find_by_id]], [[hall_main#stop_training]], [[hall_main#admit]], [[hall_main#discharge]], [[hall_main#revive]] (as the passed callables).

### _upgrade
`static func _upgrade(hall: HallMain, building: int) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:188`

Upgrades a building by id. **Returns:** "" if its level went up, else "locked" / "cannot upgrade (gold or max level)". Called by [[agent_bridge_actions#plan]] (`:91`).

**Calls:** [[hall_main#is_locked]], [[guild_upgrades#get_level]], [[hall_main#upgrade_building]].

### _assign
`static func _assign(hall: HallMain, quest: int, id: String) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:197`

Opens the quest's assign screen and puts the hero in its party (skipped if already in, since `toggle_in_party` would remove it). **Returns:** "" or "no such quest" / "no such hero" / "cannot join (hurt, busy, party full or quest denied)". Called by [[agent_bridge_actions#plan]] (`:99`).

**Calls:** [[agent_bridge_state#find_by_id]], [[hall_main#open_assign]], [[hall_main#toggle_in_party]].

### _deny
`static func _deny(hall: HallMain, quest: int) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:212`

Denies a quest by Board index. **Returns:** "" or "locked" / "no such quest" / "already denied" / "the final battle cannot be denied" / "cannot deny". Called by [[agent_bridge_actions#plan]] (`:101`).

**Calls:** [[hall_main#is_locked]], [[hall_main#can_deny_quest]], [[hall_main#open_assign]], [[hall_main#deny_quest]].

### end_day
`static func end_day(hall: HallMain, tree: SceneTree) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:233`

Coroutine. Plays the night out and, unless the run ended, starts the next day. Refuses with `{ok: false, error, undecided}` when quests are still open, and with an error when the night is already falling. Waits (frame by frame, up to `MAX_SETTLE_SECONDS`) until the report, credits or boss crawl shows; a boss crawl is closed with `close_boss_crawl`. The report comes from `shown_report`, or `previous_report` for credits.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | Running hall | `_hall` in [[agent_bridge#_dispatch]] |
| `tree` | `SceneTree` | For frame waits | `get_tree()` in [[agent_bridge#_dispatch]] |

**Returns:** `{ok, report: {results, home}, run_over, run_over_reason, state?}` (`state` only if the next day began), or `{ok: false, error}` ("night did not settle in 20 seconds" on timeout). Sent to the client by [[agent_bridge#_dispatch]] (`agent_bridge.gd:207`).

**Side effects:** runs the whole night, starts the next day (emits `day_started`).

**Called by:** [[agent_bridge#_dispatch]] (`agent_bridge.gd:207`), command `end_day`.

**Calls:** [[hall_main#undecided_count]], [[agent_bridge_actions#use_rules_motion]], [[hall_main#end_day]], [[agent_bridge_actions#_is_settled]], [[hall_main#close_boss_crawl]], [[agent_bridge_actions#_report]], [[hall_main#start_new_day]], [[agent_bridge_state#build]], [[agent_bridge_actions#is_run_over]], [[agent_bridge_actions#run_over_reason]].

### _is_settled
`static func _is_settled(hall: HallMain) -> bool` · `Scripts/Playtest/agent_bridge_actions.gd:264`

True once the night has played out (not `is_night_falling`, and the report, credits or boss crawl is showing). Called by [[agent_bridge_actions#end_day]] (`:245`).

### _report
`static func _report(raw: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:272`

Makes the Day Report JSON-ready: per result `{quest, succeeded, gold, injuries, deaths, story_text}` (BBCode stripped) plus `home`. `raw` is the hall's report dictionary (`shown_report` or `previous_report`). Called by [[agent_bridge_actions#end_day]] (`:254`).

**Calls:** [[agent_bridge_actions#strip_bbcode]], [[agent_bridge_actions#_home]]; `_named_hero` is passed as a `map` callable.

### _named_hero
`static func _named_hero(hero: GuildCharacter) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:287`

`{id, name, injury}` for a hero in a result. Used as a Callable in [[agent_bridge_actions#_report]] (`:279`, `:280`).

**Calls:** [[agent_bridge_state#id_of]].

### _home
`static func _home(raw: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:296`

Converts `GuildUpgrades.run_night`'s `{trained, healed, hospital_bill, sent_home_unpaid}` so heroes and stats appear as names. Called by [[agent_bridge_actions#_report]] (`:283`).

### strip_bbcode
`static func strip_bbcode(text: String) -> String` · `Scripts/Playtest/agent_bridge_actions.gd:320`

Removes BBCode tags matching `BBCODE_TAG_PATTERN`. `text`: the quest story BBCode. **Returns:** plain text. Called by [[agent_bridge_actions#_report]] (`:281`).

### debug
`static func debug(hall: HallMain, call_args: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:331`

Test hook. Calls one of the hall's `debug_*` methods by name with `args`. **Returns:** `{ok, state}` or `{ok: false, error: "not a debug_ action: X"}`. Called by [[agent_bridge#_dispatch]] (`agent_bridge.gd:221`) only with `--test-hooks`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `call_args` | `Dictionary` | `{call: String, args: Array}` | the command's `args` |

**Calls:** [[agent_bridge_state#build]].

### kill_all
`static func kill_all(hall: HallMain) -> Dictionary` · `Scripts/Playtest/agent_bridge_actions.gd:342`

Test hook. Sets every roster hero's `injury_level` to DEAD. **Returns:** `{ok, killed}`. Called by [[agent_bridge#_dispatch]] (`agent_bridge.gd:220`) only with `--test-hooks`.

## Suspected issues
- `agent_bridge_actions.gd:79-89`: `_hero_step` actions (`stop_training`, `admit`, `discharge`, `revive`) are not locked-checked, unlike hire, buy and upgrade; not traced whether the hall guards them.
- `agent_bridge_actions.gd:233`: the `agent_bridge_actions.gd:243` hit in the index (`hall.end_day()`) is the hall's method, not a recursive call.
