## The text sections of a film-style crawl, shared by the final credits
## (overlay_credits.gd) and the boss fights' crawl (overlay_boss_crawl.gd):
## a title with a subtitle, then one block per fight. A block is a heading,
## the quest's story one centred line at a time, the party (skull or
## "survived" under each hero), and an optional won / lost line.
##
## It only builds the text. The overlay owns the ScrollContainer, the blank
## space, the button and the motion (CrawlRoll). The roll's other sections
## (the credits ledger, team and closing line) sit beside this node in the
## overlay's own roll.
##
## Usage: show_title() once, then add_fight() per fight (clear() empties the
## fights first when the overlay is reused).
## Scene: Scenes/Components/crawl_sections.tscn
class_name CrawlSections
extends VBoxContainer

# ---- LOOK
## Font sizes (design px; HallFontScale grows them): story lines, party names,
## the "fell / survived" line, section headings, the won / lost line.
const STORY_FONT_SIZE := 30
const PARTY_FONT_SIZE := 32
const NOTE_FONT_SIZE := 26
const HEADING_FONT_SIZE := 28
const OUTCOME_FONT_SIZE := 48
## Blank space above each fight's heading and above its party (pixels).
const GAP_SIZE := 60.0
## Space between a fight's story lines, and between its party lines (pixels).
const STORY_SEPARATION := 26
const PARTY_SEPARATION := 6
## The skull beside a fallen party member (pixels).
const PARTY_ICON_SIZE := 34.0

# ---- TEXT
const TEXT_PARTY_LINE := "%s · %s"
## Under a fallen hero when the caller doesn't word it (the final says its own).
const TEXT_FELL := "fell in battle"
const TEXT_SURVIVED := "survived"
const TEXT_NOBODY_WENT := "Nobody answered the call."

# ---- NODES
@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _fights: VBoxContainer = %Fights


## Title and subtitle in `ink` / `ink_soft`. An empty subtitle hides that line.
func show_title(title: String, subtitle: String, ink: Color, ink_soft: Color) -> void:
	_title.text = title
	_sub.text = subtitle
	_sub.visible = not subtitle.is_empty()
	HallStyle.set_font_color(_title, ink)
	HallStyle.set_font_color(_sub, ink_soft)


## Empties every fight (the title stays).
func clear() -> void:
	HallStyle.clear_children(_fights)


## Appends one fight: heading, story lines, party, then the won / lost line.
## heading: the small caps heading above the story ("" for none).
## story: the quest's BBCode story; each line becomes one beat.
## result: the quest's result (see HallRules.play_quest): its party and died.
## won: picks won_line or lost_line.
## ink / ink_soft: the fight's text colours (a won and a lost fight differ).
## party_heading: heading above the party ("" for none).
## fell_text: the line under a fallen hero.
## won_line / lost_line: the closing line for a win or a loss ("" for none).
func add_fight(heading: String, story: String, result: Dictionary, won: bool, ink: Color, ink_soft: Color,
		party_heading: String = "", fell_text: String = TEXT_FELL, won_line: String = "",
		lost_line: String = "") -> void:
	_fights.add_child(_make_gap())
	if not heading.is_empty():
		_fights.add_child(_make_heading(heading, ink_soft))
	_fights.add_child(_make_story(story, ink))
	_fights.add_child(_make_gap())
	if not party_heading.is_empty():
		_fights.add_child(_make_heading(party_heading, ink_soft))
	_fights.add_child(_make_party(result, ink, ink_soft, fell_text))
	var outcome_line := won_line if won else lost_line
	if not outcome_line.is_empty():
		_fights.add_child(_make_gap())
		_fights.add_child(make_line(outcome_line, ink, OUTCOME_FONT_SIZE, &"HeadingLight"))


## A centred, wrapping label in `ink`. look = a hall_theme.tres label variation.
static func make_line(text: String, ink: Color, font_size: int, look: StringName = &"LabelLight") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = look
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 40
	HallFontScale.set_size(label, "font_size", font_size)
	HallStyle.set_font_color(label, ink)
	return label


func _make_gap() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.y = GAP_SIZE
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


func _make_heading(text: String, ink_soft: Color) -> Label:
	var heading := make_line(text, ink_soft, HEADING_FONT_SIZE, &"CapsLight")
	heading.uppercase = true
	return heading


## The story, one centred line per beat. Its colours are the bright ones meant
## for dark backgrounds, so they're used as they are.
func _make_story(story: String, ink: Color) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", STORY_SEPARATION)
	for line in story.split("\n"):
		var beat := line.strip_edges()
		if beat.is_empty():
			continue
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		HallFontScale.set_size(label, "normal_font_size", STORY_FONT_SIZE)
		HallFontScale.set_size(label, "bold_font_size", STORY_FONT_SIZE)
		HallStyle.set_font_color(label, ink)
		label.text = "[center]%s[/center]" % beat
		column.add_child(label)
	return column


## Everyone who went: name and role, then whether they fell (with a skull) or survived.
func _make_party(result: Dictionary, ink: Color, ink_soft: Color, fell_text: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", PARTY_SEPARATION)
	var died: Array = result.get("died", [])
	if result.party.is_empty():
		column.add_child(make_line(TEXT_NOBODY_WENT, ink_soft, PARTY_FONT_SIZE))
	for character in result.party:
		var has_fallen := died.has(character) or HallStyle.is_dead(character)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		if has_fallen:
			var skull := TextureRect.new()
			skull.texture = HallStyle.icon_texture("skull")
			skull.custom_minimum_size = Vector2(PARTY_ICON_SIZE, PARTY_ICON_SIZE)
			skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			HallStyle.tint_art(skull, ink_soft)
			row.add_child(skull)
		var name_text := TEXT_PARTY_LINE % [character.name, HallStyle.role_name(character)]
		var name_label := make_line(name_text, ink, PARTY_FONT_SIZE)
		# beside the skull the name sizes itself (a wrapping label would shrink to nothing)
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(name_label)
		column.add_child(row)
		column.add_child(make_line(fell_text if has_fallen else TEXT_SURVIVED, ink_soft, NOTE_FONT_SIZE, &"ItalicLight"))
	return column
