# Difficulty Phase B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make heroes, gold and standing compete with each other through costs that only show on buttons the player already presses. Hire prices rise as the roster grows, Hospital beds cost gold per night, and a "guild in trouble" warning appears in the header. Then recheck the upgrade costs.

**Architecture:**
- **Prices** are static functions in `HireScaling` and `GuildUpgrades`. Every place that shows or charges a price calls them.
- **The trouble check** is a static function in `HallLedger`. It reads a per-day failure tally kept in `HallMain.run_stats`, which is already saved, so the save format doesn't change.

**Tech Stack:** Godot 4.7, GDScript. Headless tests run through `tools/tests/run_test.sh`, from phase A Task 0.

**Spec:** `Docs/superpowers/specs/2026-11-21-difficulty-and-dilemmas-design.md`, phase B. **Prerequisite:** phase A is merged and its playtest targets hold (phase A Task 10).

## Executive summary

- **Task 1, hire prices rise with the roster:** each living hero above 3 adds 15% to a recruit's price. The hire card and the hero screen show the live price, and paying always uses that same number.
- **Task 2, Hospital beds cost gold per night:**
  - A bed costs `20 × (standing rank + 1)` gold a night, 120 at rank S, charged at End Day.
  - You can discharge a hero early, which stops the charge.
  - When gold runs out, patients go home in the order they were admitted.
  - The Admit button reads "Admit · N gold/night", bed rows show the rate, and the Day Report lists the bill.
- **Task 3, a "guild in trouble" warning:** a milder header strip shows when 2 or more quests failed over the last 2 days, or half the living roster is Hurt or worse. It names the reason.
- **Task 4, recheck the upgrade costs:** rerun the playtest and the income model. If an average player now maxes buildings later than about day 42, lower `UPGRADE_GOLD_COST` proportionally.
- **Out of scope:** wages, new currencies, and any cost that isn't shown on its button.

## Global Constraints

- Everything in phase A's Global Constraints applies here too.
- Starting values, copied from the spec:

  | Constant | Value |
  |---|---|
  | `HIRE_PRICE_PER_HERO` | 0.15 (above 3 living heroes) |
  | `HOSPITAL_FEE_PER_NIGHT` | 20 (× standing rank + 1) |
  | Trouble: failures | 2 or more failed quests over the last 2 days |
  | Trouble: injuries | half or more of the living roster is Hurt or worse |

- Recruits on days 1-2 stay free (`cost == 0` stays 0).
- Gold never goes negative.
- Button labels state the price: "Admit · %d gold/night".

## Review Focus

1. **The roster changes between seeing a price and tapping Hire,** for example after a hire or a death that same day. The button shows, and charges, the price at the moment of the tap. Test in Task 1.
2. **Patients when the gold runs out:** the guild can pay for some patients that night but not all. The earliest admitted are paid for, the rest go home, and gold lands at exactly the leftover amount, never negative. Test in Task 2.
3. **Discharge and re-admit on the same day** charges nothing extra until that night. Test in Task 2.
4. **Old saves:** an old save's `run_stats` has no `"failed_by_day"`. Loading it shows no trouble strip and doesn't crash. Test in Task 3.
5. **Both header strips apply:** the guild is in trouble and also down to its last hero. Only the existing red "last hero standing" strip shows. Test in Task 3.

---

### Task 1: Hire prices rise with roster size

**Files:**
- Modify: `Scripts/Hall/Rules/hire_scaling.gd`. Add `const HIRE_PRICE_PER_HERO := 0.15`, `const HIRE_PRICE_FREE_HEROES := 3` and `static func roster_price(base_cost: int, living_heroes: int) -> int`.
- Modify: `Globals/character_container.gd`. Add `hire_price(character: GuildCharacter) -> int`, which applies `roster_price` to `character.cost` with the current living count. `add_character_to_guild` charges `hire_price()` instead of `.cost`.
- Modify: everything that shows or checks the price uses `CharacterContainer.hire_price(character)`:
  - `Scripts/UI/Rows/Heroes/hire_card.gd`
  - `Scripts/UI/Screens/screen_character.gd`
  - `Scripts/Hall/Rules/hall_ledger.gd` `can_afford_a_recruit_today`
  - `Scripts/Playtest/agent_bridge_state.gd` `"cost"`
- Test: `tools/tests/hire_price_test.gd`

**Interfaces:**
- Produces:
  - `HireScaling.roster_price(base_cost: int, living_heroes: int) -> int`, which returns `roundi(base_cost * (1.0 + HIRE_PRICE_PER_HERO * maxi(0, living_heroes - HIRE_PRICE_FREE_HEROES)))`.
  - `CharacterContainer.hire_price(character: GuildCharacter) -> int`
- `character.cost` stays the saved base price. Nothing new is saved.

- [ ] **Step 1: Write the failing test.**
  - `roster_price(200, 3) == 200`
  - `roster_price(200, 8) == 350`
  - `roster_price(200, 12) == 470`
  - `roster_price(0, 10) == 0`
  - **Review Focus 1:**
    - With 7 living heroes and a recruit at base 200, `hire_price == 320`.
    - Hire another hero, and the same recruit's `hire_price == 350`.
    - Hiring them takes exactly 350 gold.
- [ ] **Step 2:** run `bash tools/tests/run_test.sh hire_price`. Expected: FAIL.
- [ ] **Step 3:** implement, and switch every caller listed under Files.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** in the game, with 8 heroes, screenshot the hire card. Expected: the raised price on the button.
- [ ] **Step 6:** add the rule to the recruiting section of `Docs/hall_design.md`. Commit: `balance(hire): recruit price rises with roster size`.

---

### Task 2: Hospital beds cost gold per night

**Files:**
- Modify: `Globals/guild_upgrades.gd`:
  - Add `const HOSPITAL_FEE_PER_NIGHT := 20`, documented as gold per night, multiplied by standing rank + 1.
  - Add `func nightly_fee() -> int`, which returns `HOSPITAL_FEE_PER_NIGHT * (HallRules.standing_rank_for(standing) + 1)`.
  - `admit()` returns false when `gold < nightly_fee()`.
  - In `run_night()`, before healing, walk `patients` in order. Charge `nightly_fee()` for each while gold lasts. Discharge the rest to home healing and list them.
  - The result gains `"hospital_bill": int` and `"sent_home_unpaid": Array[GuildCharacter]`.
- Modify: `Scripts/UI/Rows/Buildings/home_row.gd`:
  - `BUTTON_ADMIT := "Admit · %d gold/night"`, filled with `nightly_fee()`.
  - The button is disabled when the guild can't pay.
  - A bed row's note adds the rate: `TEXT_BED_RATE := "%d gold/night"`.
- Modify: `Scripts/UI/Overlays/Day/overlay_report.gd`:
  - The night section shows `"Hospital: −%d gold"` when `hospital_bill > 0`.
  - It shows `"%s went home: no gold for a bed"` for each hero in `sent_home_unpaid`.
- Modify: `Scripts/Playtest/agent_bridge_state.gd`. Add `"hospital_fee": GuildUpgrades.nightly_fee()`.
- Test: `tools/tests/hospital_fee_test.gd`

**Interfaces:**
- Consumes: `HallRules.standing_rank_for(standing) -> int`
- Produces: `GuildUpgrades.nightly_fee() -> int`, and `run_night()`'s added keys `hospital_bill` and `sent_home_unpaid`.

- [ ] **Step 1: Write the failing test.**
  - `nightly_fee()` is 20 at standing 1 and 120 at standing 60.
  - Admit two hurt heroes with 300 gold at standing 60. `run_night()` gives `hospital_bill == 240` and gold 60.
  - **Review Focus 2:** three patients and 250 gold. The first two are paid for, the third is in `sent_home_unpaid` and isn't a patient any more, and gold is 10.
  - **Review Focus 3:** admit, discharge and admit again before `run_night()`. The bill for that hero is 120, not 240.
  - With 50 gold at standing 60, `admit()` returns false.
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** implement the rules, then the UI and report lines.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** in the game, screenshot the Facilities tab with a patient, and the Day Report after a night. Expected: "Admit · 120 gold/night", the rate on the bed row, and the bill line in the report.
- [ ] **Step 6:** update the Hospital rules in `Docs/hall_design.md`. Commit: `balance(hospital): beds cost gold per night`.

---

### Task 3: "Guild in trouble" warning

**Files:**
- Modify: `Scripts/Hall/hall_main.gd`:
  - In `_run_quest`, on a loss, `run_stats.failed_by_day[GameState.day] = run_stats.get("failed_by_day", {}).get(GameState.day, 0) + 1`.
  - Create the dictionary if it's missing: `run_stats` is a saved dictionary, and old saves don't have the key.
  - Add a wrapper, `trouble_reason() -> String`.
- Modify: `Scripts/Hall/Rules/hall_ledger.gd`:
  - Add `const TROUBLE_FAILURES := 2` and `const TROUBLE_WINDOW_DAYS := 2`.
  - Add `static func trouble_reason(run_stats: Dictionary, roster: Array, day: int) -> String`. It returns `"failures"`, `"injuries"` or `""`, and checks failures first.
  - Failures are summed over `day - 1` and `day - 2`. Use the days just reported, not today, which hasn't been played yet.
  - Injuries mean that half or more of the living heroes have `injury_level >= LIGHTLY_INJURED`.
- Modify: `Scripts/UI/Shell/Header/hall_header.gd` `_refresh_danger_strip`:
  - When the existing strip doesn't show and `trouble_reason()` isn't empty, show the same strip in `HallStyle.GOLD_BG` with `TROUBLE_TITLE := "Guild in trouble"`.
  - The text is `TROUBLE_FAILURES_TEXT := "%d quests lost in two days. Pick safer quests for a while."` or `TROUBLE_INJURIES_TEXT := "Half the guild is hurt. Rest or heal before sending more."`
  - Play `danger_warning` only when the strip first appears, as today.
- Test: `tools/tests/trouble_test.gd`

**Interfaces:**
- Produces: `HallLedger.trouble_reason(run_stats, roster, day) -> String`, and `HallMain.trouble_reason() -> String`.

- [ ] **Step 1: Write the failing test.**
  - `failed_by_day = {9: 1, 10: 1}` on day 11 gives `"failures"`, and on day 13 gives `""`.
  - With 4 living heroes and 2 of them `LIGHTLY_INJURED`, it gives `"injuries"`.
  - **Review Focus 4:** `run_stats` without `failed_by_day` gives `""`, with no error.
  - **Review Focus 5:** set up one living hero and short gold, so `is_one_death_from_falling()` is true. Also set `failed_by_day = {10: 2}`. The strip shows the red `DANGER_TITLE`, not the trouble title. Instance the header through `hall_main.tscn`.
- [ ] **Step 2:** run it. Expected: FAIL.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** run it. Expected: PASS.
- [ ] **Step 5:** in the game, lose two quests on one day and screenshot the next morning's header. Expected: the gold "Guild in trouble" strip with the failures line.
- [ ] **Step 6:** add the header strip's second state to `Docs/hall_design.md`. Commit: `feat(header): guild-in-trouble warning`.

---

### Task 4: Recheck the upgrade costs

**Files:**
- Modify (only if needed): `Globals/guild_upgrades.gd` `UPGRADE_GOLD_COST` and its doc comment.
- Create: `Docs/playtests/<date>-phase-b.md` (written by `/playtest`).

- [ ] **Step 1:** run every test from phase A and phase B. Expected: every test prints `TEST PASS`.
- [ ] **Step 2:** run `/playtest personas=min-maxer,typical-player,reckless-gambler,cautious-planner runs=2 label=phase-b`.
- [ ] **Step 3:** read off the day each rules run maxed all buildings (from its diary and gold curve). The targets are about days 38-42 for typical-player, and no sooner than about day 30 for min-maxer.
- [ ] **Step 4:** if typical-player lands later than about day 42, scale every `UPGRADE_GOLD_COST` entry by `40 / (observed day)`. Round to the nearest 100 and keep the level ratios. Then rerun Step 2 once.
- [ ] **Step 5:**
  - Check the earliest finish is still no sooner than about day 30. If it's sooner, report to Santi instead of tuning further.
  - Update the doc comment with the new total, the playtest report path and the reasoning.
  - Commit: `balance(upgrades): retune after phase B costs`, together with the report.
