## One seat in Assign Party's party: a pinned card with portrait, name, role and
## their value in the quest's favored stat (tap to take them out), or a
## compact empty seat waiting for someone (tap to scroll down to the
## adventurers; empty seats share a row and split its width).
## Scene: Scenes/Rows/Quests/party_slot.tscn
extends TapPanel


## Empty seats fade back.
const EMPTY_SEAT_OPACITY := 0.55
## Empty seats share a row (Assign Party's EmptySeats), so they're shorter than
## a filled seat and stretch to split the row: smallest width and height
## (design px), and their "Empty seat" text size.
const EMPTY_SEAT_MIN_WIDTH := 130
const EMPTY_SEAT_HEIGHT := 76
const EMPTY_SEAT_FONT_SIZE := 26

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_EMPTY := "Empty seat"

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %SlotName
@onready var _hint: Label = %SlotHint
@onready var _favored_chip = %FavChip         # chip.gd


## seated = the adventurer in this seat, or null for an empty seat.
## on_empty_pressed: called when an empty seat is tapped (Assign Party scrolls
## down to its picker); left empty, an empty seat does nothing.
func setup(hall: HallMain, entry: Dictionary, seated: GuildCharacter,
		on_empty_pressed: Callable = Callable()) -> void:
	var is_filled := seated != null
	_portrait.visible = is_filled
	_favored_chip.visible = is_filled
	if is_filled:
		_portrait.show_character(seated)
		_name.text = seated.name
		_hint.text = TEXT_ROLE % HallStyle.role_name(seated)
		_favored_chip.set_stat(seated, HallStyle.favored_stat_index(entry.quest), true)
		pressed.connect(hall.toggle_in_party.bind(seated))
		# just pinned: their portrait slams into the seat
		if hall.pending_fx.get("seat_in") == seated:
			HallFx.stamp_in(_portrait, 1.7)
			HallFx.pop(self, 1.05, 0.1)
	else:
		_name.text = TEXT_EMPTY
		_hint.visible = false
		# compact, and stretched to share its row with the other empty seats
		custom_minimum_size = Vector2(HallFontScale.px(EMPTY_SEAT_MIN_WIDTH), HallFontScale.px(EMPTY_SEAT_HEIGHT))
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		HallFontScale.set_size(_name, "font_size", EMPTY_SEAT_FONT_SIZE)
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		HallStyle.set_font_color(_name, HallStyle.TEXT_SOFT)
		modulate = Color(1, 1, 1, EMPTY_SEAT_OPACITY)
		if on_empty_pressed.is_valid():
			pressed.connect(on_empty_pressed)
