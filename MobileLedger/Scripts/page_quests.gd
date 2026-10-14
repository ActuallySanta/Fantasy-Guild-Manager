## Quests tab: today's postings as parchment slips with wax seals.
## Accept opens the Mission Charter to pick a party; Deny turns the quest down.
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const QuestCardScene := preload("res://MobileLedger/Scenes/Rows/quest_card.tscn")

var ui


func setup(main) -> void:
	ui = main


func refresh() -> void:
	var denied := 0
	S.clear(%QuestList)
	for e in ui.entries:
		if e.state == "denied":
			denied += 1
			continue
		S.add_row(%QuestList, QuestCardScene).setup(ui, e)
	%QuestList.visible = %QuestList.get_child_count() > 0
	%DeniedNote.visible = denied > 0
	%DeniedNote.text = "%d quest%s denied today" % [denied, "" if denied == 1 else "s"]
	%AllDecided.visible = denied == ui.entries.size()

