## Quest card face (Scenes/Cards/card_quest.tscn): party slots filled from the
## roster tray, live success chance. Swipe right to send, left to deny.
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const SlotFilled := preload("res://MobileDeck/Scenes/Rows/slot_filled.tscn")
const SlotEmpty := preload("res://MobileDeck/Scenes/Rows/slot_empty.tscn")

var ui


func setup(main) -> void:
	ui = main


func refresh() -> void:
	var e: Dictionary = ui.current().entry
	var q: CreatedQuest = e.quest
	var n: int = ui.slot_count(e)
	var milestone: bool = e.get("milestone", false)

	var type_name: String = "MILESTONE" if milestone else S.TYPE_NAMES.get(int(q.type), "Quest").to_upper()
	%TypeChip.set_chip(type_name, S.BAD_BG if milestone else S.BOX_ALT, S.BAD if milestone else S.INK_SOFT, -1, false)
	%RankChip.set_chip("Rank %s" % S.rank_letter(q), S.BOX_ALT, S.INK, -1, false)
	%GoldChip.set_icon_chip("coins", "%d gold" % q.goldReward, S.GOLD_BG, S.GOLD)
	%QuestTitle.text = q.questTitle
	%QuestTitle.add_theme_color_override("font_color", S.BAD if milestone else S.INK)
	var fi := S.favored_index(q)
	var st: Dictionary = S.STATS[fi]
	%FavChip.set_icon_chip("", st.name, st.bg, st.color, -1, true)
	%FavNote.text = "(counts twice)" if fi < 4 else "(doesn't change odds)"
	%MilestoneNote.visible = milestone

	# party slots: tap a filled one to remove that adventurer
	%PartyLabel.text = "Solo quest" if n == 1 else "Party of up to %d" % n
	var size := 150.0 if n <= 2 else 120.0
	S.clear(%Slots)
	for i in n:
		if i < ui.draft.size():
			S.add_row(%Slots, SlotFilled).setup(ui, ui.draft[i], size)
		else:
			S.add_row(%Slots, SlotEmpty).setup(size)

	var ch_pct: int = ui.chance_for(e, ui.draft)
	var o: Array = S.odds(ch_pct)
	%ChancePercent.text = "--" if ch_pct < 0 else "%d%%" % mini(ch_pct, 100)
	%ChancePercent.add_theme_color_override("font_color", o[1])
	%ChanceWord.text = "chance of success" if ch_pct < 0 else o[0]
	%ChanceWord.add_theme_color_override("font_color", o[1])
	%ChanceGauge.set_value(0.0 if ch_pct < 0 else minf(ch_pct, 100) / 100.0, o[2])

	if CharacterContainer.active_characters.is_empty():
		%Hint.text = "No adventurers yet. Press Back to see the recruits, or swipe left to deny."
	elif ui.draft.is_empty():
		%Hint.text = "Tap adventurers in the tray below to add them.\nThen swipe right to send, or left to deny."
	else:
		%Hint.text = "Swipe right to send this party, left to deny the quest."
