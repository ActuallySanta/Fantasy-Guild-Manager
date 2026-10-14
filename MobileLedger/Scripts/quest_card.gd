## One quest slip on the Quests tab (Scenes/Rows/quest_card.tscn).
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const PortraitScene := preload("res://MobileLedger/Scenes/Components/portrait.tscn")
const SlotDashed := preload("res://MobileLedger/Scenes/Components/slot_dashed.tscn")


func setup(ui, e: Dictionary) -> void:
	var q: CreatedQuest = e.quest
	var ready: bool = e.state == "ready"
	var key := S.type_key(e)
	add_theme_stylebox_override("panel", S.panel_box("ready" if ready else "card", Vector4(22, 20, 22, 18)))
	%Seal.set_rank(S.rank_letter(q), e.get("milestone", false))
	%QuestTitle.text = q.questTitle
	%QuestTitle.add_theme_color_override("font_color", S.TYPE_COLORS[key])
	var type_name: String = "Milestone" if e.get("milestone", false) else S.TYPE_NAMES.get(int(q.type), "Quest")
	%TypeGold.text = "[color=#6B5537]%s ·[/color] [b]%d Gold[/b]" % [type_name, q.goldReward]
	var n: int = ui.slot_count(e)
	%PartySize.text = "1 adventurer (solo)" if n == 1 else "Up to %d adventurers" % n
	var st: Dictionary = S.STATS[S.favored_index(q)]
	%FavChip.set_icon_chip(st.icon, st.name, st.bg, st.color)
	var ch: int = ui.chance_for(e, e.party)
	var o: Array = S.odds(ch)
	var ch_text := "--" if ch < 0 else "%d%% · %s" % [mini(ch, 100), o[0]]
	%Success.text = "Success: [b][color=#%s]%s[/color][/b]" % [o[1].to_html(false), ch_text]
	%Picture.texture = S.tex(S.TYPE_SCENES[key])

	%ReadyGroup.visible = ready
	%OpenGroup.visible = not ready
	if ready:
		var names := []
		for c in e.party:
			var p := PortraitScene.instantiate()
			p.custom_minimum_size = Vector2(76, 76)
			%PartyPortraits.add_child(p)
			p.show_character(c)
			names.append(c.name)
		%PartyNames.text = " & ".join(PackedStringArray(names))
		%EditButton.pressed.connect(ui.open_charter.bind(e))
		%CancelButton.pressed.connect(ui.cancel.bind(e))
	else:
		for i in n:
			%Slots.add_child(SlotDashed.instantiate())
		%PickTap.custom_minimum_size.x = n * 90
		%PickTap.pressed.connect(ui.open_charter.bind(e))
		%DenyButton.pressed.connect(ui.deny.bind(e))
		%AcceptButton.pressed.connect(ui.open_charter.bind(e))
