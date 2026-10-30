## Shared look and helpers for the Mobile Hall UI.
##
## Every other MobileHall script preloads this file as `Style` and calls its
## static helpers (Style.style_button(...), Style.QUEST_STATE_SENT, ...).
## Nothing here holds state except the icon texture cache.
##
## The look: a guild hall at night. Dark wood behind everything, parchment
## cards, blackletter titles, and ink colours that mean something (each stat
## has its own ink, green = good / sent, red = bad / denied / hurt,
## blue = odds / to do, gold = money).
##
## Where things live (see MobileHall/Art/README.md for how to swap the art):
##   - Layout: every screen, row and widget is a .tscn under MobileHall/Scenes.
##   - Art:    every image, icon and font is in MobileHall/Art. Replace a file
##             with your own of the same name and the whole UI picks it up.
##   - Boxes:  one StyleBox per surface (paper card, gold button...) in
##             MobileHall/Styles, and hall_theme.tres names the looks scenes use
##             (theme_type_variation = TitleLabel, PaperCard, GoldButton...).
##   - This file: ink colours, display tables, the icon table, text helpers,
##     game lookups, and the restyles that change with game state. Restyles
##     never build boxes for the art: they pick a theme look or tint white art.
##
## Sections:
##   QUEST STATES · PALETTE · DISPLAY TABLES · TEXT HELPERS · GAME LOOKUPS ·
##   ICONS · STYLE BOXES · RESTYLES · SCENE HELPERS
extends RefCounted


# ============================================================ QUEST STATES
# Every quest entry on the day's board is in exactly one of these states.
# (See hall_main.gd -> quest_entries for the full entry layout.)

## Not decided yet. Its party (if any) is a draft that is kept until changed.
const QUEST_STATE_OPEN := "open"
## The party has been sent; it goes out when the day ends.
const QUEST_STATE_SENT := "sent"
## Turned down. It stays on the board and can be reconsidered.
const QUEST_STATE_DENIED := "denied"


# ============================================================ PALETTE

# ---- ink on paper
const TEXT_MAIN := Color("#342920")       ## main text, outlines
const TEXT_SOFT := Color("#6B5D4F")       ## secondary text, hints
const LINE := Color("#9C8B70")            ## rules and dashes on paper

# ---- ink on wood
const CREAM := Color("#EDE3CB")           ## text on the wood background
const CREAM_SOFT := Color("#CBBBA0")      ## secondary text on wood

# ---- paper tints (multiplied over the parchment art by style_panel)
const CARD_BG := Color("#FFFFFF")         ## plain parchment (no tint)
const NEUTRAL_BG := Color("#EFE9DD")      ## neutral inset
const BORDER := Color("#9C8B70")          ## default border ink
const WHITE := Color("#FFFFFF")
const SENT_CARD_BG := Color("#E4EED8")    ## sent quest, picked adventurer, affordable upgrade
const DENIED_CARD_BG := Color("#E2DDD5")  ## denied quest, adventurer who can't go
const EMPTY_SEAT_BG := Color("#EFE9DD")   ## empty party seat

# ---- meaning inks: [ink, text ink, paper tint]
const RED := Color("#8B2E2A")             ## deny, failed, hurt, warnings
const RED_BG := Color("#F2DCD4")
const GOLD := Color("#B8913A")
const GOLD_TEXT := Color("#6B5A1E")
const GOLD_BG := Color("#F3E7C6")
const GREEN := Color("#4A6B35")           ## success, sent, done
const GREEN_TEXT := Color("#3D5A2A")
const GREEN_BG := Color("#E0EBD3")
const BLUE_TEXT := Color("#2F4A66")       ## odds, to do, picked
const BLUE_BG := Color("#DDE5EC")
## The navy ink for names on letters and sign-offs.
const NAVY := Color("#26304A")


# ============================================================ DISPLAY TABLES

# ---- quest types

## Key used for the milestone (Bone Drake) quest; it isn't a CreatedQuest.QuestType.
const MILESTONE_TYPE_ID := 5

## CreatedQuest.QuestType (plus MILESTONE_TYPE_ID) -> display name, writ name
## (the Assign Party scroll), seal colour, short tag.
const QUEST_TYPES := {
	1: {"name": "Clear Dungeon", "writ": "Writ of Clearing", "color": Color("#4A5E32"), "tag": "DUN"},
	2: {"name": "Escort", "writ": "Writ of Escort", "color": Color("#7A5236"), "tag": "ESC"},
	3: {"name": "Scout Terrain", "writ": "Writ of Scouting", "color": Color("#3F5A74"), "tag": "SCT"},
	4: {"name": "Gather Intel", "writ": "Writ of Intelligence", "color": Color("#5B4A7A"), "tag": "INT"},
	MILESTONE_TYPE_ID: {"name": "Milestone", "writ": "Writ of the Drake", "color": Color("#7D2A26"), "tag": "BOSS"},
}

# ---- stats

## How many stats a character has (Power, Defense, Wisdom, Sleaziness, Pluck).
## Power is GuildCharacter.StatType.STRENGTH; only the name shown to players differs.
const STAT_COUNT := 5
## How many of those quests actually use (all but Pluck).
const QUEST_STAT_COUNT := 4
## Pluck is stored on its own field, not in GuildCharacter.stats.
const PLUCK_INDEX := 4

## The five stats in GuildCharacter.StatType order (Pluck last).
## name = full name, short = chip label, color = the stat's ink, bg = a paper tint.
const STATS := [
	{"name": "Power", "short": "Pow", "color": Color("#8B2E2A"), "bg": Color("#F2DCD4")},
	{"name": "Defense", "short": "Def", "color": Color("#2F4A66"), "bg": Color("#DDE5EC")},
	{"name": "Wisdom", "short": "Wis", "color": Color("#5B4A7A"), "bg": Color("#E6E0EE")},
	{"name": "Sleaziness", "short": "Slz", "color": Color("#3D5A2A"), "bg": Color("#E0EBD3")},
	{"name": "Pluck", "short": "Plk", "color": Color("#7A4A1E"), "bg": Color("#F0E0CC")},
]

# ---- health

## GuildCharacter.InjuryLevel -> label, ink (text) and a paper tint (bg).
const INJURY_LOOKS := [
	{"label": "Healthy", "bg": Color("#E0EBD3"), "text": Color("#3D5A2A")},
	{"label": "Sore", "bg": Color("#F3E7C6"), "text": Color("#6E5410")},
	{"label": "Hurt", "bg": Color("#F2E0CC"), "text": Color("#8A4A10")},
	{"label": "Gravely hurt", "bg": Color("#F2DCD4"), "text": Color("#8B2E2A")},
	{"label": "Dead", "bg": Color("#E2DDE3"), "text": Color("#4A3B4F")},
]

# ---- portraits

## Portrait ground colour per GuildCharacter.CharacterRole.
const ROLE_PORTRAIT_BGS := [Color("#D9D3C2"), Color("#E3D7BD"), Color("#D3D7C0"), Color("#DCD3CA")]

# ---- success odds

## Success chance bands, checked top to bottom: the first band whose `min`
## the chance reaches is used. word = label, text_color = numbers and words,
## bar_color = the ink the odds bar's hatching is tinted.
const ODDS_BANDS := [
	{"min": 80, "word": "Strong odds", "text_color": BLUE_TEXT, "bar_color": BLUE_TEXT},
	{"min": 60, "word": "Fair odds", "text_color": GOLD_TEXT, "bar_color": GOLD_TEXT},
	{"min": 40, "word": "Risky", "text_color": Color("#8A4A1E"), "bar_color": Color("#8A4A1E")},
	{"min": 0, "word": "Long shot", "text_color": RED, "bar_color": RED},
]
## Shown when a quest has nobody in its party yet (chance = -1).
const ODDS_NO_PARTY := {"min": -1, "word": "No party yet", "text_color": TEXT_SOFT, "bar_color": LINE}

# ---- buildings

## GuildUpgrades.Building -> short tag shown on the building's seal.
const BUILDING_TAGS := {0: "OFF", 1: "TRN", 2: "HSP", 3: "ARM", 4: "BRK"}
## GuildUpgrades.Building -> icon (an ICON_FILES name) drawn on its plan.
const BUILDING_ICONS := {0: "quill", 1: "target", 2: "cross", 3: "swords", 4: "bed"}

# ---- items

## StandardItem.Rarity name -> short tag and seal ink (shop tags, gear rows).
const ITEM_RARITY_LOOKS := {
	"COMMON": {"tag": "COM", "color": Color("#6B6358")},
	"UNCOMMON": {"tag": "UNC", "color": Color("#4A6B35")},
	"RARE": {"tag": "RAR", "color": Color("#2F4A66")},
	"LEGENDARY": {"tag": "LEG", "color": Color("#5B4A7A")},
	"MYTHIC": {"tag": "MYT", "color": Color("#9C7426")},
	"NAMED": {"tag": "NAM", "color": Color("#8B2E2A")},
}


# ============================================================ TEXT HELPERS

## The right word for an amount: pick_plural(1, "quest", "quests") -> "quest".
static func pick_plural(amount: int, singular: String, plural: String) -> String:
	return singular if amount == 1 else plural


## An amount with its word: count_text(3, "quest", "quests") -> "3 quests".
static func count_text(amount: int, singular: String, plural: String) -> String:
	return "%d %s" % [amount, pick_plural(amount, singular, plural)]


## Character names joined for display, e.g. "Alex & Gwen".
static func join_names(characters: Array, separator := " & ") -> String:
	var name_list := PackedStringArray()
	for character in characters:
		name_list.append(character.name)
	return separator.join(name_list)


## A character's backstory with blank lines and stray spaces removed.
static func clean_backstory(character: GuildCharacter) -> String:
	var kept_lines := PackedStringArray()
	for line in character.description.strip_edges().split("\n"):
		var trimmed := line.strip_edges()
		if trimmed != "":
			kept_lines.append(trimmed)
	return "\n".join(kept_lines)


## The odds band for a success chance (0-100, or -1 = no party yet).
## Returns {word, text_color, bar_color}.
static func odds_look(chance: int) -> Dictionary:
	if chance < 0:
		return ODDS_NO_PARTY
	for band in ODDS_BANDS:
		if chance >= band.min:
			return band
	return ODDS_NO_PARTY


## A number in Roman numerals: roman_numeral(14) -> "XIV".
static func roman_numeral(number: int) -> String:
	var numerals := [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
			[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var text := ""
	for numeral in numerals:
		while number >= numeral[0]:
			text += numeral[1]
			number -= numeral[0]
	return text


# ============================================================ GAME LOOKUPS

# ---- quests

## Key into QUEST_TYPES for a quest entry (the milestone gets its own key).
static func quest_type_id(entry: Dictionary) -> int:
	return MILESTONE_TYPE_ID if entry.get("milestone", false) else int(entry.quest.type)


## {name, writ, color, tag} for a quest entry's type (falls back to Clear Dungeon).
static func quest_type_info(entry: Dictionary) -> Dictionary:
	return QUEST_TYPES.get(quest_type_id(entry), QUEST_TYPES[1])


## Index into STATS for the stat a quest favors.
static func favored_stat_index(quest: CreatedQuest) -> int:
	return clampi(int(quest.favStat), 0, STAT_COUNT - 1)


## Rank letter for a quest ("F" ... "S").
static func rank_letter(quest: CreatedQuest) -> String:
	return str(CreatedQuest.QuestDifficulty.find_key(quest.difficulty))

# ---- characters


## Role as a word ("Fighter", "Rogue", ...).
static func role_name(character: GuildCharacter) -> String:
	return str(GuildCharacter.CharacterRole.find_key(character.role)).capitalize()


## A character's base value for STATS[stat_index] (Pluck is stored separately).
## Doesn't include temp stats (gear, pluck bonus); see quest_stat_value.
static func stat_value(character: GuildCharacter, stat_index: int) -> int:
	return character.pluck if stat_index == PLUCK_INDEX else int(character.stats[stat_index])


## The value quests use: base stat + temp stats (gear and pluck bonus).
static func quest_stat_value(character: GuildCharacter, stat_index: int) -> int:
	if stat_index == PLUCK_INDEX:
		return character.pluck
	character.reset_temp_stats()
	return character.get_quest_stat(stat_index)


## Everything added on top of a character's own stat: Armory + gear + Pluck bonus.
## quest_stat_value - stat_bonus is the stat before any bonus.
static func stat_bonus(character: GuildCharacter, stat_index: int) -> int:
	if stat_index == PLUCK_INDEX:
		return 0
	var armory_bonus := GuildUpgrades.get_stat_bonus(character, stat_index)
	return armory_bonus + quest_stat_value(character, stat_index) - stat_value(character, stat_index)


## The four quest stats added up (the applicant letter's "Stat total").
static func quest_stat_total(character: GuildCharacter) -> int:
	var total := 0
	for stat_index in QUEST_STAT_COUNT:
		total += stat_value(character, stat_index)
	return total


## {label, bg, text} for a character's current injury level.
static func injury_look(character: GuildCharacter) -> Dictionary:
	return INJURY_LOOKS[clampi(int(character.injury_level), 0, INJURY_LOOKS.size() - 1)]


static func is_dead(character: GuildCharacter) -> bool:
	return character.injury_level >= GuildCharacter.InjuryLevel.DEAD

# ---- items


## {name, short, tag, color, effect} for a StandardItem, e.g.
## name "Rare Sword", short "Sword", tag "RAR", effect "+16 Power · Knights only".
static func item_look(item: StandardItem) -> Dictionary:
	var rarity_name := str(StandardItem.Rarity.find_key(item.rarity))
	var rarity_look: Dictionary = ITEM_RARITY_LOOKS.get(rarity_name, ITEM_RARITY_LOOKS.COMMON)
	var full_name := item.name.capitalize()
	var space := full_name.find(" ")
	return {
		"name": full_name,
		"short": full_name.substr(space + 1) if space >= 0 else full_name,
		"tag": rarity_look.tag,
		"color": rarity_look.color,
		"effect": item_effect(item),
	}


## "+16 Power · Knights only"
static func item_effect(item: StandardItem) -> String:
	var role_text := "%ss only" % item_role_name(item)
	if item is PassiveItem:
		var passive := item as PassiveItem
		return "+%d %s · %s" % [passive.stat_amount, STATS[passive.affected_stat].name, role_text]
	return role_text


## The role that can use an item, as a word ("Knight").
static func item_role_name(item: StandardItem) -> String:
	return str(GuildCharacter.CharacterRole.find_key(item.role)).capitalize()

# ---- buildings


## Buildings in display order: working ones first, "coming soon" after.
static func buildings_in_order() -> Array:
	var buildings: Array = GuildUpgrades.Building.values()
	buildings.sort_custom(func(first, second):
		return GuildUpgrades.is_implemented(first) and not GuildUpgrades.is_implemented(second))
	return buildings


# ============================================================ ICONS

const ART_FOLDER := "res://MobileHall/Art/"

## Icon names used by the screens -> file in ART_FOLDER. Line icons are white
## so they can be tinted; swap any file for your own art (keep it white to
## keep the tinting). Names not listed here have no icon, so it's hidden.
const ICON_FILES := {
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
	"stall": "Icons/stall.svg",
	"nav_settings": "Icons/gear.svg",
	"nav_quests": "Icons/scroll.svg",
	"nav_characters": "Icons/person.svg",
	"nav_upgrades": "Icons/hammer.svg",
	"nav_shop": "Icons/stall.svg",
}

## Loaded icon textures by path, so each file is only loaded once.
static var _icon_cache := {}


## The texture for a name in ICON_FILES, or null if it has none.
static func icon_texture(icon_name: String) -> Texture2D:
	if not ICON_FILES.has(icon_name):
		return null
	var path: String = ART_FOLDER + ICON_FILES[icon_name]
	if not _icon_cache.has(path):
		_icon_cache[path] = load(path)
	return _icon_cache[path]


# ============================================================ STYLE BOXES

## A flat rounded box. padding = content margins (left, top, right, bottom).
## For simple shapes drawn in code; anything with art uses a theme look instead.
static func flat_box(fill: Color, corner_radius: int = 12, border_width: int = 0, border_color: Color = TEXT_MAIN, padding: Vector4 = Vector4(12, 6, 12, 6)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(corner_radius)
	box.set_border_width_all(border_width)
	box.border_color = border_color
	box.content_margin_left = padding.x
	box.content_margin_top = padding.y
	box.content_margin_right = padding.z
	box.content_margin_bottom = padding.w
	box.anti_aliasing = true
	return box


# ============================================================ RESTYLES

## Button kinds -> theme_type_variation in hall_theme.tres. The old colour
## names still work: green / blue = gold (go), red / wood = dark wood, paper = paper.
const BUTTON_KINDS := {
	"gold": &"GoldButton",
	"green": &"GoldButton",
	"blue": &"GoldButton",
	"wood": &"WoodButton",
	"red": &"WoodButton",
	"paper": &"PaperButton",
	"seal": &"SealButton",
}

## Every Button state that should share one box / one font colour.
const BUTTON_BOX_STATES := ["normal", "hover", "pressed", "hover_pressed"]
const BUTTON_FONT_STATES := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]

## The parchment look style_panel puts on a panel that has none of its own.
const PAPER_LOOK := &"PaperCard"


## Pick a button's look by kind (see BUTTON_KINDS). font_size 0 keeps the theme's.
static func style_button(button: Button, kind: String = "gold", font_size: int = 0) -> void:
	button.theme_type_variation = BUTTON_KINDS.get(kind, &"PaperButton")
	if font_size > 0:
		button.add_theme_font_size_override("font_size", font_size)


## A coloured seal (white art tinted `fill`) with a short tag on it (quest type, building).
static func style_tag(tag_panel: Control, tag_label: Label, text: String, fill: Color) -> void:
	tag_panel.theme_type_variation = &"TypeSeal"
	tint_art(tag_panel, fill)
	tag_label.text = text
	tag_label.theme_type_variation = &"SealLabel"


## Card state colours: the panel keeps (or gets) its parchment look and the
## paper is tinted with `fill` (CARD_BG / WHITE = no tint). The border and
## shape arguments are kept for older callers; the art decides those now.
static func style_panel(panel: Control, fill: Color, _border_color: Color = BORDER, _border_width: int = 3, _corner_radius: int = 14, _padding: Vector4 = Vector4.ZERO) -> void:
	if panel.theme_type_variation == &"":
		panel.theme_type_variation = PAPER_LOOK
	tint_art(panel, fill)


## Swap a panel's look for another theme variation (PaperCard, PlanCard...).
static func set_look(panel: Control, variation: StringName) -> void:
	panel.theme_type_variation = variation


## Ink a white piece of art (seal disc, stamp, outline box, icon) or tint
## parchment. self_modulate tints the node's own drawing, not its children.
static func tint_art(node: CanvasItem, ink: Color) -> void:
	node.self_modulate = ink


## Recolour a label's (or button's, or rich text's) text.
static func set_font_color(control: Control, font_color: Color) -> void:
	control.add_theme_color_override("font_color", font_color)
	control.add_theme_color_override("default_color", font_color)


# ============================================================ SCENE HELPERS

## Remove and free every child of a list container before refilling it.
static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## Instance a row scene at the end of `container` and return it
## (call the row's setup(...) right after).
static func add_row(container: Node, row_scene: PackedScene) -> Node:
	var row := row_scene.instantiate()
	container.add_child(row)
	return row
