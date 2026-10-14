## Mission Charter: pick the party for one quest and see the odds live.
## Every adventurer's four quest stats are on screen while you choose, with
## the quest's favored stat outlined, plus how much each one adds to the odds.
extends TextureRect

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const SlotFilled := preload("res://MobileLedger/Scenes/Rows/charter_slot_filled.tscn")
const SlotEmpty := preload("res://MobileLedger/Scenes/Rows/charter_slot_empty.tscn")
const PickRow := preload("res://MobileLedger/Scenes/Rows/charter_pick_row.tscn")

var ui


func setup(main) -> void:
	ui = main
	%TopBar.back_pressed.connect(func(): ui.close_page())
	%GoHireButton.pressed.connect(func(): ui.open_tab("characters", "hire"))
	%DispatchButton.pressed.connect(dispatch)


func scroll_to_top() -> void:
	%PageScroll.scroll_vertical = 0


func refresh() -> void:
	var e: Dictionary = ui.page.entry
	var q: CreatedQuest = e.quest
	var draft: Array = ui.page.draft
	var n: int = ui.slot_count(e)
	var key := S.type_key(e)

	# --- the charter itself
	%QuestTitle.text = q.questTitle
	%QuestTitle.add_theme_color_override("font_color", S.TYPE_COLORS[key])
	var type_name: String = "Milestone" if e.get("milestone", false) else S.TYPE_NAMES.get(int(q.type), "Quest")
	%QuestSub.text = "[center][color=#6B5537]%s ·[/color] [b]%d Gold[/b] [color=#6B5537]· Rank %s[/color][/center]" % [type_name, q.goldReward, S.rank_letter(q)]
	%QuestPicture.texture = S.tex(S.TYPE_SCENES[key])
	var st: Dictionary = S.STATS[S.favored_index(q)]
	%FavChip.set_icon_chip(st.icon, st.name, st.bg, st.color)

	# --- party slots
	%SlotsTitle.text = "Select 1 Adventurer" if n == 1 else "Select up to %d" % n
	S.clear(%Slots)
	for i in n:
		if i < draft.size():
			S.add_row(%Slots, SlotFilled).setup(self, draft[i])
		else:
			S.add_row(%Slots, SlotEmpty)

	# --- success estimate
	var ch: int = ui.chance_for(e, draft)
	var o: Array = S.odds(ch)
	%ChancePercent.text = "-- %" if ch < 0 else "%d%%" % mini(ch, 100)
	%ChancePercent.add_theme_color_override("font_color", o[1])
	%ChanceWord.text = o[0]
	%ChanceGauge.set_value(0.0 if ch < 0 else minf(ch, 100) / 100.0, o[2])
	var total := 0
	for c in draft:
		total += score(q, c)
	%EstimateNote.text = "Pick adventurers to see the odds" if draft.is_empty() else "Party stat total %d · %d needed for 100%%" % [total, hit(q)]

	# --- roster to pick from
	%FavNote.text = "Each adventurer adds all four stats, plus %s again.%s" % [st.name, " Solo quests need half as much." if n == 1 else ""]
	var roster: Array = CharacterContainer.active_characters.duplicate()
	roster.sort_custom(func(a, b): return score(q, a) > score(q, b))
	S.clear(%PickList)
	for c in roster:
		S.add_row(%PickList, PickRow).setup(self, e, c, draft, n)
	%NoRoster.visible = roster.is_empty()

	# --- dispatch
	var label := "Pick an adventurer"
	if not draft.is_empty():
		label = "Update Party" if e.state == "ready" else "Dispatch Party"
	%DispatchButton.text = label
	%DispatchButton.disabled = draft.is_empty()


static func score(q: CreatedQuest, c: GuildCharacter) -> int:
	var s: Dictionary = c.stats
	var total: int = s[0] + s[1] + s[2] + s[3]
	var f := S.favored_index(q)
	if f < 4:
		total += s[f]
	return total


## CreatedQuest.calcSuccessChance's target for 100%.
static func hit(q: CreatedQuest) -> int:
	var h := 60.0 + 20 * q.difficulty
	if q.maxAdventurers == 1:
		h = h / 2
	return int(h)


func toggle(c: GuildCharacter) -> void:
	var e: Dictionary = ui.page.entry
	var n: int = ui.slot_count(e)
	var draft: Array = ui.page.draft
	if draft.has(c):
		draft.erase(c)
	elif n == 1:
		ui.page.draft = [c]
	elif draft.size() < n:
		draft.append(c)
	ui.queue_refresh()


func dispatch() -> void:
	var e: Dictionary = ui.page.entry
	if ui.page.draft.is_empty():
		return
	ui.set_party(e, ui.page.draft)
	ui.page = {}
	ui.toast("Party ready for %s" % e.quest.questTitle)
	ui.queue_refresh()
