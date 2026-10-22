## Shared look and helpers for the Mobile Hall UI.
##
## The look: a guild hall at night. Dark wood behind everything, parchment
## cards, blackletter titles, ink colours that mean something (each stat has its
## own ink, green = good / sent, red = bad / denied, blue = odds / to do,
## gold = money).
##
## Where the art lives (see MobileHall/Art/README.md for how to swap it):
##   - Art/Textures, Art/Icons, Art/Fonts: every image and font file. Replace a
##     file with your own art of the same name and the whole UI picks it up.
##   - Styles/*.tres: one StyleBox per surface (paper card, gold button...).
##   - hall_theme.tres: fonts, text colours, and the named looks scenes use
##     (theme_type_variation = TitleLabel, PaperCard, GoldButton...).
##   - This file: ink colours, display tables, the icon table, text helpers,
##     game lookups, and the restyles that change with game state.
##
## Sections: PALETTE · DISPLAY TABLES · ICONS · TEXT HELPERS · GAME LOOKUPS ·
##           RESTYLES · SCENE HELPERS
extends RefCounted


# ============================================================ PALETTE

const INK := Color("#342920")         ## main text on paper
const INK_SOFT := Color("#6B5D4F")    ## secondary text on paper
const CREAM := Color("#EDE3CB")       ## text on wood
const CREAM_SOFT := Color("#CBBBA0")  ## secondary text on wood
const LINE := Color("#9C8B70")        ## rules and dashes on paper
const WAX := Color("#8B2E2A")         ## red ink: deny, failed, hurt
const GOLD_TEXT := Color("#6B5A1E")
const GREEN_TEXT := Color("#3D5A2A")
const BLUE_TEXT := Color("#2F4A66")
const WHITE := Color("#FFFFFF")


# ============================================================ DISPLAY TABLES

## CreatedQuest.QuestType (5 = milestone) -> seal colour, name, writ, short tag.
const TYPES := {
	1: {"name": "Clear Dungeon", "writ": "Writ of Clearing", "color": Color("#4A5E32"), "tag": "DUN"},
	2: {"name": "Escort", "writ": "Writ of Escort", "color": Color("#7A5236"), "tag": "ESC"},
	3: {"name": "Scout Terrain", "writ": "Writ of Scouting", "color": Color("#3F5A74"), "tag": "SCT"},
	4: {"name": "Gather Intel", "writ": "Writ of Intelligence", "color": Color("#5B4A7A"), "tag": "INT"},
	5: {"name": "Milestone", "writ": "Writ of the Drake", "color": Color("#7D2A26"), "tag": "BOSS"},
}

## The five stats in GuildCharacter.StatType order (Pluck last).
const STATS := [
	{"name": "Strength", "short": "Str", "color": Color("#8B2E2A")},
	{"name": "Defense", "short": "Def", "color": Color("#2F4A66")},
	{"name": "Wisdom", "short": "Wis", "color": Color("#5B4A7A")},
	{"name": "Sleaziness", "short": "Slz", "color": Color("#3D5A2A")},
	{"name": "Pluck", "short": "Plk", "color": Color("#7A4A1E")},
]

## GuildCharacter.InjuryLevel -> [label, ink].
const INJURY := [
	["Healthy", GREEN_TEXT],
	["Sore", Color("#6E5410")],
	["Hurt", Color("#8A4A10")],
	["Gravely hurt", WAX],
	["Dead", Color("#4A3B4F")],
]

## Portrait ground per GuildCharacter.CharacterRole.
const ROLE_GROUNDS := [Color("#D9D3C2"), Color("#E3D7BD"), Color("#D3D7C0"), Color("#DCD3CA")]

## Success chance -> [word, ink]. Checked top to bottom.
const ODDS := [
	[80, "Strong odds", BLUE_TEXT],
	[60, "Fair odds", GOLD_TEXT],
	[40, "Risky", Color("#8A4A1E")],
	[0, "Long shot", WAX],
]
const ODDS_UNKNOWN := ["No party yet", INK_SOFT]

## Building -> short tag and icon (an ICONS name).
const BUILDINGS := {
	0: {"tag": "OFF", "icon": "quill"},
	1: {"tag": "TRN", "icon": "target"},
	2: {"tag": "HSP", "icon": "cross"},
	3: {"tag": "ARM", "icon": "swords"},
	4: {"tag": "BRK", "icon": "bed"},
}


# ============================================================ ICONS

const ART := "res://MobileHall/Art/"

## Icon names used by the screens -> files. Line icons are white so they can be
## tinted; swap any file for your own art (keep it white to keep the tinting).
const ICONS := {
	"board": "Icons/scroll.svg",
	"guild": "Icons/shield.svg",
	"upgrades": "Icons/hammer.svg",
	"gear": "Icons/gear.svg",
	"coins": "Icons/coins.svg",
	"person": "Icons/person.svg",
	"bed": "Icons/bed.svg",
	"swords": "Icons/swords.svg",
	"chest": "Icons/chest.svg",
	"scroll": "Icons/scroll.svg",
	"x": "Icons/x.svg",
	"back": "Icons/arrow_left.svg",
	"check": "Icons/check.svg",
	"diamond": "Icons/diamond.svg",
	"diamond_empty": "Icons/diamond_empty.svg",
	"target": "Icons/target.svg",
	"cross": "Icons/cross.svg",
	"quill": "Icons/quill.svg",
	"skull": "Icons/skull.svg",
	"heart": "Icons/heart.svg",
}

static var _texture_cache := {}


## The texture for a name in ICONS, or null.
static func icon_tex(icon_name: String) -> Texture2D:
	if not ICONS.has(icon_name):
		return null
	var path: String = ART + ICONS[icon_name]
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]


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


## [word, ink] for a success chance (-1 = no party yet).
static func odds(chance: int) -> Array:
	if chance < 0:
		return ODDS_UNKNOWN
	for row in ODDS:
		if chance >= row[0]:
			return row.slice(1)
	return ODDS_UNKNOWN


## 14 -> "XIV"
static func roman(n: int) -> String:
	var out := ""
	for pair in [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= pair[0]:
			out += pair[1]
			n -= pair[0]
	return out


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


static func stat_total(c: GuildCharacter) -> int:
	var total := 0
	for i in 4:
		total += stat_value(c, i)
	return total


static func injury(c: GuildCharacter) -> Array:
	return INJURY[clampi(int(c.injury_level), 0, 4)]


static func is_dead(c: GuildCharacter) -> bool:
	return c.injury_level >= GuildCharacter.InjuryLevel.DEAD


## Buildings in display order: working ones first, "coming soon" after.
static func buildings_in_order() -> Array:
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	return order


# ============================================================ RESTYLES

## Button kinds -> theme_type_variation in hall_theme.tres.
const BUTTON_KINDS := {
	"gold": &"GoldButton",
	"wood": &"WoodButton",
	"paper": &"PaperButton",
	"seal": &"SealButton",
}


## Pick a button's look by kind (gold | wood | paper | seal). font_size 0 keeps the theme's.
static func style_button(b: Button, kind: String = "gold", font_size: int = 0) -> void:
	b.theme_type_variation = BUTTON_KINDS.get(kind, &"PaperButton")
	if font_size > 0:
		b.add_theme_font_size_override("font_size", font_size)


## Swap a panel's look for another theme variation (PaperCard, PlanCard...).
static func look(p: Control, variation: StringName) -> void:
	p.theme_type_variation = variation


## Ink a white piece of art (seal disc, stamp, outline box, icon) in a colour.
## self_modulate tints the node's own drawing, not its children.
static func tint(p: CanvasItem, c: Color) -> void:
	p.self_modulate = c


## A coloured seal or tag with short text on it (quest type, building).
static func seal(p: Control, l: Label, text: String, fill: Color) -> void:
	tint(p, fill)
	l.text = text
	color(l, CREAM)


## Recolour a label.
static func color(l: Control, c: Color) -> void:
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("default_color", c)


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
