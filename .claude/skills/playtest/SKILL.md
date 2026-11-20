---
name: playtest
description: Run the AI playtesters against the game and write a playtest report. Use when the user says "playtest", "run the AI playtesters", "/playtest", or asks for a balance or new-player check of Fantasy Guild Manager.
---

# /playtest

This is a controller procedure for the main Claude session. It copies the project to a scratch folder, launches one Godot bridge per (persona, run), dispatches the persona agents, and combines their JSON blocks into `Docs/playtests/<date>-<label>.md`. Design: `Docs/superpowers/specs/2026-11-20-ai-playtesters-design.md`.

Never stop to ask the user anything. Do not commit the report. At the end, tell the user the report path, the sheet status, and any failed personas.

## Arguments

`/playtest [personas=<slugs|all>] [runs=<n>] [seed=<n>] [label=<slug>] [days=<n>]`

| Argument | Default | Meaning |
|---|---|---|
| `personas` | `min-maxer,typical-player,first-timer,skimmer` | Comma-separated slugs, or `all` for all 8. |
| `runs` | `2` | Runs per persona. `--run` is 1..runs, so each persona's runs have different run ids. |
| `seed` | `4417` | Same seed gives the same day-1 heroes, shop and quests for every persona. |
| `label` | `run` | Report name suffix. |
| `days` | `5` | Day cap for eyes personas only. |

Constant: `MAX_PARALLEL = 4` (at most 4 bridges/Godot windows at once).

## Personas

| Slug | Agent (`subagent_type`) | Mode | Launch flags (after `--`) | `day_cap` passed |
|---|---|---|---|---|
| `min-maxer` | `playtester-min-maxer` | rules | none | 999 |
| `cautious-planner` | `playtester-cautious-planner` | rules | none | 999 |
| `reckless-gambler` | `playtester-reckless-gambler` | rules | none | 999 |
| `typical-player` | `playtester-typical-player` | rules | none | 999 |
| `first-timer` | `playtester-first-timer` | eyes | `--intro` | `days` |
| `skimmer` | `playtester-skimmer` | eyes | none | `days` |
| `accessibility` | `playtester-accessibility` | eyes | `--text-size=2 --color-filter=1 --reduce-motion` | `days` |
| `genre-veteran` | `playtester-genre-veteran` | eyes | none | `days` |

`day_cap` means play days 1..day_cap inclusive. For rules personas, 999 means a full run: play until the run is over or day 50's final battle. Never pass `--test-hooks`.

## Procedure

1. **Set up.** Parse the arguments and apply the defaults. Set `DATE=$(date +%F)`, `REPO` to the repo root, and `SCRATCH=/tmp/fgm-playtest-$DATE-$LABEL`. Create `$SCRATCH/bridges` and `$SCRATCH/diaries`. Run `git rev-parse --short HEAD` for the report header. Keep a list `LAUNCHED` of every bridge dir you start.

2. **Prepare the scratch copy.** Once, from the repo root:
   ```bash
   bash tools/playtest/prepare.sh "$SCRATCH/project"
   ```
   If it fails, write a report that says so and finish. Nothing else can run.

3. **Build the job list.** One job per (persona, run). For job `<slug>` run `<n>`: `BRIDGE=$SCRATCH/bridges/<slug>-<n>`, `DIARY=$SCRATCH/diaries/<slug>-<n>.md`.

4. **Run jobs, at most MAX_PARALLEL at a time.** For each job:
   1. Launch the bridge. Rules mode may be headless. Eyes mode must be windowed (no `--headless`), because screenshots need the renderer.
      ```bash
      # rules
      bash tools/playtest/launch.sh "$SCRATCH/project" "$BRIDGE" --headless -- --bridge-dir="$BRIDGE" --mode=rules --seed=<seed> --persona=<slug> --run=<n> --label=<label>
      # eyes (persona flags from the table appended)
      bash tools/playtest/launch.sh "$SCRATCH/project" "$BRIDGE" -- --bridge-dir="$BRIDGE" --mode=eyes --seed=<seed> --persona=<slug> --run=<n> --label=<label> [persona flags]
      ```
      Add the bridge dir to `LAUNCHED` as soon as you call launch. If launch exits non-zero, record the persona run as `failed: <reason>` (use the launch message and the tail of `$BRIDGE/godot.log`), run `stop.sh` on it, and carry on with the other jobs.
   2. Dispatch the persona with the Agent tool: `subagent_type: playtester-<slug>`, `run_in_background: true`. The prompt gives exactly these lines:
      ```
      bridge_dir: <BRIDGE>
      diary_path: <DIARY>
      day_cap: <999 for rules personas, days for eyes personas>
      run: <n>
      game_rules_hint: none
      ```
      Use the absolute bridge path as the bash scripts see it. The agent plays only through `bridge.sh`, writes its own diary, and ends its reply with one fenced json block.
   3. When the agent finishes, parse the last fenced json block of its reply. If there is no valid block, record `failed: no valid JSON block` for that run. Either way, run `bash tools/playtest/stop.sh "$BRIDGE"` and start the next waiting job.

5. **Check the sheet once.** On the first live bridge, before it is stopped (a rules run is easiest), run:
   ```bash
   bash tools/playtest/bridge.sh "$BRIDGE" status '{}'
   ```
   Read `sheet`: `off`, `checking`, `ready`, `not_redeployed` or `offline`. `quit` (inside `stop.sh`) flushes pending rows to the sheet when `ready`. If `sheet` is `checking`, check again on the next bridge. If the final value is not `ready`, put a banner at the top of the report:
   - `not_redeployed`: "AI rows were logged locally only: the run-log Apps Script hasn't been redeployed yet".
   - `offline`: "AI rows were logged locally only: the sheet could not be reached".
   - `off` or `checking`: "AI rows were not sent to the sheet (sheet status: <value>)".

6. **Always clean up.** Before writing the report, and also when anything above fails, run `bash tools/playtest/stop.sh "$B"` for every dir in `LAUNCHED`. It is safe to run twice.

7. **Copy screenshots.** For every `screenshot` path cited in the JSON blocks' `confusions` and `ui_issues`, copy the PNG into `Docs/playtests/<date>-<label>/`, prefixing the filename with `<slug>-<run>-` to avoid clashes. Skip paths that don't exist. Use the copied relative path (`<date>-<label>/<file>.png`) in the report.

8. **Read the previous report's metrics.** Find the newest earlier `Docs/playtests/*.md` (excluding `README.md` and today's file). Take its trailing `<!-- metrics {...} -->` comment. If none, the section says "First report, nothing to compare".

9. **Write `Docs/playtests/<date>-<label>.md`.**
   - Any sheet banner first (blockquote), then the title `# Playtest <date> <label>`.
   - Header: seed, commit (`git rev-parse --short HEAD`), the persona list with run numbers, and each run's outcome. Failed runs read `failed: <reason>`.
   - Sections, in this order:
     1. **Headline**: 3-5 bullets of what matters most.
     2. **Balance**: one block per rules persona. Furthest day, gold and standing curve, deaths, Drake result, strategies found. Give figures as ranges across that persona's runs (for example "furthest day 31-38"). Note any exploit or never-worth-it option.
     3. **New-player**: confusion moments (day, screen, what, screenshot link), from every persona, grouped by screen.
     4. **UI / readability**: issues by screen, ranked by severity (3 first), each with its screenshot.
     5. **Changes since last report**: compare the per-persona metrics with the previous comment (furthest day, drake, deaths, gold, confusion count, ui_issue count) and say what moved.
     6. **Persona diaries**: for each run, a collapsed `<details>` with the verdict and the diary text from `$DIARY` (read it). If a diary is missing, say so.
   - The last line of the file is the metrics comment, in the shape below.

10. **Finish.** Tell the user the report path, the sheet status (and banner text if any), and the failed personas with reasons. Do not commit.

## Metrics comment

The file ends with exactly one line of this shape (single-line JSON, keys exactly as shown; ranges are `[min, max]` across that persona's successful runs, and `null` when no run could report it):

```
<!-- metrics {"seed":4417,"commit":"abc1234","date":"2026-11-20","label":"run","personas":{"min-maxer":{"runs":2,"failed":0,"furthest_day":[31,38],"drake":{"won":1,"lost":1,"not_reached":0},"deaths":[0,3],"final_gold":[420,910],"confusion_count":[1,2],"ui_issue_count":[0,1]}}} -->
```

- `furthest_day`, `deaths`, `final_gold` (last value of `gold_by_day`), `confusion_count` (length of `confusions`) and `ui_issue_count` (length of `ui_issues`) are `[min, max]` over successful runs.
- `drake` counts runs by their `drake` value.
- `runs` is the number requested, `failed` the number that failed.
- One key per persona that was requested, including ones whose runs all failed (`failed` equals `runs`, other fields `null`).

## Notes

- The bridge scene and scripts (`Scenes/Playtest/agent_bridge.tscn`, `Scripts/Playtest/agent_bridge*.gd`) are excluded from exports. The scratch copy has its own `user://` (the project is renamed "(Playtest)").
- The scripts live in `tools/playtest/` (`prepare.sh`, `launch.sh`, `bridge.sh`, `stop.sh`, `common.sh`). `BRIDGE_TIMEOUT_SECONDS` (60) and `LAUNCH_TIMEOUT_SECONDS` (60) can be overridden in the environment.
- The personas' own rules live in `.claude/agents/playtester-*.md`. They never read the source or docs.
