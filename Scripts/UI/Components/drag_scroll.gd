## Makes every scroll list in the hall drag-scrollable by touch from anywhere
## on it, not just from the gaps between cards.
##
## Why: `PanelContainer` and every `BaseButton` default to Mouse Filter Stop.
## A touch that starts on a Stop control is used up there and never reaches
## the ScrollContainer, so on a phone the list won't scroll from that spot.
##
## `fix_tree(root)` walks `root`, and inside every ScrollContainer it:
##   - sets plain Stop controls (panels, tags, cards) to Pass, and
##   - sets buttons to Pass too, and cancels a button's press once the finger
##     has moved further than TapPanel.TAP_MOVE_LIMIT, so a scroll that starts
##     on a button scrolls instead of pressing it on release.
## hall_main calls it at the end of every refresh(), after rows are rebuilt.
## Tappable rows don't need it: they extend TapPanel, which is already Pass.
class_name DragScroll
extends RefCounted

## Meta key set on a button once its drag check is connected (so a button
## that survives several refreshes is only hooked up once).
const GUARDED_META := &"drag_scroll_guarded"
## Meta key holding where the button's current press started (global pixels).
const PRESS_META := &"drag_scroll_press"


## Fix every control inside every ScrollContainer under `root` (see the header).
## root: the node to search, usually the whole hall.
static func fix_tree(root: Node) -> void:
	_fix_children(root, root is ScrollContainer)


## Recursive half of fix_tree.
## node: whose children to check.
## is_inside_scroll: true once the walk has passed through a ScrollContainer.
static func _fix_children(node: Node, is_inside_scroll: bool) -> void:
	for child in node.get_children():
		if is_inside_scroll and child is Control:
			_fix_control(child)
		_fix_children(child, is_inside_scroll or child is ScrollContainer)


## Let one control inside a scroll list pass its touches up to the list.
static func _fix_control(control: Control) -> void:
	if control.mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	if control is BaseButton and not control.has_meta(GUARDED_META):
		var button: BaseButton = control
		button.set_meta(GUARDED_META, true)
		button.gui_input.connect(func(event: InputEvent) -> void: _on_button_input(button, event))


## Track a button's press and cancel it once it turns into a scroll.
## The ScrollContainer still gets every event (the button is Pass) and scrolls.
static func _on_button_input(button: BaseButton, event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.button_index == MOUSE_BUTTON_LEFT and press.pressed:
		button.set_meta(PRESS_META, press.global_position)
		return
	var motion := event as InputEventMouseMotion
	if motion == null or not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return
	if not button.has_meta(PRESS_META) or button.disabled:
		return
	var start: Vector2 = button.get_meta(PRESS_META)
	if motion.global_position.distance_to(start) < TapPanel.TAP_MOVE_LIMIT:
		return
	button.remove_meta(PRESS_META)
	# Disabling a button drops the press in progress (a toggle keeps its
	# on/off state), so the release won't fire `pressed`; re-enable at once.
	button.disabled = true
	button.disabled = false
