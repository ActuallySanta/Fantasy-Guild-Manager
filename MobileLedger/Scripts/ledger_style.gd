## Style kit for the Mobile Ledger UI: painted parchment, wood, wax seals.
## Every screen builds its widgets through these helpers so the look stays
## consistent and can be re-tuned in one place. Art lives in MobileLedger/Art
## (regenerate with MobileLedger/Tools/generate_art.py).
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

static var display_font: FontVariation
static var display_black: FontVariation
static var body_font: Font
static var body_bold: Font
static var body_italic: Font
static var _cache := {}


static func init_fonts() -> void:
	if display_font:
		return
	var cinzel: Font = load(FONTS + "Cinzel-Variable.ttf")
	display_font = FontVariation.new()
	display_font.base_font = cinzel
	display_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	display_black = FontVariation.new()
	display_black.base_font = cinzel
	display_black.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 900}
	body_font = load(FONTS + "AlegreyaSans-Medium.ttf")
	body_bold = load(FONTS + "AlegreyaSans-Bold.ttf")
	body_italic = load(FONTS + "AlegreyaSans-Italic.ttf")


static func make_theme() -> Theme:
	init_fonts()
	var t := Theme.new()
	t.default_font = body_font
	t.default_font_size = 28
	t.set_color("font_color", "Label", INK)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(INK_SOFT, 0.5)
	grab.set_corner_radius_all(6)
	grab.content_margin_left = 5
	grab.content_margin_right = 5
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var track := StyleBoxEmpty.new()
	track.content_margin_left = 5
	track.content_margin_right = 5
	t.set_stylebox("scroll", "VScrollBar", track)
	return t


# ---------------------------------------------------------------- resources

static func tex(file: String) -> Texture2D:
	var path := ART + file
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


static func icon_tex(icon_name: String) -> Texture2D:
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


# ---------------------------------------------------------------- containers

static func vbox(sep: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 16) -> HBoxContainer:
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


## A painted parchment panel. kind: "panel" | "card" | "ready" | "inset".
static func panel(kind: String = "panel", pad: Vector4 = Vector4(26, 22, 26, 24)) -> PanelContainer:
	var p := PanelContainer.new()
	var file: String = {"panel": "panel_parchment.png", "card": "card_parchment.png", "ready": "card_ready.png", "inset": "inset_parchment.png"}[kind]
	var m := 40.0 if kind != "inset" else 26.0
	var sh := 10.0 if kind != "inset" else 8.0
	p.add_theme_stylebox_override("panel", sbtex(file, m, pad, sh))
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


# ---------------------------------------------------------------- text

static func label(text: String, size: int = 28, color: Color = INK, font: Font = null) -> Label:
	init_fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else body_font)
	l.add_theme_font_size_override("font_size", size)
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


static func title(text: String, size: int = 36, color: Color = INK) -> Label:
	init_fonts()
	return label(text, size, color, display_font)


static func caps(text: String, size: int = 22, color: Color = INK_SOFT) -> Label:
	init_fonts()
	var l := label(text.to_upper(), size, color, body_bold)
	return l


static func rich(bbcode: String, size: int = 26) -> RichTextLabel:
	init_fonts()
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_override("normal_font", body_font)
	r.add_theme_font_override("bold_font", body_bold)
	r.add_theme_font_override("italics_font", body_italic)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", INK)
	r.text = bbcode
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


## Section heading with leafy flourishes on both sides (as in the reference art).
static func divider(text: String, size: int = 32) -> HBoxContainer:
	var h := hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := TextureRect.new()
	l.texture = tex("flourish_l.png")
	l.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	l.custom_minimum_size = Vector2(110, 26)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var r := TextureRect.new()
	r.texture = tex("flourish_r.png")
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.custom_minimum_size = Vector2(110, 26)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var t := title(text, size)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(t)
	h.add_child(r)
	return h


# ---------------------------------------------------------------- widgets

static func icon(icon_name: String, size: float = 40.0, tint: Color = Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon_tex(icon_name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func picture(file: String, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(file)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Painted button. kind: green | red | wood | blue | paper.
static func button(text: String, kind: String = "green", size: int = 28, min_h: float = 88.0) -> Button:
	init_fonts()
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_h)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var pad := Vector4(26, 10, 26, 10)
	var normal := sbtex("btn_%s.png" % kind, 26, pad, 6)
	var down := sbtex("btn_%s_down.png" % kind, 26, pad + Vector4(0, 4, 0, -4), 6)
	var off := sbtex("btn_disabled.png", 26, pad, 6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", display_font)
	b.add_theme_font_size_override("font_size", size)
	var light := kind != "paper"
	var fc := WHITE if light else INK
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, fc)
	b.add_theme_color_override("font_disabled_color", Color("#7A6A55"))
	if light:
		b.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.03, 0.85))
		b.add_theme_constant_override("outline_size", 6)
	b.add_theme_constant_override("icon_max_width", int(size * 1.3))
	b.add_theme_constant_override("h_separation", 10)
	return b


## A whole-row tappable area: a flat Button with any children laid out inside.
static func tap_area(child: Control, min_h: float = 0.0) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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


static func chip(text: String, bg: Color, fg: Color, size: int = 22, border: bool = true) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(bg, 18, 2 if border else 0, fg, Vector4(14, 2, 14, 4)))
	var l := label(text, size, fg, body_bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


static func icon_chip(icon_name: String, text: String, bg: Color, fg: Color, size: int = 22, outlined: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(bg, 18, 3 if outlined else 0, fg, Vector4(8, 2, 14, 2)))
	var h := hbox(6)
	h.add_child(icon(icon_name, size + 6))
	h.add_child(label(text, size, fg, body_bold))
	p.add_child(h)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


static func injury_chip(level: int, size: int = 22) -> PanelContainer:
	var info: Array = INJURY[clampi(level, 0, 4)]
	return chip(info[0], info[1], info[2], size)


## Ribbon-style banner label (the "Healthy" ribbon in the reference).
static func ribbon_label(text: String, bg: Color, fg: Color, size: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := flat(bg, 4, 3, fg.darkened(0.1), Vector4(26, 4, 26, 6))
	sb.skew = Vector2(0.0, 0.0)
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text, size, fg, display_font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


## Character portrait from the project's own role art, clipped to a circle or
## rounded square on a soft painted ground.
static func portrait(character: GuildCharacter, size: float, shape: String = "rounded") -> Control:
	var holder := Panel.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var role: int = character.role if character else 0
	var r := int(size / 2) if shape == "circle" else int(size * 0.18)
	var ground: Color = ROLE_GROUNDS[clampi(role, 0, 3)]
	holder.add_theme_stylebox_override("panel", flat(ground, r, 0))
	holder.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var t := TextureRect.new()
	t.texture = ExternalContentContainer.get_character_icon(role)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.offset_top = size * 0.06
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if character and character.injury_level >= GuildCharacter.InjuryLevel.DEAD:
		t.modulate = Color(0.6, 0.55, 0.62)
	holder.add_child(t)
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsb := flat(Color(0, 0, 0, 0), r, 3, INK)
	fsb.draw_center = false
	frame.add_theme_stylebox_override("panel", fsb)
	holder.add_child(frame)
	return holder


## Five-segment rune bar like the reference's success gauge.
static func gauge(value: float, fill: Color, width: float = 560.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 40)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var w := c.size.x
		var h := c.size.y
		c.draw_style_box(flat(Color("#3A2816"), 10, 0), Rect2(0, 0, w, h))
		var inner := Rect2(10, 8, w - 20, h - 16)
		c.draw_style_box(flat(Color("#5E4A32"), 6, 0), inner)
		var segs := 10
		var gap := 4.0
		var sw := (inner.size.x - gap * (segs - 1)) / segs
		for i in segs:
			var on := (i + 1) / float(segs) <= value + 0.0001
			var rect := Rect2(inner.position.x + i * (sw + gap), inner.position.y + 3, sw, inner.size.y - 6)
			c.draw_style_box(flat(fill if on else Color("#7C6648"), 4, 0), rect)
		# gold end caps
		for x in [4.0, w - 4.0]:
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, h / 2 - 12), Vector2(x + (8 if x < 10 else -8), h / 2), Vector2(x, h / 2 + 12)]), GOLD)
	)
	return c


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


static func hline() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(LINE, 0.9)
	line.custom_minimum_size = Vector2(0, 2)
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
