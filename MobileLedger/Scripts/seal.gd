## The wax seal with ribbon tails, stamped with a quest's rank letter.
## Dark red for the milestone quest.
## Scene: MobileLedger/Scenes/Components/seal.tscn
extends Control

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

@onready var _wax: TextureRect = $Wax
@onready var _rank: Label = $Rank


func set_rank(rank: String, dark: bool) -> void:
	_wax.texture = S.tex("seal_dark.png" if dark else "seal_ribbon.png")
	_rank.text = rank
