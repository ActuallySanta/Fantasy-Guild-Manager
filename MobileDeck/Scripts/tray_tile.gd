## One adventurer in the roster tray along the bottom.
## On a quest card: tap to add / remove them. Otherwise: tap for details.
## Scene: MobileDeck/Scenes/Rows/tray_tile.tscn
extends Button

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")

const TEXT_ON_QUEST := "On a quest"

@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _status: Label = %Status


func setup(ui: Main, c: GuildCharacter) -> void:
	var chosen: bool = ui.draft.has(c)
	var busy: bool = not ui.entry_of(c).is_empty() and not chosen

	# chosen tiles get a thick blue border
	var sb := S.flat(S.INFO_BG if chosen else S.BOX, 16, 1, S.INFO if chosen else S.LINE, Vector4(6, 6, 6, 6))
	sb.set_border_width_all(3 if chosen else 1)
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		add_theme_stylebox_override(s, sb)

	_portrait.show_character(c)
	_char_name.text = c.name
	# health, or "On a quest" when they're already sent somewhere else
	var injury: Array = S.INJURY[clampi(c.injury_level, 0, 4)]
	_status.text = TEXT_ON_QUEST if busy else injury[0]
	S.color(_status, S.INFO if busy else injury[2])
	pressed.connect(ui.toggle_draft.bind(c))
