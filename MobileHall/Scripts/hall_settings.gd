## Hall settings: the player's accessibility choices, saved to disk. No state:
## hall_main.gd keeps the current values (color_filter, reduce_motion) and
## calls in here to load them at start-up and to save each change.
class_name HallSettings


# ============================================================ SETTINGS

## Colorblind filter choices, in Menu order. Index = the shader's `mode`.
const COLOR_FILTERS := ["Off", "Red-weak", "Green-weak", "Blue-yellow"]
## Where player settings are saved, and the section they're saved under.
const PATH := "user://settings.cfg"
const SECTION := "accessibility"
## Keys: the colorblind filter (index into COLOR_FILTERS), and Reduced Motion
## (turns hall_fx.gd animations off).
const KEY_COLOR_FILTER := "color_filter"
const KEY_REDUCE_MOTION := "reduce_motion"


# ============================================================ LOAD AND SAVE

## The saved settings, or the defaults when nothing is saved yet.
## Returns {color_filter: int (clamped into COLOR_FILTERS), reduce_motion: bool}.
static func load_settings() -> Dictionary:
	var settings := {"color_filter": 0, "reduce_motion": false}
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		settings.color_filter = clamp_color_filter(int(config.get_value(SECTION, KEY_COLOR_FILTER, 0)))
		settings.reduce_motion = bool(config.get_value(SECTION, KEY_REDUCE_MOTION, false))
	return settings


## Save one setting (key: KEY_COLOR_FILTER or KEY_REDUCE_MOTION), keeping the rest of the file.
static func save_value(key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value(SECTION, key, value)
	config.save(PATH)


## filter_index pulled into the range of COLOR_FILTERS.
static func clamp_color_filter(filter_index: int) -> int:
	return clampi(filter_index, 0, COLOR_FILTERS.size() - 1)
