## Style kit for the Mobile Deck UI: dark mode, rounded cards, Godot's default
## font. Colour only carries meaning (stat colours, green = go / good,
## red = deny / bad, yellow = gold, blue = info / selected). Only art used is the
## project's own Sprites/Character Icons and Sprites/UI Icons (recoloured with a
## tiny shader, since the SVGs are black).
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

const INK := Color("#EEEFF3")
const INK_SOFT := Color("#9EA2B3")
const PARCH := Color("#FFFFFF")
const CREAM := Color("#FFFFFF")
const LINE := Color("#3D4050")
const WHITE := Color("#FFFFFF")
const BG := Color("#16171D")
const BOX := Color("#262833")
const BOX_ALT := Color("#30323F")
const BTN := Color("#3A3D4C")

## Colour is used only to mean something:
## green = good / go, red = bad / danger, yellow = gold, blue = info / in progress.
const GOOD := Color("#66BB6A")
const GOOD_BG := Color("#1F3A24")
const BAD := Color("#EF5350")
const BAD_BG := Color("#4A1F22")
const WARN := Color("#FFA726")
const WARN_BG := Color("#4A3315")
const GOLD := Color("#FFCA28")
const GOLD_BG := Color("#463A12")
const INFO := Color("#42A5F5")
const INFO_BG := Color("#163552")
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
	{"name": "Strength", "short": "Str", "icon": "", "color": Color("#EF5350"), "bg": Color("#3E1E22")},
	{"name": "Defense", "short": "Def", "icon": "", "color": Color("#42A5F5"), "bg": Color("#15304A")},
	{"name": "Wisdom", "short": "Wis", "icon": "", "color": Color("#CE93D8"), "bg": Color("#36203D")},
	{"name": "Sleaziness", "short": "Slz", "icon": "", "color": Color("#66BB6A"), "bg": Color("#1E3522")},
	{"name": "Pluck", "short": "Plk", "icon": "", "color": Color("#FFA726"), "bg": Color("#45311A")},
]

## GuildCharacter.InjuryLevel → label, background, text colour (green → red → grey).
const INJURY := [
	["Healthy", GOOD_BG, GOOD],
	["Sore", GOLD_BG, GOLD],
	["Lightly Injured", WARN_BG, WARN],
	["Gravely Injured", BAD_BG, BAD],
	["Dead", Color("#2A2A2E"), Color("#8A8A90")],
]

## Button kinds → fill colour. Anything else is plain grey.
const BUTTON_FILLS := {
	"green": Color("#2E7D32"), "red": Color("#B3261E"), "blue": Color("#1565C0"),
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
	var grab := flat(Color("#555A6E"), 4, 0, INK, Vector4(4, 0, 4, 0))
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
	sb.set_corner_radius_all(radius)
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
	var sb := flat(fill, 0 if kind == "bar" or kind == "panel" else 18, 1, INFO if kind == "ready" else LINE, pad)
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
	t.material = tint_material(tint)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static var _tint_shader: Shader
static var _tint_mats := {}

## The UI Icons are black SVGs; this paints them any colour (modulate can't lighten black).
static func tint_material(tint: Color) -> ShaderMaterial:
	var key := tint.to_html()
	if _tint_mats.has(key):
		return _tint_mats[key]
	if _tint_shader == null:
		_tint_shader = Shader.new()
		_tint_shader.code = "shader_type canvas_item;\nuniform vec4 tint : source_color;\nvoid fragment() { COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a); }\n"
	var m := ShaderMaterial.new()
	m.shader = _tint_shader
	m.set_shader_parameter("tint", tint)
	_tint_mats[key] = m
	return m


static func _btn_box(fill: Color) -> StyleBoxFlat:
	return flat(fill, 14, 0, LINE, Vector4(16, 6, 16, 6))


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
	b.add_theme_stylebox_override("disabled", _btn_box(Color("#24252E")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", mini(size, 26))
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, INK)
	b.add_theme_color_override("font_disabled_color", Color("#5C6070"))
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
	p.add_theme_stylebox_override("panel", flat(bg, 12, 1 if border else 0, fg if fg != INK else LINE, Vector4(10, 2, 10, 2)))
	var l := label(text, size, fg)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


## Chip with an optional icon; `outlined` = darker border (used for the favored stat).
static func icon_chip(icon_name: String, text: String, bg: Color = BOX_ALT, fg: Color = INK, size: int = 20, outlined: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := flat(bg, 12, 1, fg if outlined else bg, Vector4(10, 2, 10, 2))
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
	var holder := Panel.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_stylebox_override("panel", flat(Color("#C9CBD6"), int(size * 0.18), 0))
	holder.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var role: int = character.role if character else 0
	var t := TextureRect.new()
	t.texture = ExternalContentContainer.get_character_icon(role)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if character and character.injury_level >= GuildCharacter.InjuryLevel.DEAD:
		t.modulate = Color(1, 1, 1, 0.3)
	holder.add_child(t)
	return holder


## Plain progress bar: grey track, dark fill.
static func gauge(value: float, fill: Color = INK_SOFT, width: float = 400.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 16)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		c.draw_style_box(flat(BOX_ALT, int(c.size.y / 2), 0), Rect2(Vector2.ZERO, c.size))
		var w := c.size.x * clampf(value, 0.0, 1.0)
		if w > 1.0:
			c.draw_style_box(flat(fill, int(c.size.y / 2), 0), Rect2(0, 0, maxf(w, c.size.y), c.size.y))
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


## Row of coloured stat chips for a character ("Str 5", "Def 7", ...).
## `fav` (0-4) gets a heavier outline; `with_pluck` adds the fifth stat.
static func stat_row(c: GuildCharacter, fav: int = -1, with_pluck: bool = true, size: int = 20) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in (5 if with_pluck else 4):
		var st: Dictionary = STATS[i]
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		f.add_child(icon_chip("", "%s %d" % [st.short, val], st.bg, st.color, size, i == fav))
	return f


## Thin page heading with a one-line explanation under it.
static func heading(text: String, sub: String = "") -> VBoxContainer:
	var v := vbox(2)
	v.add_child(title(text, 30))
	if sub != "":
		var l := label(sub, 22, INK_SOFT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 40
		v.add_child(l)
	return v
