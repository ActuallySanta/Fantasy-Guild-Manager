# Difficulty and dilemmas: design

Date: 2026-11-21. Status: approved by Santi.

## Executive summary

- **The problem:** the first AI playtest found the game too easy and flat. Odds sat at 100-180% from about day 15, every run won both bosses and the final, and nothing felt like a hard choice. Quest difficulty stops rising at rank S, but heroes keep getting stronger.
- **The goal:** real trade-offs between heroes, gold and standing from day 5 onward, without adding anything new for players to keep track of. An average player should win 80-85% of the quests they send. One bad day should be recoverable, and a losing streak should be alarming.
- **Phase A, rules and bosses:**
  - Quests get harder each day, with a boss every 10 days that spikes the difficulty and leaves it higher afterwards. The bosses are the Drake, the Drake and Necromancer, one Demon General, two Demon Generals, then the Demon King.
  - A failed quest costs half the standing a win pays.
  - Injuries follow the odds, and losing adds a retreat hit to every hero.
  - Heroes only die on a failed quest, or if they were sent out already Hurt.
  - The Hospital heals more slowly.
  - Bosses use stories that are already written, and get the final's text crawl without its stats page.
  - Phase A ends with an AI playtest to tune the numbers.
- **Phase B, costs on existing buttons:**
  - Hire prices rise as the roster grows.
  - Hospital beds cost gold per night, shown on the Admit button.
  - A "guild in trouble" warning appears in the header.
  - The upgrade costs are rechecked.
- **Not included:** wages, new currencies, multi-day quests, and new story writing.
- **The rule everything follows:** every new cost shows on the button that pays it, and every new risk shows through numbers already on screen.

## Intent

The first AI playtest (`Docs/playtests/2026-11-20-run.md`) found the game easy and flat. Every full run won both the Bone Drake and the final. Odds sat at 100-180% from about day 15, and the testers' verdicts said nothing "felt like a hard choice." Santi wants it harder in a specific way:

- **Dilemmas, not dice.** Heroes, gold and standing are each wanted in several places at once. Choosing one use gives up another, and it's almost impossible to make a choice with no downside, even if the downside is small.
- **Standing is a target, not a currency.** It isn't spent. It's the number players weigh when choosing between a safe quest and a riskier one that could get them to the next upgrade threshold.
- **Failure is recoverable, streaks are alarming.** One bad day sets you back a few days. More than that should be real cause for alarm.
- **It starts at day 5,** once the player has learned to hire, pick quests and send parties.
- **Boss fights mark the run.** A major quest every 10 days, with a noticeable difficulty spike on the day. Afterwards difficulty comes back down, but never as low as before.
  - Day 10: the Bone Drake.
  - Day 20: the Resurrected Bone Drake and the Necromancer.
  - Day 30: one Demon General.
  - Day 40: two Demon Generals.
  - Day 50: the Demon King.
- **No new things to remember.** Human playtesters already forget Pluck and other small mechanics, so this work must not add to what players have to track.

The upgrade cost change in PR #76 is already done: 100k total, standing gates of 10/40/100/200. It assumes an average player denies about 15% of quests and wins 80-85% of the rest. This design is what makes that assumption true.

## Goals

- An average player wins about **80-85% of the quests they send** and denies about 15% of the board, so they win roughly **70% of all board quests**.
- **On a normal day the board offers a real choice,** from day 5 to day 49:
  - The player's best party on a quest of their own rank shows about **85-95%**.
  - A quest a rank above them shows about **55-75%**.
- **Bosses are a visible spike.**
  - A prepared party sees about **65-70%** against the bosses on days 10, 20, 30 and 40.
  - Against the Demon King on day 50 it's about **75-80%**, since losing him ends the run.
- **The odds tell the truth about risk.** Sending at better odds means fewer injuries, and that keeps improving above 100%.
- **Every quest wears heroes down a little, and losing hurts everyone in the party.**
- **Deaths are explainable.** A hero only dies on a failed quest, or if they set out already Hurt.
- **One failed quest costs about a day of progress.** Three failures in a few days put the guild in visible trouble.
- **Buildings max out around day 40 on average,** as PR #76 intends.

## Non-goals

- Wages, upkeep, or any cost that runs in the background between days.
- New currencies, multi-day quests, quest deadlines, or limits on how many quests you can accept.
- Changes to Pluck, training rules or the Office building.
- New boss story writing. The boss and lead-up stories already exist in `External Content/`; this work wires them up. The only content edit is fixing one copy-paste line (B0).

## Anti-goals (failure even if it "works")

- **Anything the player has to remember between days.** Every new cost shows on the button that pays it, and every new risk shows through numbers already on screen.
- **One bad day spiraling into Game Over.**
- **Deaths players can't explain**, like today's deaths at 150% odds.
- **Difficulty that punishes getting stronger,** for example quests that scale with the guild's power.

## The no-new-mechanics rule

Every change below must show up through one of:

1. **Numbers players already read:**
   - The odds percentage.
   - The odds word on Assign Party (`HallStyle.ODDS_BANDS`: Strong odds / Fair odds / Risky / Long shot).
   - Gold.
   - Standing.
2. **A price on the button you press:** Hire, Admit, Build.
3. **A warning the game shows unprompted:**
   - The header strip.
   - The boss countdown.

If a change can't be shown one of these ways, it doesn't belong in this work.

## Approaches considered

| Approach | What it is | Trade-off |
|---|---|---|
| **A. Retune existing rules and wire the bosses** | Difficulty staircase with boss spikes, failure costs standing, injuries follow the odds with a retreat hit on a loss, simpler death rule, slower Hospital, bosses on days 30/40/50. | Uses what already exists and is measurable with `/playtest`. Doesn't add new pressure on gold or heroes. |
| **B. A, plus costs on existing buttons** | Hire prices rise with roster size, Hospital beds cost gold, a "guild in trouble" warning. | Adds dilemmas between resources with no new concepts. Touches more files and adds one saved run-state value. |
| C. A + B + new quest systems | Multi-day quests, deadlines, board limits. | Strongest dilemmas, but a project of its own and much more for players to learn. |

**Chosen: A first, measured with `/playtest`, then B on top.** Santi picked this. B was revised after Santi raised cognitive load: wages were dropped and replaced with costs on buttons that already exist.

**How quests get harder over time:**
- **A staircase by day, chosen.** It's predictable, it gives each boss a spike and a lasting step up, and it doesn't punish getting stronger.
- **Scaling by the guild's power, rejected.** It's a rubber band that makes training and gear pointless, which is an anti-goal.
- **Scaling by standing, rejected.** Standing stops mattering past rank S (standing 50), and extending the ranks would need new content.

**How injuries relate to winning and losing:** Santi chose (c).
- **(a) Roll the outcome first, then pick the injuries.** Wins are nearly free, and losses are where people get hurt.
- **(b) Injuries independent of the outcome.** Losing costs only standing and gold, and deaths come almost entirely from sending hurt heroes.
- **(c) Chosen: fights wear heroes down at rates set by the odds, and a loss adds one retreat hit to every hero.** There's steady pressure on the roster, plus a clear, painful cost for each failure. It's also the simplest to build: the fights play out as they do now, with one extra step at the end.

## Phase A: retune existing rules and wire the bosses

### A1. The difficulty staircase

**Today:**
- The requirement is `(60 + 20 × rank) × slot factor × requirement_multiplier`, computed in `CreatedQuest.calcSuccessChance`.
- Rank tops out at S around day 15.
- Heroes keep growing (stat training on good-odds wins, Pluck, gear, Armory), so odds climb to 150-180%.
- `requirement_multiplier` is only set in freeplay (`HallRules.freeplay_scale`, +2% a day after day 50).

**Change:** add `HallRules.difficulty_scale(day)`:

```
difficulty_scale(day) = 1.0                                   for day < 5
                      = 1.0 + DRIFT × (day − 4) + STEP × bosses_before(day)   from day 5
```

- `bosses_before(day)` is the number of boss days before `day`.
- **Starting values: `DIFFICULTY_DRIFT_PER_DAY` 0.01 and `DIFFICULTY_STEP_PER_BOSS` 0.15.** These give ×1.05 on day 9, ×1.22 on day 11, ×1.47 on day 21, ×1.72 on day 31, ×1.97 on day 41 and ×2.05 on day 49.
- **Bosses multiply on top:**
  - The regular bosses (days 10, 20, 30, 40) by **`BOSS_SPIKE` 1.35**. An 85-95% party drops to about 65-70%.
  - The Demon King (day 50) by **`FINAL_BOSS_SPIKE` 1.15**, which puts it at about 75-80%.
- Every quest gets `requirement_multiplier = difficulty_scale(day) × (spike if boss) × freeplay_scale(day)`.
- **Freeplay:** `difficulty_scale` stops rising at its day-50 value (without the spike). After that only `freeplay_scale` climbs, +2% a day as today, so freeplay difficulty keeps pace with recruits and pay.
- **Only the requirement scales, not the gold.** The PR #76 upgrade costs were tuned against today's pay, so gold keeps using `freeplay_scale` alone. Recruits (`HireScaling`) are unchanged.

**What players see:** lower odds, a clearly harder boss on boss day, and the boss countdown (A7).

### A2. A failed quest costs standing

**Today:** a loss pays 0 standing. In `play_quest`, `standing_earned` is only paid when `succeeded`.

**Change:**
- A failed quest loses **half** of what a win would have paid: `ceil(standing_for_win(quest) / 2)`, as a new `HallRules.standing_for_loss`. Standing can't go below `GuildUpgrades.MINIMUM_STANDING`.
- At rank S that's −3. A typical late day earns about +25-30, so three failures cost about a third of a day of standing.

**Why half, not a full win's worth:** Santi wants players to keep improving even when they make some mistakes. Expected standing per quest sent, as a share of what a win pays:

| Odds when sent | Loss costs 0 (today) | Loss costs half (chosen) | Loss costs a full win |
|---|---|---|---|
| 95% | 95% | 93% | 90% |
| 85% | 85% | 78% | 70% |
| 80% | 80% | 70% | 60% |
| 60% | 60% | 40% | 20% |
| 50% | 50% | 25% | 0% |

- **A full loss** makes a 50% quest worth nothing on average. That makes a stretch quest almost never worth it, and it kills the "risk a harder quest to reach the next tier" dilemma.
- **Half keeps a player at 80-85% improving** at about 70-78% of a perfect pace, while a streak still sets them back.
- **The main cost of a bad day** is the retreat injuries (A3), not standing.

**What players see:**
- Assign Party and the quest row show the stake: "Win +6 · Fail −3 standing".
- The Day Report shows the loss in red, like other losses.
- `play_quest`'s `standing` result becomes negative on a loss. Every view that reads it must handle that.

### A3. Injuries follow the odds, plus a retreat hit on a loss

**Today:**
- Each combat encounter is won with probability `min(0.90, (odds/100)²)`.
- Winning an encounter injures someone 10% of the time; losing one injures someone 75% of the time.
- Higher ranks have more encounters: about 2.5 at F, about 10 at S.
- Measured injuries per quest for the whole party:

| Rank | 60% | 80% | 90% | 100% | 130% |
|---|---|---|---|---|---|
| F | 1.3 | 0.8 | 0.6 | 0.4 | 0.4 |
| C | 2.2 | 1.4 | 1.0 | 0.7 | 0.7 |
| S | 5.3 | 3.4 | 2.3 | 1.7 | 1.7 |

Two problems:
- **The 0.90 cap** means going above 100% stops helping.
- **The encounter count** makes rank S four times as dangerous as F at the same odds.

If A1 lowers odds to 80-85% without changing this, an S party takes about 3.4 injuries a quest. Four injuries kill a healthy hero.

**Change, part 1: fight wear.**
- The injury chance per encounter is set so that **expected fight injuries per hero, per quest, depend only on the odds**, whatever the rank.
- It's per hero, so a solo hero is no more at risk than each member of a party. Today a solo takes every hit, which is why solos died most.
- Target fight injuries per hero, interpolated linearly between columns:

| Odds | ≥130% | 100% | 90% | 80% | 70% | 60% | 50% or less |
|---|---|---|---|---|---|---|---|
| Fight injuries per hero | 0.1 | 0.2 | 0.35 | 0.5 | 0.7 | 0.9 | 1.2 |

- **Suggested implementation:** injury chance per encounter = target(odds) × party size ÷ the rank's expected encounter count. Encounter counts stay the same, so stories keep their length and gold finds.
- **Story text must match what happened.** The "defeated them without injuries" and "INJURED" lines have to agree with the actual result.
- **Two failure lines in `_search`** ("gained 1 INJURY", "INJURED 1 TIME") never call `injure_character` and change nothing today. Reword them so they don't claim an injury, rather than making them real. That keeps the table calibrated on fight injuries alone.

**Change, part 2: the retreat.**
- When a quest **fails**, every hero in the party takes **one more injury** after the fights.
- The story's loss text adds one line saying the party was beaten back and everyone was hurt in the retreat. Use the existing `STORY_RECOLORS` red for INJURED.

**What this means in play (rank S, party of two, 80% odds):**
- **8 in 10 times, a win:** about one injury across the pair. One hero might come back Sore.
- **2 in 10 times, a loss:** the same fights, then both heroes take the retreat hit. Each comes back a step or two worse, and a hero who set out Sore can end up Gravely hurt or dead.

**What players see:** "Strong odds" rarely hurts anyone, "Risky" usually does, and losing hurts everyone. That's one plain rule.

### A4. Deaths only on failure, or for heroes sent hurt

**Change:**
- On a **won** quest, a hero who set out Healthy or Sore can be injured up to Gravely hurt but **can't die**.
- On a **failed** quest, or for a hero who **set out Hurt or worse**, deaths happen as today: four injuries in total.

**Where it lives:**
- The check stops an injury at Gravely when it would kill a protected hero. It belongs in `GuildCharacter.injure_character` or its callers in `quest_resource.gd`.
- Win or loss is rolled at the end of `generateResults`. So the builder either rolls the outcome before the fights (without changing its probability), or holds back would-be deaths until the outcome is known.
- Either way, all of these must be correct:
  - The quest's `dead_adventurers` list.
  - The story text: a protected hero is never said to have died.
  - `play_quest`'s split into died and injured.

**What players see:**
- **The rule:** "a hero dies only on a failed quest, or if you send them out already Hurt."
- **On Assign Party:** hero rows already show their injury state. If there's room, a hero who is Hurt or worse gets a one-word "at risk" tag, using text that's already on screen.

### A5. A slower Hospital

**Change:**
- `HOSPITAL_STAGES_PER_NIGHT` goes from `[1, 2, 3, 3, 3]` to **`[1, 1, 2, 2, 2]`**.
- A Gravely hurt hero (3 stages) now takes 2 nights even at level 5. A loss, with its retreat hits, benches that party for a day or two, which is the "bad day" Santi described.
- Revive is unchanged: Hospital level 5, once per run.

**What players see:** the Hospital rows already show nights left. The building's effect text comes from `get_effect_text`, so the new number shows up there.

### A6. Bosses every 10 days

**Today:**
- **Day 10:** the Bone Drake. It's the whole board, has the BOSS seal and the header countdown.
- **Day 20:** the Resurrected Bone Drake and the Necromancer. Both are built through `_initMilestoneVars(20 / −20)` and the `18, 20` branch of `build_day_quests`, but they aren't flagged as milestones, so they get no BOSS seal.
- **Day 50:** a random rank-S placeholder.
- **Days 30 and 40:** nothing.

**What's already written:**
- **Boss stories, in `External Content/Quest Stuff (Test)/Milestone Story Parts.txt`.** Rows are 0-indexed by `questNum`:
  - 0 Bone Drake, 1 Resurrected Bone Drake, 2 Necromancer.
  - 3 First Demon General (the Blood Moon Cult's portal).
  - 4 Second Demon General, 5 Third Demon General.
  - 6 The Demon King.
- **The writer's plan, in `milestone stories draft.txt`:**
  - First General: 5 heroes, favors Sleaze, Ashen Wastes.
  - The other two Generals: 4 and 5 heroes. One favors Power and Defense (Boglands), the other Wisdom and Sleaze (Glass Mountains).
  - The Demon King: 8 heroes, favors Pluck, Windswept Meadows.

**Change:**
1. **The boss schedule.** It's a list in `HallRules`, so the header and `difficulty_scale` can both read it:

   | Day | Quests (story row) | Heroes | Favors | Region |
   |---|---|---|---|---|
   | 10 | Bone Drake (0) | 3 | Defense | Boglands (as today) |
   | 20 | Resurrected Bone Drake (1), Necromancer (2) | 3 each | Power / Wisdom | as today |
   | 30 | First Demon General (3) | 5 | Sleaze | Ashen Wastes |
   | 40 | Second Demon General (4), Third Demon General (5) | 4 / 5 | Power+Defense / Wisdom+Sleaze | Boglands / Glass Mountains |
   | 50 | The Demon King (6) | 8 | Pluck | Windswept Meadows |

   - Add `_initMilestoneVars` cases for days 30, 40 / −40 and 50, following the day-20 pattern.
   - Their rank and gold follow the existing milestone formula (`300 + 150 × difficulty`). Ranks are D for day 10, C for 20, B for 30, A for 40 and S for 50. **Claude's call:** this steps up with each boss.
   - `FavoredStat` already has the paired values (`PowerAndDefense = 10`, `WisdomAndSleaze = 23`) and a Pluck option (`4`).
2. **Boss days show only their bosses,** as day 10 already does.
   - Every boss quest is flagged `milestone` so it gets the BOSS seal.
   - Day 50 keeps `final = true` and its FINAL seal, so the credits still roll.
   - Day 50 replaces the placeholder in `build_day_quests`. The "FINAL QUEST CONTENT" comments there describe exactly this.
3. **Party sizes above 3.**
   - The requirement's slot factor becomes `slots / 2` for any size. It already is for 1, 2 and 3 (×0.5, ×1, ×1.5), so a 5-hero boss asks ×2.5 and the 8-hero King ×4.
   - Assign Party has to fit up to 8 portraits.
   - A player with fewer healthy heroes than slots can still send a smaller party, at lower odds. That's the dilemma: you can only field 8 against the King if you've built the Barracks to level 3 and kept the roster alive.
4. **The lead-up side quests.**
   - Rows 9-21 of `MinorVariables.txt` are written but unused. Today only rows 0-8 are wired, to days 1-18.
   - Wire them to the days between bosses in story order:
     - Rows 9-12 (the Blood Moon) on days 21-29, leading to the First General.
     - Rows 13-18 (King Alastair, King Bernard's advisor, the Crypt) on days 31-39, leading to the two Generals.
     - Rows 19-21 (the Sepulchral Citadel) on days 41-48, with row 21's "48 hours" warning on day 48.
   - They use the existing minor-quest path (`_initMilestoneVars` `storyNum`, `noRepeatQuests`).
   - **Exact days are left to the builder.** Rows 15-17 are three versions of "Search for King Bernard's AWOL Advisor", each revealing a different General. The builder should decide whether all three appear or one is picked, and check with the writer if it's unclear.

### A7. The boss countdown

**Change:**
- The header's Bone Drake countdown (`hall_main.days_until_drake`, `hall_header._refresh_drake_countdown`) counts down to the **next boss day** in the A6 schedule.
- It keeps the BOSS seal, and uses the FINAL seal for day 50.
- After day 50 it hides, as it does after day 10 today.
- If the tutorial or other code reads `days_until_drake`, keep a wrapper or update the callers.

### A8. The boss crawl

Santi asked for this: major quests on days 10, 20, 30 and 40 get the same text crawl as the final, but without the final's stats page.

**Today:** only day 50 has the crawl, in `Scenes/Overlays/Run End/overlay_credits.tscn` (`overlay_credits.gd`). It shows, in order:
- A title.
- The quest's story, one centred line per beat.
- The party, with a skull or "survived" for each hero.
- A parchment ledger (final stats, run records, roll call).
- The team credits.
- A closing line, then Begin Freeplay or Found a New Guild.

The motion is `CrawlRoll` (`Scripts/UI/Components/crawl_roll.gd`). It scrolls on its own after a short delay, hands control to the player on any touch, and shows its button once the bottom is reached. With Reduced Motion on, it doesn't scroll on its own.

**Change:**
- **When it shows:** a new authored overlay, `overlay_boss_crawl`, plays after End Day on a boss day, before that night's Day Report.
- **What it shows, in order:**
  - **The title:** the boss's name and the day.
  - **The story:** the boss quest's story, line by line.
  - **The party:** who went, and who fell or survived.
  - **The closing line:** won or lost, worded per boss.
  - **A Continue button:** it opens the normal Day Report. The Day Report then shows the gold, standing and injuries as usual.
- **What it leaves out:** the ledger, the run records, the roll call and the team credits. Continue replaces the freeplay and new-run buttons.
- **Days with two bosses (20 and 40):** one crawl holds both fights in board order. Each gets its own heading, story, party and result line.
- **Mood:** a won fight uses the victory ink, and a lost fight the defeat ink and the slower speed, like the final. When the two bosses on day 20 or 40 split one win and one loss, each section takes its own mood and the roll uses the defeat speed.
- **Motion and accessibility:**
  - It uses `CrawlRoll`, so touch-to-take-over, the bottom-reached button and Reduced Motion all behave as they do in the final.
  - It honours the large text setting through `HallFontScale`, as the final does.
- **Sharing code:**
  - The title, story-line and party-row code in `overlay_credits.gd` should move into a shared component scene, so both overlays use it and it isn't copied.
  - Day 50 keeps its full credits roll unchanged.
- **Saving:** if the game is closed during the crawl, reopening it skips straight to the Day Report. The crawl is presentation only, and the quest's result is already applied and saved. The builder should check this against how `hall_main` saves `shown_report`.

**What players see:** each boss fight gets its moment, without a stats page that would make it feel like the run had ended.

### A9. Measure, then tune

1. **Headless tests** in a scratch copy, per CLAUDE.md:
   - `difficulty_scale` on sample days, including the boss spikes and the freeplay freeze.
   - Standing loss on a failed quest, clamped at the floor.
   - Fight injuries per hero within ±15% of the A3 table, over many simulated quests at several ranks, odds and party sizes.
   - The retreat hit is applied to every hero on a loss.
   - Protected heroes never die on a won quest.
   - Every boss day builds the right quests, with the right sizes and flags.
2. **A playtest:** `/playtest personas=min-maxer,typical-player,reckless-gambler,cautious-planner runs=2`. Targets:
   - typical-player wins 80-85% of the quests it sends, and about 70% of the board.
   - Bosses are won more often than not by typical-player. The Demon King is won in most typical runs.
   - Typical deaths per run drop well below today's 19-25. Single digits is the target.
   - reckless-gambler gets into visible trouble, but doesn't collapse after one bad day.
   - Buildings max out around day 38-42 for typical-player, and no sooner than about day 30 for min-maxer.
3. **Tune** `DIFFICULTY_DRIFT_PER_DAY`, `DIFFICULTY_STEP_PER_BOSS`, the two spikes and the injury table until the targets hold. Record the chosen values and the playtest report in the constants' doc comments.

## Phase B: costs on existing buttons

B starts only after phase A's targets hold.

### B0. Fix the Demon King's victory line

Row 6 of `Milestone Story Parts.txt` ends with a line copied from a General: "She warns that THE DEMON KING will soon be upon you…". Replace it with a victory line that fits the end of the main story.

**Claude's call:** do this with A6, since A6 wires up this story row and A8 shows it in the crawl. It's listed here only because it's a content edit, not a rule change.

### B1. Hire prices rise with roster size

**Change:**
- A recruit's price (`HireScaling` and `GuildCharacter.recruit_cost_for_day`) is multiplied by `1 + HIRE_PRICE_PER_HERO × max(0, living heroes − 3)`.
- **Starting value: 0.15.** At 8 heroes a 200-gold recruit costs 350. At 12 heroes it costs 470.
- Recruits on days 1-2 stay free.
- Returning heroes (`RETURN_COST_MULTIPLIER`) use the raised price.

**What players see:** the price on the hire card, as today.

### B2. Hospital beds cost gold per night

**Change:**
- **The rate:** each night a hero spends in a bed costs `HOSPITAL_FEE_PER_NIGHT × (standing rank + 1)` gold. **Starting value: 20.** That's 20 a night at rank F and 120 at rank S.
- **When it's charged:** at End Day, during `GuildUpgrades.run_night()`, before healing. The fee is for that night's healing.
- **Taking a hero out early:** Discharge works at any time and stops the charge, so the player can pull a hero out early to save gold or send them on a quest. Nights already paid aren't refunded.
- **Running out of gold:**
  - If the guild can't pay for every patient on a night, patients are paid for in admission order until the gold runs out.
  - Anyone left unpaid is discharged and heals at home on `HOME_HEAL_NIGHTS`.
  - The Day Report says who was sent home for lack of gold. Gold never goes negative.
- **Admit when broke:** Admit is disabled when the guild can't pay one night.

**What players see** (Santi asked for the price to be clearly labelled):
- **The Admit button names the rate:** "Admit · 120 gold/night".
- **Each bed row shows the same rate** next to its nights left, so it's visible every day the hero is in a bed.
- **The Day Report lists the night's hospital bill** with the other gold changes.

Gold now competes with getting heroes back fast.

**Why this fits the no-new-mechanics rule:** it is a cost that recurs, but the price stays on screen while it applies, and the player chose it with a labelled button.

### B3. A "guild in trouble" warning

**Change:** the header's warning strip (`hall_header`, `HallLedger`) gets a second, milder state.
- **It shows when either is true:**
  - Two or more quests failed over the last 2 days.
  - Half or more of the living roster is Hurt or worse.
- **It names which reason applies** in one short line, like the existing "last hero standing" strip.
- **The existing strip wins** when both would show.

**New run state:**
- Recent failed-quest counts, as instance variables on `HallMain` (CLAUDE.md).
- Saved through `HallSave.build_snapshot`/`apply_snapshot` and read with `.get(key, default)`, so old saves load it as zero.
- No `SAVE_VERSION` bump.

**What players see:** the game tells them they're in trouble before Game Over is close.

### B4. Retune the upgrade costs

B1 and B2 take gold away.
- Re-run the PR #76 check: `/playtest` plus the income model.
- If typical-player now maxes buildings later than about day 42, lower `UPGRADE_GOLD_COST` proportionally to bring it back to about day 40.
- Keep the earliest finish no sooner than about day 30.

## Constraints

- **CLAUDE.md conventions:**
  - Tuning constants go at the top of the file that owns them, with `##` docs and units.
  - Rules go in static `HallRules`/`HallLedger`/`HireScaling`.
  - New hall code stays out of `hall_main.gd` beyond thin wrappers, since it's over the soft limit.
  - Legacy camelCase in `quest_resource.gd` stays.
  - Quest `.txt` content stays on `res://` paths.
- **Save compatibility:**
  - Phases A and B only add fields or change tuning.
  - Saved quests carry `requirement_multiplier`, so quests in an old save keep the multiplier they were made with.
  - An old save past day 30 has missed the new bosses. That's acceptable: it meets them from the next boss day on.
  - Nothing renames or re-means a saved value.
- **Docs, updated in the same change as each rule:**
  - `Docs/hall_design.md`: Hospital, the death rule, standing on failure, the retreat, bosses and the countdown, the warning strip.
  - `README.md`: the pitch mentions the Bone Drake and the day-50 final, so add the boss schedule to the daily loop lines.
  - `CLAUDE.md`: its Project line describes the Drake and day 50, so update it.
- **The AI playtest bridge** (`Scripts/Playtest/agent_bridge*.gd`): expose the new values the rules personas need to choose well, namely "fail −N standing", the next boss day, and the Hospital price.

## Decided by Santi

- Dilemmas across heroes, gold and standing, with no free choices.
- Standing is a target number, not a spendable resource.
- A bad day is recoverable in a few days. Longer streaks are cause for alarm.
- Dilemmas begin around day 5.
- Build A, measure, then build B on top.
- No wages. New costs only appear on the button that pays them (the no-new-mechanics rule).
- Injuries: option (c). Fights wear heroes down by the odds, and a loss adds a retreat hit to everyone.
- Bosses every 10 days: the Drake on 10, the Drake and Necromancer on 20, one Demon General on 30, two on 40, and the Demon King on 50. Each is a spike, and difficulty settles higher afterwards.
- The Demon King is a gentler spike, at about 75-80% for a prepared party. Losing him still ends the run.
- Hospital beds cost gold per night. The player can discharge a hero early, and the Admit button says the Hospital costs gold.
- Major quests get the final's text crawl, but not its stats page (A8).

## Left to the builder

- How A3's per-hero targets are met inside `_combatEncounter`/`_search`, and where A4's check lives. The averages must hit the table and stories must match outcomes.
- Which days the lead-up side quests land on (A6.4), within the windows given.
- Wording and layout of "Win +N · Fail −N standing", the retreat line, the Admit price and the trouble strip, using the existing `TEXT` constants style.
- Final tuning values, settled in the measurement step.

## Calls Claude made (check these)

- **Starting values:**
  - Drift 0.01 a day, step 0.15 per boss, boss spike 1.35, Demon King spike 1.15.
  - The per-hero injury table.
  - Hospital stages `[1, 1, 2, 2, 2]`.
  - `HIRE_PRICE_PER_HERO` 0.15 and `HOSPITAL_FEE_PER_NIGHT` 20 (per night, × standing rank + 1).
- **Standing:** a failure costs half of what a win would pay, rounded up (Santi asked why it shouldn't be a full win; see A2).
- **What scales:** requirement scaling applies to bosses too, but quest gold doesn't scale before day 50.
- **The injury table is per hero,** not per party.
- **Freeplay:** `difficulty_scale` freezes at day 50, and freeplay keeps today's +2% a day.
- **`_search` wording:** the lines that claim an injury get reworded rather than made real.
- **Boss ranks:** D, C, B, A, S on days 10 to 50.
- **Boss days:** they show only their bosses.
- **The lead-up side quests are part of phase A,** because the bosses need them for story.
- **When the Hospital fee is charged:** at End Day, and unpaid patients are sent home in admission order. (Santi chose a per-night fee with early discharge and a labelled Admit button.)
