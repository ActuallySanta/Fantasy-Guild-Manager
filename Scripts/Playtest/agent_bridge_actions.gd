## Rules-mode actions of the agent bridge: `plan`, `end_day` and the
## test-only hooks (`debug`, `kill_all`).
## Used by: Scripts/Playtest/agent_bridge.gd. No scene.
##
## Static functions only, no state (run state lives on the bridge node). Every
## change to the game goes through HallMain's public actions; the only
## exceptions are the test hooks, which the bridge offers only when launched
## with --test-hooks. Ids are the strings AgentBridgeState emits.
## This script is excluded from exports (export_presets.cfg exclude_filter).
class_name AgentBridgeActions
extends RefCounted

## Longest the bridge waits for the night to settle (the report, the credits
## or Game Over showing), in seconds. A hung night answers with an error.
const MAX_SETTLE_SECONDS := 20
## Name prefix a `debug` call must have (it can only reach HallMain's debug_* actions).
const DEBUG_PREFIX := "debug_"
## `run_over_reason` values.
const REASON_GAME_OVER := "game_over"
const REASON_FINAL_WON := "final_won"
const REASON_FINAL_LOST := "final_lost"
## Matches a BBCode tag such as [b], [/color] or [color=#fff].
const BBCODE_TAG_PATTERN := "\\[/?[a-zA-Z_]+(=[^\\]]*)?\\]"


## True once the run has ended for good: the Game Over ledger or the final
## battle's credits are showing. hall: the running hall.
static func is_run_over(hall: HallMain) -> bool:
	return not hall.run_over_stats.is_empty() or not hall.shown_credits.is_empty()


## Why the run is over (REASON_*), or null while it goes on. hall: the running hall.
static func run_over_reason(hall: HallMain) -> Variant:
	if not hall.shown_credits.is_empty():
		return REASON_FINAL_WON if hall.run_stats.final_result == HallMain.FINAL_RESULT_WON else REASON_FINAL_LOST
	if not hall.run_over_stats.is_empty():
		return REASON_GAME_OVER
	return null


## Reduced motion makes the hall skip its animations, so the night settles in a
## few frames. hall: the running hall.
static func use_rules_motion(hall: HallMain) -> void:
	if not hall.reduce_motion:
		hall.set_reduce_motion(true)


# ---- plan


## Runs one day plan. plan_args: {hire, release, buy, equip, unequip, train,
## stop_training, admit, discharge, revive, upgrade, assign, deny}, run in that
## order; any key may be missing. hall: the running hall.
## Returns {ok, applied: [String], rejected: [{step, reason}], state}.
static func plan(hall: HallMain, plan_args: Dictionary) -> Dictionary:
	use_rules_motion(hall)
	var applied: Array = []
	var rejected: Array = []
	# records one step: an empty reason means it worked
	var log := func(step: String, reason: String) -> void:
		if reason == "":
			applied.append(step)
		else:
			rejected.append({"step": step, "reason": reason})

	for id in _list(plan_args, "hire"):
		log.call("hire %s" % id, _hire(hall, str(id)))
	for id in _list(plan_args, "release"):
		log.call("release %s" % id, _release(hall, str(id)))
	for index in _list(plan_args, "buy"):
		log.call("buy %d" % int(index), _buy(hall, int(index)))
	for pair in _list(plan_args, "equip"):
		log.call("equip %s" % [pair], _equip(hall, pair))
	for id in _list(plan_args, "unequip"):
		log.call("unequip %s" % id, _unequip(hall, str(id)))
	for pair in _list(plan_args, "train"):
		log.call("train %s" % [pair], _train(hall, pair))
	for id in _list(plan_args, "stop_training"):
		log.call("stop_training %s" % id, _hero_step(hall, str(id), hall.stop_training,
				func(hero): return "" if not GuildUpgrades.is_training(hero) else "still training"))
	for id in _list(plan_args, "admit"):
		log.call("admit %s" % id, _hero_step(hall, str(id), hall.admit,
				func(hero): return "" if GuildUpgrades.is_patient(hero) else "no free bed or not hurt"))
	for id in _list(plan_args, "discharge"):
		log.call("discharge %s" % id, _hero_step(hall, str(id), hall.discharge,
				func(hero): return "" if not GuildUpgrades.is_patient(hero) else "still in a bed"))
	for id in _list(plan_args, "revive"):
		log.call("revive %s" % id, _hero_step(hall, str(id), hall.revive,
				func(hero): return "" if not HallStyle.is_dead(hero) else "could not revive"))
	for building in _list(plan_args, "upgrade"):
		log.call("upgrade %d" % int(building), _upgrade(hall, int(building)))
	for assignment in _list(plan_args, "assign"):
		if not assignment is Dictionary:
			log.call("assign %s" % [assignment], "expected {quest, party}")
			continue
		var quest := int(assignment.get("quest", -1))
		var party: Array = assignment.get("party", []) if assignment.get("party", []) is Array else []
		for id in party:
			log.call("assign %s to quest %d" % [id, quest], _assign(hall, quest, str(id)))
	for index in _list(plan_args, "deny"):
		log.call("deny %d" % int(index), _deny(hall, int(index)))

	return {"ok": true, "applied": applied, "rejected": rejected, "state": AgentBridgeState.build(hall)}


## plan_args[key] as an Array (empty when missing or not a list).
static func _list(plan_args: Dictionary, key: String) -> Array:
	var value: Variant = plan_args.get(key, [])
	return value if value is Array else []


## Hires an applicant. Returns "" on success, else the reason it failed.
static func _hire(hall: HallMain, id: String) -> String:
	if hall.is_locked("hire"):
		return "locked"
	var applicant := AgentBridgeState.find_by_id(CharacterContainer.hireable_characters, id) as GuildCharacter
	if applicant == null:
		return "no such applicant"
	return "" if hall.hire(applicant) else "cannot hire (gold or roster full)"


## Lets a hero go. Returns "" on success, else the reason.
static func _release(hall: HallMain, id: String) -> String:
	var hero := AgentBridgeState.find_by_id(hall.roster(), id) as GuildCharacter
	if hero == null:
		return "no such hero"
	hall.release(hero)
	return "" if not hall.roster().has(hero) else "could not release"


## Buys a shop item by stock index. Returns "" on success, else the reason.
static func _buy(hall: HallMain, index: int) -> String:
	if hall.is_locked("shop"):
		return "locked"
	if ItemShop.get_item(index) == null:
		return "no such shop item"
	if ItemShop.is_sold(index):
		return "already sold"
	hall.buy_item(index)
	return "" if ItemShop.is_sold(index) else "cannot afford"


## Equips [item_id, hero_id]. Returns "" on success, else the reason.
static func _equip(hall: HallMain, pair: Variant) -> String:
	if not pair is Array or pair.size() != 2:
		return "expected [item_id, hero_id]"
	var item := AgentBridgeState.find_by_id(ItemContainer.owned_items, str(pair[0])) as StandardItem
	var hero := AgentBridgeState.find_by_id(hall.roster(), str(pair[1])) as GuildCharacter
	if item == null or hero == null:
		return "no such item or hero"
	hall.equip_item(item, hero)
	return "" if item.curr_user == hero else "cannot equip (role, slots or dead)"


## Takes an item off its wearer. Returns "" on success, else the reason.
static func _unequip(hall: HallMain, id: String) -> String:
	var item := AgentBridgeState.find_by_id(ItemContainer.owned_items, id) as StandardItem
	if item == null:
		return "no such item"
	if item.curr_user == null:
		return "not worn"
	hall.unequip_item(item)
	return "" if item.curr_user == null else "could not unequip"


## Starts training [hero_id, stat]. Returns "" on success, else the reason.
static func _train(hall: HallMain, pair: Variant) -> String:
	if not pair is Array or pair.size() != 2:
		return "expected [hero_id, stat]"
	var hero := AgentBridgeState.find_by_id(hall.roster(), str(pair[0])) as GuildCharacter
	if hero == null:
		return "no such hero"
	hall.train(hero, int(pair[1]))
	return "" if GuildUpgrades.is_training(hero) else "cannot train (hurt or no free slot)"


## Runs a one-hero hall action. action: the hall's Callable; check: returns ""
## when the result is right, else a reason. Returns "" on success, else the reason.
static func _hero_step(hall: HallMain, id: String, action: Callable, check: Callable) -> String:
	var hero := AgentBridgeState.find_by_id(hall.roster(), id) as GuildCharacter
	if hero == null:
		return "no such hero"
	action.call(hero)
	return check.call(hero)


## Upgrades a building by id. Returns "" on success, else the reason.
static func _upgrade(hall: HallMain, building: int) -> String:
	if hall.is_locked("upgrades"):
		return "locked"
	var level_before := GuildUpgrades.get_level(building)
	hall.upgrade_building(building)
	return "" if GuildUpgrades.get_level(building) > level_before else "cannot upgrade (gold or max level)"


## Pins a hero on a quest's party. Returns "" on success, else the reason.
static func _assign(hall: HallMain, quest: int, id: String) -> String:
	if quest < 0 or quest >= hall.quest_entries.size():
		return "no such quest"
	var hero := AgentBridgeState.find_by_id(hall.roster(), id) as GuildCharacter
	if hero == null:
		return "no such hero"
	hall.open_assign(quest)
	var entry: Dictionary = hall.quest_entries[quest]
	# toggle_in_party would take a hero already in the party back out
	if not entry.party.has(hero):
		hall.toggle_in_party(hero)
	return "" if entry.party.has(hero) else "cannot join (hurt, busy, party full or quest denied)"


## Denies a quest by Board index. Returns "" on success, else the reason.
static func _deny(hall: HallMain, quest: int) -> String:
	if hall.is_locked("deny"):
		return "locked"
	if quest < 0 or quest >= hall.quest_entries.size():
		return "no such quest"
	hall.open_assign(quest)
	hall.deny_quest()
	return "" if hall.quest_entries[quest].state == HallStyle.QUEST_STATE_DENIED else "cannot deny"


# ---- end of day


## Plays the night out and, unless the run ended, starts the next day. A
## coroutine: await it. hall: the running hall. tree: the scene tree (frames
## to wait on). Returns {ok, report: {results, home}, run_over, run_over_reason,
## state?} (state is there when the next day began) or {ok: false, error}.
static func end_day(hall: HallMain, tree: SceneTree) -> Dictionary:
	if hall.undecided_count() > 0:
		var open: Array = []
		for index in hall.quest_entries.size():
			if hall.quest_entries[index].state == HallStyle.QUEST_STATE_OPEN:
				open.append(index)
		return {"ok": false, "error": "undecided quests: %s" % [open], "undecided": open}
	if hall.is_night_falling:
		return {"ok": false, "error": "the night is already falling"}
	use_rules_motion(hall)
	hall.end_day()
	var deadline := Time.get_ticks_msec() + MAX_SETTLE_SECONDS * 1000
	while not _is_settled(hall):
		if Time.get_ticks_msec() > deadline:
			return {"ok": false, "error": "night did not settle in %d seconds" % MAX_SETTLE_SECONDS}
		await tree.process_frame
	# the credits keep their night in previous_report, the Day Report in shown_report
	var raw_report: Dictionary = hall.shown_report if not hall.shown_report.is_empty() else hall.previous_report
	var response := {"ok": true, "report": _report(raw_report)}
	if hall.shown_credits.is_empty():
		hall.start_new_day()
		response["state"] = AgentBridgeState.build(hall)
	response["run_over"] = is_run_over(hall)
	response["run_over_reason"] = run_over_reason(hall)
	return response


## True once the night has played out: the report or the credits show.
static func _is_settled(hall: HallMain) -> bool:
	if hall.is_night_falling:
		return false
	return not hall.shown_report.is_empty() or not hall.shown_credits.is_empty()


## The JSON-ready report. raw: a Day Report dictionary (HallMain.end_day).
static func _report(raw: Dictionary) -> Dictionary:
	var results: Array = []
	for result in raw.get("results", []):
		results.append({
			"quest": result.quest.questTitle,
			"succeeded": result.succeeded,
			"gold": result.gold,
			"injuries": result.injured.map(_named_hero),
			"deaths": result.died.map(_named_hero),
			"story_text": strip_bbcode(result.story),
		})
	return {"results": results, "home": _home(raw.get("home", {}))}


## {id, name, injury} for a hero in a result.
static func _named_hero(hero: GuildCharacter) -> Dictionary:
	return {
		"id": AgentBridgeState.id_of(hero),
		"name": hero.name,
		"injury": GuildCharacter.InjuryLevel.keys()[hero.injury_level],
	}


## GuildUpgrades.run_night's {trained, healed} with heroes and stats as names.
static func _home(raw: Dictionary) -> Dictionary:
	var trained: Array = []
	for entry in raw.get("trained", []):
		trained.append({"hero": entry.character.name, "stat": GuildCharacter.StatType.keys()[entry.stat], "gain": entry.gain})
	var healed: Array = []
	for entry in raw.get("healed", []):
		healed.append({
			"hero": entry.character.name,
			"from": GuildCharacter.InjuryLevel.keys()[entry.from],
			"to": GuildCharacter.InjuryLevel.keys()[entry.to],
			"in_hospital": entry.in_hospital,
		})
	return {"trained": trained, "healed": healed}


## Story text without its BBCode tags. text: BBCode. Returns plain text.
static func strip_bbcode(text: String) -> String:
	var regex := RegEx.new()
	regex.compile(BBCODE_TAG_PATTERN)
	return regex.sub(text, "", true)


# ---- test hooks (only offered with --test-hooks)


## Calls one of HallMain's debug_* actions. call_args: {call: String, args: Array}.
## Returns {ok, state} or {ok: false, error}.
static func debug(hall: HallMain, call_args: Dictionary) -> Dictionary:
	var call_name := str(call_args.get("call", ""))
	if not call_name.begins_with(DEBUG_PREFIX) or not hall.has_method(call_name):
		return {"ok": false, "error": "not a debug_ action: %s" % call_name}
	var args: Array = call_args.get("args", []) if call_args.get("args", []) is Array else []
	hall.callv(call_name, args)
	return {"ok": true, "state": AgentBridgeState.build(hall)}


## Marks every hero dead, the way a quest death does (injury_level DEAD, which
## HallStyle.is_dead reads). hall: the running hall. Returns {ok, killed}.
static func kill_all(hall: HallMain) -> Dictionary:
	for hero in hall.roster():
		hero.injury_level = GuildCharacter.InjuryLevel.DEAD
	return {"ok": true, "killed": hall.roster().size()}
