## Style kit for the Mobile Ledger UI: painted parchment, wood, wax seals.
## Every node lives in a .tscn (MobileLedger/*.tscn, Scenes/); shared boxes are
## in MobileLedger/Styles and the base theme is MobileLedger/ledger_theme.tres.
## This file only holds the palette, fonts and the restyles that depend on game
## state at runtime. Art lives in MobileLedger/Art (regenerate with
## MobileLedger/Tools/generate_art.py).
class_name LedgerStyle
extends RefCounted

const ART := "res://MobileLedger/Art/"
const ICONS := "res://MobileLedger/Art/Icons/"
const FONTS := "res://MobileLedger/Fonts/"

const INK := Color("#3A2816")
const INK_SOFT := Color("#6B5537")
const PARCH := Color("#F3E4C2")
const CREAM := Color("#FBF3DF")
const LINE := Color("#C9A96A")
const WAX := Color("#A3262A")
const GOLD := Color("#D4A84F")
const GOLD_TEXT := Color("#7A5A12")
const GREEN_TEXT := Color("#2F6A22")
const BLUE_TEXT := Color("#2F5F8A")
const WHITE := Color("#FFFFFF")

## Quest title colours by CreatedQuest.QuestType (and 5 = milestone).
const TYPE_COLORS := {
	1: Color("#2E6B2A"), 2: Color("#8A4B12"), 3: Color("#24557F"), 4: Color("#5B3F8C"), 5: Color("#A3262A"),
}
const TYPE_NAMES := {1: "Clear Dungeon", 2: "Escort", 3: "Scout Terrain", 4: "Gather Intel"}
const TYPE_SCENES := {
	1: "scene_dungeon.png", 2: "scene_escort.png", 3: "scene_scout.png", 4: "scene_intel.png", 5: "scene_milestone.png",
}

## GuildCharacter.StatType order, plus Pluck (stored separately on the character).
const STATS := [
	{"name": "Strength", "short": "Str", "icon": "strength", "color": Color("#A3262A"), "bg": Color("#F2D5CB")},
	{"name": "Defense", "short": "Def", "icon": "defense", "color": Color("#2F5F8A"), "bg": Color("#D3E1EE")},
	{"name": "Wisdom", "short": "Wis", "icon": "wisdom", "color": Color("#5B3F8C"), "bg": Color("#E2D9EF")},
	{"name": "Sleaziness", "short": "Slz", "icon": "sleaziness", "color": Color("#3E6B35"), "bg": Color("#D9E8CF")},
	{"name": "Pluck", "short": "Plk", "icon": "pluck", "color": Color("#94500F"), "bg": Color("#F5DCC0")},
]

## GuildCharacter.InjuryLevel → label, background, text colour.
const INJURY := [
	["Healthy", Color("#D9E8CF"), Color("#2F5A27")],
	["Sore", Color("#F4E5AC"), Color("#6E5410")],
	["Lightly Injured", Color("#F6D7B2"), Color("#8A4A10")],
	["Gravely Injured", Color("#F2CBC3"), Color("#8A1E22")],
	["Dead", Color("#DDD3E0"), Color("#4A3B4F")],
]

const ROLE_GROUNDS := [Color("#B9C9D6"), Color("#E6DCC6"), Color("#C4D8A8"), Color("#D8C8E8")]

const DISPLAY_FONT := preload("res://MobileLedger/Fonts/cinzel_bold.tres")
const DISPLAY_BLACK := preload("res://MobileLedger/Fonts/cinzel_black.tres")
const BODY_FONT := preload("res://MobileLedger/Fonts/AlegreyaSans-Medium.ttf")
const BODY_BOLD := preload("res://MobileLedger/Fonts/AlegreyaSans-Bold.ttf")
const BODY_ITALIC := preload("res://MobileLedger/Fonts/AlegreyaSans-Italic.ttf")

static var _cache := {}


# ---------------------------------------------------------------- resources

static func tex(file: String) -> Texture2D:
	var path := ART + file
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


static func icon_tex(icon_name: String) -> Texture2D:
	if icon_name == "":
		return null
	var path := ICONS + icon_name + ".svg"
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


## 9-slice stylebox from a painted texture. `margin` = slice size in the texture,
## `pad` = content padding. `shadow` = extra pixels baked under the art.
static func sbtex(file: String, margin: float, pad: Vector4 = Vector4(20, 18, 20, 18), shadow: float = 0.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(file)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin + shadow
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w + shadow
	return sb


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


## A painted parchment panel box. kind: "panel" | "card" | "ready" | "inset".
static func panel_box(kind: String = "panel", pad: Vector4 = Vector4(26, 22, 26, 24)) -> StyleBoxTexture:
	var file: String = {"panel": "panel_parchment.png", "card": "card_parchment.png", "ready": "card_ready.png", "inset": "inset_parchment.png"}[kind]
	var m := 40.0 if kind != "inset" else 26.0
	var sh := 10.0 if kind != "inset" else 8.0
	return sbtex(file, m, pad, sh)


# ---------------------------------------------------------------- restyles

## Painted button. kind: green | red | wood | blue | paper.
static func style_button(b: Button, kind: String = "green", size: int = 28) -> void:
	var pad := Vector4(26, 10, 26, 10)
	var normal := sbtex("btn_%s.png" % kind, 26, pad, 6)
	var down := sbtex("btn_%s_down.png" % kind, 26, pad + Vector4(0, 4, 0, -4), 6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", sbtex("btn_disabled.png", 26, pad, 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", DISPLAY_FONT)
	b.add_theme_font_size_override("font_size", size)
	var light := kind != "paper"
	var fc := WHITE if light else INK
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, fc)
	b.add_theme_color_override("font_disabled_color", Color("#7A6A55"))
	if light:
		b.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.03, 0.85))
		b.add_theme_constant_override("outline_size", 6)
	else:
		b.remove_theme_color_override("font_outline_color")
		b.remove_theme_constant_override("outline_size")
	b.add_theme_constant_override("icon_max_width", int(size * 1.3))
	b.add_theme_constant_override("h_separation", 10)


static func style_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, border: bool = true) -> void:
	p.add_theme_stylebox_override("panel", flat(bg, 18, 2 if border else 0, fg, Vector4(14, 2, 14, 4)))
	l.add_theme_color_override("font_color", fg)


static func style_icon_chip(p: PanelContainer, l: Label, bg: Color, fg: Color, outlined: bool = false) -> void:
	p.add_theme_stylebox_override("panel", flat(bg, 18, 3 if outlined else 0, fg, Vector4(8, 2, 14, 2)))
	l.add_theme_color_override("font_color", fg)


## The Ledger icons are painted in colour; `tint` multiplies them.
static func tint_icon(t: TextureRect, tint: Color) -> void:
	t.modulate = tint

## [word, text colour, gauge colour] for a success chance (-1 = no party yet).
static func odds(p: int) -> Array:
	if p < 0:
		return ["Chance unknown", INK_SOFT, Color("#7C6648")]
	if p >= 80:
		return ["Strong odds", GREEN_TEXT, Color("#6FD1A8")]
	if p >= 60:
		return ["Fair odds", Color("#6E5410"), GOLD]
	if p >= 40:
		return ["Risky", Color("#8A4A10"), Color("#E09A4F")]
	return ["Long shot", Color("#8A1E22"), Color("#C9574F")]


static func stat_name(i: int) -> String:
	return STATS[i].name


## Display name for a CreatedQuest.FavoredStat. The quest system calls Strength
## "Attack" and Sleaziness "Sleaze"; the UI uses the character-sheet names.
static func favored_index(quest: CreatedQuest) -> int:
	return clampi(int(quest.favStat), 0, 4)


static func role_name(character: GuildCharacter) -> String:
	return str(GuildCharacter.CharacterRole.find_key(character.role)).capitalize()


static func rank_letter(quest: CreatedQuest) -> String:
	return str(CreatedQuest.QuestDifficulty.find_key(quest.difficulty))


## TYPE_COLORS / TYPE_SCENES key for a quest entry (5 = the milestone).
static func type_key(e: Dictionary) -> int:
	return 5 if e.get("milestone", false) else int(e.quest.type)


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
