## Style kit for the Mobile Flow UI: flat grey boxes, 1px borders, Godot's
## default font. Colour is only used to mean something (see GOOD/BAD/GOLD/INFO
## and the per-stat colours). Only art used is the project's own
## Sprites/Character Icons (portraits) and Sprites/UI Icons.
##
## Every node lives in a .tscn (MobileFlow/*.tscn, Components/, Rows/); shared
## boxes are in MobileFlow/Styles and the base theme is MobileFlow/flow_theme.tres.
## This file only holds the palette and the few restyles that depend on game
## state at runtime (button kinds, chip colours).

extends RefCounted

const UI_ICONS := "res://Sprites/UI Icons/"

## Every widget name the screens ask for → a file in Sprites/UI Icons.
## Names with no match there render nothing.
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

const INK := Color("#111111")
const INK_SOFT := Color("#555555")
const PARCH := Color("#FFFFFF")
const CREAM := Color("#FFFFFF")
const LINE := Color("#999999")
const WHITE := Color("#FFFFFF")
const BG := Color("#E6E6E6")
const BOX := Color("#FFFFFF")
const BOX_ALT := Color("#F2F2F2")
const BTN := Color("#DDDDDD")

## Colour is used only to mean something:
## green = good / go, red = bad / danger, yellow = gold, blue = info / in progress.
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
const WAX := BAD
const GOLD_TEXT := GOLD
const GREEN_TEXT := GOOD
const BLUE_TEXT := INFO

## Quest title colours by CreatedQuest.QuestType: plain, except the milestone (5) in red.
const TYPE_COLORS := {1: INK, 2: INK, 3: INK, 4: INK, 5: BAD}
const TYPE_NAMES := {1: "Clear Dungeon", 2: "Escort", 3: "Scout Terrain", 4: "Gather Intel"}

## GuildCharacter.StatType order, plus Pluck. Each stat has its own colour so it
## can be matched at a glance (e.g. a quest's favored stat vs. a character's).
const STATS := [
	{"name": "Strength", "short": "Str", "icon": "", "color": Color("#C62828"), "bg": Color("#FFEBEE")},
	{"name": "Defense", "short": "Def", "icon": "", "color": Color("#1565C0"), "bg": Color("#E3F2FD")},
	{"name": "Wisdom", "short": "Wis", "icon": "", "color": Color("#6A1B9A"), "bg": Color("#F3E5F5")},
	{"name": "Sleaziness", "short": "Slz", "icon": "", "color": Color("#2E7D32"), "bg": Color("#E8F5E9")},
	{"name": "Pluck", "short": "Plk", "icon": "", "color": Color("#E65100"), "bg": Color("#FFF3E0")},
]

## GuildCharacter.InjuryLevel → label, background, text colour (green → red → grey).
const INJURY := [
	["Healthy", GOOD_BG, GOOD],
	["Sore", GOLD_BG, GOLD],
	["Lightly Injured", WARN_BG, WARN],
	["Gravely Injured", BAD_BG, BAD],
	["Dead", Color("#CCCCCC"), Color("#333333")],
]

## Button kinds → fill colour. Anything else is plain grey.
const BUTTON_FILLS := {
	"green": Color("#A5D6A7"), "red": Color("#EF9A9A"), "blue": Color("#90CAF9"),
}


# ---------------------------------------------------------------- resources

static var _cache := {}


static func icon_tex(icon_name: String) -> Texture2D:
	if not ICON_FILES.has(icon_name):
		return null
	var path: String = UI_ICONS + ICON_FILES[icon_name]
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


static func flat(fill: Color, _radius: int = 0, border: int = 0, border_color: Color = LINE, pad: Vector4 = Vector4(12, 6, 12, 6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(1 if border > 0 else 0)
	sb.border_color = border_color
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


## Plain bordered box. kind: "panel" | "card" | "ready" | "inset" | "bar".
static func box(kind: String = "panel", pad: Vector4 = Vector4(14, 10, 14, 10)) -> StyleBoxFlat:
	var fill := BOX
	if kind == "inset" or kind == "bar":
		fill = BOX_ALT
	var border := 2 if kind == "ready" else 1
	var sb := flat(fill, 0, 1, INK if kind == "ready" else LINE, pad)
	sb.set_border_width_all(border)
	return sb


static func _btn_box(fill: Color) -> StyleBoxFlat:
	return flat(fill, 0, 1, Color("#888888"), Vector4(16, 6, 16, 6))


# ---------------------------------------------------------------- restyles

## Button colours. kind: "green" (go / confirm), "red" (deny / cancel),
## "blue" (navigate); anything else is plain grey.
static func style_button(b: Button, kind: String = "") -> void:
	var fill: Color = BUTTON_FILLS.get(kind, BTN)
	b.add_theme_stylebox_override("normal", _btn_box(fill))
	b.add_theme_stylebox_override("hover", _btn_box(fill.darkened(0.06)))
	b.add_theme_stylebox_override("pressed", _btn_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("hover_pressed", _btn_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", _btn_box(Color("#F0F0F0")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INK)
	b.add_theme_color_override("font_disabled_color", Color("#999999"))
	b.add_theme_color_override("icon_normal_color", INK)


## Highlighted (selected tab / current step) look for a button.
static func style_button_active(b: Button) -> void:
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, flat(INFO_BG, 0, 2, INFO, Vector4(6, 4, 6, 4)))
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INFO)


## Chip box + text colour. `outlined` = darker 2px border (the favored stat).
static func style_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, border: bool = true, outlined: bool = false) -> void:
	var sb := flat(bg, 0, 1 if border or outlined else 0, fg if (outlined or fg != INK) else LINE, Vector4(8, 2, 8, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	l.add_theme_color_override("font_color", fg)


## Icon-chip box + text colour (the icon itself is tinted with tint_icon).
static func style_icon_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, outlined: bool = false) -> void:
	var sb := flat(bg, 0, 1, fg if outlined else LINE, Vector4(8, 2, 8, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	l.add_theme_color_override("font_color", fg)


## Icons are black SVGs; tint them with modulate.
static func tint_icon(t: TextureRect, tint: Color) -> void:
	t.modulate = tint


## [word, text colour, gauge colour] for a success chance (-1 = no party yet).
static func odds(p: int) -> Array:
	if p < 0:
		return ["Chance unknown", INK_SOFT, INK_SOFT]
	if p >= 80:
		return ["Strong odds", GOOD, Color("#43A047")]
	if p >= 60:
		return ["Fair odds", GOLD, Color("#FBC02D")]
	if p >= 40:
		return ["Risky", WARN, Color("#FB8C00")]
	return ["Long shot", BAD, Color("#E53935")]


static func stat_name(i: int) -> String:
	return STATS[i].name


## Display index for a CreatedQuest.FavoredStat. The quest system calls Strength
## "Attack" and Sleaziness "Sleaze"; the UI uses the character-sheet names.
static func favored_index(quest: CreatedQuest) -> int:
	return clampi(int(quest.favStat), 0, 4)


static func role_name(character: GuildCharacter) -> String:
	return str(GuildCharacter.CharacterRole.find_key(character.role)).capitalize()


static func rank_letter(quest: CreatedQuest) -> String:
	return str(CreatedQuest.QuestDifficulty.find_key(quest.difficulty))


static func plural(n: int, one: String, many: String) -> String:
	return one if n == 1 else many


## Empty a list container before filling it with fresh row scenes.
static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


## Instance a row/component scene into `parent` and return it.
static func add_row(parent: Node, scene: PackedScene) -> Node:
	var n := scene.instantiate()
	parent.add_child(n)
	return n
