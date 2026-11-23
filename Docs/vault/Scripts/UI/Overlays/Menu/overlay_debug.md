---
source: Scripts/UI/Overlays/Menu/overlay_debug.gd
class_name: ""
extends: Control
scene: "[[overlay_debug (scene)]]"
systems: ["[[UI Architecture and Refresh]]", "[[Saving Migration and Backup Codes]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_debug.gd

## Purpose
Menu > Debug tools (only when `GuildUpgrades.SHOW_DEBUG_BUTTONS`): cheats for testing a run. The first time in a run the sheet only warns that the tools stop the run from being saved, with an Enable button ([[hall_main#enable_debug_tools]]). The "Save runs" checkbox and Check for update sit above the cheats because they aren't cheats. After Enable the sheet lists the tools: Time (skip day, jump to milestone / final day), Wallet (gold and standing steps), Guild (add hero, add item, heal, max buildings, reset upgrades), Run (reroll, skip tutorial, replay intro). The rules live in [[hall_debug]]; every button calls a `hall.debug_*` action. Back returns to the Menu; tapping the dim closes both. Scene: [[overlay_debug (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUTTON_FONT_SIZE` | const | Button font size (design px). |
| `BUTTON_HEIGHT` | const | Height of a tool button (design px): big enough for a thumb. |
| `NOTE_*`, `BUTTON_*`, `CHECK_*`, `TOAST_*` | const | UI strings and toast messages. |
| `_dim`, `_note`, `_enable_button`, `_scroll`, `_skip_button`, `_jump_grid`, `_wallet_grid`, `_hero_button`, `_item_button`, `_heal_button`, `_max_button`, `_reset_button`, `_reroll_button`, `_tutorial_button`, `_intro_button`, `_save_check`, `_back_button`, `_update_button`, `_update_confirm` | onready | Scene nodes by unique name (`%Dim`, `%Note`, `%EnableButton`, `%Scroll`, `%SkipButton`, `%JumpGrid`, `%WalletGrid`, ..., `%SaveCheckBox`, `%UpdateButton`, `%UpdateConfirm`). `_update_confirm` is the [[overlay_update_confirm (scene)]] child. |
| `hall` | var | The [[hall_main]] node. |
| `_jump_buttons` | var | `{day (int): Button}`, one per `HallDebug.JUMP_DAYS` entry. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Menu/overlay_debug.gd:79`

Stores the hall, connects every button, sets up the update popup, builds the step buttons from [[hall_debug]]'s tables (`JUMP_DAYS`, `GOLD_STEPS`, `STANDING_STEPS`), then sets texts and styles.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in `view.setup(self)` ([[hall_main#_ready]], `hall_main.gd:427`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%EnableButton` to [[hall_main#enable_debug_tools]], `%SkipButton` to [[hall_main#debug_skip_day]], `%HeroButton` to [[hall_main#debug_add_hero]], `%ItemButton` to [[hall_main#debug_add_item]], `%HealButton` to [[hall_main#debug_heal_everyone]], `%MaxButton` to [[hall_main#debug_max_buildings]], `%ResetButton` to [[hall_main#reset_upgrades]], `%RerollButton` to [[hall_main#debug_reroll_today]], `%TutorialButton` to [[hall_main#debug_skip_tutorial]], `%IntroButton` to [[hall_main#debug_replay_intro]], `toggled` on `%SaveCheckBox` to [[hall_main#set_save_enabled]], `%BackButton` to [[hall_main#close_debug]], `%UpdateButton` to [[overlay_debug#_on_update_pressed]], `gui_input` on `%Dim` to [[overlay_debug#_on_dim_input]]. Each generated jump button is bound to [[hall_main#debug_jump_to_day]] with its day, gold buttons to [[hall_main#debug_add_gold]], standing buttons to [[hall_main#debug_add_standing]]. `visibility_changed` closes the update popup when the sheet hides.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[overlay_update_confirm#setup]] (`overlay_debug.gd:95`), [[overlay_update_confirm#close]] (`:99`), [[overlay_debug#_make_button]], [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Menu/overlay_debug.gd:130`

Until `hall.is_debug_run` is true, shows only the warning note, Enable and the Save runs checkbox. Once on, shows the scroll of tools and enables or disables buttons: skip day via `HallDebug.can_skip_day`, jump buttons via `HallDebug.can_jump_to`, Add hero via `CharacterContainer.has_free_bed()`, Skip tutorial only when `hall.tutorial` is running, Replay intro only when it isn't. The checkbox mirrors `hall.is_save_enabled` with `set_pressed_no_signal` (so settings aren't written again) and reads "(off for debug runs)" once enabled.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`) while visible.

**Calls:** [[hall_debug#can_skip_day]], [[hall_debug#can_jump_to]], [[character_container#has_free_bed]].

### _make_button
`func _make_button(grid: GridContainer, text: String) -> Button` · `Scripts/UI/Overlays/Menu/overlay_debug.gd:155`

Adds a paper tool button to `grid`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `grid` | `GridContainer` | Where the button goes | `_jump_grid` or `_wallet_grid` in [[overlay_debug#setup]] |
| `text` | `String` | Button label | `BUTTON_JUMP % day`, `BUTTON_GOLD % amount`, `BUTTON_STANDING % amount` |

**Returns:** the new `Button`, so the caller can connect its signal.

**Called by:** [[overlay_debug#setup]].

**Calls:** [[hall_style#style_button]].

### _on_update_pressed
`func _on_update_pressed() -> void` · `Scripts/UI/Overlays/Menu/overlay_debug.gd:169`

Check for update: disables the button, shows "Checking...", and asks the live site via `HallWebUpdate.check_latest(self, _on_update_checked)`.

**Called by:** `pressed` on `%UpdateButton`.

**Calls:** [[hall_web_update#check_latest]].

### _on_update_checked
`func _on_update_checked(result: HallWebUpdate.CheckResult, latest_stamp: String) -> void` · `Scripts/UI/Overlays/Menu/overlay_debug.gd:177`

`check_latest`'s answer: re-enables the button, then toasts (up to date, not the web build, or check failed) or, for a newer build, opens the update popup (only if Debug tools are still visible in the tree).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `HallWebUpdate.CheckResult` | UP_TO_DATE / UPDATE_AVAILABLE / NOT_WEB / other (failure) | passed by [[hall_web_update#check_latest]] |
| `latest_stamp` | `String` | The site's build stamp ("" unless the fetch worked) | same |

**Returns:** nothing.

**Called by:** [[hall_web_update#check_latest]] (the callback handed in by [[overlay_debug#_on_update_pressed]]).

**Calls:** [[hall_main#show_toast]], [[overlay_update_confirm#open]] (`overlay_debug.gd:186`), [[hall_build_info#stamp]].

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Menu/overlay_debug.gd:194`

A mouse press on the dim closes Debug tools and the Menu.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[hall_main#close_debug]] with `false`.

## Suspected issues
- None found.
