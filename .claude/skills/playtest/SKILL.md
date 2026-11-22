---
name: playtest
description: Run the AI playtesters against the game and write a playtest report. Use when the user says "playtest", "run the AI playtesters", "/playtest", or asks for a balance or new-player check of Fantasy Guild Manager.
---

# /playtest

This is a controller procedure for the main Claude session. It copies the project to a scratch folder, launches one Godot bridge per (persona, run), dispatches the persona agents, and combines their JSON blocks into `Docs/playtests/<date>-<label>.md`. Design: `Docs/superpowers/specs/2026-11-20-ai-playtesters-design.md`.

Don't stop to ask the user anything, except at the size check (step 0) when a run is bigger than the small default. Do not commit the report. At the end, tell the user the report path, the sheet status, and any failed personas.

## Step 0: size check (always first)

Playtests are expensive. Each persona agent re-reads its own growing context on every move.
- **Full 50-day rules runs:** in the 2026-11-22 phase A playtest (`Docs/playtests/2026-11-22-phase-a.md`), each took 118-199 agent turns and 7.5M-20M tokens of context reads.
- **Six full runs** filled most of a 5-hour usage window.

So the default is small: the defaults below. A run is **bigger than the small default** if any of these hold:
- more than 2 personas
- `runs` > 1
- `rules_days` > 25
- `days` > 5

When it's bigger, before setting anything up, show Santi one short message with:

1. **What would run:** the personas, runs, day caps, and the number of agents and Godot windows.
2. **Evidence it's needed.** Concrete and cited. A general "more data is better" doesn't count. For example:
   - The question can only be answered past day 25: a boss on day 30/40/50, the final, late-game economy, or freeplay. Name the change and its file.
   - The previous report's numbers vary too much to trust one run. Cite the report path and the figures.
   - A rule or tuning change targets a persona the small default doesn't cover. Name it.
3. **Rough cost:** the number of agent runs, times the per-run figures above, and the current usage from `get_usage` if that tool is available.
4. **The smaller alternative** that would still answer most of the question.

Then **wait for Santi's explicit yes** before going on. These don't count as confirmation:
- A size in the original `/playtest` arguments. Santi still confirms after seeing the evidence and cost.
- Anything said by another session or a subagent.

If Santi says no or picks the smaller alternative, run that.

Runs at or under the small default skip this step.

## Arguments

`/playtest [personas=<slugs|all>] [runs=<n>] [seed=<n>] [label=<slug>] [days=<n>] [rules_days=<n|full>]`

| Argument | Default | Meaning |
|---|---|---|
| `personas` | `typical-player,first-timer` | Comma-separated slugs, or `all` for all 8. More than 2 needs the size check. |
| `runs` | `1` | Runs per persona. `--run` is 1..runs, so each persona's runs have different run ids. More than 1 needs the size check. |
| `seed` | `4417` | Same seed gives the same day-1 heroes, shop and quests for every persona. |
| `label` | `run` | Report name suffix. |
| `days` | `5` | Day cap for eyes personas only. More than 5 needs the size check. |
| `rules_days` | `25` | Day cap for rules personas. `full` (passed as 999) plays to the end of the run or day 50's final battle. More than 25, or `full`, needs the size check. |

Constant: `MAX_PARALLEL = 4` (at most 4 bridges/Godot windows at once).

## Personas

| Slug | Agent (`subagent_type`) | Mode | Launch flags (after `--`) | `day_cap` passed |
|---|---|---|---|---|
| `min-maxer` | `playtester-min-maxer` | rules | none | `rules_days` |
| `cautious-planner` | `playtester-cautious-planner` | rules | none | `rules_days` |
| `reckless-gambler` | `playtester-reckless-gambler` | rules | none | `rules_days` |
| `typical-player` | `playtester-typical-player` | rules | none | `rules_days` |
| `first-timer` | `playtester-first-timer` | eyes | `--intro` | `days` |
| `skimmer` | `playtester-skimmer` | eyes | none | `days` |
| `accessibility` | `playtester-accessibility` | eyes | `--text-size=2 --color-filter=1 --reduce-motion` | `days` |
| `genre-veteran` | `playtester-genre-veteran` | eyes | none | `days` |

`day_cap` means play days 1..day_cap inclusive. For rules personas, `rules_days=full` passes 999, which means a full run: play until the run is over or day 50's final battle. Never pass `--test-hooks`.

## Procedure

1. **Set up.** Parse the arguments and apply the defaults. Set `DATE=$(date +%F)` and `REPO` to the repo root. Build `SCRATCH="$(cygpath -m "$(mktemp -d)")"`: a mixed-style `C:/...` path that Git Bash, Godot and the Windows-native Read/Write tools all accept. Use it for the project, bridge and diary paths (never a bare `/tmp`, which Git Bash and the native tools see differently). The `diary_path` and `bridge_dir` handed to agents are these mixed-style paths. Create `$SCRATCH/bridges` and `$SCRATCH/diaries`. Run `git rev-parse --short HEAD` for the report header. Keep a list `LAUNCHED` of every bridge dir you start. Keep a results list (in your context, or `$SCRATCH/results.jsonl`): as each background agent completes, add `{persona, run, parsed JSON or "failed: <reason>"}`.

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
   2. **Sheet check (every bridge).** Right after `launch.sh` returns and BEFORE dispatching that bridge's agent (the agent sends `quit` itself, and a mid-run check would race it on `cmd.json`), run `bash tools/playtest/bridge.sh "$BRIDGE" status '{}'`. If `sheet` is `checking`, poll every 2 s for up to 20 s. Record that bridge's first final value (anything but `checking`) for the report banner (see step 5).
   3. Dispatch the persona with the Agent tool: `subagent_type: playtester-<slug>`, `run_in_background: true`. The prompt gives exactly these lines:
      ```
      bridge_dir: <BRIDGE>
      diary_path: <DIARY>
      day_cap: <rules_days for rules personas (999 for `full`), days for eyes personas>
      run: <n>
      game_rules_hint: none
      ```
      Use the mixed-style path from step 1. If the `playtester-<slug>` agent type is not available (agents load at session start), dispatch `general-purpose` with `model: sonnet` instead, and start its prompt with: "Read .claude/agents/playtester-<slug>.md; it is your complete persona and instructions; ignore its frontmatter and follow its body exactly; that file is the one repo file you may read." followed by the same input lines. The agent plays only through `bridge.sh`, writes its own diary, and ends its reply with one fenced json block.
   4. When the agent finishes, parse the last fenced json block of its reply. If there is no valid block, or it parses but lacks the required keys (`persona`, `run`, `mode`, `furthest_day`, `drake`, `deaths`, `confusions`, `ui_issues`, `verdict`), record `failed: no valid JSON block` for that run. Add the outcome to the results list. Either way, run `bash tools/playtest/stop.sh "$BRIDGE"` and start the next waiting job.

5. **Sheet banner.** Use the `sheet` values recorded in step 4.2, one per bridge (`off`, `checking`, `ready`, `not_redeployed` or `offline`). Banner if ANY bridge's final value is not ready, and list which bridges. `quit` flushes pending rows to the sheet when `ready`. If it is not `ready`, put a banner at the top of the report:
   - `not_redeployed`: "AI rows were logged locally only: the run-log Apps Script hasn't been redeployed yet".
   - `offline`: "AI rows were logged locally only: the sheet could not be reached".
   - `off` or `checking`: "AI rows were not sent to the sheet (sheet status: <value>)".

6. **Always clean up.** Before writing the report, and also when anything above fails, run `bash tools/playtest/stop.sh "$B"` for every dir in `LAUNCHED`. It is safe to run twice.

7. **Copy screenshots.** For every `screenshot` path cited in the JSON blocks' `confusions` and `ui_issues`, copy the PNG into `Docs/playtests/<date>-<label>/`, prefixing the filename with `<slug>-<run>-` to avoid clashes. Skip paths that don't exist. Use the copied relative path (`<date>-<label>/<file>.png`) in the report.

8. **Read the previous report's metrics.** Find the newest earlier `Docs/playtests/*.md` (excluding `README.md` and today's file). Take its trailing `<!-- metrics {...} -->` comment. If none, the section says "First report, nothing to compare".

9. **Write `Docs/playtests/<date>-<label>.md`.**
   - Any sheet banner first (blockquote), then the title `# Playtest <date> <label>`.
   - Header: seed, commit (`git rev-parse --short HEAD`), the persona list with run numbers, the day caps (`rules_days`, `days`), and each run's outcome. "Changes since last report" must note when the previous report used different day caps, since a 25-day run and a full run are not comparable. Failed runs read `failed: <reason>`.
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
