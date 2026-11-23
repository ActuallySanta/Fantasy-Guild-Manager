---
name: docs-vault
description: Build or update the Obsidian code-docs vault in Docs/vault (every script and function, every scene, system flow diagrams) by dispatching the docs-writer agent in batches. Use when the user says "/docs-vault", "update the docs vault", "document the code", or asks for the vault to be refreshed for a system or file.
---

# /docs-vault

This skill keeps `Docs/vault/` (an Obsidian vault) in step with the code. You, the main session, orchestrate. The `docs-writer` agent (`.claude/agents/docs-writer.md`) writes the notes. Always dispatch it with `model: "sonnet"`, one batch at a time (batches share `Home.md` and the system notes, so they never run in parallel).

Arguments:
- none: update, or bootstrap if the vault hasn't been built yet
- `<system name>`: refresh that system note
- `<path>`: refresh that script's or scene's note
- `resume`: continue an unfinished bootstrap

## 1. Index
Run `python tools/docs/index_functions.py`. It writes `Docs/vault/_meta/function_index.json` and prints the totals.

Then read `Docs/vault/_meta/sync.md` if it exists. It holds `last_commit`, `date` and `bootstrap_done`.

## 2. Pick the mode
- **No `sync.md`, or `bootstrap_done` doesn't list every batch:** bootstrap (step 3), starting from the first batch not yet done.
- **Otherwise:** update (step 4).
- **A system or path argument:** dispatch one agent for just that system or file (as in step 4), then do step 5.

Before a bootstrap or any run of more than 2 batches:
1. Check usage with `mcp__ccd_session_mgmt__get_usage`, per the user's global CLAUDE.md.
2. Tell the user how many batches are left and roughly what they cost. Each batch is one Sonnet agent reading about 2k lines; the whole bootstrap is several times one playtest persona.
3. If the 5-hour window is past about 60%, propose doing fewer batches now.

## 3. Bootstrap batches
Each batch is one dispatch. Include every script and scene listed, and the folder prefixes the agent should `--check`.

| Batch | Scripts | Scenes |
|---|---|---|
| B1 | `Globals/` | none |
| B2 | `Scripts/Hall/hall_main.gd`: create the note and document functions up to line 950 | `Scenes/hall_main.tscn` |
| B3 | `Scripts/Hall/hall_main.gd`: add the functions after line 950 to the same note | none |
| B4 | `Scripts/Hall/Rules/`, `Scripts/Quest Creator/`, `Scripts/Character Generator/`, `Scripts/Item System/` | none |
| B5 | `Scripts/Hall/Save/`, `Scripts/Hall/Web/`, `Scripts/Hall/Debug/`, `Scripts/Credits/` | none |
| B6 | `Scripts/Hall/Style/` | none |
| B7 | `Scripts/UI/Shell/`, `Scripts/UI/Tabs/`, `Scripts/UI/Screens/` | `Scenes/Shell/`, `Scenes/Tabs/`, `Scenes/Screens/` |
| B8 | `Scripts/UI/Overlays/Day/` | `Scenes/Overlays/Day/` |
| B9 | `Scripts/UI/Overlays/Items/`, `Menu/`, `Run End/` | `Scenes/Overlays/Items/`, `Menu/`, `Run End/` |
| B10 | `Scripts/UI/Rows/`, `Scripts/UI/Components/` | `Scenes/Rows/`, `Scenes/Components/` |
| B11 | `Scripts/Playtest/` | `Scenes/Playtest/` |
| S1 | Systems: Boot and Autoload Order, Day Cycle, Hiring Characters, Party Drafting and Assignment, Success Chance | |
| S2 | Systems: Quest Generation and Difficulty, Quest Resolution and Injuries, Night - Training Hospital Revive, Economy and Wallet, Items and Shop | |
| S3 | Systems: Saving Migration and Backup Codes, Run End, UI Motion and Feedback, UI Architecture and Refresh, Playtest Bridge; then `Home.md` | |

B3 has no `--check` of its own for `hall_main.gd` until it finishes: run `--check Scripts/Hall/hall_main` after B3, not after B2.

What each system note covers:
- **Boot and Autoload Order:** load order in `project.godot` and `hall_main._ready` (loading the save).
- **Day Cycle:** `end_day` → `_run_quest` → night → `GameState.start_new_day` → `day_started` listeners → refresh.
- **Hiring Characters:** the For Hire pool, `HireScaling`, the hire action, `GuildCharacter.new`, returning heroes.
- **Party Drafting and Assignment:** `screen_assign` and slot counts.
- **Success Chance:** `stats` → `reset_temp_stats` (pluck, gear) → `calcSuccessChance` / `QuestScoring.get_success_chance` → the odds bar.
- **Quest Generation and Difficulty:** `HallRules.build_day_quests`, the count and rank tables, regions and monsters, bosses on days 10/20/30/40/50, `freeplay_scale`, hire scaling.
- **Quest Resolution and Injuries:** `play_quest` → `generateResults` / `generateMilestoneResults` → `did_succeed` → gold, injuries, pluck, deaths.
- **Night - Training Hospital Revive:** `GuildUpgrades.run_night`.
- **Economy and Wallet:** gold and standing, `HallWallet`, building upgrades.
- **Items and Shop:** restock, the rarity roll by standing rank, buying, role-locked equipping and the slot cap (`HallGear`).
- **Saving Migration and Backup Codes:** `HallSave` snapshot/apply/migrate, `HallSaveTransfer`, `HallWebFiles`.
- **Run End:** `HallLedger` danger checks, Game Over, the final battle, credits, freeplay S++.
- **UI Motion and Feedback:** `HallFx`, the header counters and popups, crawl roll and sections, tap panel, drag scroll, reduced motion, font scale, `Sfx` hooks.
- **UI Architecture and Refresh:** `setup(hall)` / `refresh()`, the tutorial and feature locks.
- **Playtest Bridge:** short.

`Home.md` gets:
- the systems list
- a full scene-tree Mermaid diagram from `hall_main (scene)`: solid `-->` for placed in the editor, dotted `-.->` for runtime. Split it by tab or overlay if it's too big.
- scripts by folder, and scenes by folder (as wikilinks)
- keep the existing Tests line

Prompt for each batch (fill in the blanks):
> Batch `<id>` of the docs-vault bootstrap. Commit: `<git rev-parse HEAD>`.
> Scripts: `<list>`. Scenes: `<list>`. (Or systems: `<list>`.)
> Create the notes from the templates in `Docs/vault/Templates/`. Use `python tools/docs/index_functions.py --show <paths>` as your checklist.
> Finish with `--check <prefixes>` at 0 gaps.

After each batch:
1. Check the agent's reply and run `--check` on the batch prefixes yourself.
2. If gaps remain, send them back to the same agent once (SendMessage).
3. Add the batch id to `bootstrap_done` in `sync.md` (create the file after B1).
4. Don't message the user per batch. Gather the results and report at the end, or when stopping for usage.

## 4. Update run
1. Run `git diff --name-only <last_commit>..HEAD -- '*.gd' '*.tscn'` to get the changed files under `Globals/`, `Scripts/` and `Scenes/`.
2. If nothing changed, say "Vault is current" and stop. Don't dispatch anything.
3. Work out the notes to refresh:
   - each changed file's own note
   - for a changed scene, the notes of its parent and child scenes (from the index)
   - every system note that links to a changed script (Grep `Docs/vault/Systems/` for `[[<stem>`)
   - new files go to the agent as "create a note; decide which systems it belongs to"
   - deleted files: delete their notes and remove links to them
4. Dispatch **one** agent with the changed files, `last_commit`, the HEAD hash and the notes to refresh. Split into 2 dispatches only if the changed files total more than about 3k lines.

## 5. Finish
1. Run `python tools/docs/index_functions.py --check`. Everything should show 0 gaps once the bootstrap is complete; while it's still running, check only the prefixes that are done.
2. Run `git status --short` and confirm every file the agents changed is under `Docs/vault/`. If anything else changed, tell the user; don't keep it silently.
3. Write `Docs/vault/_meta/sync.md`:
   ```
   ---
   last_commit: <HEAD hash>
   date: <YYYY-MM-DD>
   bootstrap_done: [B1, B2, …]
   ---
   Last /docs-vault pass. Written by the docs-vault skill; don't edit by hand.
   ```
4. Summarize for the user in a few lines:
   - notes created and updated
   - the gap count
   - the agents' "suspected issues" in the code, each with `file:line`
   - nothing is committed unless the user asks
