---
source: Scripts/UI/Components/drag_scroll.gd
class_name: DragScroll
extends: RefCounted
scene: ""
systems: ["[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# drag_scroll.gd

## Purpose
Makes every scroll list in the hall drag-scrollable by touch from anywhere on it, not just from the gaps between cards. `PanelContainer` and every `BaseButton` default to Mouse Filter Stop, so a touch that starts on one is used up there and never reaches the ScrollContainer. `fix_tree(root)` walks `root`, and inside every ScrollContainer sets Stop controls to Pass and, for buttons, cancels a press once the finger has moved further than `TapPanel.TAP_MOVE_LIMIT`. [[hall_main#refresh]] calls it at the end of every refresh, after rows are rebuilt. Tappable rows ([[tap_panel]]) don't need it. Static functions only, no scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `GUARDED_META` | const | Meta key set on a button once its drag check is connected, so a button that survives several refreshes is only hooked up once. |
| `PRESS_META` | const | Meta key holding where the button's current press started (global pixels). |

## Functions

### fix_tree
`static func fix_tree(root: Node) -> void` · `Scripts/UI/Components/drag_scroll.gd:27`

Fixes every control inside every ScrollContainer under `root`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `root` | `Node` | The node to search, usually the whole hall | `self` in [[hall_main#refresh]] |

**Returns:** nothing.

**Called by:** [[hall_main#refresh]] (`hall_main.gd:1798`, `DragScroll.fix_tree(self)`).

**Calls:** [[drag_scroll#_fix_children]].

### _fix_children
`static func _fix_children(node: Node, is_inside_scroll: bool) -> void` · `Scripts/UI/Components/drag_scroll.gd:34`

Recursive half of `fix_tree`. For each child, fixes it if the walk has passed through a ScrollContainer, then recurses (flagging true once the child is a ScrollContainer).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | Whose children to check | `root`, then each child, from [[drag_scroll#fix_tree]] |
| `is_inside_scroll` | `bool` | True once the walk has passed through a ScrollContainer | `root is ScrollContainer` at the top |

**Returns:** nothing.

**Called by:** [[drag_scroll#fix_tree]] (`drag_scroll.gd:28`), itself (`drag_scroll.gd:38`).

**Calls:** [[drag_scroll#_fix_control]].

### _fix_control
`static func _fix_control(control: Control) -> void` · `Scripts/UI/Components/drag_scroll.gd:42`

Lets one control inside a scroll list pass its touches up to the list. Only controls with Mouse Filter Stop are changed (to Pass). A button also gets a `gui_input` hook ([[drag_scroll#_on_button_input]]), once.

**Parameters:** `control` (`Control`), a child found by [[drag_scroll#_fix_children]].

**Returns:** nothing.

**Side effects:** changes `mouse_filter`; sets meta `drag_scroll_guarded`; connects `gui_input` on buttons.

**Called by:** [[drag_scroll#_fix_children]] (`drag_scroll.gd:37`).

**Calls:** [[drag_scroll#_on_button_input]] (through the connected lambda).

### _on_button_input
`static func _on_button_input(button: BaseButton, event: InputEvent) -> void` · `Scripts/UI/Components/drag_scroll.gd:54`

Tracks a button's press and cancels it once it turns into a scroll (moved at least `TapPanel.TAP_MOVE_LIMIT` with the left button held). Cancelling disables and immediately re-enables the button, which drops the press in progress without firing `pressed`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `button` | `BaseButton` | The guarded button | captured in the lambda from [[drag_scroll#_fix_control]] |
| `event` | `InputEvent` | The button's `gui_input` event | signal `gui_input` on the button |

**Returns:** nothing.

**Side effects:** sets/removes meta `drag_scroll_press`; briefly toggles `button.disabled`.

**Called by:** signal `gui_input` on each guarded button (lambda connected at `drag_scroll.gd:49`).

## Suspected issues
- None found.
