---
source: Globals/sound_effects.gd
class_name: null
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# sound_effects.gd

## Purpose
Autoload `Sfx`. Plays the game's sound effects from a drop-in folder: put a file named after a key of `SOUNDS` (for example `shop_buy.ogg`) in `res://Audio/SFX/` and it plays the next time the game starts. A missing file is silent. Numbered variants (`shop_buy_2.ogg` ... up to `MAX_VARIANTS`) are picked at random. Code plays by name: `Sfx.play(&"shop_buy")` or `Sfx.play_after(&"letter_success", 0.4)`. Every button press plays `ui_tap` on its own, unless the press also played a sound of its own. It's an autoload (not run state on `HallMain`) so a playing sound survives the scene reload that starts a new run. `Audio/SFX/README.md` lists the names and must be kept in step with `SOUNDS`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SOUND_FOLDER` | const | `res://Audio/SFX/`. Files are found by name at startup, so they're loaded by `res://` path. |
| `EXTENSIONS` | const | File types looked for, in order: ogg, wav, mp3. |
| `MAX_VARIANTS` | const | Highest numbered variant looked for (5). |
| `VOICE_COUNT` | const | Players in the pool (12): how many sounds can play at once. The oldest is cut off when all are busy. |
| `BUS` | const | Audio bus (`Master`). |
| `TAP_SOUND` | const | The sound every pressed button plays (`ui_tap`) unless its action played its own that frame. |
| `SOUNDS` | const | Every sound name with `volume_db` (dB, 0 = as recorded) and `pitch_jitter` (fraction, 0.05 = +-5%). Groups: interface, quests, guild, items, upgrades, gold and standing, the night and Day Report, endings, tutorial (`pip_talk`). |
| `_streams` | var (Dictionary) | Sound name -> array of loaded `AudioStream`s (empty = no file). |
| `_voices` | var (`Array[AudioStreamPlayer]`) | The player pool. |
| `_next_voice` | var (int) | Which voice is tried next. |
| `_tap_frame` | var (int) | `Engine.get_process_frames()` of the last button press (-1 = never). |
| `_action_sound_frame` | var (int) | Frame of the last non-tap sound played with `play` (-1 = never). |
| `_schedule_batch` | var (int) | Bumped by `cancel_scheduled`. A `play_after` timer from an older batch is dropped. |

## Functions

### _ready
`func _ready() -> void` · `Globals/sound_effects.gd:109`

Engine callback. Sets `process_mode` to always (sounds keep playing while the tree is paused), creates `VOICE_COUNT` `AudioStreamPlayer`s on `BUS`, loads the sound files, and connects `get_tree().node_added` to `_on_node_added`.

**Calls:** [[sound_effects#_load_sounds]], [[sound_effects#_on_node_added]] (as a connection).

### play
`func play(sound_name: StringName) -> void` · `Globals/sound_effects.gd:124`

Plays a sound now. Unknown names warn (in `_play_now`), and names with no file play nothing. Any sound other than `ui_tap` records the current frame in `_action_sound_frame` so the press's tap is skipped.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `sound_name` | `StringName` | A key of `SOUNDS` | a literal such as `&"page_open"` in the caller |

**Returns:** nothing.

**Called by:** [[sound_effects#play_after]] (line 135 when `seconds <= 0`), 43 sites in [[hall_main]] (for example [[hall_main#open_tab]] `hall_main.gd:745`, [[hall_main#hire]] `:1097`), 3 in [[hall_header]] (for example [[hall_header#land_earnings]]), and 1 in [[overlay_tutorial]].

**Calls:** [[sound_effects#_play_now]].

### play_after
`func play_after(sound_name: StringName, seconds: float) -> void` · `Globals/sound_effects.gd:133`

Plays a sound `seconds` from now, to line up with an animation. With `seconds <= 0` it just calls `play`. Otherwise a timer is started that plays through `_play_now`, but only if no `cancel_scheduled()` happened since it was queued. Note that the delayed play doesn't mark `_action_sound_frame`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `sound_name` | `StringName` | A key of `SOUNDS` | literal in the caller |
| `seconds` | `float` | Delay in seconds | the reveal animation's timing in [[report_entry#reveal]] and [[hall_header#land_earnings]] |

**Called by:** [[report_entry#reveal]] (`report_entry.gd:291`, `:301`), [[hall_header#land_earnings]] (`hall_header.gd:261`).

**Calls:** [[sound_effects#play]], [[sound_effects#_play_now]].

### cancel_scheduled
`func cancel_scheduled() -> void` · `Globals/sound_effects.gd:145`

Drops every sound still waiting in `play_after` (for example the Day Report's reveal when the player skips ahead) by bumping `_schedule_batch`.

**Called by:** [[hall_main#start_new_day]] (`hall_main.gd:1636`), [[hall_main#close_report]] (`hall_main.gd:1734`).

### has_sound
`func has_sound(sound_name: StringName) -> bool` · `Globals/sound_effects.gd:150`

True when at least one file was found for this sound.

**Called by:** nothing found.

### _load_sounds
`func _load_sounds() -> void` · `Globals/sound_effects.gd:159`

For every name in `SOUNDS`, looks for the base file and the variants `name_2` to `name_MAX_VARIANTS` in `SOUND_FOLDER` and stores what it finds in `_streams`. It uses `ResourceLoader.exists`, which also finds imported files in an exported build where the folder only holds `.import` remaps.

**Called by:** [[sound_effects#_ready]] (line 117).

**Calls:** [[sound_effects#_find_stream]].

### _find_stream
`func _find_stream(base_name: String) -> AudioStream` · `Globals/sound_effects.gd:173`

The first file named `base_name` with one of `EXTENSIONS`, or null.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `base_name` | `String` | File name without extension | the sound name or `"%s_%d"` variant name built in `_load_sounds` |

**Returns:** `AudioStream` or null. `_load_sounds` skips nulls.

**Called by:** [[sound_effects#_load_sounds]] (lines 162, 166).

### _play_now
`func _play_now(sound_name: StringName) -> void` · `Globals/sound_effects.gd:184`

Plays one of the sound's files on a free voice. Unknown names `push_warning`. A sound with no files returns silently. Volume is `volume_db`, and pitch is `1.0 + randf_range(-jitter, jitter)`.

**Called by:** [[sound_effects#play]] (128), [[sound_effects#play_after]] (140), [[sound_effects#_play_waiting_tap]] (238).

**Calls:** [[sound_effects#_free_voice]].

### _free_voice
`func _free_voice() -> AudioStreamPlayer` · `Globals/sound_effects.gd:201`

A voice that isn't playing, or the next one round the pool when all are busy (cuts it off).

**Returns:** `AudioStreamPlayer`, used by [[sound_effects#_play_now]].

**Called by:** [[sound_effects#_play_now]] (192).

### _on_node_added
`func _on_node_added(node: Node) -> void` · `Globals/sound_effects.gd:216`

Gives every `Control` that has a `pressed` signal (buttons and `TapPanel`) the tap sound by connecting `pressed` to `_on_any_press`, once (a node can enter the tree more than once, for example when `HallFx.detach` reparents rows).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | The node that just entered the tree | the argument of `SceneTree.node_added` |

**Called by:** signal `node_added` on the `SceneTree` (connected at line 118).

### _on_any_press
`func _on_any_press() -> void` · `Globals/sound_effects.gd:228`

A press: queues the tap for the end of the frame, once per frame. If the press's action played a sound of its own in this frame (before or after this handler), `_play_waiting_tap` drops the tap.

**Called by:** signal `pressed` on every button or tappable card (connected in `_on_node_added`, line 221).

**Calls:** [[sound_effects#_play_waiting_tap]] (deferred).

### _play_waiting_tap
`func _play_waiting_tap() -> void` · `Globals/sound_effects.gd:235`

Plays `ui_tap` unless `_action_sound_frame == _tap_frame`.

**Called by:** [[sound_effects#_on_any_press]] (deferred, line 232).

**Calls:** [[sound_effects#_play_now]].

## Suspected issues
- `Globals/sound_effects.gd:150` `has_sound` has no callers.
- `Globals/sound_effects.gd:233-235` `_play_waiting_tap` is documented only through `_on_any_press`; it has no `##` comment.
