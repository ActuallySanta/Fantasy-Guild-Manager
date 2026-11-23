---
source: Scripts/UI/Tabs/tab_guild.gd
class_name: ""
extends: VBoxContainer
scene: "[[tab_guild (scene)]]"
systems: ["[[Hiring Characters]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tab_guild.md

## Purpose
The Guild tab (the "Members" nav button): a folder with two tabs, "Your Guild" (the roster) and "Applicants" (today's recruits). Applicants come as a stack of letters: the top one is read in full, the ones under it peek out and come to the top when tapped. A line at the top shows beds used. Scene: [[tab_guild (scene)]]. No `class_name`; [[hall_main]] reaches it as `_tabs.guild`. See [[Hiring Characters]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `MemberCardScene` | const (preload) | `uid://dls1bjn8gt2fe`, `Scenes/Rows/Heroes/member_card.tscn`, [[member_card (scene)]]. |
| `HireCardScene` | const (preload) | `uid://cy6d8ep8exxlt`, `Scenes/Rows/Heroes/hire_card.tscn`, [[hire_card (scene)]]. |
| `HirePeekScene` | const (preload) | `uid://3jfkcim0fo7x`, `Scenes/Rows/Heroes/hire_peek.tscn`, [[hire_peek (scene)]]. |
| `HeadingScene` | const (preload) | `uid://bve0dglxrk3x4`, `Scenes/Rows/Buildings/home_heading.tscn`, [[home_heading (scene)]]. |
| `FALLEN_OPACITY` | const | Alpha of fallen heroes' cards (0.6). |
| `PEEK_COUNT` | const | Letters peeking out under the top one (2). |
| `PEEK_TILTS` | const | Their small tilts in degrees (0.6, -0.5). |
| `NEXT_LETTER_SLIDE` | const | Where the next letter slides up from after a hire (`Vector2(0, 48)`). |
| `FOLDER_TAB_HEIGHT` / `FOLDER_TAB_HEIGHT_OPEN` | const | Folder tab heights in px (72 / 80). |
| `BEDS_FULL_COLOR` | const | Beds-line ink when every bed is taken. |
| `SHOW_ROSTER_COUNT` | const | `false`: hides the "· 3/4" count on the roster tab. |
| `SHOW_BARRACKS_LINK` | const | `false`: hides "· Barracks Lv" and the Barracks button. |
| `SECTION_*`, `BEDS*`, `EMPTY_*`, `NO_LIVING`, `HEADING_FALLEN`, `LOW_STANDING`, `PEEK` | const | Text strings. |
| `_roster_section_button`, `_hire_section_button`, `_hire_badge`, `_hire_badge_text`, `_beds_label`, `_barracks_button`, `_scroll`, `_card_list`, `_letter_stack`, `_empty_label` | var | `%SegRoster`, `%SegHire`, `%HireBadge`, `%HireBadgeText`, `%Beds`, `%BedsButton`, `%Scroll`, `%List`, `%Stack`, `%Empty`. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_top_letter` | var | Index into `CharacterContainer.hireable_characters` of the letter on top. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_guild.gd:73`

Stores the hall and connects the folder tabs and the Barracks button.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** `pressed` on `%SegRoster` / `%SegHire` calls [[hall_main#show_guild_section]]; `pressed` on `%BedsButton` calls [[hall_main#open_tab]] (`"upgrades"`, `UPGRADES_SECTION_BUILD`); sets the Barracks button's text and visibility (`SHOW_BARRACKS_LINK`).

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`). **Calls:** [[hall_main#show_guild_section]], [[hall_main#open_tab]].

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_guild.gd:82`

Sets `%Scroll`'s `scroll_vertical` to 0.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1851`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_guild.gd:86`

Redraws the folder tabs and beds line, clears both lists, then fills the roster or the applicants stack.

**Side effects:** `HallStyle.clear_children` on `%List` and `%Stack`.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1843`).

**Calls:** [[tab_guild#_show_section_buttons]], [[tab_guild#_show_beds]], [[hall_style#clear_children]], [[tab_guild#_is_hire_section]], [[tab_guild#_show_for_hire]], [[tab_guild#_show_roster]].

### _is_hire_section
`func _is_hire_section() -> bool` · `Scripts/UI/Tabs/tab_guild.gd:97`

**Returns:** `true` when `hall.guild_section` is `GUILD_SECTION_HIRE` and hiring isn't locked by the tutorial (the hire section stays closed until taught). Used by [[tab_guild#refresh]] and [[tab_guild#_show_section_buttons]].

**Called by:** [[tab_guild#refresh]] (`tab_guild.gd:91`), [[tab_guild#_show_section_buttons]] (`:107`). **Calls:** [[hall_main#is_locked]].

### _show_section_buttons
`func _show_section_buttons() -> void` · `Scripts/UI/Tabs/tab_guild.gd:106`

The open folder tab is the lighter, taller one that joins the folder; Applicants shows a count badge while closed (and not locked, and the roster isn't full).

**Side effects:** texts, `theme_type_variation` (`FolderTab` / `FolderTabActive`), heights, [[hall_style#set_locked]] on `%SegHire` (and `%BedsButton` with `SHOW_BARRACKS_LINK`), badge visibility and text.

**Called by:** [[tab_guild#refresh]] (`tab_guild.gd:87`). **Calls:** [[tab_guild#_is_hire_section]], [[hall_main#is_locked]], [[hall_main#is_tab_locked]], [[hall_main#is_roster_full]], [[hall_style#set_locked]].

### _show_beds
`func _show_beds() -> void` · `Scripts/UI/Tabs/tab_guild.gd:128`

"Beds 3 of 5" (plus "· Barracks Lv N" with `SHOW_BARRACKS_LINK`), or "All N beds full" in light red when every bed is taken. Beds used = `CharacterContainer.living_count()`, total = `CharacterContainer.max_characters`.

**Called by:** [[tab_guild#refresh]] (`tab_guild.gd:88`). **Calls:** [[guild_upgrades#get_level]], [[hall_style#set_font_color]].

### _show_roster
`func _show_roster() -> void` · `Scripts/UI/Tabs/tab_guild.gd:146`

Living heroes first, then the fallen under a "Fallen · N" heading (they don't take a bed but stay so the Hospital can revive them, shown at `FALLEN_OPACITY`). Shows `EMPTY_ROSTER` when the roster is empty, or a "Nobody left standing." note when only the fallen remain.

**Side effects:** adds [[member_card (scene)]] rows via `HallStyle.add_row` and calls [[member_card#setup]] (`hall, character`) on each; adds a [[home_heading (scene)]] row for the fallen heading; sets `%Empty`.

**Called by:** [[tab_guild#refresh]] (`tab_guild.gd:94`). **Calls:** [[hall_main#roster]], [[hall_style#is_dead]], [[hall_style#add_row]], [[member_card#setup]].

### _show_for_hire
`func _show_for_hire() -> void` · `Scripts/UI/Tabs/tab_guild.gd:172`

Recruits only come while standing is above `GuildUpgrades.MINIMUM_STANDING`; otherwise `LOW_STANDING` shows and nothing else. Otherwise one [[hire_card (scene)]] on top of `%Stack` (`setup(hall, recruit, _top_letter)`), and up to `PEEK_COUNT` [[hire_peek (scene)]] buttons under it, tilted by `PEEK_TILTS`, each labelled "name · role" and wired to [[tab_guild#_bring_to_top]]. If `hall.pending_fx.hire_next` is set (the last letter was just hired) the top card slides in with [[hall_fx#slide_in]].

**Side effects:** clamps `_top_letter`; adds rows; connects `pressed` on each peek.

**Called by:** [[tab_guild#refresh]] (`tab_guild.gd:92`). **Calls:** [[hall_style#add_row]], [[hire_card#setup]], [[hall_fx#slide_in]], [[hall_style#role_name]], [[tab_guild#_bring_to_top]].

### _bring_to_top
`func _bring_to_top(recruit_index: int) -> void` · `Scripts/UI/Tabs/tab_guild.gd:202`

Makes the tapped peeking letter the top one and queues a refresh.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `recruit_index` | `int` | Index into `hireable_characters` | bound at `tab_guild.gd:199` as `(_top_letter + 1 + peek_index) % recruits.size()` |

**Side effects:** sets `_top_letter`, calls [[hall_main#queue_refresh]].

**Called by:** `pressed` on each runtime `hire_peek` button (connected at `tab_guild.gd:199`). **Calls:** [[hall_main#queue_refresh]].

### roster_button
`func roster_button() -> Control` · `Scripts/UI/Tabs/tab_guild.gd:208`

The "Your Guild" folder tab, where hired letters fly to.

**Returns:** `%SegRoster`. Used by [[hall_main#_fly_hired_letter]] (`hall_main.gd:1132`) as the fly target and the pop target.

**Called by:** [[hall_main#_fly_hired_letter]] (`hall_main.gd:1132`). **Calls:** none.

## Suspected issues
- The comment above `roster_button` names `hall_main.send_hired_letter`, but the function is `_fly_hired_letter` (`tab_guild.gd:207`, `hall_main.gd:1129`).
- `SHOW_ROSTER_COUNT` and `SHOW_BARRACKS_LINK` are both `false`, so `SECTION_ROSTER`, `BEDS` and the Barracks button are not reachable at runtime.
