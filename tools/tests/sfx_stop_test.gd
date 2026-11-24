extends TestCase
## Sfx.stop(name) silences every voice playing that sound and leaves the others
## alone; stopping a sound that isn't playing is safe. Injects a silent
## AudioStreamWAV for quest_travel, since no file is dropped in.
## Scene: tools/tests/sfx_stop_test.tscn

## Length of the injected silent stream (seconds).
const SILENT_SECONDS := 2.0
## Sample rate of the injected stream (Hz).
const MIX_RATE := 22050


func _ready() -> void:
	await _run()
	finish()


func _run() -> void:
	var saved_travel: Array = Sfx._streams.get(&"quest_travel", [])
	var saved_tap: Array = Sfx._streams.get(&"ui_tap", [])
	Sfx._streams[&"quest_travel"] = [_silent_wav(SILENT_SECONDS)]
	Sfx._streams[&"ui_tap"] = [_silent_wav(SILENT_SECONDS)]

	Sfx.play(&"quest_travel")
	Sfx.play(&"ui_tap")
	await get_tree().process_frame
	check(_voices_playing(&"quest_travel") == 1, "quest_travel plays")
	check(_voices_playing(&"ui_tap") == 1, "ui_tap plays")

	Sfx.stop(&"quest_travel")
	check(_voices_playing(&"quest_travel") == 0, "stop silences it")
	check(_voices_playing(&"ui_tap") == 1, "stop leaves other sounds playing")

	Sfx.stop(&"victory")
	check(true, "stop with nothing playing is safe")

	Sfx.stop(&"ui_tap")
	Sfx._streams[&"quest_travel"] = saved_travel
	Sfx._streams[&"ui_tap"] = saved_tap


## A silent 16-bit mono stream `seconds` long.
## @param seconds: length in seconds.
## @return: the stream.
func _silent_wav(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = MIX_RATE
	var bytes := PackedByteArray()
	bytes.resize(int(seconds * MIX_RATE) * 2)
	bytes.fill(0)
	wav.data = bytes
	return wav


## How many Sfx voices are playing `sound_name` right now.
## @param sound_name: a key of Sfx.SOUNDS.
## @return: the count.
func _voices_playing(sound_name: StringName) -> int:
	var count := 0
	for i in Sfx._voices.size():
		if Sfx._voices[i].playing and Sfx._voice_sounds[i] == sound_name:
			count += 1
	return count
