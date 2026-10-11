## Mobile Ledger — a phone-first UI for the guild game.
##
## UI only: every rule comes from the existing systems. Characters come from
## CharacterContainer / GuildCharacter, quests from CreatedQuest, results from
## CreatedQuest.generateResults (scored with the same helpers DayBar uses),
## days from GameState and upgrades from GuildUpgrades. Nothing in those
## scripts is changed; this scene just presents them differently.
##
## Screens are rebuilt from game state whenever something changes, which keeps
## each screen script short and stateless.
extends Control

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")
const PageHome := preload("res://MobileLedger/Scripts/page_home.gd")
const PageQuests := preload("res://MobileLedger/Scripts/page_quests.gd")
const PageCharacters := preload("res://MobileLedger/Scripts/page_characters.gd")
const PageUpgrades := preload("res://MobileLedger/Scripts/page_upgrades.gd")
const PageSettings := preload("res://MobileLedger/Scripts/page_settings.gd")
const ScreenCharter := preload("res://MobileLedger/Scripts/screen_charter.gd")
const ScreenCodex := preload("res://MobileLedger/Scripts/screen_codex.gd")
const OverlayReport := preload("res://MobileLedger/Scripts/overlay_report.gd")
const OverlayWelcome := preload("res://MobileLedger/Scripts/overlay_welcome.gd")

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10

const TABS := [
	["characters", "Characters", "nav_characters"],
	["quests", "Quests", "nav_quests"],
	["home", "Home", "nav_home"],
	["upgrades", "Upgrades", "nav_upgrades"],
	["settings", "Settings", "nav_settings"],
]

## Which bottom tab is showing, and which half of the Characters tab.
var tab := "home"
var seg := "guild"
## Today's quests: {quest: CreatedQuest, state: "open"|"ready"|"denied", party: Array}
var entries: Array = []
## Full-screen page over the content: {kind: "charter", entry, draft} or {kind: "codex", character}
var page := {}
## Day report being shown: {live: bool, day: int, results: Array}. Empty = hidden.
var report := {}
## Yesterday's results, readable again from Home.
var last_report := {}
var story_open := true
var show_welcome := false

var _stat_labels := {}
var _content_wrap: Control
var _scroll: ScrollContainer
var _content: VBoxContainer
var _page_layer: Control
var _day_bar: PanelContainer
var _nav: PanelContainer
var _overlay: Control
var _toast: PanelContainer
var _dirty := false
var _last_tab := ""


func _ready() -> void:
	theme = S.make_theme()
	_build_shell()
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)
	_generate_quests()
	show_welcome = true
	refresh()


# ================================================================ game actions

## Mirrors QuestList.populate / _generate_quests.
func _generate_quests() -> void:
	entries.clear()
	if GameState.day == MILESTONE_DAY:
		entries.append({"quest": CreatedQuest.new(MILESTONE_DAY), "state": "open", "party": [], "milestone": true})
		return
	for i in QUESTS_PER_DAY:
		entries.append({"quest": CreatedQuest.new(), "state": "open", "party": [], "milestone": false})


func _on_day_started(_day: int) -> void:
	_generate_quests()
	queue_refresh()


## Quests that still need Accept (with a party) or Deny — QuestCard.is_outstanding.
func outstanding() -> int:
	return entries.filter(func(e): return e.state == "open").size()


func ready_entries() -> Array:
	return entries.filter(func(e): return e.state == "ready")


func entry_of(character: GuildCharacter) -> Dictionary:
	for e in entries:
		if e.state == "ready" and e.party.has(character):
			return e
	return {}


func slot_count(entry: Dictionary) -> int:
	return QuestCard.get_slot_count(entry.quest)


## Success chance as the quest computes it (-1 = no party yet).
func chance_for(entry: Dictionary, party: Array) -> int:
	if party.is_empty():
		return -1
	return int(entry.quest.calcSuccessChance(party))


## A character can only sit in one quest's slots (CharacterSlot.assign).
func set_party(entry: Dictionary, party: Array) -> void:
	for e in entries:
		if e == entry:
			continue
		e.party = e.party.filter(func(c): return not party.has(c))
		if e.state == "ready" and e.party.is_empty():
			e.state = "open"
	entry.party = party.duplicate()
	entry.state = "ready" if not party.is_empty() else "open"
	queue_refresh()


func deny(entry: Dictionary) -> void:
	entry.party = []
	entry.state = "denied"
	toast("Denied: %s" % entry.quest.questTitle)
	queue_refresh()


func cancel(entry: Dictionary) -> void:
	entry.party = []
	entry.state = "open"
	queue_refresh()


func hire(character: GuildCharacter) -> void:
	if CharacterContainer.add_character_to_guild(character):
		toast("%s joined the guild!" % character.name)
	queue_refresh()


func upgrade(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		toast("%s upgraded to level %d!" % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the summary.
func end_day() -> void:
	if outstanding() > 0:
		open_tab("quests")
		return
	var results := []
	for e in ready_entries():
		var typed_party: Array[GuildCharacter] = []
		typed_party.assign(e.party)
		var chance: float = DayBarLogic._get_success_chance(e.quest, typed_party)
		var story: String = e.quest.generateResults(typed_party, chance)
		var succeeded: bool = DayBarLogic._did_succeed(story)
		var gold: int = DayBarLogic._get_gold_earned(e.quest, succeeded)
		GameState.add_gold(gold)
		results.append({"quest": e.quest, "party": e.party.duplicate(), "story": story, "succeeded": succeeded, "chance": chance, "gold": gold})
	page = {}
	report = {"live": true, "day": GameState.day, "results": results}
	queue_refresh()


## DaySummary's "New Day" button.
func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = {}
	tab = "quests"
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		toast("Day %d. The Bone Drake is attacking!" % GameState.day)
	else:
		toast("Day %d begins · %d new quests · %d for hire" % [GameState.day, entries.size(), CharacterContainer.hireable_characters.size()])
	queue_refresh()


# ================================================================ navigation

func open_tab(t: String, segment: String = "") -> void:
	tab = t
	if segment != "":
		seg = segment
	page = {}
	queue_refresh()


func open_charter(entry: Dictionary) -> void:
	page = {"kind": "charter", "entry": entry, "draft": entry.party.duplicate()}
	queue_refresh()


func open_codex(character: GuildCharacter) -> void:
	page = {"kind": "codex", "character": character}
	story_open = true
	queue_refresh()


func close_page() -> void:
	page = {}
	queue_refresh()


func open_last_report() -> void:
	if last_report.is_empty():
		return
	report = last_report.duplicate()
	report.live = false
	queue_refresh()


func close_report() -> void:
	if report.get("live", false):
		start_new_day()
	else:
		report = {}
		queue_refresh()


func close_welcome() -> void:
	show_welcome = false
	if CharacterContainer.active_characters.is_empty():
		tab = "characters"
		seg = "hire"
	queue_refresh()


# ================================================================ shell

func _build_shell() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = S.tex("page_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var col := S.vbox(0)
	col.set_anchors_preset(PRESET_FULL_RECT)
	add_child(col)
	col.add_child(_build_header())

	_content_wrap = Control.new()
	_content_wrap.size_flags_vertical = SIZE_EXPAND_FILL
	_content_wrap.clip_contents = true
	col.add_child(_content_wrap)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.set_anchors_preset(PRESET_FULL_RECT)
	_content_wrap.add_child(_scroll)
	_content = S.vbox(26)
	_content.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(S.margin(_content, 24, 26, 24, 40))
	_scroll.get_child(0).size_flags_horizontal = SIZE_EXPAND_FILL
	_page_layer = Control.new()
	_page_layer.set_anchors_preset(PRESET_FULL_RECT)
	_page_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_content_wrap.add_child(_page_layer)

	_day_bar = PanelContainer.new()
	_day_bar.add_theme_stylebox_override("panel", S.sbtex("inset_parchment.png", 26, Vector4(26, 12, 22, 12), 8))
	col.add_child(_day_bar)

	_nav = PanelContainer.new()
	var nsb := S.sbtex("wood_dark.png", 8, Vector4(14, 26, 14, 18))
	nsb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_nav.add_theme_stylebox_override("panel", nsb)
	col.add_child(_nav)

	_overlay = Control.new()
	_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_overlay)


func _build_header() -> Control:
	var head := PanelContainer.new()
	var hsb := S.sbtex("wood_bar.png", 8, Vector4(18, 14, 18, 18))
	head.add_theme_stylebox_override("panel", hsb)
	var v := S.vbox(10)
	head.add_child(v)

	var banner_row := Control.new()
	banner_row.custom_minimum_size = Vector2(0, 104)
	v.add_child(banner_row)
	for side in [0, 1]:
		var sp := TextureRect.new()
		sp.texture = S.tex("sprig_l.png" if side == 0 else "sprig_r.png")
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		sp.mouse_filter = MOUSE_FILTER_IGNORE
		sp.anchor_left = 0.0 if side == 0 else 1.0
		sp.anchor_right = sp.anchor_left
		sp.offset_left = -8.0 if side == 0 else -150.0
		sp.offset_right = sp.offset_left + 158.0
		sp.offset_top = -8
		sp.offset_bottom = 104
		banner_row.add_child(sp)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	banner_row.add_child(center)
	var banner := PanelContainer.new()
	var bsb := StyleBoxTexture.new()
	bsb.texture = S.tex("banner.png")
	bsb.texture_margin_left = 70
	bsb.texture_margin_right = 70
	bsb.texture_margin_top = 30
	bsb.texture_margin_bottom = 36
	bsb.content_margin_left = 84
	bsb.content_margin_right = 84
	bsb.content_margin_top = 12
	bsb.content_margin_bottom = 22
	banner.add_theme_stylebox_override("panel", bsb)
	banner.custom_minimum_size = Vector2(0, 104)
	var t := S.title("Guild Ledger", 50)
	t.add_theme_font_override("font", S.display_black)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_child(t)
	center.add_child(banner)

	var strip := S.panel("panel", Vector4(16, 10, 16, 12))
	var h := S.hbox(0)
	strip.add_child(h)
	var cells := [["sun", "day", "Day"], ["coins", "gold", "Gold"], ["rook", "standing", "Standing"]]
	for i in cells.size():
		var c: Array = cells[i]
		if i > 0:
			var line := ColorRect.new()
			line.color = S.LINE
			line.custom_minimum_size = Vector2(2, 0)
			h.add_child(line)
		var cell := S.hbox(12)
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		cell.add_child(S.icon(c[0], 62))
		var cv := S.vbox(-6)
		var num := S.title("0", 38)
		num.add_theme_font_override("font", S.display_black)
		cv.add_child(num)
		cv.add_child(S.label(c[2], 23, S.INK_SOFT, S.body_bold))
		cell.add_child(cv)
		h.add_child(cell)
		_stat_labels[c[1]] = num
	v.add_child(strip)
	return head


# ================================================================ refresh

func queue_refresh() -> void:
	if _dirty:
		return
	_dirty = true
	refresh.call_deferred()


func refresh() -> void:
	_dirty = false
	_stat_labels.day.text = str(GameState.day)
	_stat_labels.gold.text = str(GameState.gold)
	_stat_labels.standing.text = str(GameState.standing)

	var keep_scroll := _last_tab == tab
	var scroll_y := _scroll.scroll_vertical
	S.clear(_content)
	match tab:
		"home":
			_content.add_child(PageHome.build(self))
		"quests":
			_content.add_child(PageQuests.build(self))
		"characters":
			_content.add_child(PageCharacters.build(self))
		"upgrades":
			_content.add_child(PageUpgrades.build(self))
		"settings":
			_content.add_child(PageSettings.build(self))
	if keep_scroll:
		_restore_scroll.call_deferred(scroll_y)
	else:
		_scroll.scroll_vertical = 0
	_last_tab = tab

	var prev_kind := ""
	var prev_y := 0
	if _page_layer.get_child_count() > 0:
		prev_kind = _page_layer.get_child(0).get_meta("kind", "")
		var old := _page_layer.get_child(0).find_child("PageScroll", true, false) as ScrollContainer
		if old:
			prev_y = old.scroll_vertical
	S.clear(_page_layer)
	_page_layer.mouse_filter = MOUSE_FILTER_IGNORE
	if page.get("kind", "") == "charter" and entries.has(page.entry) and page.entry.state != "denied":
		_page_layer.add_child(ScreenCharter.build(self))
		_page_layer.mouse_filter = MOUSE_FILTER_STOP
	elif page.get("kind", "") == "codex":
		_page_layer.add_child(ScreenCodex.build(self))
		_page_layer.mouse_filter = MOUSE_FILTER_STOP
	else:
		page = {}
	if _page_layer.get_child_count() > 0:
		var cur := _page_layer.get_child(0)
		cur.set_meta("kind", page.kind)
		if prev_kind == page.kind:
			var sc := cur.find_child("PageScroll", true, false) as ScrollContainer
			if sc:
				_restore_page_scroll.call_deferred(sc, prev_y)

	_build_day_bar()
	_build_nav()

	S.clear(_overlay)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	if not report.is_empty():
		_overlay.add_child(OverlayReport.build(self))
		_overlay.mouse_filter = MOUSE_FILTER_STOP
	elif show_welcome:
		_overlay.add_child(OverlayWelcome.build(self))
		_overlay.mouse_filter = MOUSE_FILTER_STOP


func _restore_page_scroll(sc: ScrollContainer, y: int) -> void:
	if is_instance_valid(sc):
		sc.scroll_vertical = y


func _restore_scroll(y: int) -> void:
	_scroll.scroll_vertical = y


func _build_day_bar() -> void:
	S.clear(_day_bar)
	_day_bar.visible = page.is_empty()
	var h := S.hbox(16)
	_day_bar.add_child(h)
	var v := S.vbox(-2)
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	v.size_flags_vertical = SIZE_SHRINK_CENTER
	var out := outstanding()
	var ready := ready_entries().size()
	var b: Button
	if out > 0:
		v.add_child(S.title("%d quest%s undecided" % [out, "" if out == 1 else "s"], 28))
		v.add_child(S.label("Accept with a party or deny each one", 24, S.INK_SOFT))
		b = S.button("Review", "blue", 28, 84)
		b.pressed.connect(open_tab.bind("quests"))
	else:
		v.add_child(S.title("Ready to end Day %d" % GameState.day, 28))
		v.add_child(S.label("%d part%s set out tonight" % [ready, "y" if ready == 1 else "ies"] if ready > 0 else "No parties going out today", 24, S.INK_SOFT))
		b = S.button("End Day", "green", 30, 84)
		b.pressed.connect(end_day)
	b.custom_minimum_size.x = 200
	b.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(v)
	h.add_child(b)


func _build_nav() -> void:
	S.clear(_nav)
	var h := S.hbox(10)
	_nav.add_child(h)
	var current := tab
	if page.get("kind", "") == "charter":
		current = "quests"
	elif page.get("kind", "") == "codex":
		current = "characters"
	for t in TABS:
		var active: bool = t[0] == current
		var b := Button.new()
		b.focus_mode = FOCUS_NONE
		b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 124)
		b.text = t[1]
		b.icon = S.icon_tex(t[2])
		b.expand_icon = false
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 52)
		b.add_theme_constant_override("h_separation", 2)
		b.add_theme_font_override("font", S.body_bold)
		b.add_theme_font_size_override("font_size", 21)
		for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(s, S.INK)
		var sb := S.sbtex("tab_tile_active.png" if active else "tab_tile.png", 22, Vector4(4, 16, 4, 12), 4)
		for s in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(open_tab.bind(t[0]))
		if active:
			var rib := TextureRect.new()
			rib.texture = S.tex("ribbon.png")
			rib.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rib.stretch_mode = TextureRect.STRETCH_SCALE
			rib.anchor_left = 0.5
			rib.anchor_right = 0.5
			rib.offset_left = -15
			rib.offset_right = 15
			rib.offset_top = -30
			rib.offset_bottom = 14
			rib.show_behind_parent = true
			rib.mouse_filter = MOUSE_FILTER_IGNORE
			b.add_child(rib)
		var badge := ""
		if t[0] == "quests" and outstanding() > 0:
			badge = str(outstanding())
		if t[0] == "characters" and CharacterContainer.active_characters.is_empty():
			badge = "!"
		if badge != "":
			var bp := PanelContainer.new()
			bp.add_theme_stylebox_override("panel", S.flat(S.WAX, 16, 3, S.INK, Vector4(9, 0, 9, 2)))
			var bl := S.label(badge, 22, S.WHITE, S.body_bold)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bp.add_child(bl)
			bp.anchor_left = 1.0
			bp.anchor_right = 1.0
			bp.offset_left = -34
			bp.offset_top = -14
			bp.grow_horizontal = GROW_DIRECTION_BOTH
			bp.mouse_filter = MOUSE_FILTER_IGNORE
			b.add_child(bp)
		h.add_child(b)


# ================================================================ toast

func toast(text: String) -> void:
	if _toast and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", S.flat(Color("#2E2012"), 16, 3, S.GOLD, Vector4(24, 14, 24, 16)))
	var l := S.wrap(S.label(text, 26, Color("#F6E2B0"), S.body_bold))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(l)
	_toast.mouse_filter = MOUSE_FILTER_IGNORE
	_toast.set_anchors_preset(PRESET_TOP_WIDE)
	_toast.offset_left = 40
	_toast.offset_right = -40
	_toast.offset_top = 16
	_content_wrap.add_child(_toast)
	var tw := create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_toast.queue_free)
