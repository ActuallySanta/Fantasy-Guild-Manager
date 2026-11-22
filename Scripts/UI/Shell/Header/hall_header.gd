## Header: the DAY tile, the next-boss countdown, the gold and standing
## counters, the Menu button, and the red "last hero standing" strip under it.
## Also owns the counters' motion: numbers roll to new values, coins fly to
## what you paid for, and the night's earnings land at dawn. Tapping the coin
## or the shield drops a popup that explains gold (popup_gold.gd) or standing
## (popup_standing.gd). The popup's backdrop covers the screen, so it closes
## before anything else can be tapped.
## Scene: Scenes/Shell/Header/hall_header.tscn
class_name HallHeader
extends VBoxContainer


# ============================================================ SETTINGS

## The next-boss countdown turns red when this many days (or fewer) are left.
const DRAKE_WARNING_DAYS := 2
## Times the next-boss note pulses on a morning inside DRAKE_WARNING_DAYS.
const DRAKE_PULSES := 3
## Padding inside the Bone Drake note's torn paper (design px), left/right and
## top/bottom. Kept small so the note hugs its seal and number (the shared
## TornNote style pads 14-16 px).
const DRAKE_NOTE_PADDING_X := 8.0
const DRAKE_NOTE_PADDING_Y := 6.0
## Seconds the gold / standing numbers take to roll to a new value.
const COUNTER_ROLL_SECONDS := 0.5
## How big the counter grows when its number changes (1 = no pop).
const COUNTER_POP := 1.22
## Counter ink while it changes: a gain, a loss (light, to read on the wood header).
const COUNTER_GAIN_INK := Color("#B5E08F")
const COUNTER_LOSS_INK := Color("#FF9C8A")
## Floating "+40" / "-2" under a counter: inks (dark, to read on paper and wood
## with their light outline) and how far under the counter they start (design
## px; grown with the font scale, since the number under it grows too).
const DELTA_GAIN_INK := Color("#3D5A2A")
const DELTA_LOSS_INK := Color("#8B2E2A")
const DELTA_OFFSET := Vector2(0, 58)
## The standing shield's box, in design px. Grown with the font scale so the
## number keeps fitting inside the shield art.
const STANDING_BOX_SIZE := Vector2(62, 72)
## The header's counters (day, gold, standing) grow no more than this with the
## font scale (metadata/font_max_factor in the scene): the header is one row
## that can't wrap, so its numbers stop growing before it runs off screen.
const STANDING_MAX_FACTOR := 1.5
## Coins / shields that fly between a counter and what you tapped: size (pixels),
## flight time (seconds), and how many fly in when the night's earnings land.
const FLY_ICON_SIZE := 44.0
const FLY_SECONDS := 0.5
const EARNINGS_COIN_COUNT := 5
## Seconds between each of those coins leaving, and before the first one
## leaves (so the dawn wash has started to clear).
const EARNINGS_COIN_GAP := 0.07
const EARNINGS_DELAY := 0.2


# ============================================================ TEXT

## The day number on the DAY tile.
const HEADER_DAY := "%d"
## The countdown note: the boss quest's seal, then the days left as a big
## number over a small "days" label. The number is in red ink; the label
## turns red too once DRAKE_WARNING_DAYS or fewer are left.
const HEADER_DRAKE_DAYS := "%d"
const HEADER_DRAKE_UNIT_ONE := "day"
const HEADER_DRAKE_UNIT_MANY := "days"
## On a boss day: "!" over "today". Once no boss is left the note hides.
const HEADER_DRAKE_TODAY := "!"
const HEADER_DRAKE_TODAY_UNIT := "today"
## The warning strip under the header (see HallLedger.is_one_death_from_falling).
## DANGER_GOLD when gold is the problem, DANGER_STANDING when standing is.
const DANGER_TITLE := "Last hero standing"
const DANGER_GOLD := "Recruits cost %d gold and you have %d. Lose %s and the guild falls."
const DANGER_STANDING := "Standing is nearly too low for recruits. Lose %s and the guild falls."
## Floating numbers under the counters.
const DELTA_GAIN := "+%d"
const DELTA_LOSS := "%d"


# ============================================================ STATE

## The main hall script (state + actions), set in setup().
var hall: HallMain

## The gold / standing numbers on screen right now (-1 = not drawn yet), and
## whether each is held still (it waits for flying coins, or for the night's
## earnings to land at dawn).
var _shown_counters := {"gold": -1, "standing": -1}
var _held_counters := {"gold": false, "standing": false}
## The day on the DAY tile (to flip it when it changes; -1 = not drawn yet).
var _shown_day := -1


# ============================================================ NODES

@onready var _day_value: Label = %DayValue
@onready var _drake_seal: PanelContainer = %DrakeSeal
@onready var _drake_tag: Label = %DrakeTag
@onready var _drake_icon: TextureRect = %DrakeIcon
@onready var _drake_days: Label = %DrakeDays
@onready var _drake_days_label: Label = %DrakeDaysLabel
@onready var _gold_value: Label = %GoldValue
@onready var _standing_value: Label = %StandingValue
@onready var _day_tile: Control = %DayTile
@onready var _drake_note: Control = %DrakeNote
@onready var _gold_box: Control = %GoldValueBox
@onready var _gold_coin: TextureRect = %Coin
@onready var _standing_box: Control = %StandingValueBox
@onready var _standing_shield: TextureRect = %Shield
@onready var _menu_button: Button = %MenuButton
@onready var _danger_strip: PanelContainer = %DangerStrip
@onready var _danger_icon: TextureRect = %DangerIcon
@onready var _danger_title: Label = %DangerTitle
@onready var _danger_text: Label = %DangerText
@onready var _gold_popup: HeaderPopup = %PopupGold
@onready var _standing_popup: HeaderPopup = %PopupStanding


# ============================================================ SETUP AND REFRESH

func setup(main: HallMain) -> void:
	hall = main
	_menu_button.pressed.connect(hall.open_menu)
	_trim_drake_note_padding()
	_gold_popup.setup(main)
	_standing_popup.setup(main)
	_gold_box.gui_input.connect(_on_counter_input.bind(_gold_popup, _gold_box))
	_standing_box.gui_input.connect(_on_counter_input.bind(_standing_popup, _standing_box))


## Give the Bone Drake note its own copy of the torn-paper style with
## DRAKE_NOTE_PADDING_X / _Y padding (the shared style stays as it is).
func _trim_drake_note_padding() -> void:
	var box := _drake_note.get_theme_stylebox("panel")
	if box == null:
		return
	box = box.duplicate()
	box.content_margin_left = DRAKE_NOTE_PADDING_X
	box.content_margin_right = DRAKE_NOTE_PADDING_X
	box.content_margin_top = DRAKE_NOTE_PADDING_Y
	box.content_margin_bottom = DRAKE_NOTE_PADDING_Y
	_drake_note.add_theme_stylebox_override("panel", box)


## The countdown to the next boss day: that boss quest's seal (BOSS, or FINAL
## for the last battle; the same one its quest card wears), then the days left
## over a "days" label. The number is always
## red ink; the label joins it once DRAKE_WARNING_DAYS or fewer are left.
func _refresh_drake_countdown() -> void:
	var days_left := hall.days_until_next_boss()
	# no boss left (freeplay): the whole note hides
	_drake_note.visible = days_left >= 0
	if days_left < 0:
		return
	var seal_id := HallStyle.FINAL_TYPE_ID if hall.next_boss_is_final() else HallStyle.MILESTONE_TYPE_ID
	var boss_type: Dictionary = HallStyle.QUEST_TYPES[seal_id]
	HallStyle.style_icon_tag(_drake_seal, _drake_tag, _drake_icon, boss_type.tag,
			boss_type.get("icon", ""), boss_type.color)

	if days_left > 0:
		_drake_days.text = HEADER_DRAKE_DAYS % days_left
		_drake_days_label.text = HallStyle.pick_plural(days_left, HEADER_DRAKE_UNIT_ONE, HEADER_DRAKE_UNIT_MANY)
	else:
		_drake_days.text = HEADER_DRAKE_TODAY
		_drake_days_label.text = HEADER_DRAKE_TODAY_UNIT
	HallStyle.set_font_color(_drake_days, HallStyle.RED)
	HallStyle.set_font_color(_drake_days_label, HallStyle.RED if days_left <= DRAKE_WARNING_DAYS else HallStyle.TEXT_SOFT)


## Redraw the day, the countdown, the counters and the danger strip.
func refresh() -> void:
	# grows with the font scale (here, not in setup, so a Text size change follows)
	_standing_box.custom_minimum_size = HallFontScale.px_vec(STANDING_BOX_SIZE, STANDING_MAX_FACTOR)
	_refresh_day_tile()
	_refresh_drake_countdown()
	_update_counter("gold")
	_update_counter("standing")
	_refresh_danger_strip()
	for popup in [_gold_popup, _standing_popup]:
		if popup.is_open():
			popup.refresh()


## A tap on the coin or the shield drops its popup (and closes the other one).
func _on_counter_input(event: InputEvent, popup: HeaderPopup, anchor: Control) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for other in [_gold_popup, _standing_popup]:
		if other != popup:
			other.close()
	popup.open(anchor)
	anchor.accept_event()


## The red "last hero standing" strip under the header, only while the guild
## is one death from falling (and not once the Game Over ledger is up).
func _refresh_danger_strip() -> void:
	var hero := hall.last_living_hero()
	var was_shown := _danger_strip.visible
	_danger_strip.visible = hall.run_over_stats.is_empty() and hero != null and hall.is_one_death_from_falling()
	if not _danger_strip.visible:
		return
	if not was_shown:
		Sfx.play(&"danger_warning")
	HallStyle.style_panel(_danger_strip, HallStyle.RED_BG)
	_danger_icon.modulate = HallStyle.RED
	_danger_title.text = DANGER_TITLE
	HallStyle.set_font_color(_danger_title, HallStyle.RED)
	if HallLedger.is_short_of_recruit_gold():
		var price := GuildCharacter.recruit_cost_for_day(GameState.day + 1)
		_danger_text.text = DANGER_GOLD % [price, GameState.gold, hero.name]
	else:
		_danger_text.text = DANGER_STANDING % hero.name


## DAY tile: a new day flips the tile over (the number changes edge-on, once
## the dawn wash has cleared). A morning inside DRAKE_WARNING_DAYS also pulses
## the Bone Drake note.
func _refresh_day_tile() -> void:
	var day: int = GameState.day
	if _shown_day == day:
		return
	var is_first_draw := _shown_day < 0
	_shown_day = day
	if is_first_draw or HallFx.reduce_motion:
		_day_value.text = HEADER_DAY % day
		return
	HallFx.flip(_day_tile, HallMain.DUSK_OUT_SECONDS * 0.5, func() -> void: _day_value.text = HEADER_DAY % day)
	var days_left := hall.days_until_next_boss()
	if days_left >= 0 and days_left <= DRAKE_WARNING_DAYS:
		HallFx.pulse(_drake_note, DRAKE_PULSES, 1.08, HallMain.DUSK_OUT_SECONDS)


# ============================================================ MOTION

## End Day: hold both counters still until land_earnings() at dawn.
func hold_counters() -> void:
	_held_counters.gold = true
	_held_counters.standing = true


## Dawn: release the counters held since End Day. Gains fly in from the middle
## of the screen as a few coins / shields and the counter rolls up as the last
## one lands; anything else (a loss, no change) just rolls.
func land_earnings() -> void:
	var start := hall.fx_layer.get_global_rect().get_center()
	for kind in ["gold", "standing"]:
		var gained: int = _counter_value(kind) - int(_shown_counters[kind])
		var land_sound := &"coin_land" if kind == "gold" else &"standing_land"
		if gained <= 0 or HallFx.reduce_motion or _shown_counters[kind] < 0:
			# no coins fly with Reduced Motion, but the gain still clinks once
			if gained > 0 and _shown_counters[kind] >= 0:
				Sfx.play(land_sound)
			_release_counter(kind)
			continue
		var target := _counter_art(kind).get_global_rect().get_center()
		var coin_count := mini(EARNINGS_COIN_COUNT, gained)
		for coin_index in coin_count:
			var is_last := coin_index == coin_count - 1
			var delay := EARNINGS_DELAY + coin_index * EARNINGS_COIN_GAP
			var land := _release_counter.bind(kind) if is_last else Callable()
			# each coin / shield clinks as it lands on the counter
			Sfx.play_after(land_sound, delay + FLY_SECONDS)
			HallFx.fly(hall.fx_layer, _counter_art(kind).texture, start, target, FLY_ICON_SIZE, delay, FLY_SECONDS, land)


## Gold or standing just paid for what the player tapped: a coin / shield
## flies from the counter to the spot they tapped (the counter drops now).
## kind: "gold" or "standing".
func pay_fx(kind: String) -> void:
	Sfx.play(&"gold_spend" if kind == "gold" else &"standing_lose")
	var art := _counter_art(kind)
	HallFx.fly(hall.fx_layer, art.texture, art.get_global_rect().get_center(), hall.tap_point(), FLY_ICON_SIZE, 0.0, FLY_SECONDS)


func _counter_value(kind: String) -> int:
	return GameState.gold if kind == "gold" else GameState.standing


func _counter_label(kind: String) -> Label:
	return _gold_value if kind == "gold" else _standing_value


## The counter's box (what pops) and its art (coin / shield, what flies).
func _counter_box(kind: String) -> Control:
	return _gold_box if kind == "gold" else _standing_box


func _counter_art(kind: String) -> TextureRect:
	return _gold_coin if kind == "gold" else _standing_shield


## Draw a counter. When its number changed it rolls to the new value, pops,
## flashes green (gain) or red (loss), and a "+40" / "-2" floats under it.
## A held counter waits (see _held_counters).
func _update_counter(kind: String) -> void:
	var value := _counter_value(kind)
	var old_value: int = _shown_counters[kind]
	if _held_counters[kind] and old_value >= 0:
		return
	_shown_counters[kind] = value
	var label := _counter_label(kind)
	if old_value < 0 or old_value == value:
		label.text = str(value)
		return
	var change := value - old_value
	var is_gain := change > 0
	HallFx.count(label, old_value, value, COUNTER_ROLL_SECONDS)
	HallFx.pop(_counter_box(kind), COUNTER_POP)
	HallFx.flash_text(label, COUNTER_GAIN_INK if is_gain else COUNTER_LOSS_INK, COUNTER_ROLL_SECONDS + 0.3)
	var delta_at := _counter_box(kind).get_global_rect().get_center() + HallFontScale.px_vec(DELTA_OFFSET)
	HallFx.float_text(hall.fx_layer, delta_at, (DELTA_GAIN if is_gain else DELTA_LOSS) % change,
			DELTA_GAIN_INK if is_gain else DELTA_LOSS_INK)


## Let a held counter catch up to the real value.
func _release_counter(kind: String) -> void:
	_held_counters[kind] = false
	_update_counter(kind)
