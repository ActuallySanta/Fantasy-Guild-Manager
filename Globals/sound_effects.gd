## Sfx autoload: plays the game's sound effects.
##
## Drop-in folder: put a sound file in SOUND_FOLDER (res://Audio/SFX/) named
## after one of the names in SOUNDS (for example `shop_buy.ogg`) and it plays
## the next time the game starts. A missing file is simply silent, so the game
## works with any number of the sounds in place. Audio/SFX/README.md lists
## every name and what it's for.
##   - Formats: .ogg, .wav or .mp3 (the first one found wins).
##   - Variants: `shop_buy_2.ogg`, `shop_buy_3.ogg` ... (up to MAX_VARIANTS)
##     are picked at random each time, so repeated sounds don't get tiring.
##
## Code plays a sound by name: `Sfx.play(&"shop_buy")`, or later with
## `Sfx.play_after(&"letter_success", 0.4)`.
##
## Every button press plays "ui_tap" on its own, unless the press also played
## a sound of its own (Buy plays "shop_buy", not "ui_tap" as well). See
## _on_any_press.
##
## Why an autoload (and not run state on HallMain): sounds aren't part of the
## run. The players have to live on a node, and this one survives the scene
## reload that starts a new run, so a sound playing then isn't cut off.
extends Node

## The drop-in folder. Sound files are found by name at startup, so they're
## loaded by res:// path (they have no uid until someone drops them in).
const SOUND_FOLDER := "res://Audio/SFX/"
## File types looked for, in order.
const EXTENSIONS: Array[String] = ["ogg", "wav", "mp3"]
## Highest numbered variant looked for (`name_2` ... `name_MAX_VARIANTS`).
const MAX_VARIANTS := 5
## How many sounds can play at once (players in the pool). The oldest one is
## cut off when they're all busy.
const VOICE_COUNT := 12
## The audio bus every sound plays on.
const BUS := &"Master"

## The sound every pressed button / tappable card plays unless its action
## played a sound of its own in the same frame.
const TAP_SOUND := &"ui_tap"

## Every sound the game asks for, with its tuning:
##   volume_db: loudness offset in decibels (0 = as recorded, -6 = about half)
##   pitch_jitter: random pitch change each play, as a fraction (0.05 = +-5%)
## Keep Audio/SFX/README.md in step when adding one.
const SOUNDS := {
	# ---- interface
	&"ui_tap": {"volume_db": -8.0, "pitch_jitter": 0.06},
	&"ui_error": {"volume_db": -4.0, "pitch_jitter": 0.0},
	&"tab_switch": {"volume_db": -6.0, "pitch_jitter": 0.04},
	&"page_open": {"volume_db": -6.0, "pitch_jitter": 0.04},
	&"page_close": {"volume_db": -6.0, "pitch_jitter": 0.04},
	# ---- quests
	&"party_join": {"volume_db": -3.0, "pitch_jitter": 0.05},
	&"party_leave": {"volume_db": -3.0, "pitch_jitter": 0.05},
	&"quest_send": {"volume_db": 0.0, "pitch_jitter": 0.03},
	&"quest_deny": {"volume_db": 0.0, "pitch_jitter": 0.03},
	&"quest_undo": {"volume_db": -4.0, "pitch_jitter": 0.0},
	# ---- guild
	&"hire": {"volume_db": 0.0, "pitch_jitter": 0.03},
	&"hire_letter_fly": {"volume_db": -4.0, "pitch_jitter": 0.05},
	&"release": {"volume_db": -2.0, "pitch_jitter": 0.0},
	# ---- items
	&"shop_buy": {"volume_db": 0.0, "pitch_jitter": 0.03},
	&"equip": {"volume_db": -2.0, "pitch_jitter": 0.05},
	&"unequip": {"volume_db": -2.0, "pitch_jitter": 0.05},
	# ---- upgrades
	&"building_upgrade": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"training_start": {"volume_db": -2.0, "pitch_jitter": 0.04},
	&"hospital_admit": {"volume_db": -2.0, "pitch_jitter": 0.0},
	&"hospital_discharge": {"volume_db": -2.0, "pitch_jitter": 0.0},
	&"revive": {"volume_db": 0.0, "pitch_jitter": 0.0},
	# ---- gold and standing
	&"gold_spend": {"volume_db": -4.0, "pitch_jitter": 0.06},
	&"standing_lose": {"volume_db": -4.0, "pitch_jitter": 0.0},
	&"coin_land": {"volume_db": -6.0, "pitch_jitter": 0.1},
	&"standing_land": {"volume_db": -6.0, "pitch_jitter": 0.08},
	# ---- the night and the Day Report
	&"night_fall": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"letter_success": {"volume_db": -2.0, "pitch_jitter": 0.03},
	&"letter_fail": {"volume_db": -2.0, "pitch_jitter": 0.03},
	&"hero_hurt": {"volume_db": -3.0, "pitch_jitter": 0.05},
	&"hero_died": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"item_found": {"volume_db": -3.0, "pitch_jitter": 0.04},
	&"day_start": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"story_day": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"danger_warning": {"volume_db": -2.0, "pitch_jitter": 0.0},
	# ---- endings
	&"game_over": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"victory": {"volume_db": 0.0, "pitch_jitter": 0.0},
	&"defeat": {"volume_db": 0.0, "pitch_jitter": 0.0},
	# ---- tutorial
	&"pip_talk": {"volume_db": -5.0, "pitch_jitter": 0.08},
}

## Sound name -> Array of AudioStreams found for it (empty = no file dropped in).
var _streams := {}
## The player pool, and which one plays next.
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
## The frame (Engine.get_process_frames) of the last button press, and of the
## last sound played by name. A press's "ui_tap" is dropped when an action
## sound played in the same frame (see _on_any_press). -1 = never.
var _tap_frame := -1
var _action_sound_frame := -1
## Bumped by cancel_scheduled(); a play_after timer from an older batch is dropped.
var _schedule_batch := 0


func _ready() -> void:
	# keep playing while the tree is paused (sounds belong to the UI)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for voice_index in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS
		add_child(voice)
		_voices.append(voice)
	_load_sounds()
	get_tree().node_added.connect(_on_node_added)


## Play a sound now. Unknown names warn (in debug builds); names with no file
## dropped in yet play nothing.
## sound_name: a key of SOUNDS.
func play(sound_name: StringName) -> void:
	if sound_name != TAP_SOUND:
		# a press this frame has its own sound: its tap is skipped
		_action_sound_frame = Engine.get_process_frames()
	_play_now(sound_name)


## Play a sound `seconds` from now (to line up with an animation).
## cancel_scheduled() drops every one still waiting.
func play_after(sound_name: StringName, seconds: float) -> void:
	if seconds <= 0.0:
		play(sound_name)
		return
	var batch := _schedule_batch
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if batch == _schedule_batch:
			_play_now(sound_name))


## Drop every sound waiting in play_after (e.g. the Day Report's reveal when
## the player skips ahead to the next day).
func cancel_scheduled() -> void:
	_schedule_batch += 1


## True when at least one file was found for this sound.
func has_sound(sound_name: StringName) -> bool:
	return not _streams.get(sound_name, []).is_empty()


# ============================================================ LOADING

## Look for every name in SOUNDS (and its numbered variants) in SOUND_FOLDER.
## ResourceLoader.exists also finds imported files in an exported build, where
## the folder itself only holds .import remaps.
func _load_sounds() -> void:
	for sound_name in SOUNDS:
		var found: Array[AudioStream] = []
		var stream := _find_stream(String(sound_name))
		if stream != null:
			found.append(stream)
		for variant in range(2, MAX_VARIANTS + 1):
			var variant_stream := _find_stream("%s_%d" % [sound_name, variant])
			if variant_stream != null:
				found.append(variant_stream)
		_streams[sound_name] = found


## The first file named `base_name` with one of EXTENSIONS, or null.
func _find_stream(base_name: String) -> AudioStream:
	for extension in EXTENSIONS:
		var path := "%s%s.%s" % [SOUND_FOLDER, base_name, extension]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


# ============================================================ PLAYING

## Play one of the sound's files on the next free player (or the oldest one).
func _play_now(sound_name: StringName) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("Sfx: no sound named '%s' (see SOUNDS in sound_effects.gd)" % sound_name)
		return
	var streams: Array = _streams.get(sound_name, [])
	if streams.is_empty():
		return
	var tuning: Dictionary = SOUNDS[sound_name]
	var voice := _free_voice()
	voice.stream = streams.pick_random()
	voice.volume_db = tuning.get("volume_db", 0.0)
	var jitter: float = tuning.get("pitch_jitter", 0.0)
	voice.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	voice.play()


## A player that isn't busy, or the next one round the pool when all are.
func _free_voice() -> AudioStreamPlayer:
	for voice_offset in VOICE_COUNT:
		var voice := _voices[(_next_voice + voice_offset) % VOICE_COUNT]
		if not voice.playing:
			_next_voice = (_voices.find(voice) + 1) % VOICE_COUNT
			return voice
	var oldest := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICE_COUNT
	return oldest


# ============================================================ BUTTON TAPS

## Every button and tappable card (TapPanel, which has its own `pressed`
## signal) that enters the tree gets the tap sound.
func _on_node_added(node: Node) -> void:
	if not node is Control or not node.has_signal(&"pressed"):
		return
	# a node can enter the tree more than once (HallFx.detach reparents rows)
	if not node.is_connected(&"pressed", _on_any_press):
		node.connect(&"pressed", _on_any_press)


## A press: queue "ui_tap" for the end of the frame. If the press's action
## played a sound of its own in this frame (before or after this handler, as
## the connection order varies), the tap is dropped, so a button never plays
## two sounds at once.
func _on_any_press() -> void:
	if _tap_frame == Engine.get_process_frames():
		return  # one tap per frame, however many signals fired
	_tap_frame = Engine.get_process_frames()
	_play_waiting_tap.call_deferred()


func _play_waiting_tap() -> void:
	if _action_sound_frame == _tap_frame:
		return
	_play_now(TAP_SOUND)
