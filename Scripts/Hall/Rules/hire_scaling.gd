## How strong (and how pricey) today's recruits are. Each morning's For Hire
## pool rolls its stats from a budget that keeps up with the guild: the higher
## of a floor set by standing rank and a share of the roster's average power.
## Now and then one applicant is a standout with a bigger budget. Recruits who
## beat the standing floor cost extra on top of the day's price.
## Static rules only: CharacterContainer.refresh_hireable_characters calls these.
class_name HireScaling


# ============================================================ TUNING

## Stat points a recruit gets at standing rank F (0). Matches the old flat
## GuildCharacter.total_points, so a Day 1 recruit is as strong as before.
const BASE_POINTS := 17
## Extra stat points per standing rank (HallRules.standing_rank_for), so rank
## S (5) recruits roll at least BASE_POINTS + 5 * this.
const POINTS_PER_RANK := 4
## Share (0-1) of the roster's average base stat total a recruit is budgeted.
## Under 1 so a typical recruit is a little weaker than a typical veteran.
const POWER_FRACTION := 0.85
## Chance (0-1) each morning that one applicant is a standout.
const STANDOUT_CHANCE := 0.35
## A standout's budget is multiplied by this.
const STANDOUT_BONUS := 1.25
## Gold added to a recruit's price per stat point above the standing floor.
## Only on days that already have a price (recruits stay free on days 1-2).
const PRICE_PER_POINT := 10
## The spread of a recruit's stats (GuildCharacter.stat_deviation) per stat
## point of budget: 2 at the old 17 points, so the spread grows with the budget.
const DEVIATION_PER_POINT := 2.0 / 17.0


# ============================================================ BUDGET

## The guild's average power: the mean base stat total of living heroes, not
## counting the Armory bonus (written into stats, but every hire gets it on
## joining), gear or Pluck (both temporary bonuses).
## roster: CharacterContainer.active_characters.
## Returns 0.0 when nobody is alive.
static func guild_power(roster: Array) -> float:
	var total := 0
	var living := 0
	for character in roster:
		if character == null or character.injury_level >= GuildCharacter.InjuryLevel.DEAD:
			continue
		living += 1
		for stat in character.stats:
			total += character.stats[stat] - GuildUpgrades.get_stat_bonus(character, stat)
	if living == 0:
		return 0.0
	return float(total) / living


## The least stat points a recruit gets at this much standing:
## BASE_POINTS plus POINTS_PER_RANK for each standing rank.
static func standing_floor(standing: int) -> int:
	return BASE_POINTS + POINTS_PER_RANK * HallRules.standing_rank_for(standing)


## Stat points for an ordinary recruit today: the higher of the standing
## floor and POWER_FRACTION of the guild's power, scaled up in freeplay like
## quests are (HallRules.freeplay_scale is 1.0 until then).
## day: GameState.day; standing: GuildUpgrades.standing;
## roster: CharacterContainer.active_characters.
static func recruit_budget(day: int, standing: int, roster: Array) -> int:
	var budget := maxf(standing_floor(standing), guild_power(roster) * POWER_FRACTION)
	return roundi(budget * HallRules.freeplay_scale(day))


## A standout's stat points, from an ordinary recruit's budget.
static func standout_budget(budget: int) -> int:
	return roundi(budget * STANDOUT_BONUS)


## How spread out a recruit's stats are for this budget
## (GuildCharacter.stat_deviation), never under the old 2.
static func deviation_for(points: int) -> int:
	return maxi(2, roundi(points * DEVIATION_PER_POINT))


# ============================================================ PRICE

## What a recruit with `points` stat points costs on `day`: the day's price
## (GuildCharacter.recruit_cost_for_day) plus PRICE_PER_POINT for each point
## over the standing floor. Free days stay free.
## The day's price is still the cheapest a recruit can be, so the Game Over
## check (HallLedger) can keep using recruit_cost_for_day alone.
static func recruit_cost(day: int, standing: int, points: int) -> int:
	var day_price := GuildCharacter.recruit_cost_for_day(day)
	if day_price <= 0:
		return 0
	return day_price + PRICE_PER_POINT * maxi(0, points - standing_floor(standing))
