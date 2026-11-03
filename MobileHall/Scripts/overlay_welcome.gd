## How to Play: a topic menu. The first topic, Basics, is the welcome card's
## own rows (the text lives in the scene); the other topics are built here
## from TOPICS. Tapping a topic opens its page; Back returns to the list.
## On a fresh run with the tutorial off it opens straight on Basics.
## Scene: MobileHall/Scenes/Overlays/overlay_welcome.tscn
extends Control


# ---- TEXT
const TITLE_MENU := "How to Play"
const TITLE_BASICS := "The Basics"
const BUTTON_BACK := "Back"
const BUTTON_CLOSE := "Close"
## Share of the screen height a page may fill before it scrolls.
const MAX_PAGE_HEIGHT := 0.62

const ICONS := "res://MobileHall/Art/Icons/%s.svg"

## Topics after Basics. Each row: [icon file, heading, body].
const TOPICS := [
	{"title": "Quests & Odds", "icon": "scroll", "rows": [
		["scroll", "Reading a quest", "Each card shows its rank, gold, party size and the stat it favours."],
		["target", "Odds", "Heroes strong in the favoured stat add the most chance. Low odds risk failure and injuries."],
		["check", "Send or Deny", "Send seals the party; they leave tonight. Deny skips the quest but costs standing. Reconsider brings it back the same day."],
		["diamond", "Ranks", "Quests run from F up to S. Higher standing brings higher ranks and bigger pay."],
	]},
	{"title": "Heroes & Stats", "icon": "person", "rows": [
		["swords", "Stats", "Power, Defense, Wisdom and Sleaziness. Every quest favours one."],
		["heart", "Pluck", "Grows with every win, more for winning at long odds, and boosts all other stats."],
		["bed", "Injuries", "Hurt heroes heal over a few nights at home, faster in the Hospital."],
		["x", "Letting go", "Releasing a living hero costs standing, more for veterans. Releasing the fallen is free."],
	]},
	{"title": "Guild Buildings", "icon": "hammer", "rows": [
		["hammer", "Upgrading", "Each building has five levels. Upgrades cost gold and need enough standing."],
		["swords", "Training Yard", "A hero stays home and drills one stat overnight."],
		["bed", "Hospital", "Hurt heroes heal faster in a bed. At max level it can revive one fallen hero per run."],
		["shield", "Armory", "Bonus Power and Defense for every hero."],
		["person", "Barracks", "Room for more heroes."],
		["cross", "Busy heroes", "Heroes training or in a bed can't go on quests."],
	]},
	{"title": "Shop & Gear", "icon": "stall", "rows": [
		["stall", "The Shop", "Opens on Day 5. New stock every morning; unbought items are gone."],
		["chest", "Role-locked", "Each item fits one role. Tap an item to see what it does and who can use it."],
		["gear", "Equipping", "Open a hero's page and tap Equip on an empty gear slot."],
	]},
	{"title": "Gold & Standing", "icon": "coins", "rows": [
		["coins", "Gold", "Earned on quests. Spent on recruits, buildings and gear. Hiring is free on Days 1 and 2."],
		["diamond", "Standing", "Wins raise it. Failing and denying lower it. More standing, better quests."],
		["skull", "Too low", "If standing sinks too far, recruits stop coming."],
	]},
	{"title": "The Story", "icon": "skull", "rows": [
		["skull", "The Bone Drake", "Attacks on Day 10. The header counts down."],
		["swords", "The final battle", "Waits on Day 50."],
		["diamond", "Freeplay", "Win it and the days go on, with harder quests up to S++."],
		["skull", "The guild falls", "If every hero is lost and you can't afford a recruit, the run ends."],
	]},
]

# ---- NODES
@onready var _start_button: Button = %StartButton
@onready var _col: VBoxContainer = $Center/Sheet/Col
@onready var _title: Label = $Center/Sheet/Col/Title

## The main hall script (state + actions), set in setup().
var hall: HallMain
var _scroll: ScrollContainer
var _body: VBoxContainer
var _menu_list: VBoxContainer
## The scene's own rows (intro + steps), moved into one page.
var _basics: VBoxContainer
## Built pages, one per TOPICS entry.
var _pages: Array[VBoxContainer] = []
var _back_button: Button
## -1 = topic list, 0 = Basics, 1+ = TOPICS[n - 1].
var _open := -1
## Opened with no menu behind it (the fresh-run welcome): Start, no Back.
var _is_welcome := true


func setup(main: HallMain) -> void:
	hall = main
	_start_button.pressed.connect(_on_close)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_col.add_child(_scroll)
	_col.move_child(_scroll, _title.get_index() + 1)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body)

	_basics = _new_page()
	for child in _col.get_children():
		if child != _title and child != _scroll and child != _start_button:
			child.reparent(_basics, false)

	_menu_list = VBoxContainer.new()
	_menu_list.add_theme_constant_override("separation", 12)
	_body.add_child(_menu_list)
	_add_topic_button(TITLE_BASICS, 0)
	for index in TOPICS.size():
		var topic: Dictionary = TOPICS[index]
		_add_topic_button(topic.title, index + 1)
		var page := _new_page()
		for row in topic.rows:
			page.add_child(_build_row(row[0], row[1], row[2]))
		_pages.append(page)

	# Back sits beside Start / Close
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	_col.add_child(foot)
	_back_button = Button.new()
	_back_button.text = BUTTON_BACK
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.custom_minimum_size = Vector2(200, _start_button.custom_minimum_size.y)
	_back_button.pressed.connect(func(): _show(-1))
	HallStyle.style_button(_back_button, "wood", 32)
	foot.add_child(_back_button)
	_start_button.reparent(foot, false)
	_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HallStyle.style_button(_start_button, "green", 32)

	visibility_changed.connect(_on_shown)
	_on_shown()


## Nothing changes while it's open; hall_main calls this on every overlay.
func refresh() -> void:
	pass


## Every time it opens: from the Menu, start at the topic list; as the
## fresh-run welcome (nothing ended yet), start on Basics.
func _on_shown() -> void:
	if not visible or hall == null:
		return
	_is_welcome = not hall.is_welcome_from_menu
	_show(0 if _is_welcome else -1)


func _show(index: int) -> void:
	_open = index
	_menu_list.visible = index == -1
	_basics.visible = index == 0
	for page_index in _pages.size():
		_pages[page_index].visible = index == page_index + 1
	if index == -1:
		_title.text = TITLE_MENU
	elif index == 0:
		_title.text = TITLE_BASICS if not _is_welcome else "Welcome, Guildmaster"
	else:
		_title.text = TOPICS[index - 1].title
	_back_button.visible = index != -1
	_start_button.text = "Start" if _is_welcome else BUTTON_CLOSE
	_scroll.scroll_vertical = 0
	_fit_scroll.call_deferred()


## The page scrolls once it's taller than MAX_PAGE_HEIGHT of the screen.
func _fit_scroll() -> void:
	var wanted: float = _body.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = minf(wanted, get_viewport_rect().size.y * MAX_PAGE_HEIGHT)


func _on_close() -> void:
	hall.close_welcome()


func _new_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(page)
	return page


func _add_topic_button(text: String, index: int) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 76)
	button.pressed.connect(_show.bind(index))
	HallStyle.style_button(button, "paper", 28)
	_menu_list.add_child(button)


## Same look as the scene's Basics rows: icon, title, italic body.
func _build_row(icon: String, heading: String, body: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var art := TextureRect.new()
	art.texture = load(ICONS % icon)
	art.modulate = HallStyle.TEXT_MAIN
	art.custom_minimum_size = Vector2(44, 44)
	art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(art)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var name_label := Label.new()
	name_label.theme_type_variation = &"TitleLabel"
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.text = heading
	text.add_child(name_label)
	var body_label := Label.new()
	body_label.theme_type_variation = &"ItalicLabel"
	body_label.add_theme_font_size_override("font_size", 21)
	body_label.custom_minimum_size.x = 40
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = body
	text.add_child(body_label)
	return row
