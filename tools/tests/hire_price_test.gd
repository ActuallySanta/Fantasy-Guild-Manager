extends TestCase
## Hire price test: a recruit costs 15% more for each living hero above 3, and
## the price charged is the price at the moment of hiring.
## Scene: tools/tests/hire_price_test.tscn


func _ready() -> void:
	check(HireScaling.roster_price(200, 3) == 200, "3 heroes: base price")
	check(HireScaling.roster_price(200, 8) == 350, "8 heroes: +75%%")
	check(HireScaling.roster_price(200, 12) == 470, "12 heroes: +135%%")
	check(HireScaling.roster_price(0, 10) == 0, "free recruits stay free")

	# Roster changes between seeing a price and tapping Hire.
	GuildUpgrades.levels[GuildUpgrades.Building.BARRACKS] = 5
	CharacterContainer.max_characters = 12
	CharacterContainer.active_characters.clear()
	for i in 7:
		CharacterContainer.active_characters.append(GuildCharacter.new())
	var recruit := GuildCharacter.new()
	recruit.cost = 200
	var other := GuildCharacter.new()
	other.cost = 0
	check(CharacterContainer.hire_price(recruit) == 320, "7 living: 320 (got %d)" % CharacterContainer.hire_price(recruit))
	CharacterContainer.add_character_to_guild(other)
	check(CharacterContainer.hire_price(recruit) == 350, "after another hire: 350")
	GameState.add_gold(1000)
	check(CharacterContainer.add_character_to_guild(recruit), "hire succeeds")
	check(GameState.gold == 650, "hiring took exactly 350 (gold %d)" % GameState.gold)

	CharacterContainer.active_characters.clear()
	GuildUpgrades.reset()
	finish()
