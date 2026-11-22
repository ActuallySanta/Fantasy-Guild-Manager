extends TestCase
## Hospital fee test: beds cost 20 x (standing rank + 1) gold a night, paid in
## admission order; patients the guild can't pay for go home.
## Scene: tools/tests/hospital_fee_test.tscn


func _hurt_hero() -> GuildCharacter:
	var hero := GuildCharacter.new()
	hero.injury_level = GuildCharacter.InjuryLevel.GRAVELY_INJURED
	CharacterContainer.active_characters.append(hero)
	return hero


func _reset(standing: int, gold: int) -> void:
	CharacterContainer.active_characters.clear()
	GuildUpgrades.reset()
	GuildUpgrades.standing = standing
	GuildUpgrades.gold = gold


func _ready() -> void:
	_reset(1, 0)
	check(GuildUpgrades.nightly_fee() == 20, "fee at standing 1 is 20 (got %d)" % GuildUpgrades.nightly_fee())
	GuildUpgrades.standing = 60
	check(GuildUpgrades.nightly_fee() == 120, "fee at standing 60 is 120 (got %d)" % GuildUpgrades.nightly_fee())

	# two patients, enough gold
	_reset(60, 300)
	var a := _hurt_hero()
	var b := _hurt_hero()
	check(GuildUpgrades.admit(a) and GuildUpgrades.admit(b), "both admitted with 300 gold")
	var night := GuildUpgrades.run_night()
	check(night.hospital_bill == 240, "bill is 240 (got %d)" % night.hospital_bill)
	check(GuildUpgrades.gold == 60, "gold left is 60 (got %d)" % GuildUpgrades.gold)

	# three patients, 250 gold: the first two are paid for
	_reset(60, 400)
	a = _hurt_hero()
	b = _hurt_hero()
	var c := _hurt_hero()
	GuildUpgrades.admit(a)
	GuildUpgrades.admit(b)
	GuildUpgrades.admit(c)
	GuildUpgrades.gold = 250
	night = GuildUpgrades.run_night()
	check(night.sent_home_unpaid == [c], "the last admitted goes home unpaid")
	check(not GuildUpgrades.is_patient(c), "the unpaid hero is no longer a patient")
	check(GuildUpgrades.is_patient(a) and GuildUpgrades.is_patient(b), "the paid ones stay in bed")
	check(GuildUpgrades.gold == 10, "gold is exactly the leftover 10 (got %d)" % GuildUpgrades.gold)

	# admit, discharge, admit again: charged once
	_reset(60, 1000)
	a = _hurt_hero()
	GuildUpgrades.admit(a)
	GuildUpgrades.discharge(a)
	GuildUpgrades.admit(a)
	night = GuildUpgrades.run_night()
	check(night.hospital_bill == 120, "re-admitting the same day bills once (got %d)" % night.hospital_bill)

	# discharged before the night: no bill
	_reset(60, 1000)
	a = _hurt_hero()
	GuildUpgrades.admit(a)
	GuildUpgrades.discharge(a)
	night = GuildUpgrades.run_night()
	check(night.hospital_bill == 0 and GuildUpgrades.gold == 1000, "discharged hero costs nothing")

	# can't pay the fee: no admit
	_reset(60, 50)
	a = _hurt_hero()
	check(not GuildUpgrades.admit(a), "admit refused with 50 gold at standing 60")

	CharacterContainer.active_characters.clear()
	GuildUpgrades.reset()
	finish()
