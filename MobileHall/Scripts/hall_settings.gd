## Hall settings: the player's accessibility choices and the dev save toggle,
## saved to disk. No state: hall_main.gd keeps the current values
## (color_filter, reduce_motion, text_size, is_save_enabled) and calls in here to load
## them at start-up and to save each change.
class_name HallSettings


# ============================================================ SETTINGS

## Colorblind filter choices, in Menu order. Index = the shader's `mode`.
const COLOR_FILTERS := ["Off", "Red-weak", "Green-weak", "Blue-yellow"]
## Text size choices, in Menu order, and how much each multiplies every font
## on top of the screen's own factor (HallFontScale). The last one, times
## HallFontScale.MAX_SCALE, must stay within HallFontScale.MAX_TOTAL_SCALE:
## that's the biggest text the scenes are checked to hold.
const TEXT_SIZES := ["Small", "Normal", "Large", "Largest"]
const TEXT_SIZE_FACTORS := [0.85, 1.0, 1.15, 1.33]
## The Text size a fresh install starts on (index into TEXT_SIZES): Normal.
const DEFAULT_TEXT_SIZE := 1
## Where player settings are saved, and the section they're saved under.
const PATH := "user://settings.cfg"
const SECTION := "accessibility"
## Section for development switches (kept apart from the player's settings).
const SECTION_DEV := "dev"
## Keys: the colorblind filter (index into COLOR_FILTERS), Reduced Motion
## (turns hall_fx.gd animations off), and Text size (index into TEXT_SIZES).
const KEY_COLOR_FILTER := "color_filter"
const KEY_REDUCE_MOTION := "reduce_motion"
const KEY_TEXT_SIZE := "text_size"
## Key (in SECTION_DEV): whether the run is saved to / loaded from HallSave's file.
const KEY_SAVE_ENABLED := "save_enabled"
## Save runs when settings.cfg doesn't say otherwise. Off while developing, so
## every launch starts a fresh Day 1; flip to true before a release so players
## keep their runs (the Menu's "Save runs (debug)" checkbox overrides it).
const DEFAULT_SAVE_ENABLED := false


# ============================================================ LOAD AND SAVE

## The saved settings, or the defaults when nothing is saved yet.
## Returns {color_filter: int (clamped into COLOR_FILTERS), reduce_motion: bool,
## text_size: int (clamped into TEXT_SIZES), save_enabled: bool}.
static func load_settings() -> Dictionary:
	var settings := {
		"color_filter": 0,
		"reduce_motion": false,
		"text_size": DEFAULT_TEXT_SIZE,
		"save_enabled": DEFAULT_SAVE_ENABLED,
	}
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		settings.color_filter = clamp_color_filter(int(config.get_value(SECTION, KEY_COLOR_FILTER, 0)))
		settings.reduce_motion = bool(config.get_value(SECTION, KEY_REDUCE_MOTION, false))
		settings.text_size = clamp_text_size(int(config.get_value(SECTION, KEY_TEXT_SIZE, DEFAULT_TEXT_SIZE)))
		settings.save_enabled = bool(config.get_value(SECTION_DEV, KEY_SAVE_ENABLED, DEFAULT_SAVE_ENABLED))
	return settings


## Save one setting, keeping the rest of the file.
## key: a KEY_* constant. section: SECTION (default) or SECTION_DEV for KEY_SAVE_ENABLED.
static func save_value(key: String, value: Variant, section := SECTION) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value(section, key, value)
	config.save(PATH)


## filter_index pulled into the range of COLOR_FILTERS.
static func clamp_color_filter(filter_index: int) -> int:
	return clampi(filter_index, 0, COLOR_FILTERS.size() - 1)


## size_index pulled into the range of TEXT_SIZES.
static func clamp_text_size(size_index: int) -> int:
	return clampi(size_index, 0, TEXT_SIZES.size() - 1)


## The font multiplier for the Text size at `size_index` (see TEXT_SIZE_FACTORS).
static func text_size_factor(size_index: int) -> float:
	return TEXT_SIZE_FACTORS[clamp_text_size(size_index)]
