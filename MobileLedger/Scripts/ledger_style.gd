## Style kit for the Mobile Ledger UI: deliberately plain. Flat grey boxes,
## 1px borders, Godot's default font, no colour. Only art used is the project's
## own Sprites/Character Icons (portraits) and Sprites/UI Icons.
class_name LedgerStyle
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

const INK := Color("#111111")
const INK_SOFT := Color("#555555")
const PARCH := Color("#FFFFFF")
const CREAM := Color("#FFFFFF")
const LINE := Color("#999999")
const WHITE := Color("#FFFFFF")
const BG := Color("#E6E6E6")
const BOX := Color("#FFFFFF")
const BOX_ALT := Color("#F2F2F2")
const BTN := Color("#DDDDDD")

## Colour is used only to mean something:
## green = good / go, red = bad / danger, yellow = gold, blue = info / in progress.
const GOOD := Color("#2E7D32")
const GOOD_BG := Color("#C8E6C9")
const BAD := Color("#C62828")
const BAD_BG := Color("#FFCDD2")
const WARN := Color("#E65100")
const WARN_BG := Color("#FFE0B2")
const GOLD := Color("#9A7400")
const GOLD_BG := Color("#FFF3C4")
const INFO := Color("#1565C0")
const INFO_BG := Color("#BBDEFB")
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
	{"name": "Strength", "short": "Str", "icon": "", "color": Color("#C62828"), "bg": Color("#FFEBEE")},
	{"name": "Defense", "short": "Def", "icon": "", "color": Color("#1565C0"), "bg": Color("#E3F2FD")},
	{"name": "Wisdom", "short": "Wis", "icon": "", "color": Color("#6A1B9A"), "bg": Color("#F3E5F5")},
	{"name": "Sleaziness", "short": "Slz", "icon": "", "color": Color("#2E7D32"), "bg": Color("#E8F5E9")},
	{"name": "Pluck", "short": "Plk", "icon": "", "color": Color("#E65100"), "bg": Color("#FFF3E0")},
]

## GuildCharacter.InjuryLevel → label, background, text colour (green → red → grey).
const INJURY := [
	["Healthy", GOOD_BG, GOOD],
	["Sore", GOLD_BG, GOLD],
	["Lightly Injured", WARN_BG, WARN],
	["Gravely Injured", BAD_BG, BAD],
	["Dead", Color("#CCCCCC"), Color("#333333")],
]

## Button kinds → fill colour. Anything else is plain grey.
const BUTTON_FILLS := {
	"green": Color("#A5D6A7"), "red": Color("#EF9A9A"), "blue": Color("#90CAF9"),
}

## All fonts are Godot's built-in default font.
static var display_font: Font
static var display_black: Font
static var body_font: Font
static var body_bold: Font
static var body_italic: Font
static var _cache := {}


static func init_fonts() -> void:
	if body_font:
		return
	body_font = ThemeDB.fallback_font
	display_font = body_font
	display_black = body_font
	body_bold = body_font
	body_italic = body_font


static func make_theme() -> Theme:
	init_fonts()
	var t := Theme.new()
	t.default_font_size = 26
	t.set_color("font_color", "Label", INK)
	var grab := flat(Color("#AAAAAA"), 0, 0, INK, Vector4(4, 0, 4, 0))
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("scroll", "VScrollBar", flat(BG, 0, 0, INK, Vector4(4, 0, 4, 0)))
	return t


# ---------------------------------------------------------------- resources

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
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(1 if border > 0 else 0)
	sb.border_color = border_color
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


## Plain bordered box. kind: "panel" | "card" | "ready" | "inset" | "bar".
static func box(kind: String = "panel", pad: Vector4 = Vector4(16, 12, 16, 12)) -> StyleBoxFlat:
	var fill := BOX
	if kind == "inset" or kind == "bar":
		fill = BOX_ALT
	var border := 2 if kind == "ready" else 1
	var sb := flat(fill, 0, 1, INK if kind == "ready" else LINE, pad)
	sb.set_border_width_all(border)
	return sb


# ---------------------------------------------------------------- containers

static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(min_w: float = 0.0) -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size.x = min_w
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func margin(child: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m


static func panel(kind: String = "panel", pad: Vector4 = Vector4(16, 12, 16, 12)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(kind, Vector4(14, 10, 14, 10)))
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


# ---------------------------------------------------------------- text

static func label(text: String, size: int = 26, color: Color = INK, _font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", mini(size, 34))
	l.add_theme_color_override("font_color", color)
	return l


static func wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 40
	return l


static func trim(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 40
	return l


static func title(text: String, size: int = 30, color: Color = INK) -> Label:
	return label(text, size, color)


static func caps(text: String, size: int = 22, color: Color = INK_SOFT) -> Label:
	return label(text.to_upper(), size, color)


static func rich(bbcode: String, size: int = 24) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", INK)
	r.text = bbcode
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


## Section heading: a label over a thin line.
static func divider(text: String, size: int = 28) -> VBoxContainer:
	var v := vbox(4)
	v.add_child(title(text, size))
	v.add_child(hline())
	return v


# ---------------------------------------------------------------- widgets

## Icon from Sprites/UI Icons. Unknown names give an empty, hidden control.
static func icon(icon_name: String, size: float = 32.0, tint: Color = INK) -> Control:
	var tx := icon_tex(icon_name)
	if tx == null:
		var none := Control.new()
		none.visible = false
		none.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return none
	var t := TextureRect.new()
	t.texture = tx
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size) * 0.75
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func _btn_box(fill: Color) -> StyleBoxFlat:
	return flat(fill, 0, 1, Color("#888888"), Vector4(16, 6, 16, 6))


## Flat button. kind: "green" (go / confirm), "red" (deny / cancel), "blue" (navigate);
## anything else is plain grey.
static func button(text: String, kind: String = "", size: int = 26, min_h: float = 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, minf(min_h, 64.0))
	var fill: Color = BUTTON_FILLS.get(kind, BTN)
	b.add_theme_stylebox_override("normal", _btn_box(fill))
	b.add_theme_stylebox_override("hover", _btn_box(fill.darkened(0.06)))
	b.add_theme_stylebox_override("pressed", _btn_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("hover_pressed", _btn_box(fill.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", _btn_box(Color("#F0F0F0")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", mini(size, 26))
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INK)
	b.add_theme_color_override("font_disabled_color", Color("#999999"))
	b.add_theme_color_override("icon_normal_color", INK)
	b.add_theme_constant_override("icon_max_width", 28)
	b.add_theme_constant_override("h_separation", 8)
	return b


## A whole-row tappable area: a flat Button with any children laid out inside.
static func tap_area(child: Control, min_h: float = 0.0) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = min_h
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_mouse(child)
	b.add_child(child)
	b.resized.connect(func(): child.size = b.size)
	child.minimum_size_changed.connect(func(): b.custom_minimum_size.y = maxf(min_h, child.get_combined_minimum_size().y))
	b.custom_minimum_size.y = maxf(min_h, child.get_combined_minimum_size().y)
	return b


static func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control and not (c is BaseButton):
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)


static func chip(text: String, bg: Color = BOX_ALT, fg: Color = INK, size: int = 20, border: bool = true) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(bg, 0, 1 if border else 0, fg if fg != INK else LINE, Vector4(8, 2, 8, 2)))
	var l := label(text, size, fg)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


## Chip with an optional icon; `outlined` = darker border (used for the favored stat).
static func icon_chip(icon_name: String, text: String, bg: Color = BOX_ALT, fg: Color = INK, size: int = 20, outlined: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := flat(bg, 0, 1, fg if outlined else LINE, Vector4(8, 2, 8, 2))
	if outlined:
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	var h := hbox(4)
	h.add_child(icon(icon_name, size + 6, fg))
	h.add_child(label(text, size, fg))
	p.add_child(h)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


static func injury_chip(level: int, size: int = 20) -> PanelContainer:
	var info: Array = INJURY[clampi(level, 0, 4)]
	return chip(info[0], info[1], info[2], size)


static func ribbon_label(text: String, bg: Color = BOX_ALT, fg: Color = INK, size: int = 24) -> PanelContainer:
	return chip(text, bg, fg, size)


## Character portrait: the project's role headshot in a plain bordered square.
static func portrait(character: GuildCharacter, size: float, _shape: String = "") -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_stylebox_override("panel", flat(Color("#DDDDDD"), 0, 1, LINE, Vector4(1, 1, 1, 1)))
	var role: int = character.role if character else 0
	var t := TextureRect.new()
	t.texture = ExternalContentContainer.get_character_icon(role)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if character and character.injury_level >= GuildCharacter.InjuryLevel.DEAD:
		t.modulate = Color(1, 1, 1, 0.35)
	holder.add_child(t)
	return holder


## Plain progress bar: grey track, dark fill.
static func gauge(value: float, fill: Color = INK_SOFT, width: float = 400.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 20)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color("#DDDDDD"))
		c.draw_rect(Rect2(0, 0, c.size.x * clampf(value, 0.0, 1.0), c.size.y), fill)
		c.draw_rect(Rect2(Vector2.ZERO, c.size), LINE, false, 1.0)
	)
	return c


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


static func hline() -> ColorRect:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


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
