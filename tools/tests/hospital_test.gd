extends TestCase
## Hospital test: at level 5 a Gravely hurt patient needs two nights, and the
## effect text says "2 injury stages".
## Scene: tools/tests/hospital_test.tscn


func _ready() -> void:
	var hero := GuildCharacter.new()
	CharacterContainer.active_characters.append(hero)
	GuildUpgrades.levels[GuildUpgrades.Building.HOSPITAL] = 5
	GuildUpgrades.gold = 1000 # beds cost gold a night
	hero.injury_level = GuildCharacter.InjuryLevel.GRAVELY_INJURED
	check(GuildUpgrades.admit(hero), "a Gravely hurt hero can be admitted")

	GuildUpgrades.run_night()
	check(hero.injury_level == GuildCharacter.InjuryLevel.SORE, "after one night the patient is Sore")
	GuildUpgrades.run_night()
	check(hero.injury_level == GuildCharacter.InjuryLevel.HEALTHY, "after two nights the patient is Healthy")

	var text := GuildUpgrades.get_effect_text(GuildUpgrades.Building.HOSPITAL, 5)
	check(text.contains("2 injury stages"), "level 5 effect text mentions 2 injury stages (got '%s')" % text)

	CharacterContainer.active_characters.erase(hero)
	GuildUpgrades.reset()
	finish()
