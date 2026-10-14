## Shared look and helpers for the Mobile Flow UI.
##
## The look: flat grey boxes, 1px borders, Godot's default font. Colour is only
## used to mean something (green = good, red = bad, yellow = gold, blue = info),
## plus one colour per stat.
##
## Where things live:
##   - Layout: every screen, row and widget is a .tscn under MobileFlow/Scenes.
##   - Boxes: shared panel / button / chip looks are .tres files in MobileFlow/Styles.
##   - This file: the palette, display tables, small text helpers, and the few
##     restyles that change with game state (button colour, chip colour).
##
## Sections: PALETTE · DISPLAY TABLES · TEXT HELPERS · GAME LOOKUPS ·
##           STYLE BOXES · RESTYLES · SCENE HELPERS
extends RefCounted


# ============================================================ PALETTE

const INK := Color("#111111")       ## main text
const INK_SOFT := Color("#555555")  ## secondary text
const LINE := Color("#999999")      ## borders and divider lines
const WHITE := Color("#FFFFFF")
const BG := Color("#E6E6E6")        ## page background
const BOX := Color("#FFFFFF")       ## cards
const BOX_ALT := Color("#F2F2F2")   ## insets, bars, plain chips
const BTN := Color("#DDDDDD")       ## plain button

## Meaning colours: text colour + matching light background.
const GOOD := Color("#2E7D32")
const GOOD_BG := Color("#C8E6C9")
const BAD := Color("#C62828")
const BAD_BG := Color("#FFCDD2")
const WARN := Color("#E65100")
const WARN_BG := Color("#FFE0B2")
const GOLD := Color("#9A7400")
const GOLD_BG := Color("#FFF3C4")
const INFO := Color("#1565C0")
const INFO_BG := Color("#BBDEFB")

## Button kinds -> fill colour. Any other kind is plain grey (BTN).
const BUTTON_FILLS := {
	"green": Color("#A5D6A7"),  # go / confirm
	"red": Color("#EF9A9A"),    # deny / cancel
	"blue": Color("#90CAF9"),   # navigate
}


# ============================================================ DISPLAY TABLES

## Icon names the scenes use -> file in Sprites/UI Icons. Unknown names show nothing.
const UI_ICONS := "res://Sprites/UI Icons/"
const ICON_FILES := {
	"sun": "sun-solid-full.svg",
	"coins": "coins-solid-full.svg",
	"rook": "chess-rook-solid-full.svg",
	"nav_home": "house-solid-full.svg",
	"nav_quests": "book-solid-full.svg",
	"nav_characters": "user-solid-full.svg",
	"nav_upgrades": "arrow-up-solid-full.svg",
	"nav_settings": "gear-solid-full.svg",
}

## CreatedQuest.QuestType -> name shown on the quest.
const TYPE_NAMES := {1: "Clear Dungeon", 2: "Escort", 3: "Scout Terrain", 4: "Gather Intel"}

## The five stats in GuildCharacter.StatType order (Pluck last).
## Each has its own colour so a quest's favored stat is easy to match.
const STATS := [
	{"name": "Strength", "short": "Str", "color": Color("#C62828"), "bg": Color("#FFEBEE")},
	{"name": "Defense", "short": "Def", "color": Color("#1565C0"), "bg": Color("#E3F2FD")},
	{"name": "Wisdom", "short": "Wis", "color": Color("#6A1B9A"), "bg": Color("#F3E5F5")},
	{"name": "Sleaziness", "short": "Slz", "color": Color("#2E7D32"), "bg": Color("#E8F5E9")},
	{"name": "Pluck", "short": "Plk", "color": Color("#E65100"), "bg": Color("#FFF3E0")},
]

## GuildCharacter.InjuryLevel -> [label, background, text colour].
const INJURY := [
	["Healthy", GOOD_BG, GOOD],
	["Sore", GOLD_BG, GOLD],
	["Lightly Injured", WARN_BG, WARN],
	["Gravely Injured", BAD_BG, BAD],
	["Dead", Color("#CCCCCC"), Color("#333333")],
]

## Success chance -> [word, text colour, gauge colour]. Checked top to bottom.
const ODDS := [
	[80, "Strong odds", GOOD, Color("#43A047")],
	[60, "Fair odds", GOLD, Color("#FBC02D")],
	[40, "Risky", WARN, Color("#FB8C00")],
	[0, "Long shot", BAD, Color("#E53935")],
]
const ODDS_UNKNOWN := ["Chance unknown", INK_SOFT, INK_SOFT]


# ============================================================ TEXT HELPERS

## "1 quest" / "3 quests" style: picks the right word for n.
static func plural(n: int, one: String, many: String) -> String:
	return one if n == 1 else many


## Party names joined for display, e.g. "Alex, Gwen".
static func names(party: Array, separator := ", ") -> String:
	var list := PackedStringArray()
	for c in party:
		list.append(c.name)
	return separator.join(list)


## "No injuries yet" / "1 injury taken" / "3 injuries taken".
static func injuries_taken(c: GuildCharacter) -> String:
	if c.injury_count == 0:
		return "No injuries yet"
	return "%d %s taken" % [c.injury_count, plural(c.injury_count, "injury", "injuries")]


## A character's backstory with blank lines removed.
static func backstory(c: GuildCharacter) -> String:
	var lines := PackedStringArray()
	for line in c.description.strip_edges().split("\n"):
		if line.strip_edges() != "":
			lines.append(line.strip_edges())
	return "\n".join(lines)


## [word, text colour, gauge colour] for a success chance (-1 = no party yet).
static func odds(chance: int) -> Array:
	if chance < 0:
		return ODDS_UNKNOWN
	for row in ODDS:
		if chance >= row[0]:
			return row.slice(1)
	return ODDS_UNKNOWN


## "45%" (capped at 100), or "--" when there's no party yet.
static func percent(chance: int) -> String:
	return "--" if chance < 0 else "%d%%" % mini(chance, 100)


# ============================================================ GAME LOOKUPS

## Index into STATS for a quest's favored stat.
static func favored_index(quest: CreatedQuest) -> int:
	return clampi(int(quest.favStat), 0, 4)


static func role_name(c: GuildCharacter) -> String:
	return str(GuildCharacter.CharacterRole.find_key(c.role)).capitalize()


static func rank_letter(quest: CreatedQuest) -> String:
	return str(CreatedQuest.QuestDifficulty.find_key(quest.difficulty))


## A character's value for STATS[i] (Pluck is stored separately).
static func stat_value(c: GuildCharacter, i: int) -> int:
	return c.pluck if i == 4 else int(c.stats[i])


## How well a character fits a quest: the total CreatedQuest.calcSuccessChance
## uses (all four stats, favored one counted twice). Used to sort the picker.
static func fit_score(q: CreatedQuest, c: GuildCharacter) -> int:
	var total: int = c.stats[0] + c.stats[1] + c.stats[2] + c.stats[3]
	var f := favored_index(q)
	if f < 4:
		total += c.stats[f]
	return total


## Buildings in display order: working ones first, "coming soon" after.
static func buildings_in_order() -> Array:
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	return order


## Label on a building's Upgrade button for its current status.
static func upgrade_button_text(status: int) -> String:
	match status:
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			return "Need gold"
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			return "Need Standing"
		GuildUpgrades.UpgradeStatus.MAX_LEVEL:
			return "Max level"
		GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED:
			return "Coming soon"
	return "Upgrade"


# ============================================================ STYLE BOXES

static var _icon_cache := {}


static func icon_tex(icon_name: String) -> Texture2D:
	if not ICON_FILES.has(icon_name):
		return null
	var path: String = UI_ICONS + ICON_FILES[icon_name]
	if not _icon_cache.has(path):
		_icon_cache[path] = load(path)
	return _icon_cache[path]


## Flat box. `border` > 0 draws a 1px border; pad = left, top, right, bottom.
static func flat(fill: Color, _radius: int = 0, border: int = 0, border_color: Color = LINE, pad: Vector4 = Vector4(12, 6, 12, 6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_border_width_all(1 if border > 0 else 0)
	sb.border_color = border_color
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


## Plain bordered box. kind: "panel" | "card" | "ready" | "inset" | "bar".
static func box(kind: String = "panel", pad: Vector4 = Vector4(14, 10, 14, 10)) -> StyleBoxFlat:
	var fill := BOX_ALT if kind == "inset" or kind == "bar" else BOX
	var sb := flat(fill, 0, 1, INK if kind == "ready" else LINE, pad)
	sb.set_border_width_all(2 if kind == "ready" else 1)
	return sb


static func _button_box(fill: Color) -> StyleBoxFlat:
	return flat(fill, 0, 1, Color("#888888"), Vector4(16, 6, 16, 6))


# ============================================================ RESTYLES

## Colour a button by kind: "green", "red", "blue", or "" for plain grey.
static func style_button(b: Button, kind: String = "") -> void:
	var fill: Color = BUTTON_FILLS.get(kind, BTN)
	b.add_theme_stylebox_override("normal", _button_box(fill))
	b.add_theme_stylebox_override("hover", _button_box(fill.darkened(0.06)))
	b.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("hover_pressed", _button_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", _button_box(Color("#F0F0F0")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INK)
	b.add_theme_color_override("font_disabled_color", Color("#999999"))
	b.add_theme_color_override("icon_normal_color", INK)


## Highlighted look (current step / selected tab).
static func style_button_active(b: Button) -> void:
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, flat(INFO_BG, 0, 2, INFO, Vector4(6, 4, 6, 4)))
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INFO)


## Plain chip: border in the text colour (grey for plain text).
## `outlined` = heavier 2px border (the favored stat).
static func style_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, border: bool = true, outlined: bool = false) -> void:
	var sb := flat(bg, 0, 1 if border or outlined else 0, fg if (outlined or fg != INK) else LINE, Vector4(8, 2, 8, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	l.add_theme_color_override("font_color", fg)


## Icon chip: always a grey border, unless `outlined`.
static func style_icon_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, outlined: bool = false) -> void:
	var sb := flat(bg, 0, 1, fg if outlined else LINE, Vector4(8, 2, 8, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	l.add_theme_color_override("font_color", fg)


## The UI Icons are black SVGs; tint them with modulate.
static func tint_icon(t: TextureRect, tint: Color) -> void:
	t.modulate = tint


## Recolour a label (shorthand used all over the screens).
static func color(l: Control, c: Color) -> void:
	l.add_theme_color_override("font_color", c)


# ============================================================ SCENE HELPERS

## Remove every row from a list container before refilling it.
static func clear(list: Node) -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()


## Instance a row scene at the end of `list` and return it (call its setup next).
static func add_row(list: Node, scene: PackedScene) -> Node:
	var row := scene.instantiate()
	list.add_child(row)
	return row
