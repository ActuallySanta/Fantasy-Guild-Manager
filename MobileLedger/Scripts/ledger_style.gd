## Shared look and helpers for the Mobile Ledger UI.
##
## The look: painted parchment, wood and wax seals, Cinzel titles and Alegreya
## Sans body text, after the "Guild Ledger" reference art.
##
## Where things live:
##   - Layout: every screen, row and widget is a .tscn under MobileLedger/Scenes.
##   - Boxes: shared panel / button looks are .tres files in MobileLedger/Styles.
##   - Art: MobileLedger/Art (regenerate with MobileLedger/Tools/generate_art.py).
##   - This file: the palette, display tables, fonts, small text helpers, and
##     the restyles that change with game state (button kind, chip colour).
##
## Sections: PALETTE · DISPLAY TABLES · FONTS · TEXT HELPERS · GAME LOOKUPS ·
##           STYLE BOXES · RESTYLES · SCENE HELPERS
class_name LedgerStyle
extends RefCounted


# ============================================================ PALETTE

const INK := Color("#3A2816")         ## main text (dark brown ink)
const INK_SOFT := Color("#6B5537")    ## secondary text
const STORY_INK := Color("#4E3D26")   ## backstory / blurb text
const CREAM := Color("#FBF3DF")
const LINE := Color("#C9A96A")        ## divider lines
const WAX := Color("#A3262A")         ## wax-seal red: warnings, "remove"
const GOLD := Color("#D4A84F")
const GOLD_TEXT := Color("#7A5A12")
const GREEN_TEXT := Color("#2F6A22")
const BLUE_TEXT := Color("#2F5F8A")
const WHITE := Color("#FFFFFF")


# ============================================================ DISPLAY TABLES

const ART := "res://MobileLedger/Art/"
const ICONS := "res://MobileLedger/Art/Icons/"

## CreatedQuest.QuestType (5 = milestone) -> title colour, name, and scene picture.
const TYPE_COLORS := {
	1: Color("#2E6B2A"), 2: Color("#8A4B12"), 3: Color("#24557F"), 4: Color("#5B3F8C"), 5: Color("#A3262A"),
}
const TYPE_NAMES := {1: "Clear Dungeon", 2: "Escort", 3: "Scout Terrain", 4: "Gather Intel"}
const TYPE_SCENES := {
	1: "scene_dungeon.png", 2: "scene_escort.png", 3: "scene_scout.png", 4: "scene_intel.png", 5: "scene_milestone.png",
}

## The five stats in GuildCharacter.StatType order (Pluck last), each with its
## own icon (Art/Icons) and colours.
const STATS := [
	{"name": "Strength", "short": "Str", "icon": "strength", "color": Color("#A3262A"), "bg": Color("#F2D5CB")},
	{"name": "Defense", "short": "Def", "icon": "defense", "color": Color("#2F5F8A"), "bg": Color("#D3E1EE")},
	{"name": "Wisdom", "short": "Wis", "icon": "wisdom", "color": Color("#5B3F8C"), "bg": Color("#E2D9EF")},
	{"name": "Sleaziness", "short": "Slz", "icon": "sleaziness", "color": Color("#3E6B35"), "bg": Color("#D9E8CF")},
	{"name": "Pluck", "short": "Plk", "icon": "pluck", "color": Color("#94500F"), "bg": Color("#F5DCC0")},
]

## GuildCharacter.InjuryLevel -> [label, background, text colour].
const INJURY := [
	["Healthy", Color("#D9E8CF"), Color("#2F5A27")],
	["Sore", Color("#F4E5AC"), Color("#6E5410")],
	["Lightly Injured", Color("#F6D7B2"), Color("#8A4A10")],
	["Gravely Injured", Color("#F2CBC3"), Color("#8A1E22")],
	["Dead", Color("#DDD3E0"), Color("#4A3B4F")],
]

## Portrait background per GuildCharacter.CharacterRole.
const ROLE_GROUNDS := [Color("#B9C9D6"), Color("#E6DCC6"), Color("#C4D8A8"), Color("#D8C8E8")]

## Success chance -> [word, text colour, gauge colour]. Checked top to bottom.
const ODDS := [
	[80, "Strong odds", GREEN_TEXT, Color("#6FD1A8")],
	[60, "Fair odds", Color("#6E5410"), GOLD],
	[40, "Risky", Color("#8A4A10"), Color("#E09A4F")],
	[0, "Long shot", Color("#8A1E22"), Color("#C9574F")],
]
const ODDS_UNKNOWN := ["Chance unknown", INK_SOFT, Color("#7C6648")]


# ============================================================ FONTS

const DISPLAY_FONT := preload("res://MobileLedger/Fonts/cinzel_bold.tres")
const DISPLAY_BLACK := preload("res://MobileLedger/Fonts/cinzel_black.tres")
const BODY_FONT := preload("res://MobileLedger/Fonts/AlegreyaSans-Medium.ttf")
const BODY_BOLD := preload("res://MobileLedger/Fonts/AlegreyaSans-Bold.ttf")
const BODY_ITALIC := preload("res://MobileLedger/Fonts/AlegreyaSans-Italic.ttf")


# ============================================================ TEXT HELPERS

## "1 quest" / "3 quests" style: picks the right word for n.
static func plural(n: int, one: String, many: String) -> String:
	return one if n == 1 else many


## Party names joined for display, e.g. "Alex & Gwen".
static func names(party: Array, separator := " & ") -> String:
	var list := PackedStringArray()
	for c in party:
		list.append(c.name)
	return separator.join(list)


## "no injuries yet" / "1 injury" / "3 injuries".
static func injury_count(c: GuildCharacter) -> String:
	if c.injury_count == 0:
		return "no injuries yet"
	return "%d %s" % [c.injury_count, plural(c.injury_count, "injury", "injuries")]


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


# ============================================================ GAME LOOKUPS

## Index into STATS for a quest's favored stat.
static func favored_index(quest: CreatedQuest) -> int:
	return clampi(int(quest.favStat), 0, 4)


static func role_name(c: GuildCharacter) -> String:
	return str(GuildCharacter.CharacterRole.find_key(c.role)).capitalize()


static func rank_letter(quest: CreatedQuest) -> String:
	return str(CreatedQuest.QuestDifficulty.find_key(quest.difficulty))


## TYPE_COLORS / TYPE_SCENES key for a quest entry (5 = the milestone).
static func type_key(e: Dictionary) -> int:
	return 5 if e.get("milestone", false) else int(e.quest.type)


## A character's value for STATS[i] (Pluck is stored separately).
static func stat_value(c: GuildCharacter, i: int) -> int:
	return c.pluck if i == 4 else int(c.stats[i])


## The four quest stats added up (shown on recruit cards).
static func stat_total(c: GuildCharacter) -> int:
	return c.stats[0] + c.stats[1] + c.stats[2] + c.stats[3]


## How well a character fits a quest: the total CreatedQuest.calcSuccessChance
## uses (all four stats, favored one counted twice).
static func fit_score(q: CreatedQuest, c: GuildCharacter) -> int:
	var total := stat_total(c)
	var f := favored_index(q)
	if f < 4:
		total += c.stats[f]
	return total


## CreatedQuest.calcSuccessChance's party total needed for 100%.
static func fit_needed(q: CreatedQuest) -> int:
	var needed := 60.0 + 20 * q.difficulty
	if q.maxAdventurers == 1:
		needed = needed / 2
	return int(needed)


## Buildings in display order: working ones first, "coming soon" after.
static func buildings_in_order() -> Array:
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	return order


# ============================================================ STYLE BOXES

static var _texture_cache := {}


static func tex(file: String) -> Texture2D:
	var path := ART + file
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]


static func icon_tex(icon_name: String) -> Texture2D:
	if icon_name == "":
		return null
	var path := ICONS + icon_name + ".svg"
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]


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


# ============================================================ RESTYLES

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
