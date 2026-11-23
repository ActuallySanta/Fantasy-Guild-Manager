---
source: Scripts/UI/Shell/Header/header_popup.gd
class_name: HeaderPopup
extends: Control
scene: ""
systems: ["[[UI Architecture and Refresh]]", "[[Economy and Wallet]]", "[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# header_popup.gd

## Purpose
Base class for the two header popups: a parchment card that drops from a header counter (the gold coin or the standing shield) with a little point aiming at it. Tapping outside the card closes it. It only reads the game. [[popup_gold]] and [[popup_standing]] extend it and fill the card in `refresh()`. It has no scene of its own; the scenes [[popup_gold (scene)]] and [[popup_standing (scene)]] provide the nodes `Catch`, `Pointer`, `Layout` and `Card` (unique names). The root is `top_level` so the header's VBox doesn't lay it out, with `z_index` 10 like the overlays.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SIDE_MARGIN` | const | Gap between the card and the screen's left/right edges (28 design px). |
| `DROP_GAP` | const | Gap between the counter's bottom and the card's top (22 design px). |
| `POINTER_SIZE` | const | Side of the square turned 45 degrees into the point (30 design px). |
| `OPEN_SECONDS` | const | Seconds the card takes to fade and drop in (0.15; none with reduced motion). |
| `DROP_DISTANCE` | const | How far above its resting place the card starts (16 design px). |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_anchor` | var | The header counter the card drops from (null while closed). |
| `_catch`, `_layout`, `_card`, `_pointer` | var | `%Catch`, `%Layout`, `%Card`, `%Pointer`. |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Shell/Header/header_popup.gd:47`

Called by the engine. Hides the popup, connects `gui_input` on `%Catch` to [[header_popup#_on_catch_input]], builds the pointer from a copy of the card's `StyleBoxTexture` (if it is one), sizes and rotates it 45 degrees, and sets the Layout's left/right/bottom margins to `SIDE_MARGIN`. Subclasses call `super()`.

**Called by:** the engine (and `super()` in [[popup_gold#_ready]], [[popup_standing#_ready]]). **Calls:** none.

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Shell/Header/header_popup.gd:64`

Stores the hall.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `main` in [[hall_header#setup]] |

**Returns:** nothing.

**Called by:** [[hall_header#setup]] (`hall_header.gd:127` gold, `:128` standing). **Calls:** none.

### open
`func open(anchor: Control) -> void` · `Scripts/UI/Shell/Header/header_popup.gd:69`

Drops the card from `anchor` and fills it in.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `anchor` | `Control` | The counter box the card hangs under | `anchor` bound in [[hall_header#setup]] (`%GoldValueBox` / `%StandingValueBox`), passed at `hall_header.gd:193` |

**Returns:** nothing.

**Side effects:** sets `_anchor`, shows the popup, calls `refresh()` and `_place()`; unless Reduced Motion, [[hall_fx#fade_in]] on the popup and [[hall_fx#slide_in]] on the card.

**Called by:** [[hall_header#_on_counter_input]] (`hall_header.gd:193`).

**Calls:** [[header_popup#refresh]], [[header_popup#_place]], [[hall_fx#fade_in]], [[hall_fx#slide_in]].

### close
`func close() -> void` · `Scripts/UI/Shell/Header/header_popup.gd:79`

Clears the anchor and hides the popup.

**Called by:** [[hall_header#_on_counter_input]] (`hall_header.gd:192`, on the other popup), [[header_popup#_on_catch_input]] (`header_popup.gd:107`). **Calls:** none.

### is_open
`func is_open() -> bool` · `Scripts/UI/Shell/Header/header_popup.gd:84`

**Returns:** `visible`. Used by [[hall_header#refresh]] (`hall_header.gd:182`) to refresh only open popups. **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Shell/Header/header_popup.gd:89`

Fills the card in from the game. Empty here; overridden by [[popup_gold#refresh]] and [[popup_standing#refresh]].

**Called by:** [[header_popup#open]] (`header_popup.gd:72`), [[hall_header#refresh]] (`hall_header.gd:183`, only while open). **Calls:** none.

### _place
`func _place() -> void` · `Scripts/UI/Shell/Header/header_popup.gd:95`

Puts the card under the anchor (Layout's top margin = anchor bottom + `DROP_GAP`) and the point under the anchor's middle. Does nothing without an anchor.

**Called by:** [[header_popup#open]] (`header_popup.gd:73`). **Calls:** none.

### _on_catch_input
`func _on_catch_input(event: InputEvent) -> void` · `Scripts/UI/Shell/Header/header_popup.gd:105`

A tap anywhere outside the card closes it (any pressed `InputEventMouseButton`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | The input event | `gui_input` on `%Catch` |

**Called by:** `gui_input` on `%Catch`, connected in [[header_popup#_ready]] (`header_popup.gd:49`). **Calls:** [[header_popup#close]].

## Suspected issues
- None found.
