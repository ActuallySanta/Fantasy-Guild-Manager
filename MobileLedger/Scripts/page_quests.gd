## Quests tab: today's postings as parchment slips with wax seals.
## Accept opens the Mission Charter to pick a party; Deny turns the quest down.
## Denied quests drop off the list.
## Scene: MobileLedger/Scenes/Pages/page_quests.tscn
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const QuestSlip := preload("res://MobileLedger/Scenes/Rows/quest_card.tscn")

const TEXT_DENIED := "%d %s denied today"

@onready var _quest_list: Container = %QuestList
@onready var _denied_note: Label = %DeniedNote
@onready var _all_decided: Control = %AllDecided

var ui: Main


func setup(main: Main) -> void:
	ui = main


func refresh() -> void:
	S.clear(_quest_list)
	for e in ui.entries:
		if e.state != "denied":
			S.add_row(_quest_list, QuestSlip).setup(ui, e)
	_quest_list.visible = _quest_list.get_child_count() > 0
	var denied: int = ui.denied_count()
	_denied_note.visible = denied > 0
	_denied_note.text = TEXT_DENIED % [denied, S.plural(denied, "quest", "quests")]
	_all_decided.visible = denied == ui.entries.size()
