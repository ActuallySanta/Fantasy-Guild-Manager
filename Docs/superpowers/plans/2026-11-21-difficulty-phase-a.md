# Difficulty Phase A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the main 50 days harder in a readable way:
- a difficulty staircase with a boss every 10 days
- standing lost on a failed quest
- injuries that follow the odds, plus a retreat hit on a loss
- deaths only on failure, or for heroes sent out hurt
- a slower Hospital
- the boss quests and lead-up side quests that are already written but not wired up
- a countdown to the next boss
- a text crawl for each boss fight

**Architecture:**
- **Tuning and rules** go in static scripts: `HallRules` and a new `QuestInjuries`.
- **Quest content setup** stays in `CreatedQuest._initMilestoneVars`.
- **The boss crawl** is a new authored overlay. It shares its story and party sections with the credits roll through a new component scene.
- **`hall_main.gd`** only gains thin wrappers and one state variable.

**Tech Stack:** Godot 4.7, GDScript. Tests are headless scenes run in a scratch copy of the project (Task 0).

**Spec:** `Docs/superpowers/specs/2026-11-21-difficulty-and-dilemmas-design.md`. Read it first; this plan argues from it.

## Executive summary

- **Task 0:** a small headless test runner, so every later task can prove itself.
- **Tasks 1-2:**
  - The difficulty staircase: about +1% a day from day 5, a ×1.35 spike on boss days (×1.15 for the Demon King), and +15% after each boss.
  - The requirement math generalized to any party size.
- **Tasks 3-4:** wire up the boss quests on days 20, 30, 40 and 50, and the 13 lead-up side quests. The stories already exist in `External Content/`. Task 3 also fixes the Demon King's wrong victory line.
- **Task 5:** a failed quest costs half the standing a win pays. The cost is shown on Assign Party and in the Day Report.
- **Task 6:** injuries per hero follow the odds, whatever the rank. A loss adds one retreat injury to every hero, and protected heroes can't die on a won quest.
- **Task 7:** the slower Hospital.
- **Task 8:** the header counts down to the next boss.
- **Task 9:** the boss crawl overlay.
- **Task 10:** an AI playtest, then tuning until the spec's targets hold.
- **Docs:** each task updates `Docs/hall_design.md`, `README.md` or `CLAUDE.md` for what it changes.
- **Out of scope:** everything in phase B (`Docs/superpowers/plans/2026-11-21-difficulty-phase-b.md`).

## Global Constraints

- Godot 4.7, GDScript only. No new autoloads, and no `static var` for run state (CLAUDE.md).
- Tuning numbers are `const` at the top of the file that owns them, each with a `##` doc comment giving its units.
- New code uses snake_case. Don't rename the legacy camelCase in `quest_resource.gd` (`goldReward`, `questNum`, `maxAdventurers`, `generateResults`, `calcSuccessChance`, `_initMilestoneVars`).
- Reach scripts by `class_name`, and load scenes by `uid://` with the path in a trailing comment. Hand-written `.tscn` files need `uid=` in the header and on each `ext_resource`.
- Save compatibility: add fields only, and read them with `.get(key, default)`. No `SAVE_VERSION` bump.
- Only the requirement scales before day 50, never the gold (PR #76's upgrade costs depend on today's pay).
- The no-new-mechanics rule: every change shows through the odds, the odds word, gold, standing, a price on a button, or the header.
- Starting values, copied from the spec:

| Constant | Value |
|---|---|
| `DIFFICULTY_DRIFT_PER_DAY` | 0.01 |
| `DIFFICULTY_STEP_PER_BOSS` | 0.15 |
| `BOSS_SPIKE` | 1.35 |
| `FINAL_BOSS_SPIKE` | 1.15 |
| Injury table (fight injuries per hero, by odds) | ≥130%: 0.1, 100%: 0.2, 90%: 0.35, 80%: 0.5, 70%: 0.7, 60%: 0.9, ≤50%: 1.2 |
| `HOSPITAL_STAGES_PER_NIGHT` | `[1, 1, 2, 2, 2]` |
| Standing lost on a failed quest | `ceil((rank + 1) / 2)` |

- `hall_main.gd` is over the soft limit. New logic goes elsewhere, and `hall_main` gets only thin wrappers.

## Review Focus

1. **A hero who starts Hurt and is sent on a won quest can still die,** and a hero who starts Sore can't. The boundary is `LIGHTLY_INJURED`, which shows in-game as "Hurt". Test in Task 6.
2. **An old save with a quest already on the board** keeps that quest's saved `requirement_multiplier`, and doesn't get rescaled on load. Test in Task 1.
3. **A boss quest sent with fewer heroes than its slots** (for example 3 heroes against the 8-slot Demon King) shows lower odds, and still plays out and pays. Test in Task 2.
4. **Standing near the floor:** a failed quest at `MINIMUM_STANDING + 1` lands exactly on the floor, never below it. Test in Task 5.
5. **Day 20 and day 40 with one boss won and one lost:** the crawl shows both results correctly, and the Day Report still opens after Continue. Test in Task 9.

---

### Task 0: Headless test runner

**Files:**
- Create: `tools/tests/run_test.sh`, `tools/tests/test_case.gd` (`class_name TestCase`)
- Modify: `export_presets.cfg`: add `tools/*` to every preset's `exclude_filter`.
- Modify: `CLAUDE.md`, "Running and testing": one line on `tools/tests/`.

**Interfaces:**
- Produces:
  - `TestCase` (`extends Node`) with:
    - `check(condition: bool, message: String) -> void`, which records a failure and prints `TEST FAIL <message>`.
    - `check_near(actual: float, expected: float, tolerance: float, message: String) -> void`
    - `finish() -> void`, which prints `TEST PASS <scene name>` or `TEST FAILED <n>` and calls `get_tree().quit(0 or 1)`.
  - Every later test is `tools/tests/<name>_test.gd` (`extends TestCase`), with a matching `.tscn` whose root node runs the checks in `_ready()` and then calls `finish()`.
  - `bash tools/tests/run_test.sh <name>`:
    - Prepares a scratch copy with `tools/playtest/prepare.sh`, reusing `$TEST_SCRATCH` if it's set (otherwise `$(mktemp -d)`).
    - Runs `--headless --path <copy> res://tools/tests/<name>_test.tscn`.
    - Exits with Godot's exit code and prints the `TEST` lines.

- [ ] **Step 1:** write `tools/tests/smoke_test.gd` and its `.tscn`. It checks `GuildUpgrades.MAX_LEVEL == 5` and `HallRules.quests_per_day(11) == 5`, then calls `finish()`.
- [ ] **Step 2:** run `bash tools/tests/run_test.sh smoke`. Expected: `TEST PASS smoke_test`, exit 0.
- [ ] **Step 3:** change the smoke check to `== 6` and run it again. Expected: `TEST FAIL`, exit 1. Then revert the change.
- [ ] **Step 4:** add `tools/*` to every `exclude_filter` line in `export_presets.cfg`, and add the CLAUDE.md line.
- [ ] **Step 5:** commit: `test: headless test runner in tools/tests`.

---

### Task 1: Boss schedule and the difficulty staircase

**Files:**
- Modify: `Scripts/Hall/Rules/hall_rules.gd`. New SETTINGS constants and functions, and `build_day_quests` applies the scale to normal quests.
- Test: `tools/tests/difficulty_scale_test.gd` / `.tscn`

**Interfaces:**
- Produces (all `static` on `HallRules`):
  - `const BOSS_DAYS := [10, 20, 30, 40, 50]` (the last one is `HallMain.FINAL_DAY`)
  - `const DIFFICULTY_START_DAY := 5`, and the four tuning constants from Global Constraints
  - `is_boss_day(day: int) -> bool`
  - `bosses_before(day: int) -> int`: the number of `BOSS_DAYS` that are `< day`
  - `next_boss_day(day: int) -> int`: the first `BOSS_DAYS` entry `>= day`, or `-1` when none is left
  - `difficulty_scale(day: int) -> float`: `1.0` for `day < 5`, otherwise `1.0 + DRIFT × (min(day, FINAL_DAY) − 4) + STEP × bosses_before(min(day, FINAL_DAY))`
  - `requirement_scale(day: int, is_boss: bool, is_final: bool) -> float`: `difficulty_scale(day) × (FINAL_BOSS_SPIKE if is_final else BOSS_SPIKE if is_boss else 1.0) × freeplay_scale(day)`

- [ ] **Step 1: Write the failing test.**
  - `difficulty_scale`: 1.0 on day 4, 1.01 on day 5, 1.05 on day 9, 1.06 on day 10, 1.22 on day 11, 1.47 on day 21, 1.72 on day 31, 1.97 on day 41, 2.05 on day 49.
  - The day-50 freeze: `difficulty_scale(50) == difficulty_scale(70)`.
  - `requirement_scale(10, true, false)` is about 1.06 × 1.35.
  - `requirement_scale(50, true, true)` is about `difficulty_scale(50) × 1.15`.
  - `requirement_scale(60, false, false)` is about `difficulty_scale(50) × 1.2`.
  - `next_boss_day(11) == 20`, `next_boss_day(50) == 50`, `next_boss_day(51) == -1`, and `bosses_before(10) == 0`.
  - On day 25, every quest from `build_day_quests(25, 60, false)` has `requirement_multiplier` about `difficulty_scale(25)`, and `goldReward` is unchanged from an unscaled quest of the same rank and size. Compare `startingGoldReward` with `100+125r`, `150+175r` or `200+225r`.
  - **Review Focus 2:** a `CreatedQuest` with `requirement_multiplier = 1.0`, saved and restored with `HallSave`'s quest encoding, keeps 1.0.
- [ ] **Step 2:** run `bash tools/tests/run_test.sh difficulty_scale`. Expected: FAIL, because `difficulty_scale` isn't declared.
- [ ] **Step 3:** implement the functions. In `build_day_quests`, after each normal quest is made, set `quest.requirement_multiplier = requirement_scale(day, false, false)`, and keep `apply_freeplay_scaling` for gold only. To do that, split it into `CreatedQuest.apply_freeplay_gold(multiplier: float)`, which scales `goldReward` and `startingGoldReward` only. `apply_freeplay_scaling` stays as a wrapper that calls it and sets the multiplier, so existing callers don't break. Bosses are built in Task 3.
- [ ] **Step 4:** run the test. Expected: PASS.
- [ ] **Step 5:** in `Docs/hall_design.md`, add a "Difficulty" paragraph: the staircase, the spikes, and that it shows as odds. Commit: `feat(rules): difficulty staircase with boss spikes`.

---

### Task 2: Requirement for any party size

**Files:**
- Modify: `Scripts/Quest Creator/quest_resource.gd` `calcSuccessChance`. Replace the 1-slot and 3-slot special cases with `statHitNum *= QuestScoring.get_slot_count(self) / 2.0`.
- Test: `tools/tests/slot_factor_test.gd`

**Interfaces:**
- Consumes: `QuestScoring.get_slot_count(quest) -> int`
- Produces: unchanged odds for 1, 2 and 3 slots, and ×2.5 for 5 and ×4 for 8.

- [ ] **Step 1: Write the failing test.**
  - Build quests at rank 3 with `maxAdventurers` of 1, 2, 3, 5 and 8, all with the same fixed party of heroes with set stats.
  - The 1-, 2- and 3-slot chances equal what the old formula gives. Hard-code the expected numbers, computed from the current code before you change it.
  - `chance(5 slots) == chance(2 slots) / 2.5` within 1.
  - `chance(8 slots) == chance(2 slots) / 4` within 1.
  - **Review Focus 3:** an 8-slot quest with a 3-hero party returns a chance greater than 0, and `generateResults` returns text containing either "SUCCESSFUL" or `QuestScoring.FAIL_MARKER`.
- [ ] **Step 2:** run it. Expected: FAIL on the 5- and 8-slot assertions.
- [ ] **Step 3:** implement the one-line change.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** commit: `feat(quests): requirement scales with any party size`.

---

### Task 3: Boss quests on days 20, 30, 40 and 50

**Files:**
- Modify: `Scripts/Quest Creator/quest_resource.gd`:
  - `_init`'s `match(dayNum)` list: add `20, -20, 30, 40, -40, 50`. Today day 20 isn't in the list, so its bosses are never built.
  - `_initMilestoneVars`: new cases `30`, `40`, `-40` and `50`.
- Modify: `Scripts/Hall/Rules/hall_rules.gd` `build_day_quests`:
  - Every `BOSS_DAYS` day returns only its boss entries, all with `milestone = true`. Day 50's entry also has `final = true`.
  - Replace the `18, 20` branch: day 18 keeps its two minor quests, and day 20 moves into the boss path.
  - Delete the FINAL QUEST CONTENT placeholder block and its comments.
- Modify: `External Content/Quest Stuff (Test)/Milestone Story Parts.txt` row `6`: replace the last field's copied line ("She warns that THE DEMON KING will soon be upon you…") with a victory line that ends the main story. Wording: *"The battle against THE DEMON KING has been WON! The realm is safe, and your guild's name will be sung for generations, Guildmaster!"*, in the row's existing BBCode style.
- Modify: `Scripts/UI/Screens/screen_assign.gd`: 8 party seats must fit at 720 wide. If the seat list is an HBox, change it to an `HFlowContainer` or a 4-column `GridContainer`.
- Test: `tools/tests/boss_days_test.gd`

**Interfaces:**
- Consumes: `HallRules.requirement_scale`, `HallRules.BOSS_DAYS`
- Produces: `build_day_quests(day, standing, false)` on each boss day returns:

| Day | Entries | `maxAdventurers` | `difficulty` | `favStat` | `regionNum` | `questNum` |
|---|---|---|---|---|---|---|
| 10 | 1 | 3 | 2 (C, as today) | Defense | 1 | 0 |
| 20 | 2 | 3, 3 | 3, 3 | Power / Wisdom | 2 / 3 | 1 / 2 |
| 30 | 1 | 5 | 3 | Sleaze | 2 (Ashen Wastes) | 3 |
| 40 | 2 | 4, 5 | 4, 4 | PowerAndDefense / WisdomAndSleaze | 1 (Boglands) / 3 (Glass Mountains) | 4 / 5 |
| 50 | 1 | 8 | 5 | Pluck | 0 (Windswept Meadows) | 6 |

  - **Region indices:** these come from the order in `REGION_FAVORED_STAT`'s doc comment: 0 Windswept Meadows, 1 Boglands, 2 Ashen Wastes, 3 Glass Mountains. Put the region name in a comment next to each hard-coded index.
  - **Gold:** `goldReward = 300 + 150 × difficulty`, as today.
  - **Requirement:** `requirement_multiplier = requirement_scale(day, true, day == HallMain.FINAL_DAY)`.
  - **Titles:**
    - Day 30: "Close the Blood Moon Cult's portal and defeat the DEMON GENERAL!"
    - Day 40: "Unmask and defeat the DEMON GENERAL KING BERNARD!" and "Unmask and defeat the DEMON GENERAL KING ALASTAIR!"
    - Day 50: "Face THE DEMON KING!"

    **Plan's call:** the minor-quest stories reveal King Bernard as the Power and Defense general and King Alastair as the Wisdom and Sleaze one.
  - **Spec deviation:** the spec suggested ranks D/C/B/A/S. Day 10 keeps rank 2 and day 20 keeps rank 3, as today, so the Drake's tutorial tuning doesn't move. Days 30, 40 and 50 use 3, 4 and 5.

- [ ] **Step 1: Write the failing test.** For each row of the table, assert the entry count, `maxAdventurers`, `difficulty`, `favStat`, `milestone == true`, and `final == (day == 50)`. Also:
  - `requirement_multiplier` is about the expected `requirement_scale`.
  - `get_Milestone_story(6, 5)` doesn't contain "She warns".
  - `build_day_quests(18, 60, false).size() == 2`.
- [ ] **Step 2:** run it. Expected: FAIL. Day 30 returns 5 random quests.
- [ ] **Step 3:** implement. `FavoredStat.Pluck = 4` is already summed twice in `calcSuccessChance`, so no change is needed there.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** run the game with the Debug tools jump-to-day (or `Scenes/Playtest/scenario_final_battle.tscn`), open the Demon King's Assign Party, and screenshot it with 8 seats. Expected: all 8 seats are visible, with no horizontal scroll.
- [ ] **Step 6:**
  - `README.md`: in the daily-loop lines, add the boss schedule (Drake on day 10, the Necromancer on 20, the Demon Generals on 30 and 40, the Demon King on 50).
  - `CLAUDE.md`: update the Project line the same way.
  - `Docs/hall_design.md`: add the bosses section.
  - Commit: `feat(quests): boss fights on days 20-50 from the written stories`.

---

### Task 4: Lead-up side quests (MinorVariables rows 9-21)

**Files:**
- Modify: `Scripts/Quest Creator/quest_resource.gd`:
  - `_init`'s `match(dayNum)` list.
  - The `_:` branch's `storyNum` match in `_initMilestoneVars`.
- Modify: `Scripts/Hall/Rules/hall_rules.gd` `build_day_quests`: the `match(GameState.day)` that sets `noRepeatQuests` gains the new days.
- Test: `tools/tests/lead_up_quests_test.gd`

**Interfaces:**
- Produces: on each day below, the first quest on the board is the minor quest for that `storyNum` row (`styleOfQuest == 1`, title from MinorVariables column 6). The rest of the board is normal quests.

| Day | Row | Day | Row | Day | Row |
|---|---|---|---|---|---|
| 22 | 9 | 32 | 13 | 38 | 16 |
| 24 | 10 | 33 | 14 | 39 | 18 |
| 26 | 11 | 34 | 15 | 42 | 19 |
| 28 | 12 | 36 | 17 | 45 | 20 |
| | | | | 48 | 21 |

**Plan's call:** all three "AWOL Advisor" versions appear. Row 15 reveals Bernard, row 17 reveals Alastair, and row 16 reveals both, so it comes last, just before day 40.

- [ ] **Step 1: Write the failing test.** For each day in the table, `build_day_quests(day, 60, false)[0].quest.questTitle` equals row N's title, read with `ExternalContentContainer.get_Minor_Story_Variables(N, 6)`, and `styleOfQuest == 1`. On day 23, no entry has `styleOfQuest == 1`.
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** implement. Make sure the normal quests on those days still apply `requirement_scale` (Task 1), and the minor quest gets it too.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** commit: `feat(quests): wire the lead-up side quests to the boss story`.

---

### Task 5: A failed quest costs standing

**Files:**
- Modify: `Scripts/Hall/Rules/hall_rules.gd`:
  - Add `standing_for_loss(quest: CreatedQuest) -> int`, which returns `ceili((quest.difficulty + 1) / 2.0)`.
  - In `play_quest`, a win keeps `standing_earned = standing_for_win(quest)`.
  - On a loss, `standing_earned = -mini(standing_for_loss(quest), maxi(GameState.standing - GuildUpgrades.MINIMUM_STANDING, 0))`, applied with `GameState.add_standing(standing_earned)`.
  - The clamp has to live here. `GuildUpgrades.add_standing` and `reduce_standing` don't clamp, and denying quests is left as it is.
- Modify: `Scripts/UI/Screens/screen_assign.gd`. The standing chip text becomes `TEXT_STANDING := "Win +%d · Fail −%d standing"`, using `[standing_for_win(quest), standing_for_loss(quest)]`.
- Modify: `Scripts/UI/Overlays/Day/overlay_report.gd` and `Scripts/UI/Rows/Day End/report_entry.gd`: a negative `result.standing` shows as "−N standing" in `HallStyle.RED`. Check every place that formats `result.standing` or sums it.
- Modify: `Scripts/Playtest/agent_bridge_state.gd`: each quest gains `"standing_win"` and `"standing_fail"`.
- Test: `tools/tests/standing_loss_test.gd`

**Interfaces:**
- Produces: `HallRules.standing_for_loss(quest) -> int`. `play_quest`'s result `"standing"` can be negative.

- [ ] **Step 1: Write the failing test.**
  - `standing_for_loss` is 1 at rank 0 (F), 1 at rank 1, 2 at rank 2, 2 at rank 3, 3 at rank 4 and 3 at rank 5.
  - Force a loss by playing a rank-5 quest with a 1-stat hero, retrying until it fails, with at most 50 tries. Standing drops by 3.
  - **Review Focus 4:** start at `MINIMUM_STANDING + 1`, force a rank-5 loss, and standing is `MINIMUM_STANDING`.
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** implement the rules and UI changes.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** in the game, open Assign Party and lose a quest. Screenshot the chip and the Day Report line. Expected: "Win +6 · Fail −3 standing", and a red "−3 standing" in the report.
- [ ] **Step 6:** add the rule to `Docs/hall_design.md`. Commit: `feat(rules): failed quests cost half a win's standing`.

---

### Task 6: Injuries follow the odds, the retreat, and the death rule

**Files:**
- Create: `Scripts/Quest Creator/quest_injuries.gd` (`class_name QuestInjuries`, static only)
- Modify: `Scripts/Character Generator/character_resource.gd`: `injure_character(can_die: bool = true) -> bool`. When `can_die` is false and the hit would make them `DEAD`, they stop at `GRAVELY_INJURED` and it returns false.
- Modify: `Scripts/Quest Creator/quest_resource.gd`:
  - **`generateResults`:**
    - At the start, roll the outcome once: `var will_fail := randi_range(0, 100) >= _successChance`. That's the same probability as the end-of-quest roll it replaces, and it's stored for the existing end branch to use.
    - Also at the start, record each hero's starting `injury_level`.
  - **`_combatEncounter`:**
    - Whether someone is injured is rolled with `QuestInjuries.injury_chance_per_encounter(_successChance, difficulty, party_size)`.
    - The story band is then picked to match: an injury band when hit, a clean band when not.
    - The injured hero is `pick_random()`.
    - The hit calls `injure_character(can_die)`, where `can_die = will_fail or starting_level >= LIGHTLY_INJURED`.
  - **`_search`:** reword the two lines that say "gained 1 INJURY" and "INJURED 1 TIME" so they don't claim an injury, for example "came back empty-handed and bruised in spirit".
  - **The failure branch:** after the fights, each hero takes the retreat injury, `injure_character(true)`. Append a story line: `"[b]The party was beaten back[/b] and everyone was [color=FD0000][b]INJURED[/b][/color] in the retreat.\n"`. A retreat death goes into `dead_adventurers`.
- Test: `tools/tests/injuries_test.gd`

**Interfaces:**
- Produces (`QuestInjuries`):
  - `const INJURIES_BY_ODDS := [[130, 0.1], [100, 0.2], [90, 0.35], [80, 0.5], [70, 0.7], [60, 0.9], [50, 1.2]]`: pairs of odds percent and fight injuries per hero. Interpolate linearly between rows, and clamp outside the ends.
  - `const EXPECTED_COMBATS_BY_RANK := {-1: 2.5, 0: 2.5, 1: 4.0, 2: 4.3, 3: 6.2, 4: 8.2, 5: 10.3}`: measured from today's encounter loops. Re-measure in Step 1 and put the measured values here.
  - `target_injuries_per_hero(odds: float) -> float`
  - `injury_chance_per_encounter(odds: float, rank: int, party_size: int) -> float`: `clampf(target × party_size / EXPECTED_COMBATS_BY_RANK[rank], 0.0, 1.0)`
  - `GuildCharacter.injure_character(can_die: bool = true) -> bool`

- [ ] **Step 1: Write the failing test.**
  - `target_injuries_per_hero`: 130 → 0.1, 100 → 0.2, 85 → 0.425, 50 → 1.2, 20 → 1.2, 160 → 0.1.
  - **Calibration:**
    - Run 3,000 quests for each combination: ranks {0, 3, 5}, odds {60, 80, 100, 130}, party sizes {1, 3}.
    - `generateResults(party, chance)` takes the chance as a parameter, so pass the odds directly. Use fresh Healthy heroes each time.
    - Count the injury levels gained from fights only: subtract the retreat, which shows up on failed quests only.
    - Mean fight injuries per hero is within ±15% of `target_injuries_per_hero(odds)`.
  - **Retreat:** on every failed quest, each hero's level rose by at least 1 more than their fight injuries.
  - **Death rule (Review Focus 1):**
    - Over 2,000 won quests at 60% odds, a hero who started `SORE` never ends `DEAD`.
    - Over 2,000 won quests with a hero who started `LIGHTLY_INJURED`, at least one ends `DEAD`.
    - Dead heroes, and only dead heroes, are in `dead_adventurers`.
  - **Story:** no "INJURED" text appears on a quest where no hero's level rose. Count the occurrences of "INJURED" against the actual hits.
- [ ] **Step 2:** run `bash tools/tests/run_test.sh injuries`. Expected: FAIL, because `QuestInjuries` isn't declared.
- [ ] **Step 3:** implement `QuestInjuries`, then `injure_character(can_die)`, then the `generateResults`, `_combatEncounter` and `_search` changes.
- [ ] **Step 4:** run it. Expected: PASS. If calibration misses, fix `EXPECTED_COMBATS_BY_RANK` from a measured count, not by tweaking the target table.
- [ ] **Step 5:** on Assign Party (`screen_assign.gd`'s hero rows), a hero at `LIGHTLY_INJURED` or worse gets an "At risk" tag next to their health chip, `TEXT_AT_RISK := "At risk"` in `HallStyle.RED`, if the row has room at 720 wide. Screenshot it. If there's no room, skip the tag and note that in the commit message.
- [ ] **Step 6:** add injuries, the retreat and the death rule to `Docs/hall_design.md`. Commit: `feat(quests): injuries follow the odds, retreat on a loss, deaths only on failure`.

---

### Task 7: Slower Hospital

**Files:**
- Modify: `Globals/guild_upgrades.gd`: `HOSPITAL_STAGES_PER_NIGHT := [1, 1, 2, 2, 2]`. Update its doc comment: "Level 3+ heals 2 stages a night, so Gravely hurt takes 2 nights."
- Test: `tools/tests/hospital_test.gd`

- [ ] **Step 1: Write the failing test.**
  - At Hospital level 5, admit a `GRAVELY_INJURED` hero. After one `run_night()` they're `SORE`, and after a second they're `HEALTHY`.
  - `get_effect_text(HOSPITAL, 5)` contains "2 injury stages".
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** change the constant.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** update the Hospital rule in `Docs/hall_design.md`. Commit: `balance(hospital): two nights for the gravely hurt`.

---

### Task 8: Countdown to the next boss

**Files:**
- Modify: `Scripts/Hall/hall_main.gd`:
  - Add `days_until_next_boss() -> int`, which returns `HallRules.next_boss_day(GameState.day) - GameState.day`, or `-1` when there are no bosses left.
  - Add `next_boss_is_final() -> bool`.
  - `days_until_drake()` becomes a one-line wrapper that calls `days_until_next_boss()`, so `agent_bridge_state.gd` keeps working.
- Modify: `Scripts/UI/Shell/Header/hall_header.gd`:
  - `_refresh_drake_countdown` and the line-229 caller use `days_until_next_boss()`.
  - The seal uses `HallStyle.QUEST_TYPES` FINAL's tag and icon when `next_boss_is_final()`.
  - The countdown hides when the result is `-1`.
- Modify: `Scripts/Playtest/agent_bridge_state.gd`: add `"next_boss_day": HallRules.next_boss_day(GameState.day)`.
- Test: `tools/tests/countdown_test.gd`

- [ ] **Step 1: Write the failing test.** Using a `HallMain` instance from `hall_main.tscn` with `GameState.day` set:
  - Day 11 → 9, day 20 → 0, day 41 → 9 with final true, day 51 → −1.
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** in the game on day 12, screenshot the header. Expected: the BOSS seal and "8".
- [ ] **Step 6:** update the header description in `Docs/hall_design.md`. Commit: `feat(header): countdown to the next boss`.

---

### Task 9: The boss crawl

**Files:**
- Create:
  - `Scenes/Components/crawl_sections.tscn` + `Scripts/UI/Components/crawl_sections.gd` (`class_name CrawlSections`). This holds the title, story and party sections, moved out of `overlay_credits.gd`.
  - `Scenes/Overlays/Day/overlay_boss_crawl.tscn` + `Scripts/UI/Overlays/Day/overlay_boss_crawl.gd`
- Modify:
  - `Scripts/UI/Overlays/Run End/overlay_credits.gd` and its `.tscn`: use `CrawlSections` for the story and party. The credits must look identical.
  - `Scripts/Hall/hall_main.gd`:
    - Add `var shown_boss_crawl := {}`. It's not saved, so a reload skips the crawl.
    - In `end_day`, when any result has `milestone and not final`, the curtain's callback sets `shown_boss_crawl = {"day": day, "results": <those results>}` instead of `shown_report`. It keeps `report` in a local pending variable.
    - Add `close_boss_crawl()`, which clears the crawl, sets `shown_report = pending report`, and refreshes.
    - `night_save` still saves `{"shown_report": report}` before the crawl. That's what makes a reload skip straight to the report.
  - `hall_main.tscn`: add the overlay node `%OverlayBossCrawl`.
  - `_refresh_overlays`: the crawl shows when `shown_boss_crawl` isn't empty, and hides the report and the other overlays, as the credits do.
- Test: `tools/tests/boss_crawl_test.gd`

**Interfaces:**
- Produces:
  - `CrawlSections.show_title(title: String, subtitle: String, ink: Color, ink_soft: Color) -> void`
  - `CrawlSections.add_fight(heading: String, story: String, result: Dictionary, won: bool, ink: Color, ink_soft: Color) -> void`: appends a heading, the story lines, the party rows (with skull or "survived"), and a won or lost line.
  - `CrawlSections.clear() -> void`
  - `HallMain.close_boss_crawl() -> void`
- The overlay's `TEXT`:
  - `TEXT_TITLE := "Day %d"`
  - `TEXT_WON := "Victory!"`
  - `TEXT_LOST := "Defeated..."`
  - `TEXT_CONTINUE := "Continue"`
  - Each fight's heading is its `questTitle`.
- **Motion:** use `CrawlRoll` the way `overlay_credits` does. Use the victory speed if every fight was won, and the defeat speed otherwise. Each fight's ink comes from its own result.
- **Not shown:** the ledger, records, roll call or team credits.

- [ ] **Step 1: Write the failing test.**
  - Instance `hall_main.tscn`, put `GameState` on day 20 with two sent boss entries, and force one to win and one to lose (fixed parties, retried until mixed).
  - Call `end_day()` and wait for the curtain, using `await get_tree().create_timer(3).timeout`.
  - Assert `shown_boss_crawl.results.size() == 2` and `shown_report.is_empty()`.
  - Call `close_boss_crawl()`, then assert `shown_report.results.size() == 2` (Review Focus 5).
  - On day 11, `end_day()` sets `shown_report` directly and `shown_boss_crawl` stays empty.
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** build `CrawlSections` by moving the code, and switch `overlay_credits` over to it. Run the final-battle playtest scenario and screenshot the credits before and after the change. They must match.
- [ ] **Step 4:** build the overlay and the `hall_main` wiring.
- [ ] **Step 5:** run the test. Expected: PASS.
- [ ] **Step 6:** in the game, screenshot the day-10 crawl, once with Reduced Motion on (no auto-scroll) and once off. Expected: the title, story, party and Continue button. No ledger.
- [ ] **Step 7:** add the boss crawl to `Docs/hall_design.md`'s overlays. Commit: `feat(ui): boss fights get the credits-style crawl`.

---

### Task 10: Measure and tune

**Files:**
- Modify: tuning constants only, in `hall_rules.gd`, `quest_injuries.gd` and `guild_upgrades.gd`.
- Create: `Docs/playtests/<date>-phase-a.md` (written by `/playtest`).

- [ ] **Step 1:** run all tests: `for t in smoke difficulty_scale slot_factor boss_days lead_up_quests standing_loss injuries hospital countdown boss_crawl; do bash tools/tests/run_test.sh $t || break; done`. Set `TEST_SCRATCH` so they share one copy. Expected: every test prints `TEST PASS`.
- [ ] **Step 2:** run `/playtest personas=min-maxer,typical-player,reckless-gambler,cautious-planner runs=2 label=phase-a`.
- [ ] **Step 3:** compare against the spec's A9 targets:
  - typical-player wins 80-85% of the quests it sends, and about 70% of the board.
  - Bosses are won more often than lost, and the Demon King in most typical runs.
  - Typical deaths per run are in single digits.
  - reckless-gambler shows trouble but doesn't collapse in one day.
  - Buildings max out around days 38-42 for typical-player, and no sooner than about day 30 for min-maxer.
- [ ] **Step 4:** if a target misses, change one constant at a time: drift or step for the odds, the injury table for deaths, `BOSS_SPIKE` for the bosses. Then re-run Step 2. Stop after three rounds and report to Santi if it still misses.
- [ ] **Step 5:** record the final values and the report path in each constant's doc comment. Commit: `balance: tune phase A from playtest`. Commit the report too.
