## One quest result in the Home tab's "Last Night" card (Scenes/Rows/last_row.tscn).
extends HBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func setup(res: Dictionary) -> void:
	%Icon.texture = S.icon_tex("check" if res.succeeded else "x")
	%Icon.modulate = S.GREEN_TEXT if res.succeeded else S.WAX
	%QuestName.text = res.quest.questTitle
	%Gold.text = "+%dg" % res.gold if res.gold > 0 else "0g"
