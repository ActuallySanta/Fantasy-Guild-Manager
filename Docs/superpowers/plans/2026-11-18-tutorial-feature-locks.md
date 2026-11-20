# Tutorial Feature Locks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything Pip's tutorial hasn't taught yet stays on screen as a blank, greyed, inert control, unlocking on the morning Pip teaches it.

**Architecture:** `OverlayTutorial.UNLOCK_DAY` becomes a feature table read through one query, `HallMain.is_locked(feature)`. `hall_main` actions refuse locked features silently. Each view calls one shared helper, `HallStyle.set_locked`, from its `refresh()`. Pip gets a Day 2 Applicants step, and two Day 1 lines that named now-blank controls are reworded.

**Tech Stack:** Godot 4.7, GDScript. No test framework: headless throwaway test scenes run in a scratch copy of the project.

**Spec:** `Docs/superpowers/specs/2026-11-18-tutorial-feature-locks-design.md` (read it first; this plan argues from it).

## Global Constraints

- Read `CLAUDE.md` first. Its conventions bind every task: GDScript naming, `##` doc comments on tunables and functions, `TEXT`/`NODES` sections, reach scripts by `class_name`, never `preload("res://….gd")`.
- Work on a new branch `tutorial-feature-locks` off `master`. Commit per task. Don't push.
- Locked feature rule (verbatim from spec): locked when `ENABLED and not is_skipped and GameState.day < UNLOCK_DAY[feature]`. A feature not in the table is never locked.
- Unlock days: `hire` 2, `hero_page` 2, `deny` 2, `upgrades` 3, `shop` 5.
- A locked control shows **no text, no badge, greyed, disabled**. It keeps its size, and nothing hides or collapses.
- A refused action does nothing: no toast, no text, no sound.
- Out of scope: the header (gold/standing counters and popups, Menu, day tile, Bone Drake countdown, danger strip), freeplay, and Day 3/5 scripts.
- No save change. Don't touch `HallSave`, and don't bump `SAVE_VERSION`.
- Don't change `can_hire_anyone()`. Run-over checks depend on it.
- Don't regenerate `Builds/`.

### Test harness (used by every task)

Tests live **only** in a scratch copy, at `Tests/` inside it. Never commit them, and never put `Tests/` in the repo.

Sync the repo into the scratch copy before every test run (PowerShell, from the repo root):

```powershell
$T = "$env:TEMP\fgm-lock-test"; robocopy . $T /MIR /XD .git .godot Builds .claude Tests /NFL /NDL /NJH /NJS | Out-Null; $p = "$T\project.godot"; [IO.File]::WriteAllText($p, ([IO.File]::ReadAllText($p) -replace 'config/name="Fantasy Guild Manager"', 'config/name="FGM Lock Test"'))
```

(The rename gives the copy its own `user://`, so a test can't touch Santi's real run save.)

The first time, and after adding a new test script, import the copy:

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "$env:TEMP\fgm-lock-test" --import
```

Run the test scene:

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "$env:TEMP\fgm-lock-test" res://Tests/test_feature_locks.tscn; "exit $LASTEXITCODE"
```

A pass prints `ALL PASS` and `exit 0`. A failure prints one `FAIL <name>: <detail>` line per failed check and `exit 1`.

`Tests/test_feature_locks.tscn` (create it once, in Task 1):

```
[gd_scene format=3]
[ext_resource type="Script" path="res://Tests/test_feature_locks.gd" id="1"]
[node name="Test" type="Node"]
script = ExtResource("1")
```

`Tests/test_feature_locks.gd` skeleton (Task 1 creates it, and each later task adds a `_test_*` function and calls it from `_ready`):

```gdscript
extends Node

var _failures := 0
var hall: HallMain

func _ready() -> void:
	hall = load("res://Scenes/hall_main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(hall)
	await _frames(5)
	hall.tutorial.is_skipped = false
	await _test_lock_rule()
	await _test_refusals()
	# Task 3 adds _test_pip_script(); Task 2 adds _test_views(),
	# _test_skip_unlocks(), _test_recall_not_locked(), _test_unlock_morning()
	print("ALL PASS" if _failures == 0 else "%d FAILED" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)

func _check(name: String, ok: bool, detail := "") -> void:
	if not ok:
		_failures += 1
		print("FAIL %s: %s" % [name, detail])

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

## Jump to `day` without the new_day event (so Pip doesn't start), then let the hall refresh.
func _at_day(day: int) -> void:
	GameState.day = day
	hall.queue_refresh()
	await _frames(3)
```

The test starts a new run on Day 1. The intro crawl is open, so Pip never starts, and Pip's own button locks don't interfere.

## Review Focus

1. **The morning a feature unlocks while Pip starts that day's script** (Day 2 → Day 3, the Guild nav button). Pip's `_apply_locks` remembers each button's `disabled` value. If it remembers the locked `true` before the hall's refresh unlocks the button, the spotlit button could stay dead. Expected: Pip's Day 3 first step can be tapped. → test in Task 2.
2. **Skip tutorial partway through Day 1.** Expected: every locked control gets its label back and works on the next refresh, with no reload. → test in Task 2.
3. **Deny's button after Send.** The same `LeftButton` reads Recall (sent) or Board (denied). Only the Deny state is locked. Expected: on Day 1 after sending, it reads "Recall", isn't greyed, and works. → test in Task 2.
4. **Members badge on Day 1.** Expected: no "N new" or "!" badge, since hiring isn't open yet. → tests in Task 1 (query) and Task 2 (badge).
5. **Biggest accessibility font size on a 720×1280 screen.** Expected: blank nav tabs and the blank Applicants tab keep their width and height, and the nav row doesn't reflow. → manual check in Task 4.

---

### Task 1: The feature table, `is_locked`, and actions that refuse

**Files:**
- Modify: `Scripts/UI/Overlays/Day/overlay_tutorial.gd` (header lines 57–58 "Tab pacing", `UNLOCK_DAY` line 69, `is_tab_locked`/`unlock_day` lines 220–228)
- Modify: `Scripts/Hall/hall_main.gd` (`TOAST_TAB_LOCKED` line 168, `is_tab_locked`/`tab_unlock_day` lines 659–666, `affordable_buildings` 672, `open_tab` 692, `open_character` 742, `deny_quest` 949, `hire` 1025, `upgrade_building` 1091, `unseen_recruit_count` 524)
- Test: `$env:TEMP\fgm-lock-test\Tests\test_feature_locks.gd` (+ `.tscn`), scratch only

**Interfaces:**
- Produces:
  - `OverlayTutorial.FEATURE_HIRE := "hire"`, `FEATURE_HERO_PAGE := "hero_page"`, `FEATURE_DENY := "deny"`. Tab features keep their tab ids `"upgrades"` and `"shop"`.
  - `OverlayTutorial.is_locked(feature: String) -> bool`.
  - `HallMain.is_locked(feature: String) -> bool`.
  - `HallMain.is_tab_locked(tab_id: String) -> bool` (kept as a one-line wrapper around `is_locked`).
- Removed: `OverlayTutorial.unlock_day` and `HallMain.TOAST_TAB_LOCKED`. `HallMain.tab_unlock_day` stays as a stub returning `0` until Task 2. `hall_nav.gd` and `tab_board.gd` still call it, and Task 2 removes those calls and then the stub.

- [ ] **Step 1: Create the test harness files and write the failing tests**

Create the `.tscn` and the skeleton above, then add:

```gdscript
func _test_lock_rule() -> void:
	var all := ["hire", "hero_page", "deny", "upgrades", "shop"]
	var open_by_day := {1: [], 2: ["hire", "hero_page", "deny"], 3: ["hire", "hero_page", "deny", "upgrades"], 5: all}
	for day in open_by_day:
		await _at_day(day)
		for feature in all:
			_check("day%d %s" % [day, feature], hall.is_locked(feature) == not open_by_day[day].has(feature))
	await _at_day(1)
	_check("board never locked", not hall.is_locked("board"))
	_check("unknown never locked", not hall.is_locked("nonsense"))
	hall.tutorial.is_skipped = true
	for feature in all:
		_check("skipped %s" % feature, not hall.is_locked(feature))
	hall.tutorial.is_skipped = false

func _test_refusals() -> void:
	await _at_day(1)
	var hero: GuildCharacter = hall.roster()[0]
	hall.open_character(hero)
	_check("day1 hero page refused", hall.active_screen.get("kind", "") != HallMain.SCREEN_CHARACTER)
	var tab_before: String = hall.active_tab
	hall.open_tab("upgrades")
	_check("day1 guild tab refused", hall.active_tab == tab_before)
	hall.open_tab("guild", HallMain.GUILD_SECTION_HIRE)
	_check("day1 applicants refused", hall.guild_section != HallMain.GUILD_SECTION_HIRE)
	_check("day1 no unseen recruits", hall.unseen_recruit_count() == 0)
	var roster_size := hall.roster().size()
	if not CharacterContainer.hireable_characters.is_empty():
		_check("day1 hire refused", not hall.hire(CharacterContainer.hireable_characters[0]) and hall.roster().size() == roster_size)
	hall.open_assign(0)
	hall.deny_quest()
	_check("day1 deny refused", hall.quest_entries[0].state != HallStyle.QUEST_STATE_DENIED)
	hall.close_screen()
	await _at_day(2)
	hall.open_character(hero)
	_check("day2 hero page opens", hall.active_screen.get("kind", "") == HallMain.SCREEN_CHARACTER)
	hall.close_screen()
	await _frames(2)
```

- [ ] **Step 2: Sync, import, run. Verify it fails**

Expected: a parse error or `FAIL` lines. `is_locked` doesn't exist yet.

- [ ] **Step 3: Implement the table and query in `overlay_tutorial.gd`**

- Replace `UNLOCK_DAY` with the five-entry table: `{"hire": 2, "hero_page": 2, "deny": 2, "upgrades": 3, "shop": 5}`. Give each entry a `##` comment naming what it covers and the Pip step that teaches it (see the spec's table).
- Add the three `FEATURE_*` constants next to it.
- Replace `is_tab_locked` with `is_locked(feature)` using the Global Constraints rule. Delete `unlock_day`.
- Rewrite the header's "Tab pacing" note (lines 57–58) as "Feature pacing": while the tutorial is on, untaught controls are blank and greyed (`UNLOCK_DAY`), and Skip tutorial lifts every lock.

- [ ] **Step 4: Implement the query and the refusals in `hall_main.gd`**

- `is_locked(feature) -> bool` returns `tutorial != null and tutorial.is_locked(feature)`. `is_tab_locked(tab_id)` calls `is_locked(tab_id)`.
- `affordable_buildings()` already returns `[]` while `"upgrades"` is locked. Keep it.
- `open_tab`: if the tab is locked, `return` (no toast). Also `return` if `tab_id == "guild"`, `section == GUILD_SECTION_HIRE` and `FEATURE_HIRE` is locked.
- `open_character`: `return` first thing if `FEATURE_HERO_PAGE` is locked.
- `deny_quest`: `return` first thing if `FEATURE_DENY` is locked.
- `hire`: `return false` first thing if `FEATURE_HIRE` is locked.
- `upgrade_building`: keep the guard, drop the toast.
- `unseen_recruit_count`: also return `0` while `FEATURE_HIRE` is locked.
- Delete `TOAST_TAB_LOCKED`. Leave `tab_unlock_day` returning `0` with a `## Deprecated: removed in Task 2` comment.

- [ ] **Step 5: Sync, run. Verify `ALL PASS`, `exit 0`**

- [ ] **Step 6: Commit**

```powershell
git add Scripts/UI/Overlays/Day/overlay_tutorial.gd Scripts/Hall/hall_main.gd; git commit -m "Add tutorial feature locks and refuse locked actions"
```

(End every commit message with the `Co-Authored-By` line from the session's attribution rule.)

---

### Task 2: Locked controls look blank, greyed and inert

**Files:**
- Modify: `Scripts/Hall/Style/hall_style.gd` (add `LOCKED_MODULATE` and `set_locked`; the file is ~690 lines, so it fits)
- Modify: `Scripts/UI/Shell/hall_nav.gd` (`BADGE_LOCKED` line 29, `setup` 45, `refresh` 59, `_badge_text_for` 79)
- Modify: `Scripts/UI/Tabs/tab_guild.gd` (`_is_hire_section` 97, `_show_section_buttons` 105)
- Modify: `Scripts/UI/Rows/Quests/today_item.gd` (`set_item`)
- Modify: `Scripts/UI/Tabs/tab_board.gd` (`UPGRADES_LOCKED` 25, `_show_recruits_box` 77, `_show_upgrades_box` 95)
- Modify: `Scripts/UI/Screens/screen_assign.gd` (`_show_footer` 406, the No Roster box near 377)
- Modify: `Scripts/UI/Rows/Quests/pick_row.gd` (`setup` 52)
- Modify: `Scripts/UI/Rows/Heroes/member_card.gd` (`setup` 52)
- Modify: `Scripts/Hall/hall_main.gd` (delete `tab_unlock_day`)
- Modify (only if `_test_unlock_morning` fails): `Scripts/UI/Overlays/Day/overlay_tutorial.gd` (`start` ~238)
- Test: scratch `Tests/test_feature_locks.gd`

**Interfaces:**
- Consumes: `HallMain.is_locked`, `OverlayTutorial.FEATURE_*` (Task 1).
- Produces:
  - `HallStyle.LOCKED_MODULATE := Color(0.55, 0.55, 0.55, 0.7)`. Documented as the tint a locked control is greyed with.
  - `HallStyle.set_locked(control: Control, is_locked: bool, label: String = "") -> void`. On a `BaseButton` with `text` (i.e. a `Button`): text becomes `""` when locked and `label` when unlocked, and `disabled` becomes `is_locked`. On any Control: `modulate` becomes `LOCKED_MODULATE` when locked and `Color.WHITE` when unlocked. Icons stay, greyed by the modulate. Callers hide badges themselves.

- [ ] **Step 1: Write the failing tests**

Add `_test_views()`, `_test_skip_unlocks()`, `_test_recall_not_locked()` and `_test_unlock_morning()`, and call them from `_ready` in that order. A helper finds the first row built from a script:

```gdscript
func _row(root: Node, script_file: String) -> Control:
	for node in root.find_children("*", "Control", true, false):
		var script = node.get_script()
		if script is Script and script.resource_path.get_file() == script_file:
			return node
	return null

func _test_views() -> void:
	await _at_day(1)
	var nav_guild_tab: Button = hall.nav_button("upgrades")
	_check("d1 nav guild blank", nav_guild_tab.text == "" and nav_guild_tab.disabled and nav_guild_tab.modulate == HallStyle.LOCKED_MODULATE)
	_check("d1 nav guild no badge", not nav_guild_tab.get_node("Badge").visible)
	_check("d1 nav items blank", hall.nav_button("shop").text == "")
	_check("d1 nav quests label", hall.nav_button("board").text == "Quests")
	_check("d1 members no badge", not hall.nav_button("guild").get_node("Badge").visible)
	var board: Node = hall._tabs.board
	_check("d1 recruits note blank", board.get_node("%TodayRecruits").get_node("%Title").text == "")
	_check("d1 upgrades note blank", board.get_node("%TodayUpgrades").get_node("%Title").text == "")
	hall.open_tab("guild", HallMain.GUILD_SECTION_ROSTER)
	await _frames(3)
	var guild: Node = hall._tabs.guild
	_check("d1 applicants blank", guild.get_node("%SegHire").text == "" and guild.get_node("%SegHire").disabled)
	_check("d1 applicants no badge", not guild.get_node("%HireBadge").visible)
	_check("d1 member caret hidden", not _row(guild, "member_card.gd").get_node("%Chevron").visible)
	hall.open_assign(0)
	await _frames(3)
	var assign: Node = hall._screens[HallMain.SCREEN_ASSIGN]
	_check("d1 deny blank", assign.get_node("%LeftButton").text == "" and assign.get_node("%LeftButton").disabled)
	_check("d1 deny cost hidden", not assign.get_node("%DenyCost").visible)
	_check("d1 info locked", _row(assign, "pick_row.gd").get_node("%InfoButton").disabled)
	hall.close_screen()
	await _at_day(2)
	_check("d2 applicants label", guild.get_node("%SegHire").text == "Applicants")
	_check("d2 recruits note", board.get_node("%TodayRecruits").get_node("%Title").text == "Recruits")
	_check("d2 upgrades note still blank", board.get_node("%TodayUpgrades").get_node("%Title").text == "")
	hall.open_assign(0)
	await _frames(3)
	_check("d2 deny label", assign.get_node("%LeftButton").text == "Deny" and not assign.get_node("%LeftButton").disabled)
	hall.close_screen()
	await _at_day(3)
	_check("d3 nav guild label", nav_guild_tab.text == "Guild" and not nav_guild_tab.disabled and nav_guild_tab.modulate == Color.WHITE)
	await _at_day(5)
	_check("d5 nav items label", hall.nav_button("shop").text == "Items")

func _test_skip_unlocks() -> void:
	await _at_day(1)
	hall.tutorial.skip_tutorial()
	await _frames(3)
	_check("skip nav guild", hall.nav_button("upgrades").text == "Guild" and not hall.nav_button("upgrades").disabled)
	_check("skip applicants", hall._tabs.guild.get_node("%SegHire").text == "Applicants")
	hall.tutorial.is_skipped = false
	hall.queue_refresh()
	await _frames(3)

func _test_recall_not_locked() -> void:
	await _at_day(1)
	hall.open_assign(0)
	hall.toggle_in_party(hall.roster()[0])
	await _frames(3)
	var left: Button = hall._screens[HallMain.SCREEN_ASSIGN].get_node("%LeftButton")
	_check("d1 recall usable", left.text != "" and not left.disabled and left.modulate == Color.WHITE, left.text)
	hall.recall_party()
	hall.close_screen()
	await _frames(3)

func _test_unlock_morning() -> void:
	await _at_day(2)
	hall.tutorial.done.erase(3)
	hall.tutorial.start(2)
	await _frames(5)
	GameState.day = 3
	hall.queue_refresh()
	hall.tutorial_event.emit("new_day", 3)
	await _frames(10)
	_check("d3 pip spotlight usable", not hall.nav_button("upgrades").disabled)
	hall.tutorial.skip_tutorial()
	hall.tutorial.is_skipped = false
```

(`_test_unlock_morning` covers Review Focus 1. If it fails, fix it in `overlay_tutorial.gd`: when Pip records a button's own `disabled` value, record `false` for a button whose feature just unlocked. The simplest fix is to clear `_locked` in `start()` after the hall's refresh: call `_release_locks()` at the top of `start()`. Keep whatever fix is smallest, and comment it.)

- [ ] **Step 2: Sync, run. Verify the new checks FAIL**

- [ ] **Step 3: Add `LOCKED_MODULATE` and `set_locked` to `hall_style.gd`** (signatures above; `##` doc comments)

- [ ] **Step 4: Lock the nav (`hall_nav.gd`)**

- In `setup`, remember each nav button's scene label (`_labels[tab_id] = nav_button.text`).
- In `refresh`, call `HallStyle.set_locked(nav_button, hall.is_tab_locked(tab_id), _labels[tab_id])`.
- `_badge_text_for` returns `""` for a locked tab. Delete `BADGE_LOCKED`.
- The `"guild"` branch returns `""` while `FEATURE_HIRE` is locked. That covers both `!` and "N new".

- [ ] **Step 5: Lock Applicants (`tab_guild.gd`)**

- `_is_hire_section()` is also false while `FEATURE_HIRE` is locked.
- After setting `_hire_section_button.text`, call `set_locked(_hire_section_button, hire_locked, SECTION_HIRE)`.
- `_hire_badge.visible` also needs `not hire_locked`.
- If `SHOW_BARRACKS_LINK`, apply `set_locked(_barracks_button, hall.is_tab_locked("upgrades"), BEDS_BUTTON)`. It's off today, but wire it anyway.

- [ ] **Step 6: Lock the Board's Today notes (`today_item.gd`, `tab_board.gd`)**

- `set_item` accepts look `"locked"`: title and value become `""`, and it calls `HallStyle.set_locked(self, true)`. Every other look calls `HallStyle.set_locked(self, false)`. Update the `look:` doc comment.
- `_show_recruits_box` first checks `hall.is_locked(OverlayTutorial.FEATURE_HIRE)`. If true, it calls `set_item("", "", "nav_characters", "locked")` and returns.
- `_show_upgrades_box` does the same when the upgrades tab is locked. Delete `UPGRADES_LOCKED`.
- Delete `HallMain.tab_unlock_day` now that nothing calls it. Grep to confirm there are no callers.

- [ ] **Step 7: Lock Deny and the Hire link (`screen_assign.gd`)**

- In `_show_footer`'s default (Deny) branch, when `FEATURE_DENY` is locked: `_left_button.icon` stays `x`, `_deny_cost.visible = false`, and it calls `set_locked(_left_button, true)`. The unlocked Deny branch and the Recall/Board branches call `set_locked(_left_button, false, <their label>)`, so the text, `disabled` and modulate always reset.
- Where the No Roster box's visibility is set, call `set_locked(_hire_button, hall.is_locked(FEATURE_HIRE), <its current text>)`. Read its text once in `setup` and keep it in a variable.

- [ ] **Step 8: Lock hero pages (`pick_row.gd`, `member_card.gd`)**

- `pick_row.setup` calls `HallStyle.set_locked(_info_button, hall.is_locked(OverlayTutorial.FEATURE_HERO_PAGE))`. It's icon-only, so `label` is `""` either way.
- `member_card.setup` sets `_chevron.visible = not hall.is_locked(OverlayTutorial.FEATURE_HERO_PAGE)`. Its tap already does nothing, because `open_character` refuses.

- [ ] **Step 9: Sync, run. Verify `ALL PASS`, `exit 0`** (the Task 1 checks too)

- [ ] **Step 10: Commit**

```powershell
git add Scripts/Hall/Style/hall_style.gd Scripts/UI/Shell/hall_nav.gd Scripts/UI/Tabs/tab_guild.gd Scripts/UI/Tabs/tab_board.gd Scripts/UI/Rows/Quests/today_item.gd Scripts/UI/Screens/screen_assign.gd Scripts/UI/Rows/Quests/pick_row.gd Scripts/UI/Rows/Heroes/member_card.gd Scripts/Hall/hall_main.gd Scripts/UI/Overlays/Day/overlay_tutorial.gd; git commit -m "Show untaught controls blank and greyed"
```

---

### Task 3: Pip's script and the design doc

**Files:**
- Modify: `Scripts/UI/Overlays/Day/overlay_tutorial.gd` (header lines 7–13, `_day_one` 950, `_day_two` 991)
- Modify: `Docs/hall_design.md` (line 37, plus a new "Tutorial pacing" section after "Intro crawl", ~line 109)
- Modify: `Docs/superpowers/specs/2026-11-18-tutorial-feature-locks-design.md` (Status line becomes "approved, implemented")
- Test: scratch `Tests/test_feature_locks.gd`

**Interfaces:**
- Consumes: `OverlayTutorial._day_one()` / `_day_two()` return Arrays of step Dictionaries. `text` is a String or a Callable.

- [ ] **Step 1: Write the failing test**

```gdscript
func _step_text(step: Dictionary) -> String:
	return step["text"].call() if step["text"] is Callable else step["text"]

func _test_pip_script() -> void:
	for step in hall.tutorial._day_one():
		var text := _step_text(step)
		_check("d1 no Applicants tab line", not text.contains("Applicants tab"), text)
		_check("d1 no upgrades line", not text.contains("available upgrades"), text)
	var day_two: Array = hall.tutorial._day_two()
	var back_index := day_two.find_custom(func(step): return step.get("do", "") == "Tap Back")
	var hire_index := day_two.find_custom(func(step): return step.get("do", "") == "Tap Applicants")
	_check("d2 applicants step after Back", hire_index == back_index + 1, "%d %d" % [back_index, hire_index])
	_check("d2 applicants step waits for hire section", day_two[hire_index].get("on", "") == "tab" and day_two[hire_index]["when"].call({"guild": "hire"}) and not day_two[hire_index]["when"].call({"guild": "roster"}))
```

Call `await _test_pip_script()` from `_ready`, after `_test_lock_rule`.

- [ ] **Step 2: Sync, run. Verify it FAILS**

- [ ] **Step 3: Reword the two Day 1 lines**

- Uncle John step text: `"Look! Here is [b]%s[/b], a priest and your first member. More heroes will come looking for work starting tomorrow." % HallRules.STARTING_HERO_NAME`
- End Day sheet step text: `"Here you can check tonight's plan before the day ends. Tap [b]End Day[/b] to finish your choices."`

- [ ] **Step 4: Add the Day 2 Applicants step** right after the `"Tap Back"` step:

```gdscript
{"target": func(): return _u(_tab("guild"), "SegHire"), "on": "tab", "when": func(d): return d.guild == "hire",
	"do": "Tap Applicants", "text": "New heroes come looking for work every morning. Hiring costs %s, and your beds limit how many you can keep." % GOLD},
```

Update the header's Day 2 line to include "Applicants (new heroes each morning, hiring)".

- [ ] **Step 5: Sync, run. Verify `ALL PASS`, `exit 0`**

- [ ] **Step 6: Update `Docs/hall_design.md`**

- Line 37: replace "the Board's box says when it opens" with "the Board's box sits blank and greyed until then".
- Add a `## Tutorial pacing` section after "Intro crawl", a few lines long. While Pip's tutorial is on, controls it hasn't taught yet keep their place but show no text or badge, are greyed, and do nothing (`OverlayTutorial.UNLOCK_DAY`):
  - Applicants, hero pages and Deny open on Day 2.
  - The Guild tab opens on Day 3, and Items on Day 5.
  - Skip tutorial lifts them all.
  - Locks come from the day and the saved skip flag, so saves are unchanged.
- `README.md` doesn't describe the tab locks (checked), so leave it as is.

- [ ] **Step 7: Commit**

```powershell
git add Scripts/UI/Overlays/Day/overlay_tutorial.gd Docs/hall_design.md Docs/superpowers/specs/2026-11-18-tutorial-feature-locks-design.md Docs/superpowers/plans/2026-11-18-tutorial-feature-locks.md; git commit -m "Teach Applicants on Day 2 and document tutorial pacing"
```

---

### Task 4: Play it through (verification only, no code)

- [ ] **Step 1:** Run `Scenes/hall_main.tscn` in the editor (F5) with a new run, and play Day 1 through Day 5 with Pip on.
  - On each morning, check that the features for that day (see the table) come back with labels.
  - Check that Pip's Day 2 Applicants step spotlights the Applicants tab, and Day 3's first step can be tapped.
  - Expected: nothing untaught shows text, and Pip never gets stuck.
- [ ] **Step 2:** New run, then Skip tutorial on Day 1's first step. Expected: every tab and button is labelled and works right away.
- [ ] **Step 3:** Menu > Accessibility, largest text, at 720×1280. Expected (Review Focus 5): on Day 1, the blank Guild/Items nav tabs and the blank Applicants tab are the same size as their labelled neighbours, and nothing scrolls sideways.
- [ ] **Step 4:** Report what was checked and anything that looked wrong, with screenshots. Don't push or open a PR without asking.
