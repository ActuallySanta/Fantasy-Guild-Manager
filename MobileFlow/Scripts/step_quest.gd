## Step 2: Quests. One quest per screen with the party picker right under it.
## Send or Deny moves straight on to the next undecided quest.
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const QuestDot := preload("res://MobileFlow/Scenes/Rows/quest_dot.tscn")
const PickRow := preload("res://MobileFlow/Scenes/Rows/pick_row.tscn")
const SlotFilled := preload("res://MobileFlow/Scenes/Rows/slot_filled.tscn")
const SlotEmpty := preload("res://MobileFlow/Scenes/Rows/slot_empty.tscn")

var ui


func setup(main) -> void:
	ui = main
	%GoHireButton.pressed.connect(func(): ui.go_step("hire"))
	%ToEndButton.pressed.connect(func(): ui.go_step("end"))
	%ChangeButton.pressed.connect(func(): ui.reopen_quest())
	%NextButton.pressed.connect(func(): ui._advance())
	%DenyButton.pressed.connect(func(): ui.deny_quest())
	%SendButton.pressed.connect(func(): ui.send_party())


func footer_height() -> float:
	return %Footer.size.y


func scroll_to_top() -> void:
	%Scroll.scroll_vertical = 0


func refresh() -> void:
	var e: Dictionary = ui.current_entry()
	var has_quest := not e.is_empty()
	%NoQuests.visible = not has_quest
	%ToEndButton.visible = not has_quest
	for n in [%QuestNav, %QuestCard, %DecisionPanel, %OddsPanel, %NoRoster, %PickHeading, %PickList, %DecidedButtons, %OpenButtons]:
		n.visible = has_quest
	if not has_quest:
		return

	var q: CreatedQuest = e.quest
	var n: int = ui.slot_count(e)
	var decided: bool = e.state != "open"

	# --- which quest of today's board this is
	%QuestOf.text = "Quest %d of %d" % [ui.quest_index + 1, ui.entries.size()]
	S.clear(%Dots)
	for i in ui.entries.size():
		S.add_row(%Dots, QuestDot).setup(ui, i)

	# --- the quest
	var milestone: bool = e.get("milestone", false)
	%QuestTitle.text = q.questTitle
	%QuestTitle.add_theme_color_override("font_color", S.BAD if milestone else S.INK)
	var type_name: String = "Milestone" if milestone else S.TYPE_NAMES.get(int(q.type), "Quest")
	%TypeChip.set_chip("%s, Rank %s" % [type_name, S.rank_letter(q)])
	%GoldChip.set_icon_chip("coins", "%d gold" % q.goldReward, S.GOLD_BG, S.GOLD)
	%PartyChip.set_chip("Solo" if n == 1 else "Party of up to %d" % n)
	var fi := S.favored_index(q)
	var st: Dictionary = S.STATS[fi]
	%FavChip.set_icon_chip("", st.name, st.bg, st.color, 22, true)
	%FavNote.text = "(counts twice)" if fi < 4 else "(Pluck doesn't change the odds)"
	%MilestoneNote.visible = milestone

	# --- decision already made?
	%DecisionPanel.visible = decided
	if decided:
		var ok: bool = e.state == "ready"
		%DecisionPanel.add_theme_stylebox_override("panel", S.flat(S.GOOD_BG if ok else S.BAD_BG, 0, 1, S.GOOD if ok else S.BAD, Vector4(14, 10, 14, 10)))
		var names := []
		for c in e.party:
			names.append(c.name)
		%DecisionText.text = "Party set: %s. They leave when the day ends." % ", ".join(PackedStringArray(names)) if ok else "You denied this quest."
		%DecisionText.add_theme_color_override("font_color", S.GOOD if ok else S.BAD)

	# --- party slots + odds
	var party: Array = e.party if decided else ui.draft
	S.clear(%Slots)
	for i in n:
		if i < party.size():
			S.add_row(%Slots, SlotFilled).show_character(party[i])
		else:
			S.add_row(%Slots, SlotEmpty)
	var ch: int = ui.chance_for(e, party)
	var o: Array = S.odds(ch)
	%ChancePercent.text = "--" if ch < 0 else "%d%%" % mini(ch, 100)
	%ChancePercent.add_theme_color_override("font_color", o[1])
	%ChanceWord.text = o[0]
	%ChanceWord.add_theme_color_override("font_color", o[1])
	%ChanceGauge.set_value(0.0 if ch < 0 else minf(ch, 100) / 100.0, o[2])

	# --- party picker
	var roster: Array = CharacterContainer.active_characters.duplicate()
	%NoRoster.visible = roster.is_empty()
	%PickHeading.visible = not roster.is_empty() and not decided
	%PickList.visible = %PickHeading.visible
	S.clear(%PickList)
	if %PickList.visible:
		roster.sort_custom(func(a, b): return _score(q, a) > _score(q, b))
		for c in roster:
			S.add_row(%PickList, PickRow).setup(ui, e, c, n)

	# --- footer
	%DecidedButtons.visible = decided
	%OpenButtons.visible = not decided
	var ready: bool = not ui.draft.is_empty()
	%SendButton.text = "Send party" if ready else "Pick a party first"
	%SendButton.disabled = not ready
	S.style_button(%SendButton, "green" if ready else "")


## Same total CreatedQuest.calcSuccessChance uses: all four stats, favored one twice.
static func _score(q: CreatedQuest, c: GuildCharacter) -> int:
	var s: Dictionary = c.stats
	var total: int = s[0] + s[1] + s[2] + s[3]
	var f := S.favored_index(q)
	if f < 4:
		total += s[f]
	return total
