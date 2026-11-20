# No negative stats on new heroes (short design)

## Intent

Newly generated heroes must never roll a negative stat. 0 is allowed.

## Cause

`GuildCharacter.generate_stat_spread` (`Scripts/Character Generator/character_resource.gd`)
draws one weight per stat with `randfn(total_points / 4, stat_deviation)` and
scales the weights to sum to `total_points`. A draw can land below zero (about a
2% chance per stat at the default 17 points / deviation 2; `HireScaling.deviation_for`
scales the spread with the budget, so the odds hold for later recruits). When the
weights sum to something tiny, the scaling also blows the other stats up.

## Goals / non-goals

- Goal: every stat from a fresh roll (`_init` and `reroll_stats`) is >= 0, and
  the stats still sum to `total_points` (before the +3 role bonus), as today.
- Non-goal: changing the shape of the spread, the point budgets, or the role bonus.
- Non-goal (Claude's call): heroes already in a save who have a negative stat
  are left as they are. No save migration, `SAVE_VERSION` unchanged.

## Approaches

1. **Redraw low weights (picked).** If a weight comes out below the floor, draw it
   again, up to a retry cap, then use the floor. Keeps the total and the normal
   shape; only the rare bad draws change.
2. Clamp final stats to 0. Rejected: adds points the budget didn't give.
3. Clamp weights to 0 before scaling. Rejected: piles stats up at exactly 0 more
   often than the normal curve would.

## Design

- In `character_resource.gd`, add documented tunables at the top:
  `MIN_STAT_WEIGHT := 0.0` (lowest a weight may be, in stat points) and
  `MAX_WEIGHT_REDRAWS := 20` (tries before falling back to `MIN_STAT_WEIGHT`).
- Pull the draw into a small helper (e.g. `_draw_stat_weight(mean, deviation) -> float`)
  that loops `randfn` until the result is `>= MIN_STAT_WEIGHT` or the cap is hit.
- `generate_stat_spread` uses the helper. Since every weight is >= 0 and their
  mean is `total_points / 4`, the sum can't collapse to near zero any more.
- Rounding stays as it is (the int assignment truncates), so a stat can be 0.

## Left to the builder

- Exact helper name and doc comments, per the project conventions.
- Verify with a headless test (in a scratch copy of the project) that generates
  many heroes at several budgets/deviations and checks no stat is negative.
