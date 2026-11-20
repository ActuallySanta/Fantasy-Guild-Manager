# AI Playtesters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `/playtest` command that runs 8 AI persona subagents through the real game via a debug-only bridge, writes a dated comparison report, and logs AI runs to separate AI tabs and charts in the run-log Google Sheet.

**Architecture:** A debug-only Godot scene (`agent_bridge`) wraps `HallMain` in a scratch copy of the project. It reads command files and writes response files, in rules mode (text state plus hall actions) or eyes mode (screenshot plus taps). Bash scripts in `tools/playtest/` prepare the scratch copy, launch the bridge, and send it commands. Persona agents in `.claude/agents/` drive the bridge through those scripts, and a project skill orchestrates the run and writes the report. `RunLogger` gains an AI target that posts to a new `AI Raw` tab. The sheet gets mirrored AI tabs and charts through the Google Sheets connector.

**Tech Stack:** Godot 4.7 GDScript, Git Bash scripts, Claude Code subagents and skills, Google Apps Script, the Google Sheets connector.

**Spec:** `Docs/superpowers/specs/2026-11-20-ai-playtesters-design.md`

## Global Constraints

- Godot: `"/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"` (4.7). Never run `--import` in the repo itself, only in the scratch copy.
- Bridge files are debug-only and must not ship: every preset in `export_presets.cfg` gets `exclude_filter="Scenes/Playtest/agent_bridge.tscn, Scripts/Playtest/agent_bridge*.gd"`. `tools/` gets a `.gdignore` so Godot never imports it.
- The scratch copy's `project.godot` gets `config/name` suffixed with ` (Playtest)`, so its `user://` (settings, CSVs) is separate from the real game's.
- Run state lives on the bridge node. No `static var`, no new autoload.
- No game-logic changes in `hall_main.gd` (about 1,830 lines). Its only change is the intro launch flag (Task 4).
- CLAUDE.md conventions apply: script headers naming the scene, `##` docs, tunables as documented constants at the top, uid preloads with a path comment, about 800 lines per script (split the bridge into `agent_bridge.gd` + `agent_bridge_state.gd` + `agent_bridge_eyes.gd` if needed).
- The human run-log payload, columns, CSV and `Sheet1` stay byte-for-byte unchanged. AI rows add extra columns only in the AI payload.
- The default `/playtest`: personas 1, 4, 5, 6; 2 runs each; fixed default seed `4417`; rules runs go to Game Over or the day-50 credits; eyes runs cover days 1–5. Tutorial on for everyone.
- No save-format changes. The bridge runs with `uses_save_file == false`, so nothing is saved.

## Review Focus

- **Two parallel runs with the same seed:** the logger's `run_id` comes from `randi()`, so with seeding they would collide. The bridge must set a unique run_id (`ai-<label>-<persona>-<run>`). Test in Task 5.
- **A command sent while the night is still falling or the report is still animating:** the bridge must not return until the hall settles (`is_night_falling == false` and the next day started), or the next command acts on a half-finished state. Test in Task 3.
- **Old sheet script still deployed:** AI rows must never reach `Sheet1`. With the doGet check failing, nothing is posted and `status` reports `sheet: "not_redeployed"`. Test in Task 5.
- **Bridge process dies or hangs:** `bridge.sh` must time out (`BRIDGE_TIMEOUT_SECONDS=60`) with a clear error instead of hanging an agent forever. Test in Task 1.
- **Run ends mid-plan** (Game Over, final battle credits, Drake loss): the `end_day` response must say `run_over: true` with the reason, and later actions return an error, not a crash. Test in Task 3.

---

### Task 1: Scratch copy, launcher, transport, and a bridge that answers `ping`

**Files:**
- Create: `tools/.gdignore` (empty)
- Create: `tools/playtest/prepare.sh`, `tools/playtest/launch.sh`, `tools/playtest/bridge.sh`, `tools/playtest/stop.sh`
- Create: `Scenes/Playtest/agent_bridge.tscn` (root `Control` named `AgentBridge`, script below, child: instance of `Scenes/hall_main.tscn` named `HallMain`, uid ext_resource like `scenario_*.tscn`)
- Create: `Scripts/Playtest/agent_bridge.gd`
- Modify: `export_presets.cfg` (every preset's `exclude_filter`)
- Test: `tools/playtest/tests/test_ping.sh`

**Interfaces:**
- Produces:
  - `prepare.sh <dest_dir>`: copies `git ls-files -co --exclude-standard` (working tree, including uncommitted changes) into `dest_dir`, appends ` (Playtest)` to `config/name`, runs `godot --headless --path <dest> --import`. Exits 0 when done.
  - `launch.sh <project_dir> <bridge_dir> [--headless] -- <user args>`: starts Godot in the background on `res://Scenes/Playtest/agent_bridge.tscn` with the user args after `--`, writes the PID to `<bridge_dir>/pid`, and waits until `<bridge_dir>/ready.json` exists (timeout 60 s).
  - `bridge.sh <bridge_dir> <command> [json_args]`: writes `{"id": N, "command": ..., "args": ...}` to `<bridge_dir>/cmd.json` (N from `<bridge_dir>/next_id`), waits for `<bridge_dir>/resp.json` with the same id, prints its JSON. On timeout it prints `{"ok":false,"error":"bridge timeout"}` and exits 2.
  - `stop.sh <bridge_dir>`: sends `quit`, then kills the PID if it's still alive after 15 s.
  - Bridge user args (`OS.get_cmdline_user_args()`): `--bridge-dir=<abs path>` (required), `--mode=rules|eyes`, `--seed=<int>`, `--persona=<slug>`, `--run=<int>`, `--label=<slug>`, `--intro`, `--text-size=<0-2>`, `--color-filter=<int>`, `--reduce-motion`, `--no-sheet`.
  - The bridge answers every command with `{"id": N, "ok": bool, ...}`. `ping` → `{"ok":true,"mode":..., "day": GameState.day}`. Unknown command → `ok:false, error:"unknown command <x>"`.

- [ ] **Step 1: Write `tests/test_ping.sh`.** It runs prepare into `$TMP/pt`, launches with `--headless -- --bridge-dir=$TMP/b1 --mode=rules --seed=1`, then asserts: `bridge.sh ping` output contains `"ok":true` and `"day":1`; `bridge.sh nonsense` contains `unknown command`; after `stop.sh`, the PID is gone; `bridge.sh ping` on a stopped bridge exits 2 within `BRIDGE_TIMEOUT_SECONDS` (override to 5 for the test).
- [ ] **Step 2: Run it.** Expect FAIL (scripts missing).
- [ ] **Step 3: Write the four shell scripts, `.gdignore`, and `agent_bridge.tscn`/`.gd`.** The bridge parses args in `_enter_tree`, polls `cmd.json` in `_process` (constant `POLL_INTERVAL_SECONDS := 0.05`), dispatches through a `match`, writes `resp.json` atomically (write `resp.tmp`, then rename), and writes `ready.json` at the end of `_ready`. Add the `exclude_filter` to all presets.
- [ ] **Step 4: Run `tests/test_ping.sh`.** Expect PASS.
- [ ] **Step 5: Commit** `feat(playtest): agent bridge skeleton, scratch copy and transport scripts`.

### Task 2: Seeding and rules-mode `state`

**Files:**
- Modify: `Scripts/Playtest/agent_bridge.gd`
- Create: `Scripts/Playtest/agent_bridge_state.gd` (`class_name AgentBridgeState`, static functions, no nodes)
- Test: `tools/playtest/tests/test_seed.sh`

**Interfaces:**
- Produces: `AgentBridgeState.build(hall: HallMain) -> Dictionary`, returned by the `state` command:
  `{day, days_until_drake, gold, standing, run_over, locked: {feature: bool}, roster: [{id, name, role, injury, pluck, stats, gear:[item ids], can_quest, training}], hires: [{id, name, role, cost, stats}], quests: [{index, name, kind (normal|milestone|final), slots, party:[ids], chance, decided, denied}], shop: [{index, name, rarity, cost, stat_bonus, sold}], items: [{id, name, worn_by}], buildings: [{id, name, level, upgrade_cost}]}`.
  `id` is `get_instance_id()` (stable for the process). Values come from the existing hall queries (`roster()`, `success_chance`, `party_size_limit`, `is_locked`, `days_until_drake`, `is_run_over`) and autoloads, never recomputed.
- Seeding: `seed(seed_value)` in the bridge's `_enter_tree`, which runs before the autoloads' `_ready` (see the `playtest_scenario.gd` header), so the first hire pool, shop stock and the hall's day-1 quests all come from the seed.

- [ ] **Step 1: Write `tests/test_seed.sh`.** Two headless launches with `--seed=4417` into separate bridge dirs, then a third with `--seed=99`. Assert the `state` outputs of the first two, with `id` fields stripped (`sed`), are identical (`hires`, `quests`, `shop`, `roster` names and stats), and that the third differs.
- [ ] **Step 2: Run it.** Expect FAIL (`state` is an unknown command).
- [ ] **Step 3: Implement seeding and `AgentBridgeState.build`.** Wire up `state`. If Step 4 shows the first roll is not seeded (autoload `_ready` ran first), re-seed in the bridge's `_ready` and re-roll with `CharacterContainer.refresh_hireable_characters()`, `ItemShop.restock()` and a new public one-line wrapper `HallMain.reroll_quests_for_playtest()` that calls `_generate_quests()`, with no toast.
- [ ] **Step 4: Run `tests/test_seed.sh`.** Expect PASS.
- [ ] **Step 5: Commit** `feat(playtest): seeded runs and rules-mode state snapshot`.

### Task 3: Rules-mode actions: `plan` and `end_day`

**Files:**
- Modify: `Scripts/Playtest/agent_bridge.gd`
- Test: `tools/playtest/tests/test_rules.sh`

**Interfaces:**
- Consumes: `state` ids from Task 2.
- Produces:
  - `plan` with args `{hire:[id], release:[id], buy:[shop index], equip:[[item_id, hero_id]], unequip:[item_id], train:[[hero_id, stat int]], stop_training:[id], admit:[id], discharge:[id], revive:[id], upgrade:[building id], assign:[{quest:int, party:[id]}], deny:[quest index]}`. The steps run in that key order, each through its hall action (`hire`, `release`, `buy_item`, `equip_item`, `unequip_item`, `train`, `stop_training`, `admit`, `discharge`, `revive`, `upgrade_building`, then `open_assign` + `toggle_in_party` per hero, then `deny_quest`). The response is `{ok, applied:[...], rejected:[{step, reason}], state}`. A locked feature (`is_locked`) or a failed action counts as rejected, not as an error.
  - `end_day`: errors if `undecided_count() > 0` (lists the undecided quests). Otherwise it turns reduce motion on for rules mode, calls `hall.end_day()`, and waits until `is_night_falling` is false and `shown_report` is set (or credits or Game Over are showing; `MAX_SETTLE_SECONDS := 20`). It then returns `{ok, report:{results:[{quest, succeeded, gold, injuries, deaths, story_text (BBCode stripped)}], home}, run_over, run_over_reason (game_over|final_won|final_lost|null)}`, calls `hall.start_new_day()` unless the run is over, and then includes the new `state`.
  - After the run is over, every action command returns `ok:false, error:"run over"`.

- [ ] **Step 1: Write `tests/test_rules.sh`** (seed 4417, headless).
  - Day 1: send `plan` assigning the starting hero to quest 0 and denying the rest. Assert `applied` is non-empty.
  - `end_day` → `"day"` in the returned state is 2, and `report.results` has 1 entry.
  - `end_day` while a quest is undecided → `ok:false` naming it.
  - Test hooks, which exist only when launched with `--test-hooks` (so personas can't use them): `debug {"call":"debug_jump_to_day","args":[50]}` passes through to the hall's `debug_*` functions, and `kill_all` marks every hero dead the same way a quest death does (check `HallStyle.is_dead` for the field it reads).
  - Jump to day 50 and assert the final quest is on the board (`kind:"final"`).
  - In a fresh launch, call `kill_all`, deny everything, and `end_day`. Assert `run_over_reason:"game_over"`, and that a later `plan` returns `"run over"`.
- [ ] **Step 2: Run it.** Expect FAIL.
- [ ] **Step 3: Implement `plan`, `end_day`, the run-over guard and the `--test-hooks` commands** (`debug` allowlist: names starting `debug_`).
- [ ] **Step 4: Run `tests/test_rules.sh`.** Expect PASS.
- [ ] **Step 5: Commit** `feat(playtest): rules-mode day plans and end of day`.

### Task 4: Eyes mode: screenshot, tap, wait, intro, accessibility flags

**Files:**
- Create: `Scripts/Playtest/agent_bridge_eyes.gd` (`class_name AgentBridgeEyes`, static helpers)
- Modify: `Scripts/Playtest/agent_bridge.gd`
- Modify: `Scripts/Hall/hall_main.gd`: add `var shows_intro_without_save := false` (documented). `is_intro_open()` becomes `is_intro_replay or ((uses_save_file or shows_intro_without_save) and not is_intro_seen and GameState.day == 1)`.
- Test: `tools/playtest/tests/test_eyes.sh` (windowed, not headless)

**Interfaces:**
- Produces (in eyes mode, only these plus `ping`, `status` and `quit` are allowed; everything else returns `"not allowed in eyes mode"`):
  - `screenshot` → saves `get_viewport().get_texture().get_image()` to `<bridge_dir>/shots/<day>-<n>.png` and returns `{path, width, height, day}`.
  - `tap {x, y}` → mouse press, then release a frame later, sent with `get_viewport().push_input(event, true)` in 720x1280 viewport coordinates. Waits `TAP_SETTLE_SECONDS := 0.6`, then returns a new `screenshot`.
  - `wait {seconds}` (max 10) → returns a `screenshot`.
- Launch flags (both modes): `--intro` sets `shows_intro_without_save` before the hall's `_ready` (set it in the bridge's `_enter_tree`, or on the instanced child before it's added to the tree). `--text-size`, `--color-filter` and `--reduce-motion` call `hall.set_text_size`, `set_color_filter` and `set_reduce_motion` in the bridge's `_ready`. Rules mode always uses reduce motion.

- [ ] **Step 1: Write `tests/test_eyes.sh`.**
  - Launch windowed with `--mode=eyes --seed=4417 --intro`.
  - `screenshot` → the PNG exists and the width/height are 720/1280.
  - `state` → `not allowed in eyes mode`.
  - Find the intro's Begin button position: use a `debug_rect` command that exists only when `--test-hooks` is passed and returns a named node's global rect. Tap its center, then assert with a second `debug_rect`/`ping` field `intro_open:false`.
  - A second launch with `--text-size=2` → `ping` reports `text_size:2`.
- [ ] **Step 2: Run it.** Expect FAIL.
- [ ] **Step 3: Implement eyes mode, the hall flag and the launch flags.** Make `ping` include `intro_open` and `text_size`.
- [ ] **Step 4: Run `tests/test_eyes.sh`, then rerun `test_ping.sh`, `test_seed.sh` and `test_rules.sh`.** Expect all to PASS.
- [ ] **Step 5: Commit** `feat(playtest): eyes mode with screenshots and taps, intro flag`.

### Task 5: RunLogger AI target and the Apps Script update

**Files:**
- Modify: `Scripts/Hall/Debug/run_logger.gd`
- Modify: `Scripts/Playtest/run_log_apps_script.gs`
- Modify: `Scripts/Playtest/agent_bridge.gd` (calls `configure_ai` in `_ready`; adds `status`; `quit` flushes first)
- Test: `tools/playtest/tests/test_logger.sh`

**Interfaces:**
- Produces on `RunLogger`:
  - `const AI_COLUMNS := ["persona", "seed", "run_number", "mode"]` (appended after `COLUMNS` in AI rows only).
  - `const AI_CSV_PATH := "user://run_log_ai.csv"`, `const AI_SHEET_NAME := "AI Raw"` (documentation only; the script owns the tab name).
  - `func configure_ai(run_id: String, persona: String, seed_value: int, run_number: int, mode: String, can_post: bool) -> void`: switches this logger to the AI target. AI rows go to `AI_CSV_PATH` (not `CSV_PATH`) with the extra columns and are posted with `{"token", "sheet":"ai", "columns": COLUMNS + AI_COLUMNS, "rows"}`. If `can_post` is true, it first GETs `SHEET_URL`. Only `{"ok":true,"ai_tab":true}` sets `ai_sheet_status = "ready"` and allows `_send()`. Otherwise `ai_sheet_status = "not_redeployed"` (or `"offline"` on a network failure), and nothing is posted.
  - `var ai_sheet_status: String` (`"off" | "checking" | "ready" | "not_redeployed" | "offline"`), and `func pending_rows() -> int`.
  - Human mode is unchanged: same columns, CSV and payload (no `sheet` key).
- Produces on the bridge: `status` → `{ok, day, run_id, sheet: ai_sheet_status, pending_rows, user_dir: OS.get_user_data_dir()}`. `quit` waits up to `QUIT_FLUSH_SECONDS := 15` for `pending_rows() == 0` (only when the sheet is `ready`). The bridge's run_id is `ai-<label>-<persona>-<run>-<unix time>`. `--no-sheet` passes `can_post=false`.
- Apps Script: `doGet` returns `{ok:true, message, ai_tab:true}`. `doPost` picks the tab with `data.sheet === "ai" ? getOrCreateAiSheet() : (ss.getSheetByName("Sheet1") || ss.getSheets()[0])`. `getOrCreateAiSheet` inserts `AI Raw` at the end if it's missing, and makes sure `getMaxColumns() >= data.columns.length` (`insertColumnsAfter`) before writing the header and rows.

- [ ] **Step 1: Write `tests/test_logger.sh`.**
  - Launch with `--no-sheet --persona=typical --run=1 --label=t`, play one `end_day`, then `status`.
  - Assert `sheet` is `"off"`.
  - Assert `<user_dir>/run_log_ai.csv` exists, its header ends with `,persona,seed,run_number,mode`, and its row contains `typical`.
  - Assert `<user_dir>/run_log.csv` was not created or changed by this run (compare mtime before/after).
  - Assert two parallel launches with the same seed report different `run_id`s.
  - Separately, against the live URL with the old script (the state today), launch without `--no-sheet` and assert `status.sheet` becomes `"not_redeployed"` within 15 s.
- [ ] **Step 2: Run it.** Expect FAIL.
- [ ] **Step 3: Implement the logger changes, the bridge `status`/`quit` changes, and the Apps Script edits.** Update the script's header comment: AI rows go to `AI Raw`, and a redeploy is needed after editing.
- [ ] **Step 4: Run `tests/test_logger.sh` and all earlier tests.** Expect PASS. Also launch the real game (`hall_main.tscn`) headless for 5 s and confirm no RunLogger errors in the output.
- [ ] **Step 5: Commit** `feat(playtest): AI run-log target with redeploy check`.
- [ ] **Step 6: Tell Santi** that the Apps Script needs pasting and redeploying (Deploy → Manage deployments → New version) from the owner's account before AI rows reach the sheet. Don't block later tasks on it.

### Task 6: AI tabs and charts in the run-log sheet

Done through the Google Sheets connector against spreadsheet `1YN1BRbHZNM5ZyHxs8oSd4T0L0wtOcbYK4MuKLQNC8QM`. No repo files change. The existing pipeline is `Sheet1` → `Day Ends` (id 103) → `Runs` (102) → `Summary` (101) → `Charts` (100, 8 charts).

- [ ] **Step 1: Check write access.** Add a throwaway tab, then delete it. If that fails, stop and tell Santi.
- [ ] **Step 2: Create the tabs** `AI Raw` (header row = `COLUMNS + AI_COLUMNS`, frozen row 1, 31 columns, so the formulas work before the first post), `AI Day Ends`, `AI Runs`, `AI Summary` and `AI Charts`.
- [ ] **Step 3: Copy the formulas.**
  - `AI Day Ends`: copy the `Day Ends` formulas with `Sheet1!` → `'AI Raw'!` and `A:AA` → `A:AE`.
  - `AI Runs`: copy the `Runs` formulas with `'Day Ends'!` → `'AI Day Ends'!`. Add `I` "Persona" (XLOOKUP on `'AI Day Ends'!AB`), `J` "Seed" (`AC`), and `K` "Run number" (`AD`).
  - `AI Summary`: copy all of `Summary` (labels and formulas) with `Runs!` → `'AI Runs'!` and `'Day Ends'!` → `'AI Day Ends'!`. Then make these changes:
    - The "Runs started per date" block becomes Date (M) plus one column per persona (N–U, headers = the 8 persona slugs, `COUNTIFS('AI Runs'!C2:C, t, 'AI Runs'!I2:I, <slug>)`).
    - Move the "Quest odds & Pluck" block right by 7 columns so it doesn't collide.
    - Add a "Last day reached by persona" block: the persona slug, then `IFERROR(MEDIAN(FILTER('AI Runs'!D2:D,'AI Runs'!I2:I=slug)),)`.
    - `B10` (minimum runs to chart) = 2, since AI runs are fewer.
- [ ] **Step 4: Recreate the charts on `AI Charts`.** Read the 8 chart specs from `Charts` with `get_spreadsheet` and recreate each one (same type, titles, axes, sizes, anchors) with `sourceRange.sheetId` pointing at `AI Summary`, and columns shifted to match Step 3's moves. "Runs started per date" becomes a stacked column chart with 8 series (by persona). Add a 9th chart, "Last day reached by persona" (column, anchored below the others).
- [ ] **Step 5: Verify.** Paste two fake `day_end` rows into `AI Raw` (persona `test`) and confirm `AI Runs` shows 1 run and the AI charts draw. Delete the fake rows, then confirm `Sheet1`, `Summary` and `Charts` are untouched (spot-check `Summary!B4`).

### Task 7: The 8 persona agents

**Files:**
- Create: `.claude/agents/playtester-min-maxer.md`, `-cautious-planner.md`, `-reckless-gambler.md`, `-typical-player.md`, `-first-timer.md`, `-skimmer.md`, `-accessibility.md`, `-genre-veteran.md`

**Interfaces:**
- Consumes: the `bridge.sh` commands from Tasks 1–4.
- Produces: each agent is given `bridge_dir`, `diary_path`, `day_cap` and `game_rules_hint: none` in its prompt by the skill. It writes its diary to `diary_path` and ends with exactly this fenced JSON block, which the skill parses:
  `{"persona", "run", "mode", "furthest_day", "run_over_reason", "drake": "won|lost|not_reached", "deaths", "gold_by_day":[...], "standing_by_day":[...], "strategies":[...], "confusions":[{"day","screen","what","screenshot"}], "ui_issues":[{"screen","issue","severity 1-3","screenshot"}], "verdict": "one paragraph"}`

- [ ] **Step 1: Write the eight files.** Each has frontmatter (`name`, `description`, `tools: Bash, Read, Write`) and a body covering:
  - Who they are and their skill level (the spec's persona table row).
  - How they decide (for example, the min-maxer reads every number and hunts for exploits; the cautious planner never sends at under 70%; the gambler always fills every quest; the skimmer reads at most the first line of any text and taps the most prominent button).
  - What to note, and the exact commands allowed: rules agents use `state`, `plan` and `end_day`, one `plan` + `end_day` per day; eyes agents use only `screenshot`, `tap` and `wait`, and Read every PNG.
  - Stopping at `day_cap` or run over.
  - Never reading game source files: they learn the game only by playing it.
  - The required JSON block.
  The first-timer and the skimmer must say aloud what they think each button does before tapping it.
- [ ] **Step 2: Dry-run check.** Launch one rules bridge (seed 4417), dispatch `playtester-typical-player` with `day_cap: 3`, and confirm it returns a valid JSON block with `furthest_day >= 3`. Then do the same for `playtester-first-timer` with an eyes bridge and `day_cap: 1`.
- [ ] **Step 3: Commit** `feat(playtest): eight playtester persona agents`.

### Task 8: `/playtest` skill, report, and docs

**Files:**
- Create: `.claude/skills/playtest/SKILL.md`
- Create: `Docs/playtests/README.md` (what the reports are and how to read them)
- Modify: `README.md` (playtest section: one paragraph plus the command), `Docs/hall_design.md` (Debug tools / playtesting: the bridge, eyes vs. rules, the AI sheet tabs), `CLAUDE.md` (change "near 1,350" to "about 1,830" and add one line under Running and testing pointing at `/playtest` and `tools/playtest/`)

**Interfaces:**
- Consumes: the scripts from Tasks 1–5, the agents from Task 7, and the JSON block format.
- `SKILL.md` arguments: `personas=<comma slugs|all>` (default `min-maxer,typical-player,first-timer,skimmer`), `runs=<n>` (default 2), `seed=<n>` (default 4417), `label=<slug>` (default `run`), `days=<n>` (eyes day cap, default 5). Constant `MAX_PARALLEL = 4` bridges at once.
- Flow:
  1. `prepare.sh` into the scratch dir.
  2. For each (persona, run): `launch.sh` with the persona's mode and flags (accessibility uses `--text-size=2 --color-filter=1 --reduce-motion`; first-timer uses `--intro`), dispatch the persona agent in the background, then `stop.sh`.
  3. Check `status.sheet` once, and put a banner in the report if it isn't `ready`.
  4. Copy the screenshots referenced in the JSON blocks into `Docs/playtests/<date>-<label>/`.
  5. Write `Docs/playtests/<date>-<label>.md` with the spec's sections. The header carries the seed, `git rev-parse --short HEAD`, and the persona/run list. Balance figures appear as ranges across runs.
  6. "Changes since last report": read the newest earlier report's trailing `<!-- metrics {...} -->` JSON comment and compare it per persona. Every report ends with that comment.
  7. Don't commit. Tell Santi where the report is.

- [ ] **Step 1: Write `SKILL.md`, `Docs/playtests/README.md`, and the three doc edits.**
- [ ] **Step 2: Commit** `feat(playtest): /playtest skill, reports folder, docs`.

### Task 9: End-to-end verification

- [ ] **Step 1:** Run `/playtest label=baseline`. Expect 8 agent runs (4 personas × 2), a report at `Docs/playtests/2026-11-…-baseline.md` with every section filled in except "Changes since last report" (it should say "first report"), and screenshots in its folder.
- [ ] **Step 2:** Run `/playtest label=baseline-repeat`. Expect a "Changes since last report" section that compares per persona.
- [ ] **Step 3:** Run `git status`. Only `Docs/playtests/` should change. No `.import`/`.uid` churn and no `.godot/` in the repo.
- [ ] **Step 4:** Check the export filters. For each preset, confirm `exclude_filter` lists both bridge paths. Optionally export the Windows preset to the scratch dir (not `Builds/`) and confirm `agent_bridge` is absent from the `.pck` (`strings <pck> | grep agent_bridge` → no match).
- [ ] **Step 5:** If Santi has redeployed the Apps Script by then, confirm `status.sheet == "ready"`, the AI tabs and charts filled in, and `Sheet1` got no AI rows. If not, report that this step is still pending.
