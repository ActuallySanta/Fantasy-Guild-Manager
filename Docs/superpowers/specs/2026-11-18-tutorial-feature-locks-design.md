# Tutorial feature locks: design

Date: 2026-11-18. Status: approved, implemented.

## Why

New players are overwhelmed on Day 1: too much text and too many tabs and
controls on screen at once. Pip's tutorial teaches the game over Days 1, 2, 3
and 5, but today only two bottom tabs (Guild, Items) are held back, and even
those still show their label plus a "Day N" badge, an "opens Day N" note on the
Board, and a "Pip will open this on Day N" toast. Everything inside the open
tabs (Applicants, Deny, hero pages) is usable from the first minute.

The goal is less to read, not more: anything Pip hasn't taught yet stays on
screen as a **blank, greyed, inert button**. The layout doesn't change as things
unlock, but nothing untaught asks for attention.

## Goals

- Every control Pip hasn't taught yet is visible but has **no text, no badge,
  greyed out, and does nothing** when tapped.
- Each feature unlocks on the morning of the day Pip teaches it.
- Applicants opens on Day 2, with a new Pip step that morning.
- Skip tutorial (and the Debug tools' Skip tutorial, and `ENABLED = false`)
  lifts every lock at once, exactly like the tab locks today.
- One table defines what unlocks when, so a tuning change is one edit.

## Non-goals

- No change to the always-on header: gold and standing counters (and their
  popups), the Menu, the day tile, the Bone Drake countdown, the danger strip.
- No change to the freeplay walkthrough or what Pip teaches on Days 3 and 5.
- No new art. Locked controls reuse their existing icon (greyed) or show as an
  empty button shape.
- No save-format change (see Saving).

## Anti-goals (a failure even if it works)

- Replacing one kind of text with another: no "Locked", "Day 3", "opens Day N"
  or toast on a locked control.
- A player getting stuck: no lock may block the only way forward (see
  "Can't get stuck").
- Controls hiding or rows collapsing, so the screen jumps when things unlock.

## Approaches considered

- **A. One unlock table + each view greys its own controls (picked).**
  `OverlayTutorial.UNLOCK_DAY` grows from tabs to features; `hall_main` gets
  `is_locked(feature)`; each view checks it in `refresh()` and calls one shared
  helper. Matching `hall_main` actions also refuse locked features. Costs a few
  lines in ~7 views; fits the project's "views read queries from `hall`" rule
  and keeps the rules in one place.
- **B. Pip blanks controls by node name.** Rejected: Pip only runs on Days 1,
  2, 3 and 5 (nothing locked on Day 4 or once a day's script ends), and node
  renames would break it silently.
- **C. Hide untaught controls entirely.** Rejected: Santi wants the buttons to
  stay visible, and hiding makes the layout jump as features unlock.

## The unlock table

In `overlay_tutorial.gd`, `UNLOCK_DAY` becomes the feature table (the two
existing tab ids keep their names, since `hall_nav` and `hall_main` already
use them):

| Feature id | Unlocks on | What it covers | Taught by |
|---|---|---|---|
| `hire` | Day 2 | Applicants sub-tab and everything that leads to it | new Day 2 step |
| `hero_page` | Day 2 | Opening a hero's page from a member card or a pick row's Info button | Day 2 steps 3–5 |
| `deny` | Day 2 | Deny on Assign Party | Day 2 last step |
| `upgrades` | Day 3 | Guild bottom tab, and links into it | Day 3 |
| `shop` | Day 5 | Items bottom tab | Day 5 |

Each entry gets a `##` comment naming what it covers and the Pip step that
teaches it. Changing an unlock day must not need any other edit, except moving
the matching Pip step.

Rule (unchanged from today's `is_tab_locked`): a feature is locked when
`ENABLED and not is_skipped and GameState.day < UNLOCK_DAY[feature]`. A feature
not in the table is never locked.

### hall_main API

- `is_locked(feature: String) -> bool` replaces `is_tab_locked`. Keep
  `is_tab_locked(tab_id)` as a one-line wrapper so existing callers keep
  working (or rename callers; builder's call).
- `tab_unlock_day` is no longer needed by any view once the "Day N" texts are
  gone. Remove it if nothing uses it.
- `TOAST_TAB_LOCKED` and its uses are removed (no toast on locked taps).

### Actions refuse locked features

Belt and braces, so a tap from any path (a stale row, a Today note, a deep
link) can't get through:

| Action | Refuses when |
|---|---|
| `open_tab(tab_id, …)` | the tab is locked (already does; drop the toast) |
| `open_tab("guild", GUILD_SECTION_HIRE)` / `show_guild_section(HIRE)` | `hire` is locked: open Your Guild instead, or do nothing if called from the hire segment itself |
| `hire(character)` | `hire` is locked |
| `open_character(character)` | `hero_page` is locked |
| `deny_quest()` | `deny` is locked |
| `upgrade(...)` (the Build action) | `upgrades` is locked (already does; drop the toast) |

A refused action does nothing: no toast, no text, no sound. *(My call: a
locked Button is `disabled`, so it never emits `pressed` and couldn't play a
sound anyway; the refusals in `hall_main` are a safety net, not feedback.)*

### Already covered by `affordable_buildings()`

`hall_main.affordable_buildings()` already returns `[]` while `upgrades` is
locked, so the End Day sheet's `UpgradeBox` (and its `suggest_row` Buy
buttons), the Guild nav badge and the Board's Upgrades count all stay empty on
Days 1–2 with no extra work. Keep that check (it reads `is_locked("upgrades")`).

## What a locked control looks like

One shared helper in `HallStyle` (or a small new static script if
`hall_style.gd` is near its size limit), e.g.
`HallStyle.set_locked(button: BaseButton, is_locked: bool, label := "")`:

- Locked: `text = ""`, `disabled = true`, greyed through `modulate` (a named,
  documented `LOCKED_MODULATE` colour in `HallStyle`), any badge child hidden.
  The icon stays (greyed) if the button has one. The button keeps its
  minimum size so the layout doesn't shift.
- Unlocked: restores `text = label` and normal modulate. `disabled` is left to
  the view's own logic (the view sets its real disabled state after calling
  the helper).

Because the hall rebuilds rows on every refresh, the helper is called from
each view's `refresh()` (or a row's `setup`) every time, never once.

TapPanel rows (member cards, Today notes) aren't Buttons. For those, the view
skips the tap (the action refuses anyway) and greys/blanks only the part that
points at the locked feature (see the per-view list).

Pip's own button locks (`_apply_locks`) store each button's `disabled` value
and restore it after a step. They must keep working with locked buttons: a
locked button is `disabled = true` both before and after Pip, so the restore
is correct, and the next refresh recomputes it anyway. Verify this on the
Day 2 → Day 3 morning (a button locked on Day 2, unlocked on Day 3, while Pip
starts Day 3's script).

## Per-view changes

| View | Control | Feature | Locked look |
|---|---|---|---|
| `hall_nav.gd` | `Nav_upgrades`, `Nav_shop` | `upgrades`, `shop` | Icon only, greyed, no label, no badge (drop `BADGE_LOCKED`) |
| `hall_nav.gd` | `Nav_guild` badge | `hire` | Badge never says "N new" / "!" for recruits while `hire` is locked |
| `tab_guild.gd` | `SegHire` (+ `HireBadge`) | `hire` | Empty greyed folder tab, no badge |
| `tab_guild.gd` | `BedsButton` (Barracks link; hidden unless `SHOW_BARRACKS_LINK`) | `upgrades` | Blank, greyed |
| `tab_board.gd` | Today note "Recruits" | `hire` | Title and value blank, greyed, tap does nothing |
| `tab_board.gd` | Today note "Upgrades" | `upgrades` | Title and value blank, greyed (replaces "opens Day %d"; drop `UPGRADES_LOCKED`) |
| `screen_assign.gd` | `LeftButton` while it reads Deny | `deny` | No text, `x` icon greyed, `DenyCost` hidden |
| `screen_assign.gd` | `HireButton` (No Roster box) | `hire` | Blank, greyed |
| `pick_row.gd` | `InfoButton` | `hero_page` | Greyed, disabled (it's icon-only) |
| `member_card.gd` | the card's tap | `hero_page` | Card content unchanged (it's the hero, not a button label); tap does nothing |

`today_item.gd` needs a way to show a locked note (e.g. a `"locked"` look for
`set_item` that blanks the labels and greys the panel, keeping its size).

Anything else the builder finds that leads into a locked feature (another
"go to Applicants / Guild / Items" link) gets the same treatment.

## Pip script changes

- **Day 1, Uncle John step:** the text says "More heroes will appear each day
  under the Applicants tab" while that tab is now blank. Reword to point at
  tomorrow without naming a tab, e.g. "More heroes will come looking for work
  starting tomorrow." *(My call: wording is Santi's to adjust.)*
- **Day 1, End Day sheet step:** the text says "as well as any available
  upgrades!", but upgrades are locked on Day 1 and the box is hidden. Drop
  that clause, e.g. "Here you can check which quests you sent and denied. Tap
  End Day to finish your choices." *(My call.)*
- **Day 2, new Applicants step**, after "Tap Back" returns to the Members tab
  and before "Open the Quests tab":
  - target: `_u(_tab("guild"), "SegHire")`, `on: "tab"`,
    `when: d.guild == "hire"`, `do: "Tap Applicants"`.
  - text (draft, Santi to adjust): "New heroes come looking for work every
    morning. Hiring costs %s, and your beds limit how many you can keep." The
    step finishes when Applicants opens; Pip doesn't force a hire.
  - If the player is already on Members when the step comes up, the Quests step
    that follows still works (it targets the nav button).
- **Day 2 header comment** at the top of `overlay_tutorial.gd` is updated to
  list Applicants, and the "Tab pacing" note becomes a "Feature pacing" note
  pointing at the table.
- Day 1's "deny" target on the pick step (`"deny": ["InfoButton"]`) can stay;
  it's harmless now that the button is locked anyway.

## Can't get stuck

- Day 1 has one quest (`QUESTS_PER_DAY_BY_DAY`) and one hero (Uncle John), so
  End Day never needs Deny.
- If Uncle John is hurt or dies on Day 1, Applicants is open on the morning of
  Day 2, before any quest must be decided.
- Resumed runs: locks come from `GameState.day` and `is_skipped`, both already
  saved, so a run loaded mid-Day 1 is locked the same way.
- Runs saved on Day 1 before this update get locked on load like any other.
  No special case and no saved flag. *(My call.)* If the restored
  `guild_section` is `hire` (or the restored screen is a hero page) while that
  feature is locked, fall back to Your Guild / close the screen. Day 2's
  steps target "a hero", so a hero hired early under the old rules doesn't
  break them.
- Playtest scenarios that start on Day 5 or later have everything open; ones
  that start earlier are locked by day, as a new run would be.

## Saving

No new saved state. `is_skipped` and `done` are already saved; locks are derived
from them plus the day. No `SAVE_VERSION` bump.

## Docs to update in the same change

- `Docs/hall_design.md`: the tutorial / tab-pacing description (feature
  locks, what a locked control looks like, Applicants on Day 2) and the
  "Tutorial skipped" row if it mentions tab locks.
- `README.md`: only if it describes the tab locks (check; likely untouched).
- `CLAUDE.md`: nothing (no architecture-level fact changes).

## Testing

- Headless behaviour test (scratch copy of the project, per CLAUDE.md):
  `is_locked` per feature on Days 1, 2, 3, 5 with tutorial on, skipped, and
  `ENABLED = false`; each refusing action does nothing while locked.
- Manual run from a new game through Day 5: check each locked control is blank,
  greyed and inert, then unlocks on its morning; the new Day 2 step spotlights
  Applicants; Skip tutorial on Day 1 unlocks everything at once.
- Check the phone layout (720×1280) at the largest accessibility font size:
  blank nav tabs and the blank Applicants tab keep their size.

## Left to the builder

- Whether `set_locked` lives in `HallStyle` or a new small static script.
- The exact grey (`LOCKED_MODULATE`), documented as a named constant.
- Whether to keep `is_tab_locked` as a wrapper or rename its callers.
