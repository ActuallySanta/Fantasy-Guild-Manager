# AI Playtesters — Design


## Context / intent

Santi wants a team of AI subagent playtesters, each with a distinct perspective and skill level, that can be **re-run after every change** (balance tweak, UI change) and produce comparable results. Goals, in Santi's words: **balance & difficulty**, **new-player experience**, **UI / readability**. Bug hunting is not a goal (bugs found along the way get reported, but nobody hunts for them).

Success = after a change, Santi runs one command and gets (a) a dated report saying what got better or worse vs. last time, and (b) the AI runs' numbers in the run-log Google Sheet, in AI-only tabs with the same charts the human playtest runs have.

**Non-goals:** replacing human playtests; statistically large balance sweeps (scripted bots, approach C, can be added later on the same bridge); testing the exported web build itself.
**Anti-goals:** AI rows mixing into the human run-log data; anything from the bridge shipping in exports; repo churn from runs (import/.uid files).

## Approaches considered

- **A. Two-mode bridge (chosen).** A debug-only scene runs the real game window and takes commands. *Rules mode*: text state, and actions call `HallMain`'s public functions, fast enough for full 50-day runs. *Eyes mode*: screenshot only, actions are taps at x,y, so UI confusion shows up as a real finding. One tool covers all three goals.
- B. Screen-only via the built-in browser on the web build. No game code changes, but slow and costly per day, flaky canvas clicks, and runs rarely get far enough to say anything about balance.
- C. A plus scripted GDScript bots for hundreds of balance runs. Best statistics, but two systems to keep up. Deferred.

## Personas (approved: all 8)

| # | Persona | Skill | Mode | Focus |
|---|---|---|---|---|
| 1 | Min-maxer | Expert | Rules | Can the economy be broken? Dominant strategies? Are the Drake and day 50 too easy? |
| 2 | Cautious planner | Mid | Rules | Does safe play still win, or does it stall or get boring? |
| 3 | Reckless gambler | Novice | Rules | Failure spirals, Game Over pacing, does losing feel explained? |
| 4 | Typical player | Mid | Rules | Baseline difficulty curve from day 1 to 50 |
| 5 | First-time phone gamer | Novice | Eyes | Tutorial and Pip clarity, every moment of confusion |
| 6 | Skimmer | Novice | Eyes | Skips text, taps the biggest button. Does the game still teach? |
| 7 | Accessibility player | Mid | Eyes | Large text, color filters, reduced motion: legibility and usability |
| 8 | Genre veteran | Expert | Eyes | Information density, missing info, clunky flows |

- **Run size (Santi: Medium):** the default set runs **2 runs per persona** on a **fixed default seed** (the same every time, so before/after comparisons are fair; `seed=` overrides it). Rules personas play to Game Over or day 50 and send **one day's whole plan per command** (assignments, hires, buys, then end the day) to keep the number of turns down. Eyes personas play days 1–5. The report shows ranges across the two runs, not single numbers.
- **Tutorial on for everyone** (my call): matches real players and keeps AI sheet numbers comparable with human ones. Eyes personas also see the intro story, through a small launch flag on the hall (today the intro shows only when the hall is the root scene).
- Each persona is a subagent file in `.claude/agents/playtester-<name>.md`: its personality, skill level, how it makes decisions, what it notices, the bridge commands it may use (eyes personas: screenshot and tap only), and a required diary/report format.
- Rules personas play full runs (to Game Over or the day-50 credits). Eyes personas play about days 1–5 by default (configurable).
- `/playtest` with no arguments runs the default set: 1, 4, 5, 6. Arguments pick personas, a label, a seed, and the day cap.

## How a run works

1. `/playtest` (a project skill in `.claude/skills/playtest/`) copies the project to a scratch folder, so `--import` and `.uid` churn stay out of the repo (per CLAUDE.md), and picks a seed (or uses the one given).
2. For each persona, it launches a Godot window (Steam Godot 4.7 path from CLAUDE.md) on the bridge scene with that persona's mode, seed and run ID. It runs windowed, not headless, because screenshots need the renderer. Personas run in parallel, one Godot instance each.
3. **Bridge scene** (debug-only, e.g. `Scenes/Playtest/agent_bridge.tscn` + `Scripts/Playtest/agent_bridge.gd`, next to the existing playtest scenarios): instances `HallMain`, calls `seed(n)` (nothing in the game seeds the RNG today, so global `randi`/`randf` become reproducible), then **re-rolls today's state** the way `debug_reroll_today` does, plus the `CharacterContainer` hire pool and the `ItemShop` stock, which the autoloads roll in `_ready` before the bridge can seed (my call: a setup-only exception to "only through actions", just like `playtest_scenario.gd`). The result is the same day-1 heroes, shop and quests for every persona. It also turns the logger's AI target on, then serves commands.
   - Rules mode: `state` returns a text or JSON snapshot built from hall queries (`roster()`, `current_quest_entry()`, `success_chance()`, `days_until_drake()`, `is_locked()`, gold and standing…). Action commands map to existing hall actions (`hire`, `toggle_in_party`, `deny_quest`, `end_day`, `buy_item`, `equip_item`, `train`, `admit`, `revive`, `upgrade_building`, `close_report`, …). The bridge never changes state except through those actions.
   - Eyes mode: `screenshot` saves the viewport to PNG and returns its path. `tap x y` injects a mouse press and release. `wait` lets animations settle. Nothing else is available.
   - Transport: agents talk to the bridge through a small CLI script (`tools/playtest/bridge.sh` or similar) that writes a command file and waits for the response file. File-based, so the agents only need Bash.
4. Each persona writes a diary (decisions, confusion, opinions, screenshot paths) to the run folder, then returns a structured summary.
5. The skill combines the summaries into one report and diffs it against the previous report.

## Report

`Docs/playtests/YYYY-MM-DD-<label>.md` (committed), with screenshots in `Docs/playtests/YYYY-MM-DD-<label>/`. It records the seed and commit hash, then these sections:
Headline · Balance (per persona: furthest day, gold and standing curve, deaths, Drake result, strategies found) · New-player (confusion moments with day + screenshot) · UI / readability (issues by screen, ranked) · Changes since last report · Persona diaries.

## Run log: separate AI sheet (Santi's request)

The sheet (`run_logger.gd` → Apps Script `Scripts/Playtest/run_log_apps_script.gs` → spreadsheet `1YN1…QNC8QM`) has this pipeline today:
`Sheet1` (raw rows, written by the script to `getSheets()[0]`) → `Day Ends` (de-duplicated `day_end` rows, A:AA) → `Runs` (per run, formulas) → `Summary` (per-day aggregates, formulas, rows 13+) → `Charts` (8 charts that read from `Summary`).

Changes:
- **Logger** (`Scripts/Hall/Debug/run_logger.gd`): add a target the bridge can set (human by default), and send it in the payload (e.g. `"sheet": "ai"`). Add `persona` and `seed` columns **at the end** of `COLUMNS` (the file's own rule), left blank for human runs. The existing CSV-retire logic handles the header change. The bridge also sends AI rows to a separate local CSV (e.g. `user://run_log_ai.csv`), so the human CSV stays clean.
- **Apps Script**: `doPost` writes to an `AI Raw` tab (created with its header if missing) when `data.sheet == "ai"`, and to the first sheet otherwise. Old builds don't send the field, so human rows keep going where they go now (backward compatible).
- **AI runs post to the Google Sheet (Santi's request)**, into the `AI Raw` tab, with separate charts reading off it. They also go to the local AI CSV. Safety check (my call): the new script's `doGet` reports that it supports the AI tab (e.g. `{"ai_tab": true}`), and the bridge or `/playtest` checks this once at the start. If the deployed script is still the old version, AI rows stay in the local queue and the report flags "sheet script not redeployed yet", instead of the rows landing in the human `Sheet1`. No manual switch to flip. Building the AI tabs needs edit access to the spreadsheet through the connected Google account; check that first.
- **Redeploy needed by a person:** the web app is deployed from Daniel's personal Google account (per the script header), so whoever owns it has to paste the new script and choose Deploy → Manage deployments → New version. The URL stays the same.
- **AI tabs mirroring the human ones**: `AI Day Ends`, `AI Runs`, `AI Summary`, `AI Charts`, with the same formulas pointed at the AI tabs and the same 8 charts, styled the same, reading from `AI Summary`. Built through the Google Sheets connector (duplicate each tab, then rewrite its references, and recreate the charts against the new tab IDs).
- AI-specific tweaks: the "Runs started per date" chart stacks by **persona** instead of platform (AI runs are all Windows). Add one extra chart, "Last day reached by persona". `AI Runs` gains persona and seed columns.

## Constraints

- Bridge code is debug/playtest only and must not ship: keep it under `Scenes/Playtest/` / `Scripts/Playtest/`, and leave it out of `export_presets.cfg` (check the presets' include/exclude filters).
- No `static var` or new autoload for run state. Bridge state lives on the bridge node.
- Follow CLAUDE.md conventions: script headers, `TEXT`/`NODES` sections where relevant, `##` docs, tunables at the top, uid preloads, about 800 lines per script.
- Don't change hall game logic for the bridge. `hall_main.gd` is about 1,830 lines (CLAUDE.md's "about 1,350" is out of date; fix that line too), so all bridge logic lives in bridge files. `hall_main` gets at most the intro launch flag and any one-line query wrapper that's truly needed.
- Update `README.md` (playtest section) and `Docs/hall_design.md` (Debug tools / playtesting) in the same change.
- No save-format changes.

## Left to the builder

The exact command vocabulary and state schema; the transport details (polling interval, timeouts); how eyes-mode personas set their accessibility settings (via taps, or a bridge launch flag); the persona prompt wording; how reports are diffed; the parallelism limit.

## Verification

- Bridge smoke test: launch the bridge in rules mode with a fixed seed, run `state`, then send a party and `end_day`. The day advances and the state changes. Two launches with the same seed show identical day-1 heroes and quests.
- Eyes mode: `screenshot` produces a 720x1280 PNG, and a `tap` on the End Day button's coordinates triggers it.
- Logger: an AI run's rows land in `AI Raw` (after the redeploy) and in the AI CSV, and nothing new appears in `Sheet1`. A normal F5 run still lands in `Sheet1`.
- The AI tabs and charts fill in after a couple of AI runs and match the human charts' layout.
- `/playtest` end to end with the default set: a report appears in `Docs/playtests/` with all sections, and a second run fills in "Changes since last report".
- An export dry run (or a filter inspection) confirms no bridge files in the build.
