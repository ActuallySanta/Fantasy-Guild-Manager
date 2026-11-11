## The Menu's Debug tools (overlay_debug.gd): cheats for testing a run.
## Static functions only. hall_main's debug_* actions call them, then show a
## toast and refresh. None of them count toward run_stats, so the Game Over
## ledger and the credits only show what the player really did.
## Turning the tools on makes the run a debug run (HallMain.is_debug_run),
## which is never saved again.
class_name HallDebug
extends RefCounted

## Gold added per tap of each wallet button (gold; negative takes gold away).
const GOLD_STEPS := [100, 1000]
## Standing added per tap of each standing button (standing; the negative
## step is for testing the danger strip and Game Over).
const STANDING_STEPS := [5, -5]
## Days the "Jump to day" buttons skip ahead to: the Bone Drake and the final battle.
const JUMP_DAYS := [HallMain.MILESTONE_DAY, HallMain.FINAL_DAY]


## True when the day can be skipped right now: not while the night is
## falling or a report, Game Over or the credits are up, and never past the
## final battle (outside freeplay), so it can't be skipped by accident.
## hall: the main hall script.
static func can_skip_day(hall: HallMain) -> bool:
	if hall.is_night_falling or not hall.shown_report.is_empty():
		return false
	if not hall.run_over_stats.is_empty() or not hall.shown_credits.is_empty():
		return false
	return GameState.is_freeplay or GameState.day < HallMain.FINAL_DAY


## Skip to the next dawn: tonight's training and healing still run
## (GuildUpgrades.run_night), but no quest is played and no Day Report shows.
## Today's drafted parties are dropped with today's quests.
## hall: the main hall script. Returns false if the day can't be skipped now.
static func skip_day(hall: HallMain) -> bool:
	if not can_skip_day(hall):
		return false
	GuildUpgrades.run_night()
	hall.start_new_day()
	return true


## True when `day` is still ahead and the day can be skipped (see can_skip_day).
static func can_jump_to(hall: HallMain, day: int) -> bool:
	return day > GameState.day and can_skip_day(hall)


## Skip day after day (skip_day, so healing, training and For Hire move on as
## they would) until `day`. Stops early if the run ends on the way.
## hall: the main hall script. day: the day to land on.
## Returns how many days were skipped.
static func jump_to_day(hall: HallMain, day: int) -> int:
	var skipped := 0
	while GameState.day < day and skip_day(hall):
		skipped += 1
	return skipped


## Put a random hero on the roster for free (they still need a free bed).
## Returns the new hero, or null when the Barracks is full.
static func add_hero() -> GuildCharacter:
	if not CharacterContainer.has_free_bed():
		return null
	var character := GuildCharacter.new()
	# free: add_character_to_guild only charges heroes with a price
	character.cost = 0
	if not CharacterContainer.add_character_to_guild(character):
		return null
	return character


## Put a random piece of gear in the Pack for free (a random role; the rarity
## is rolled as usual, like ItemShop's stock). Returns the new item.
static func add_random_item() -> StandardItem:
	var role: GuildCharacter.CharacterRole = GuildCharacter.CharacterRole.values().pick_random()
	var item := PassiveItem.new(role)
	# set again like ItemShop._make_item does: equipping is role-locked
	item.role = role
	ItemContainer.owned_items.append(item)
	return item


## Every living hero back to Healthy and out of the Hospital, and the dead
## come back Healthy while there's a free bed (this doesn't use up the
## Hospital's revives).
## Returns {"healed": int (living heroes healed), "revived": int,
## "left_dead": int (dead heroes with no bed to come back to)}.
static func heal_everyone() -> Dictionary:
	var counts := {"healed": 0, "revived": 0, "left_dead": 0}
	for character: GuildCharacter in CharacterContainer.active_characters:
		if character == null or character.injury_level == GuildCharacter.InjuryLevel.HEALTHY:
			continue
		if character.injury_level == GuildCharacter.InjuryLevel.DEAD:
			# the dead don't take a bed, so coming back needs a free one
			if not CharacterContainer.has_free_bed():
				counts.left_dead += 1
				continue
			character.died_on_day = -1
			character.died_on_quest = ""
			counts.revived += 1
		else:
			counts.healed += 1
		character.injury_level = GuildCharacter.InjuryLevel.HEALTHY
		if character.has_meta(GuildUpgrades.RECOVERY_META):
			character.remove_meta(GuildUpgrades.RECOVERY_META)
		GuildUpgrades.patients.erase(character)
		character.reset_temp_stats()
	GuildUpgrades.home_changed.emit()
	return counts


## Every building to its top level for free (GuildUpgrades.max_all_buildings).
static func max_buildings() -> void:
	GuildUpgrades.max_all_buildings()


## A fresh For Hire pool for today, without moving the day on. (Today's
## quests are rebuilt by hall_main, which owns them; see HallMain.debug_reroll_today.)
static func reroll_hires() -> void:
	CharacterContainer.refresh_hireable_characters()
