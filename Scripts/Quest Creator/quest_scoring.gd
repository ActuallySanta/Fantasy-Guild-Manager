## Static scoring rules for a quest: its odds, whether a played-out story was a
## win, what it pays, and how many heroes it takes. No nodes, no state.
## Used by HallRules.play_quest, HallWallet's expected-gold forecast and
## HallMain's party drafting. (These used to live on the old prototype UI's
## DayBar and QuestCard.)
class_name QuestScoring
extends RefCounted

## Party size used when a quest doesn't set maxAdventurers (heroes).
const DEFAULT_PARTY_SIZE := 2

## Marker that CreatedQuest.generateResults writes into a failed quest's story.
## A loss must always contain it, since success is detected by searching for it.
const FAIL_MARKER := "NOT SUCCESSFUL"


## The party's chance to win the quest.
## [param quest]: the quest being attempted.
## [param party]: the heroes going on it.
## Returns the chance in percent (0-100, can run past 100 before clamping).
static func get_success_chance(quest: CreatedQuest, party: Array[GuildCharacter]) -> float:
	return quest.calcSuccessChance(party)


## Whether a played-out quest was won. The quest system only reports the result
## inside its story text, so this searches it for FAIL_MARKER.
## [param story]: the BBCode text generateResults returned.
## Returns true on a win.
static func did_succeed(story: String) -> bool:
	return not story.contains(FAIL_MARKER)


## How much gold the guild actually gets for a quest.
## A win pays the full goldReward. A loss only keeps the bonus gold found along
## the way (goldReward grows during play; startingGoldReward is what it began
## at). Item quests start at 0 gold, so they only ever pay that bonus.
## [param quest]: the quest after generateResults has run.
## [param succeeded]: whether it was won (see did_succeed).
## Returns the gold earned.
static func get_gold_earned(quest: CreatedQuest, succeeded: bool) -> int:
	if succeeded:
		return quest.goldReward
	return quest.goldReward - quest.startingGoldReward


## How many heroes a quest takes.
## [param quest]: the quest.
## Returns its maxAdventurers, or DEFAULT_PARTY_SIZE if it doesn't set one.
static func get_slot_count(quest: CreatedQuest) -> int:
	return quest.maxAdventurers if quest.maxAdventurers > 0 else DEFAULT_PARTY_SIZE
