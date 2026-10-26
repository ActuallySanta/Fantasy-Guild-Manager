## Shared look and helpers for the Mobile Hall UI.
##
## Every other MobileHall script preloads this file as `Style` and calls its
## static helpers (Style.flat_box(...), Style.QUEST_STATE_SENT, ...).
## Nothing here holds state except the icon texture cache.
##
## The look: generic primitives. Flat boxes, Godot's default font, and colour
## only where it means something (each stat has its own colour, green = good /
## sent, red = bad / denied, blue = info / to do, yellow = gold). The only art is
## the project's own Sprites/Character Icons and Sprites/UI Icons.
##
## Where things live:
##   - Layout: every screen, row and widget is a .tscn under MobileHall/Scenes.
##   - Boxes:  shared panel / button looks are .tres files in MobileHall/Styles.
##   - This file: the palette, display tables, text helpers, game lookups and
##     the restyles that change with game state (button kind, chip colour).
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

# ---- text
const TEXT_MAIN := Color("#222222")       ## main text, outlines
const TEXT_SOFT := Color("#666666")       ## secondary text, hints

# ---- backgrounds and borders
const CARD_BG := Color("#FFFFFF")         ## default card / row background
const NEUTRAL_BG := Color("#E6E6E6")      ## neutral chip / inset background
const BORDER := Color("#BBBBBB")          ## default card border
const BAR_BG := Color("#3B3F45")          ## header / nav background (set in the scene)
const WHITE := Color("#FFFFFF")
const BADGE_RED := Color("#C8302F")       ## nav badge dot (set in the scene)

# ---- card backgrounds for quest / upgrade state
const SENT_CARD_BG := Color("#E8F5E9")    ## sent quest, picked adventurer, affordable upgrade
const DENIED_CARD_BG := Color("#EEEEEE")  ## denied quest, adventurer who can't go
const EMPTY_SEAT_BG := Color("#F5F5F5")   ## empty party seat

# ---- meaning colours: [strong colour, text colour, light background]
const RED := Color("#A3262A")             ## deny, failed, warnings
const RED_BG := Color("#F2CBC3")
const GOLD := Color("#E0B23A")
const GOLD_TEXT := Color("#7A5A12")
const GOLD_BG := Color("#F4E5AC")
const GREEN := Color("#3F7A2E")           ## success, sent, done
const GREEN_TEXT := Color("#2F6A22")
const GREEN_BG := Color("#D9E8CF")
const BLUE_TEXT := Color("#2F5F8A")       ## info, to do, picked
const BLUE_BG := Color("#D3E1EE")


# ============================================================ DISPLAY TABLES

# ---- quest types

## Key used for the milestone (Bone Drake) quest; it isn't a CreatedQuest.QuestType.
const MILESTONE_TYPE_ID := 5

## CreatedQuest.QuestType (plus MILESTONE_TYPE_ID) -> display name, colour, short tag.
const QUEST_TYPES := {
	1: {"name": "Clear Dungeon", "color": Color("#2E7D32"), "tag": "DUN"},
	2: {"name": "Escort", "color": Color("#B26A00"), "tag": "ESC"},
	3: {"name": "Scout Terrain", "color": Color("#1E63A8"), "tag": "SCT"},
	4: {"name": "Gather Intel", "color": Color("#6A3FA0"), "tag": "INT"},
	MILESTONE_TYPE_ID: {"name": "Milestone", "color": Color("#B3261E"), "tag": "BOSS"},
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
## name = full name, short = chip label, color = text / outline, bg = chip fill.
const STATS := [
	{"name": "Power", "short": "Pow", "color": Color("#A3262A"), "bg": Color("#F2D5CB")},
	{"name": "Defense", "short": "Def", "color": Color("#2F5F8A"), "bg": Color("#D3E1EE")},
	{"name": "Wisdom", "short": "Wis", "color": Color("#5B3F8C"), "bg": Color("#E2D9EF")},
	{"name": "Sleaziness", "short": "Slz", "color": Color("#3E6B35"), "bg": Color("#D9E8CF")},
	{"name": "Pluck", "short": "Plk", "color": Color("#94500F"), "bg": Color("#F5DCC0")},
]

# ---- health

## GuildCharacter.InjuryLevel -> label and chip colours.
const INJURY_LOOKS := [
	{"label": "Healthy", "bg": Color("#D9E8CF"), "text": Color("#2F5A27")},
	{"label": "Sore", "bg": Color("#F4E5AC"), "text": Color("#6E5410")},
	{"label": "Hurt", "bg": Color("#F6D7B2"), "text": Color("#8A4A10")},
	{"label": "Gravely hurt", "bg": Color("#F2CBC3"), "text": Color("#8A1E22")},
	{"label": "Dead", "bg": Color("#DDD3E0"), "text": Color("#4A3B4F")},
]

# ---- portraits

## Portrait background colour per GuildCharacter.CharacterRole.
const ROLE_PORTRAIT_BGS := [Color("#D5DEE6"), Color("#E8E2D4"), Color("#D6E4CC"), Color("#E2D9EC")]

# ---- success odds

## Success chance bands, checked top to bottom: the first band whose `min`
## the chance reaches is used. word = label, text_color = numbers and words,
## bar_color = a softer fill for bars.
const ODDS_BANDS := [
	{"min": 80, "word": "Strong odds", "text_color": GREEN_TEXT, "bar_color": Color("#5DBB8E")},
	{"min": 60, "word": "Fair odds", "text_color": Color("#6E5410"), "bar_color": GOLD},
	{"min": 40, "word": "Risky", "text_color": Color("#8A4A10"), "bar_color": Color("#E09A4F")},
	{"min": 0, "word": "Long shot", "text_color": Color("#8A1E22"), "bar_color": Color("#C9574F")},
]
## Shown when a quest has nobody in its party yet (chance = -1).
const ODDS_NO_PARTY := {"min": -1, "word": "No party yet", "text_color": TEXT_SOFT, "bar_color": BORDER}

# ---- buildings

## GuildUpgrades.Building -> short tag shown in the building's colour box.
const BUILDING_TAGS := {0: "OFF", 1: "TRN", 2: "HSP", 3: "ARM", 4: "BRK"}

# ---- items

## StandardItem.Rarity name -> short tag and colour (shop tiles, gear rows).
const ITEM_RARITY_LOOKS := {
	"COMMON": {"tag": "COM", "color": Color("#7D7D7D")},
	"UNCOMMON": {"tag": "UNC", "color": Color("#3F7A2E")},
	"RARE": {"tag": "RAR", "color": Color("#2F5F8A")},
	"LEGENDARY": {"tag": "LEG", "color": Color("#5B3F8C")},
	"MYTHIC": {"tag": "MYT", "color": Color("#B8862B")},
	"NAMED": {"tag": "NAM", "color": Color("#A3262A")},
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


# ============================================================ GAME LOOKUPS

# ---- quests

## Key into QUEST_TYPES for a quest entry (the milestone gets its own key).
static func quest_type_id(entry: Dictionary) -> int:
	return MILESTONE_TYPE_ID if entry.get("milestone", false) else int(entry.quest.type)


## {name, color, tag} for a quest entry's type (falls back to Clear Dungeon).
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


## A character's value for STATS[stat_index] (Pluck is stored separately).
static func stat_value(character: GuildCharacter, stat_index: int) -> int:
	return character.pluck if stat_index == PLUCK_INDEX else int(character.stats[stat_index])


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

const UI_ICON_FOLDER := "res://Sprites/UI Icons/"

## Icon names used by the screens -> file in UI_ICON_FOLDER. Names not listed
## here (e.g. "check", "heart") have no icon yet, so their icon is hidden.
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

## Loaded icon textures by path, so each file is only loaded once.
static var _icon_cache := {}


## The project UI icon for a name in ICON_FILES, or null if it has none.
static func icon_texture(icon_name: String) -> Texture2D:
	if not ICON_FILES.has(icon_name):
		return null
	var path: String = UI_ICON_FOLDER + ICON_FILES[icon_name]
	if not _icon_cache.has(path):
		_icon_cache[path] = load(path)
	return _icon_cache[path]


# ============================================================ STYLE BOXES

## A flat rounded box. padding = content margins (left, top, right, bottom).
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

## Button colours per kind.
const BUTTON_KINDS := {
	"green": {"fill": Color("#43A047"), "pressed_fill": Color("#2E7D32"), "text": Color.WHITE},
	"red": {"fill": Color("#E53935"), "pressed_fill": Color("#B71C1C"), "text": Color.WHITE},
	"blue": {"fill": Color("#1E88E5"), "pressed_fill": Color("#1565C0"), "text": Color.WHITE},
	"wood": {"fill": Color("#3B3F45"), "pressed_fill": Color("#24272B"), "text": Color.WHITE},
	"paper": {"fill": Color("#EEEEEE"), "pressed_fill": Color("#D5D5D5"), "text": Color("#222222")},
}
const BUTTON_PADDING := Vector4(18, 8, 18, 8)
const BUTTON_CORNER_RADIUS := 10
const BUTTON_DISABLED_FILL := Color("#D0D0D0")
const BUTTON_DISABLED_BORDER := Color("#C4C4C4")
const BUTTON_DISABLED_TEXT := Color("#888888")

## Every Button state that should share one box / one font colour.
const BUTTON_BOX_STATES := ["normal", "hover", "pressed", "hover_pressed"]
const BUTTON_FONT_STATES := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]


## Flat button. kind: green | red | blue | wood (dark) | paper (light grey).
static func style_button(button: Button, kind: String = "green", font_size: int = 28) -> void:
	var colors: Dictionary = BUTTON_KINDS.get(kind, BUTTON_KINDS.paper)
	var border_color: Color = BORDER if kind == "paper" else colors.pressed_fill
	var normal_box := flat_box(colors.fill, BUTTON_CORNER_RADIUS, 2, border_color, BUTTON_PADDING)
	var pressed_box := flat_box(colors.pressed_fill, BUTTON_CORNER_RADIUS, 2, border_color, BUTTON_PADDING)
	var disabled_box := flat_box(BUTTON_DISABLED_FILL, BUTTON_CORNER_RADIUS, 2, BUTTON_DISABLED_BORDER, BUTTON_PADDING)

	# boxes: hover looks like normal (touch screens have no hover)
	button.add_theme_stylebox_override("normal", normal_box)
	button.add_theme_stylebox_override("hover", normal_box)
	button.add_theme_stylebox_override("pressed", pressed_box)
	button.add_theme_stylebox_override("hover_pressed", pressed_box)
	button.add_theme_stylebox_override("disabled", disabled_box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# text
	button.add_theme_font_size_override("font_size", font_size)
	for font_state in BUTTON_FONT_STATES:
		button.add_theme_color_override(font_state, colors.text)
	button.add_theme_color_override("font_disabled_color", BUTTON_DISABLED_TEXT)


## Small coloured box with a short white tag (quest type, building).
static func style_tag(tag_panel: Control, tag_label: Label, text: String, fill: Color) -> void:
	tag_panel.add_theme_stylebox_override("panel", flat_box(fill, 10, 0, fill, Vector4(6, 6, 6, 6)))
	tag_label.text = text
	set_font_color(tag_label, WHITE)


## Recolour a panel with a flat rounded box (state colours on cards and tabs).
static func style_panel(panel: Control, fill: Color, border_color: Color, border_width: int = 3, corner_radius: int = 14, padding: Vector4 = Vector4(14, 10, 14, 10)) -> void:
	panel.add_theme_stylebox_override("panel", flat_box(fill, corner_radius, border_width, border_color, padding))


## Recolour a label's (or button's) text.
static func set_font_color(control: Control, font_color: Color) -> void:
	control.add_theme_color_override("font_color", font_color)


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
