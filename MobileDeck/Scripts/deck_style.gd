## Style kit for the Mobile Deck UI: dark mode, rounded cards, Godot's default
## font. Colour only carries meaning (stat colours, green = go / good,
## red = deny / bad, yellow = gold, blue = info / selected). Only art used is the
## project's own Sprites/Character Icons and Sprites/UI Icons (recoloured with a
## tiny shader, since the SVGs are black).
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

const INK := Color("#EEEFF3")
const INK_SOFT := Color("#9EA2B3")
const PARCH := Color("#FFFFFF")
const CREAM := Color("#FFFFFF")
const LINE := Color("#3D4050")
const WHITE := Color("#FFFFFF")
const BG := Color("#16171D")
const BOX := Color("#262833")
const BOX_ALT := Color("#30323F")
const BTN := Color("#3A3D4C")

## Colour is used only to mean something:
## green = good / go, red = bad / danger, yellow = gold, blue = info / in progress.
const GOOD := Color("#66BB6A")
const GOOD_BG := Color("#1F3A24")
const BAD := Color("#EF5350")
const BAD_BG := Color("#4A1F22")
const WARN := Color("#FFA726")
const WARN_BG := Color("#4A3315")
const GOLD := Color("#FFCA28")
const GOLD_BG := Color("#463A12")
const INFO := Color("#42A5F5")
const INFO_BG := Color("#163552")
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
	{"name": "Strength", "short": "Str", "icon": "", "color": Color("#EF5350"), "bg": Color("#3E1E22")},
	{"name": "Defense", "short": "Def", "icon": "", "color": Color("#42A5F5"), "bg": Color("#15304A")},
	{"name": "Wisdom", "short": "Wis", "icon": "", "color": Color("#CE93D8"), "bg": Color("#36203D")},
	{"name": "Sleaziness", "short": "Slz", "icon": "", "color": Color("#66BB6A"), "bg": Color("#1E3522")},
	{"name": "Pluck", "short": "Plk", "icon": "", "color": Color("#FFA726"), "bg": Color("#45311A")},
]

## GuildCharacter.InjuryLevel → label, background, text colour (green → red → grey).
const INJURY := [
	["Healthy", GOOD_BG, GOOD],
	["Sore", GOLD_BG, GOLD],
	["Lightly Injured", WARN_BG, WARN],
	["Gravely Injured", BAD_BG, BAD],
	["Dead", Color("#2A2A2E"), Color("#8A8A90")],
]

## Button kinds → fill colour. Anything else is plain grey.
const BUTTON_FILLS := {
	"green": Color("#2E7D32"), "red": Color("#B3261E"), "blue": Color("#1565C0"),
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


static func flat(fill: Color, radius: int = 0, border: int = 0, border_color: Color = LINE, pad: Vector4 = Vector4(12, 6, 12, 6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
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
	var sb := flat(fill, 0 if kind == "bar" or kind == "panel" else 18, 1, INFO if kind == "ready" else LINE, pad)
	sb.set_border_width_all(border)
	return sb


static func _btn_box(fill: Color) -> StyleBoxFlat:
	return flat(fill, 14, 0, LINE, Vector4(16, 6, 16, 6))


# ---------------------------------------------------------------- restyles

## Button colours. kind: "green" (go / confirm), "red" (deny / cancel),
## "blue" (navigate); anything else is plain grey.
static func style_button(b: Button, kind: String = "") -> void:
	var fill: Color = BUTTON_FILLS.get(kind, BTN)
	b.add_theme_stylebox_override("normal", _btn_box(fill))
	b.add_theme_stylebox_override("hover", _btn_box(fill.darkened(0.06)))
	b.add_theme_stylebox_override("pressed", _btn_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("hover_pressed", _btn_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", _btn_box(Color("#24252E")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INK)
	b.add_theme_color_override("font_disabled_color", Color("#5C6070"))
	b.add_theme_color_override("icon_normal_color", INK)


## Chip box + text colour. `outlined` = darker 2px border (the favored stat).
static func style_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, border: bool = true, outlined: bool = false) -> void:
	var sb := flat(bg, 12, 1 if border or outlined else 0, fg if (outlined or fg != INK) else LINE, Vector4(10, 2, 10, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	l.add_theme_color_override("font_color", fg)


## Icon-chip box + text colour (the icon itself is tinted with tint_icon).
static func style_icon_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, outlined: bool = false) -> void:
	var sb := flat(bg, 12, 1, fg if outlined else bg, Vector4(10, 2, 10, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	l.add_theme_color_override("font_color", fg)


const TINT_SHADER := preload("res://MobileDeck/icon_tint.gdshader")
static var _tint_mats := {}


## The UI Icons are black SVGs; this paints them any colour (modulate can't lighten black).
static func tint_material(tint: Color) -> ShaderMaterial:
	var key := tint.to_html()
	if not _tint_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = TINT_SHADER
		m.set_shader_parameter("tint", tint)
		_tint_mats[key] = m
	return _tint_mats[key]


static func tint_icon(t: TextureRect, tint: Color) -> void:
	t.material = tint_material(tint)


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
