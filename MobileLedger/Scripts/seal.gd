## The wax seal with ribbon tails, stamped with a quest's rank letter
## (Scenes/Components/seal.tscn).
extends Control

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func set_rank(rank: String, dark: bool) -> void:
	$Wax.texture = S.tex("seal_dark.png" if dark else "seal_ribbon.png")
	$Rank.text = rank
