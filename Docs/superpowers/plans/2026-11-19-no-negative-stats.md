# No Negative Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Newly generated heroes never roll a negative stat (0 is allowed).

**Architecture:** `GuildCharacter.generate_stat_spread` draws each stat's weight through a new helper that redraws `randfn` results below a floor, up to a retry cap, then falls back to the floor. Scaling, rounding and the role bonus are unchanged.

**Tech Stack:** Godot 4.7, GDScript. Headless test scene run in a scratch copy of the project.

**Spec:** `Docs/superpowers/specs/2026-11-19-no-negative-stats-design.md`

## Global Constraints

- Floor is 0: `MIN_STAT_WEIGHT := 0.0`; retry cap `MAX_WEIGHT_REDRAWS := 20`.
- No save format change: `SAVE_VERSION` unchanged, no migration, existing heroes untouched.
- Project conventions (CLAUDE.md): snake_case, `##` doc comments with units on tunables and functions, tunables at the top of the file.
- Tests run in a scratch copy of the project, never in the repo (`--import` / `.uid` churn).

## Review Focus

- Very large spread relative to the mean (e.g. deviation 10 at 17 points): no negative stat, no blown-up stat; the fallback path is hit. Covered by the stress case in Task 1.
- Late-game budgets from `HireScaling` (deviation grows with points): no negative stat. Covered by the budget loop in Task 1.
- Stats must not exceed the budget plus role bonus (the old near-zero-sum blow-up). Covered by the upper-bound assertion in Task 1.
- Both entry points (`_init` and `reroll_stats`) go through the helper. Covered: test uses both.

---

### Task 1: Redraw negative stat weights

**Files:**
- Modify: `Scripts/Character Generator/character_resource.gd` (tunables near the existing `stat_deviation` / `total_points` vars; `generate_stat_spread` at ~146-172)
- Test (scratch copy only, not committed): `res://test_no_negative_stats.gd` + `res://test_no_negative_stats.tscn` (a root `Node` with the script)

**Interfaces:**
- Produces: `const MIN_STAT_WEIGHT := 0.0`, `const MAX_WEIGHT_REDRAWS := 20`, `func _draw_stat_weight(mean: float, deviation: float) -> float` on `GuildCharacter`.

- [ ] **Step 1: Make the scratch copy and write the failing test**

Copy the repo (excluding `.git`) into the session scratchpad, run `godot --headless --path <copy> --import` once. In the copy, write `test_no_negative_stats.gd` (`extends Node`), whose `_ready` does:

```gdscript
var failures := 0
# _init path: default 17 points, deviation 2
for i in 3000:
	failures += _check(GuildCharacter.new(), 17)
# reroll path: HireScaling budgets, plus a stress spread
for points in [17, 30, 60, 120]:
	for i in 1000:
		var c := GuildCharacter.new()
		c.reroll_stats(points, HireScaling.deviation_for(points))
		failures += _check(c, points)
for i in 2000:
	var c := GuildCharacter.new()
	c.reroll_stats(17, 10)
	failures += _check(c, 17)
print("NEGATIVE_STATS_TEST ", "PASS" if failures == 0 else "FAIL %d" % failures)
get_tree().quit(1 if failures else 0)
```

`_check(c, points) -> int` returns 1 if any `c.stats[s] < 0` or any `c.stats[s] > points + 3`, else 0.

- [ ] **Step 2: Run it and see it fail**

Run: `godot --headless --path <copy> res://test_no_negative_stats.tscn`
Expected: `NEGATIVE_STATS_TEST FAIL <n>` with n > 0.

- [ ] **Step 3: Implement in `character_resource.gd`**

Add the two documented constants. Add `_draw_stat_weight(mean, deviation)`: loop up to `MAX_WEIGHT_REDRAWS` times calling `randfn(mean, deviation)`, return the first result `>= MIN_STAT_WEIGHT`; after the cap return `MIN_STAT_WEIGHT`. In `generate_stat_spread`, replace the `randfn(...)` call with `_draw_stat_weight(float(_total_points) / _stats.size(), stat_deviation)`.

Note: the old call used integer division (`_total_points / _stats.size()`); switching to float division nudges the mean up by under 1 point per stat and doesn't change the total (weights are normalized). Acceptable and intended.

- [ ] **Step 4: Copy the edited file into the scratch copy and rerun**

Run: same command as Step 2.
Expected: `NEGATIVE_STATS_TEST PASS`, exit code 0.

- [ ] **Step 5: Commit (in the repo, after asking Santi)**

```bash
git add "Scripts/Character Generator/character_resource.gd" Docs/superpowers/specs/2026-11-19-no-negative-stats-design.md Docs/superpowers/plans/2026-11-19-no-negative-stats.md
git commit -m "Fix: heroes can no longer roll negative stats"
```

READMEs: neither `README.md` nor `Docs/hall_design.md` describes stat rolling, so no doc update is needed.
