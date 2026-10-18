## Shared look and helpers for the Mobile Hall UI.
##
## The look: generic primitives. Flat boxes, Godot's default font, and colour
## only where it means something (each stat has its own colour, green = good /
## sent, red = bad / denied, blue = info / to do, yellow = gold). The only art is
## the project's own Sprites/Character Icons and Sprites/UI Icons.
##
## Where things live:
##   - Layout: every screen, row and widget is a .tscn under MobileHall/Scenes.
##   - Boxes: shared panel / button looks are .tres files in MobileHall/Styles.
##   - This file: the palette, display tables, fonts, text helpers, game lookups
##     and the restyles that change with game state (button kind, chip colour).
##
## Sections: PALETTE · DISPLAY TABLES · FONTS · TEXT HELPERS · GAME LOOKUPS ·
##           STYLE BOXES · RESTYLES · SCENE HELPERS
extends RefCounted


# ============================================================ PALETTE

const INK := Color("#222222")         ## main text
const INK_SOFT := Color("#666666")    ## secondary text
const CREAM := Color("#FFFFFF")       ## card background
const PAPER := Color("#E6E6E6")       ## neutral chip / inset
const LINE := Color("#BBBBBB")        ## borders
const BAR := Color("#3B3F45")         ## header / nav background
const WAX := Color("#A3262A")         ## red: deny, failed, warnings
const WAX_BG := Color("#F2CBC3")
const GOLD := Color("#E0B23A")
const GOLD_TEXT := Color("#7A5A12")
const GOLD_BG := Color("#F4E5AC")
const GREEN := Color("#3F7A2E")
const GREEN_TEXT := Color("#2F6A22")
const GREEN_BG := Color("#D9E8CF")
const BLUE_TEXT := Color("#2F5F8A")
const BLUE_BG := Color("#D3E1EE")
const WHITE := Color("#FFFFFF")
const BADGE := Color("#C8302F")       ## nav badge dot


# ============================================================ DISPLAY TABLES

const UI_ICONS := "res://Sprites/UI Icons/"

## Icon names used by the screens -> the project's own UI icons. Names not
## listed here have no icon (the TextureRect / chip icon is hidden).
const ICON_FILES := {
	"coins": "coins-solid-full.svg",
	"rook": "chess-rook-solid-full.svg",
	"nav_settings": "gear-solid-full.svg",
	"nav_quests": "book-solid-full.svg",
	"nav_characters": "user-solid-full.svg",
	"nav_upgrades": "arrow-up-solid-full.svg",
	"nav_home": "house-solid-full.svg",
	"sun": "sun-solid-full.svg",
}

## CreatedQuest.QuestType (5 = milestone) -> colour, name, short tag.
const TYPES := {
	1: {"name": "Clear Dungeon", "color": Color("#2E7D32"), "tag": "DUN"},
	2: {"name": "Escort", "color": Color("#B26A00"), "tag": "ESC"},
	3: {"name": "Scout Terrain", "color": Color("#1E63A8"), "tag": "SCT"},
	4: {"name": "Gather Intel", "color": Color("#6A3FA0"), "tag": "INT"},
	5: {"name": "Milestone", "color": Color("#B3261E"), "tag": "BOSS"},
}

## The five stats in GuildCharacter.StatType order (Pluck last).
const STATS := [
	{"name": "Strength", "short": "Str", "color": Color("#A3262A"), "bg": Color("#F2D5CB")},
	{"name": "Defense", "short": "Def", "color": Color("#2F5F8A"), "bg": Color("#D3E1EE")},
	{"name": "Wisdom", "short": "Wis", "color": Color("#5B3F8C"), "bg": Color("#E2D9EF")},
	{"name": "Sleaziness", "short": "Slz", "color": Color("#3E6B35"), "bg": Color("#D9E8CF")},
	{"name": "Pluck", "short": "Plk", "color": Color("#94500F"), "bg": Color("#F5DCC0")},
]

## GuildCharacter.InjuryLevel -> [label, background, text colour].
const INJURY := [
	["Healthy", Color("#D9E8CF"), Color("#2F5A27")],
	["Sore", Color("#F4E5AC"), Color("#6E5410")],
	["Hurt", Color("#F6D7B2"), Color("#8A4A10")],
	["Gravely hurt", Color("#F2CBC3"), Color("#8A1E22")],
	["Dead", Color("#DDD3E0"), Color("#4A3B4F")],
]

## Portrait background per GuildCharacter.CharacterRole.
const ROLE_GROUNDS := [Color("#D5DEE6"), Color("#E8E2D4"), Color("#D6E4CC"), Color("#E2D9EC")]

## Success chance -> [word, text colour, bar colour]. Checked top to bottom.
const ODDS := [
	[80, "Strong odds", GREEN_TEXT, Color("#5DBB8E")],
	[60, "Fair odds", Color("#6E5410"), GOLD],
	[40, "Risky", Color("#8A4A10"), Color("#E09A4F")],
	[0, "Long shot", Color("#8A1E22"), Color("#C9574F")],
]
const ODDS_UNKNOWN := ["No party yet", INK_SOFT, LINE]

## Building -> short tag shown in its colour box.
const BUILDING_TAGS := {0: "OFF", 1: "TRN", 2: "HSP", 3: "ARM", 4: "BRK"}


# ============================================================ TEXT HELPERS

## Picks the right word for n ("1 quest" / "3 quests").
static func plural(n: int, one: String, many: String) -> String:
	return one if n == 1 else many


## "3 quests"
static func count(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, plural(n, one, many)]


## Party names joined for display, e.g. "Alex & Gwen".
static func names(party: Array, separator := " & ") -> String:
	var list := PackedStringArray()
	for c in party:
		list.append(c.name)
	return separator.join(list)


## A character's backstory with blank lines removed.
static func backstory(c: GuildCharacter) -> String:
	var lines := PackedStringArray()
	for line in c.description.strip_edges().split("\n"):
		if line.strip_edges() != "":
			lines.append(line.strip_edges())
	return "\n".join(lines)


## [word, text colour, bar colour] for a success chance (-1 = no party yet).
static func odds(chance: int) -> Array:
	if chance < 0:
		return ODDS_UNKNOWN
	for row in ODDS:
		if chance >= row[0]:
			return row.slice(1)
	return ODDS_UNKNOWN


# ============================================================ GAME LOOKUPS

static func type_key(e: Dictionary) -> int:
	return 5 if e.get("milestone", false) else int(e.quest.type)


static func type_info(e: Dictionary) -> Dictionary:
	return TYPES.get(type_key(e), TYPES[1])


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


static func injury(c: GuildCharacter) -> Array:
	return INJURY[clampi(int(c.injury_level), 0, 4)]


static func is_dead(c: GuildCharacter) -> bool:
	return c.injury_level >= GuildCharacter.InjuryLevel.DEAD


## Buildings in display order: working ones first, "coming soon" after.
static func buildings_in_order() -> Array:
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	return order


# ============================================================ STYLE BOXES

static var _texture_cache := {}


## The project UI icon for a name in ICON_FILES, or null.
static func icon_tex(icon_name: String) -> Texture2D:
	if not ICON_FILES.has(icon_name):
		return null
	var path: String = UI_ICONS + ICON_FILES[icon_name]
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]


static func flat(fill: Color, radius: int = 12, border: int = 0, border_color: Color = INK, pad: Vector4 = Vector4(12, 6, 12, 6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = border_color
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	sb.anti_aliasing = true
	return sb


# ============================================================ RESTYLES

## Button colours per kind: [fill, pressed fill, text].
const BUTTON_KINDS := {
	"green": [Color("#43A047"), Color("#2E7D32"), Color.WHITE],
	"red": [Color("#E53935"), Color("#B71C1C"), Color.WHITE],
	"blue": [Color("#1E88E5"), Color("#1565C0"), Color.WHITE],
	"wood": [Color("#3B3F45"), Color("#24272B"), Color.WHITE],
	"paper": [Color("#EEEEEE"), Color("#D5D5D5"), Color("#222222")],
}


## Flat button. kind: green | red | blue | wood (dark) | paper (light grey).
static func style_button(b: Button, kind: String = "green", font_size: int = 28) -> void:
	var k: Array = BUTTON_KINDS.get(kind, BUTTON_KINDS.paper)
	var pad := Vector4(18, 8, 18, 8)
	var edge: Color = LINE if kind == "paper" else k[1]
	var normal := flat(k[0], 10, 2, edge, pad)
	var down := flat(k[1], 10, 2, edge, pad)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", flat(Color("#D0D0D0"), 10, 2, Color("#C4C4C4"), pad))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", font_size)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, k[2])
	b.add_theme_color_override("font_disabled_color", Color("#888888"))


## Small coloured box with a short tag (quest type, building).
static func style_tag(p: Control, l: Label, text: String, fill: Color) -> void:
	p.add_theme_stylebox_override("panel", flat(fill, 10, 0, fill, Vector4(6, 6, 6, 6)))
	l.text = text
	color(l, WHITE)


## Recolour a panel with a flat rounded box (state colours on cards and tabs).
static func style_panel(p: Control, fill: Color, border_color: Color, border: int = 3, radius: int = 14, pad: Vector4 = Vector4(14, 10, 14, 10)) -> void:
	p.add_theme_stylebox_override("panel", flat(fill, radius, border, border_color, pad))


## Recolour a label.
static func color(l: Control, c: Color) -> void:
	l.add_theme_color_override("font_color", c)


# ============================================================ SCENE HELPERS

## Remove every child from a list container before refilling it.
static func clear(list: Node) -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()


## Instance a row scene at the end of `list` and return it (call its setup next).
static func add_row(list: Node, scene: PackedScene) -> Node:
	var row := scene.instantiate()
	list.add_child(row)
	return row
