## Header: the DAY tile, the Bone Drake countdown, the gold and standing
## counters, the Menu button, and the red "last hero standing" strip under it.
## Also owns the counters' motion: numbers roll to new values, coins fly to
## what you paid for, and the night's earnings land at dawn.
## Scene: MobileHall/Scenes/Shell/hall_header.tscn
class_name HallHeader
extends VBoxContainer


# ============================================================ SETTINGS

## The Bone Drake countdown turns red when this many days (or fewer) are left.
const DRAKE_WARNING_DAYS := 2
## Times the Bone Drake note pulses on a morning inside DRAKE_WARNING_DAYS.
const DRAKE_PULSES := 3
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
## The countdown note (BBCode); the days left are in red ink, and the whole
## note turns red once DRAKE_WARNING_DAYS or fewer are left.
const HEADER_DRAKE := "Bone Drake in [color=#%s]%d %s[/color]"
const HEADER_DRAKE_TODAY := "Bone Drake [color=#%s]attacks today![/color]"
const HEADER_DRAKE_GONE := "Bone Drake has passed"
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
@onready var _drake_value: RichTextLabel = %DrakeValue
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


# ============================================================ SETUP AND REFRESH

func setup(main: HallMain) -> void:
	hall = main
	_menu_button.pressed.connect(hall.open_menu)


## Redraw the day, the countdown, the counters and the danger strip.
func refresh() -> void:
	# grows with the font scale (here, not in setup, so a Text size change follows)
	_standing_box.custom_minimum_size = HallFontScale.px_vec(STANDING_BOX_SIZE, STANDING_MAX_FACTOR)
	_refresh_day_tile()

	# the days left are always in red ink; in the last days the whole note is
	var days_left := hall.days_until_drake()
	var red_ink := HallStyle.RED.to_html(false)
	if days_left > 0:
		_drake_value.text = HEADER_DRAKE % [red_ink, days_left, HallStyle.pick_plural(days_left, "day", "days")]
	elif days_left == 0:
		_drake_value.text = HEADER_DRAKE_TODAY % red_ink
	else:
		_drake_value.text = HEADER_DRAKE_GONE
	var is_drake_close := days_left >= 0 and days_left <= DRAKE_WARNING_DAYS
	HallStyle.set_font_color(_drake_value, HallStyle.RED if is_drake_close else HallStyle.TEXT_MAIN)

	_update_counter("gold")
	_update_counter("standing")
	_refresh_danger_strip()


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
	var days_left := hall.days_until_drake()
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
