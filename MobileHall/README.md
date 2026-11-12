# Mobile Hall UI (playtest variant)

A phone-first UI for the guild game, built from the playtest feedback on the Deck,
Flow and Ledger prototypes. It keeps Flow's structure (one clear next step, stats visible
while picking a party), adds Ledger's navigation aids (tab badges, a home summary), and
changes the things all three were criticized for.
It is **UI only**: it runs on the existing systems (`CharacterContainer`, `GuildCharacter`,
`CreatedQuest`, `GameState`, `GuildUpgrades`, `DayBar`'s scoring helpers) and changes none of them.

- **Run it:** open `MobileHall/hall_main.tscn` and press *Run Current Scene* (F6).
  The project's main scene is unchanged.

## Look

A guild hall at night: dark wood behind everything, parchment cards, blackletter titles
(Pirata One) over an old-style serif (Alegreya). Quests are scrolls, applicants are letters
of introduction, buildings are plans on grid paper, and the night's results come back as
letters with a Success / Failed stamp.
Colour still carries meaning, now as ink: each stat has its own ink, green = good / sent,
red = bad / denied / hurt, blue = odds / to do, gold = money, and each quest type has a
coloured seal (DUN, ESC, SCT, INT, BOSS).

All art is a swappable placeholder. **See `Art/README.md`** for every file, what it's used
for and how to replace it. In short: images and fonts are in `Art/`, each surface is a
StyleBox in `Styles/`, and `hall_theme.tres` holds the named looks scenes use
(`theme_type_variation` = `TitleLabel`, `PaperCard`, `GoldButton`...). Scripts never build
boxes in code; they only pick a look or tint white art with an ink colour.

## What changed, by feedback

| Feedback | What Mobile Hall does |
|---|---|
| Can't compare one quest against all the others (Deck, Flow) | **Board** tab lists every quest of the day on one screen, with reward, party size, favored stat, state and odds |
| Can't see stats while assigning (Deck) | **Assign Party** picker shows each adventurer's health and four quest stats (favored one outlined), plus how much they add to the odds |
| Picked parties are dropped unless you send them (Flow) | A quest's party is a **draft** that stays until you send, recall or change it. Switching quests keeps every draft |
| Hard to switch between quests (Ledger) | Numbered **quest strip** at the top of Assign Party. One tap switches quests, and each tab is coloured by state |
| Not sure what to do next (Ledger) | One **action bar** button above the nav, always the next step: *For Hire* → *Next Quest* → *End Day* |
| Upgrades forgotten in every version | **Upgrades** tab badge when you can afford something, an Upgrades box on the Board's Today checklist, and the **End Day check** offers affordable upgrades before the day ends. None of these offer upgrades while Pip still holds the Guild tab back (until Day 3); the Board's box says when it opens |
| No way to get denied quests back (Ledger) | Denied quests stay on the Board. Open one and tap **Reconsider** |
| No signal when new recruits arrive (Ledger) | **Guild** badge ("3 new") each morning until you open Applicants |
| Hiring and questing blurred together (Deck) | Guild tab has two clearly separate folder tabs: **Your Guild** / **Applicants** |
| Tutorial skipped Home (Ledger) | Welcome card walks through Board, Guild, Upgrades and the big button, then lands on the Board |
| Small buttons (Flow) | Main buttons are 88–96 px tall, nav tabs 100 px, list rows are tappable as a whole |
| Too much scrolling / decorative art (Ledger) | No decorative art. The Board fits 5 quests without much scrolling. "Coming soon" buildings collapse into one line |
| Quest results are walls of text (Flow) | **Day Report** is one short letter per quest: a result stamp, who went and at what odds, who got hurt, one line per story beat with an icon, and a one-line sign-off |

## Layout

```
┌ header ─ Day · Bone Drake countdown · gold · standing · menu ┐
│ warning strip ─ "Last hero standing" (only when one death from falling) │
│ content ─ Board | Guild | Upgrades | Items  (or a screen over them) │
│ action bar ─ "what to do next" + one big button             │
└ nav ─ Board (undecided) · Members (new recruits) · Guild (affordable) · Items ┘
```

| Screen | What's on it |
|---|---|
| Board (tab) | Today checklist (Recruits / Quests / Upgrades, each tappable), then all quests. Rows show *Pick a party*, *Party picked*, *Sent* or *Denied* with odds and mini portraits |
| Assign Party | Quest strip; quest card; party seats (tap to remove) with live odds; picker sorted best fit first. Adventurers already in another quest's party are hidden unless **Show busy** is on; shown, they say "Picked for / Sent on #N" and move over when tapped. Footer: Deny / Send Party, or Recall / Next Quest, or Board / Reconsider |
| Guild (tab, "Members" in the nav) | A folder with two tabs: Your Guild (roster with health, today's task, all five stats) / Applicants (a stack of letters of introduction; tap one peeking out to read it, Hire on the top one). Bed count links to the Barracks |
| Upgrades (tab, "Guild" in the nav) | A folder with two tabs. **Facilities**: the Training Yard plan (heroes in a slot with a Pow / Def / Wis / Slz picker and Remove; "+ Add a hero" opens who can train, with Add or Move here) and the Hospital plan (heroes in a bed with nights left and Discharge; hurt heroes with nights at home vs in a bed and Admit; fallen heroes, Revive at level 5). Badge = hurt heroes not in a bed. **Build**: the treasury ledger, a plan per building (affordable first) with level diamonds, now/next effect, cost or what's missing, and "coming soon" buildings as rolled-up scrolls. Badge = upgrades you can afford |
| Items (tab, id "shop") | A folder with two tabs; the first visit each day opens on the Shop. **Inventory** (the "pack" section in code): every item the guild owns as goods tags (grouped by role), with a Hide equipped box and role filters. A worn item has its hero's round portrait on the corner and an "ON GWEN" ribbon; the item bar shows Take off (asks first, with the stat it drops) or Equip on… (a sheet of heroes of the right role: Equip, or Swap… for full slots, which asks which item comes off). **Shop**: Grizzle behind his counter under a striped awning, with a speech bubble and a hanging sign; today's goods as price tags (3 x 2, sold-out ones stamped); a torn-paper Buy bar where the action bar usually is |
| Character | Portrait, health, injuries, today's task, five stats with Armory bonus, backstory, Hire for recruits |
| End Day check | Parties going out with odds, denied quests, affordable upgrades with buy buttons |
| Day Report | Totals (succeeded, gold, injuries), an "At home" line (training, healing), one letter per quest with its story |
| Final Battle credits | Day 50 only. **Victory**: on a warm, dark backdrop the night's story rolls up the screen line by line, then who fought, a parchment ledger (final stats without the Bone Drake, run records, roll call), the team credits, and **Begin Freeplay**. **Defeat**: the same roll in cold colours with an epitaph, and **Found a New Guild** |
| Game Over | The guild ledger: days survived, a 2 x 3 grid (gold earned, quests won, heroes hired, fallen, final standing, Bone Drake), a roll call of every hero and their fate, and Found a New Guild |
| Menu | How to play, last night's report, Accessibility, reset upgrades (debug), abandon run |
| Accessibility | Text size (Small / Normal / Large / Largest, applied live by `HallFontScale.set_text_factor`), colorblind filter (Off / Red-weak / Green-weak / Blue-yellow), reduced motion; each button taps to the next choice, saved to `user://settings.cfg` |

## Game Over

The run ends when the guild can never send anyone out again (`HallMain.is_run_over`):
nobody is alive (patients in a Hospital bed count as alive), nobody in today's For Hire
costs what you have, and no recruit ever will. That means standing is at or below
`GuildUpgrades.MINIMUM_STANDING`, or tomorrow's recruit price is already more than your
gold (prices never go down). Recruits are free on days 1-2, so it can't happen then. It's
checked when a new day starts (after the Day Report), after a release, and when the
scene loads. The ledger's numbers come from `HallMain.run_stats`, tallied as you play.
**Found a New Guild** resets the autoloads to Day 1 and loads `hall_main.tscn` again.
`Playtest/scenario_game_over.tscn` opens straight onto the ledger.

A red **Last hero standing** strip shows under the header when the guild is one death
from falling (`HallMain.is_one_death_from_falling`). That means one hero is alive, nobody
in today's For Hire is affordable, and either tomorrow's recruit price is more than your
gold or standing is within `DANGER_STANDING_MARGIN` of the floor. The Welcome card's
"Don't run out of heroes" row and Pip's Day 1 Day Report step explain the rule.

Tapping the gold coin or the standing shield in the header drops a parchment card
from it (`HeaderPopup`; tap anywhere else to close it). The **gold** card shows what
the quests sent tonight pay if they all win and about how much at today's odds, then
where gold goes (hiring, gear, building upgrades) with a price tag that turns green when
you can pay it. The **standing** card shows the rank quests center on and a two-way
meter: the red half fills as standing nears `MINIMUM_STANDING` (recruits stop coming),
the green half fills toward the next milestone, a quest rank or a building level. The
numbers come from `HallWallet` (static functions); the milestones are built from
`HallRules` and `GuildUpgrades` tuning, so they follow it.

## Final battle, credits and freeplay

`HallMain.FINAL_DAY` (50) has a single quest, the final battle (`entry.final`). It's a
random S-rank quest for now. The `FINAL QUEST CONTENT` / `FINAL QUEST STORY` comments in
`hall_rules.gd` (`build_day_quests`, `play_quest`) and `FINAL QUEST DEFEAT TEXT` in
`overlay_credits.gd` mark where the real quest goes.

Ending Day 50 opens the credits roll (`Scenes/Overlays/overlay_credits.tscn`) instead of the
Day Report. The night's letters are still in the Menu's "Last night's report". The roll
scrolls by itself after a moment. Any touch, drag or wheel hands it to the player, and
Reduced Motion turns the auto-scroll off. The button appears once the bottom is first
reached and stays, so the player can scroll back up.

- **Won:** **Begin Freeplay** (`HallMain.start_freeplay`) sets `GameState.is_freeplay`
  and opens Day 51, and Pip explains freeplay (it runs even if the tutorial was skipped).
  From then on, quests can roll past S into **S++** (`CreatedQuest.QuestDifficulty.SPP`).
  Every quest's stat requirement and gold also grow by `HallRules.FREEPLAY_SCALE_PER_DAY` (2%) for
  each day past 50, without a cap. Game Over still applies.
- **Lost:** the run ends (`HallMain.final_battle_lost`). The defeat roll stands in for the
  Game Over ledger and ends on **Found a New Guild**.

Run records (gold spent, items found, building levels, longest-serving hero) come from
`HallLedger.build_run_records`. `Playtest/scenario_final_battle.tscn` starts on Day 50.

### Adding your team credits

The "Made By" block near the end of the roll reads `MobileHall/Data/credits.tres`, a
`CreditsList` (`Scripts/Credits/`). Edit it in the Godot editor:

1. Double-click `MobileHall/Data/credits.tres` in the FileSystem dock.
2. In the Inspector, expand **Entries** and click **Add Element**.
3. Click the new empty slot and pick **New CreditEntry**.
4. Fill in **Section** (the heading, e.g. "Art"), **Name**, and **Contribution**.
5. Drag elements to reorder them, then save.

Entries that share a Section are grouped under one heading, in the order the section first
appears. Entries with an empty Name are skipped.

## Colorblind filter

`Styles/colorblind_filter.gdshader` is a full-screen daltonize pass on a CanvasLayer
(layer 100) at the bottom of `hall_main.tscn`, so it recolours everything, overlays and
art included. It moves the colour differences a player can't see into ones they can.
It doesn't fake colourblindness. When it's Off the rect is hidden and costs nothing.
`strength` on the material (0-1) softens it.

## Training Yard and Hospital

Both live on the Upgrades tab's **Facilities** half (`Scenes/Rows/home_section.tscn`, one building plan each). The rules
live in `Globals/guild_upgrades.gd` (`run_night()`, called by End Day before the quests
are played out), and the tuning numbers sit at the top of that file.

- **Training:** a hero in a slot gets +`TRAINING_STAT_GAIN` to the stat they picked each
  night. Slots stay filled from day to day. Heroes can be Healthy or Sore, but not in a bed.
  **Trainees can't be sent on quests**: take them out of their slot first. "Move here"
  pulls a hero out of a quest party and into a slot.
- **Healing:** at home injuries heal one level at a time, each taking
  `HOME_HEAL_NIGHTS` (Sore 2, Hurt 4, Gravely 6). In a Hospital bed a hero heals
  `HOSPITAL_STAGES_PER_NIGHT` stages every night (level 1: one stage, level 2: two,
  level 3+: all three). Heroes in a bed can't go on quests, and they go home on their
  own once they're Healthy.
- **Revive:** Hospital level 5 brings one fallen hero back per run, Gravely hurt and in a bed.
- The Day Report's header has an "At home" line with who trained and who healed.

## Quest growth

A won quest grows the party in one of two ways, based on the odds it was sent at
(`HallRules`, tuning at the top of `hall_rules.gd`):

- **Good odds train a stat.** The good-odds threshold is `train_odds_for(rank)`: F 60%,
  D 65%, C 70%, B 75%, A 80%, S and S++ 85%. A win at or above it gives every party member
  +`TRAIN_STAT_GAIN` to one stat and no Pluck. One coin flip for the whole party picks the
  stat: the quest's favored stat or the region's favored stat
  (`CreatedQuest.REGION_FAVORED_STAT`).
- **Riskier odds build Pluck.** A win below the threshold gives Pluck by
  `PLUCK_GAIN_BY_ODDS`, the same as before. The threshold rises with rank, so more
  high-rank wins pay Pluck.

Assign Party's odds caption shows which one a win would give ("win to train Defense or
Power" or "win for +2 Pluck"), and the Day Report's sign-off names what the party gained.

Looks come from the theme, not from overrides: a label is `TitleLabel`, `CapsLabel`,
`ItalicLabel` (or `TitleLight` / `ItalicLight` / `LabelLight` on wood), a panel is
`PaperCard`, `PlanCard`, `TornPaper`... and a button is `GoldButton`, `WoodButton`,
`PaperButton` or `SealButton`. Pick one in the inspector (*Theme > Type Variation*) rather
than overriding colours or styles on the node, so a reskin reaches it.

## Debug tools

Menu > **Debug tools** (shown while `GuildUpgrades.SHOW_DEBUG_BUTTONS` is on) holds
cheats for testing. The rules are in `Scripts/hall_debug.gd` (`HallDebug`), and the sheet
is `overlay_debug`. The first time in a run it only shows a warning and **Enable debug
tools**. Enabling makes the run a **debug run** (`HallMain.is_debug_run`): it is never
saved again, so the last save on disk stays as it was before the tools were used. A new
run starts with saving back on.

- **Time:** skip to the next day (training and healing still run; no quests, no report;
  blocked on the final battle day outside freeplay), or jump to day 10 / 50 (a skip
  repeated, so For Hire and healing move on as usual).
- **Wallet:** gold and standing steps (`HallDebug.GOLD_STEPS`, `STANDING_STEPS`).
- **Guild:** add a free hero (needs a free bed), add a random item to the Inventory, heal
  everyone (the dead come back if there's a bed), max every building, reset upgrades.
- **Run:** reroll today's quests and For Hire, skip the tutorial.

None of it counts toward the Game Over ledger or the credits (`run_stats`).

## Saving and offline play

**Dev switch:** saving is **off by default** (`HallSettings.DEFAULT_SAVE_ENABLED`), so
every launch starts a fresh Day 1. Tick "Save runs" in Menu > Debug tools (shown while
`GuildUpgrades.SHOW_DEBUG_BUTTONS` is on; it's there before you enable the tools, so
turning saving on doesn't make a debug run) to turn it on; the choice is kept in
`settings.cfg`. Off means the save is neither loaded nor written (the file on disk is
left alone). Flip the default to `true` before a release.

With saving on, the run saves itself. Close the game at any point (the browser tab, the home-screen app,
or the desktop window), open it again, and the hall picks up where it was with a
"Welcome back" toast instead of the Welcome card. `Scripts/hall_save.gd` (`HallSave`)
holds the whole format:

- **When:** after every refresh (every action ends in one), when the app goes to the
  background, and right after End Day plays the night out. The night's report (or the
  final battle's credits) is saved as already showing, so closing during the dusk
  can't replay the night with new dice. An unchanged run isn't written again.
- **Where:** `user://run_save.dat`, with `run_save.bak` (the save before it). On the web,
  `user://` is the browser's IndexedDB, and `HallSave` asks the browser to keep it
  (`navigator.storage.persist()`). Settings stay in their own `user://settings.cfg`.
- **What:** the day, wallet, buildings, Training Yard and Hospital, roster, For Hire,
  released heroes, gear, Shop stock, today's Board and parties, the run's tallies, the
  open report / credits / Game Over, and Pip's progress. Not the open tab or menus.
  A tutorial day cut off halfway starts again from its first step.
- **Shared objects:** each hero, item and quest is written once in a numbered table, and
  everywhere else (parties, training, `curr_user`, reports) holds a reference like
  `{"$character": 3}`, so a hero in three lists is still one hero after loading.
- **New fields:** a new `GuildCharacter`, item or `CreatedQuest` property that matters
  between sessions goes in `CHARACTER_FIELDS` / `ITEM_FIELDS` / `QUEST_FIELDS`. A new
  piece of run state on `HallMain` or an autoload goes in `build_snapshot` and
  `apply_snapshot`. Bump `SAVE_VERSION` when old saves can't be read with the new
  layout: saves with another version are ignored and the player starts fresh.
- **Starting over:** Game Over's "Found a New Guild" and the Menu's **Abandon run** (two
  taps) delete the save. Playtest scenarios never load or write it (`uses_save_file` is
  only true when the hall is the scene root).
- **Offline:** the Web export is a PWA, so after one online visit the service worker
  serves the game files with no connection. Its home-screen icons come from the
  project icon (`icon.svg`) while the preset's icon fields are empty.
- **iPhone:** a home-screen app has its own storage, separate from Safari. A run started
  in a Safari tab doesn't carry over to the installed app, and Safari can clear a tab's
  storage after about a week unused (installed apps are kept).

## Things to watch in the playtest

- Do players compare quests on the Board, or go straight to Next Quest?
- Do they use the quest strip to move picks around, and does keeping drafts feel right?
- Do they buy upgrades during the day, or only from the End Day check?
- Is the Day Report short enough? Does anyone open the stories?
- Do they notice the Guild badge each morning?

## Files

- `hall_main.tscn` + `Scripts/hall_main.gd`: state, every game action, refresh
- `Scripts/hall_rules.gd`, `hall_ledger.gd`, `hall_settings.gd`, `hall_save.gd`, `hall_wallet.gd`: quest building and payout, run-over checks and the Game Over numbers, saved settings, the saved run, the gold and standing popups' numbers (static functions, no state)
- `Scenes/Shell/`: the header (day, Bone Drake countdown, counters, danger strip, gold and standing popups), action bar, nav and toast
- `Scenes/Tabs/`: Board, Guild, Upgrades, Shop
- `Scenes/Screens/`: Assign Party, Character
- `Scenes/Overlays/`: End Day check, Day Report, Welcome, Menu, Game Over, Final Battle credits
- `Data/credits.tres`: the team credits for the credits roll (see Adding your team credits)
- `Scenes/Rows/`: list rows (quest row, quest tab, party seat, picker row, roster / hire cards, applicant peek, upgrade card, Today note, plan row, upgrade suggestion, report entry, story line, Training / Hospital card, row and heading, shop tile)
- `Scenes/Components/`: chip, portrait, stat strip, odds bar, divider, seal button, rolled-up scroll tag
- `Art/`: every image, icon and font (placeholders; see `Art/README.md`)
- `Styles/` + `hall_theme.tres`: one StyleBox per surface, and the theme with every named look
- `Scripts/hall_style.gd`: ink colours, stat / injury / odds tables, quest-type and building tables, icon table, text helpers, restyles

### Editing

Same conventions as Flow and Ledger. Every screen, row and widget is an authored scene,
and scripts only fill in text, show/hide nodes and instance rows. Each script has a header
comment naming its scene, a **TEXT** section with every message as a constant, a **NODES**
section of `@onready var _x = %X` (unique names in the scene), then `setup(main)` and
`refresh()`. Game state and actions live only in `hall_main.gd` (SETTINGS at the top:
milestone day, release cost, dusk timings). Quests per day and quest ranks are in
`hall_rules.gd`, toast time in `hall_toast.gd`. Screens call its actions and never change
game state themselves.

Anything that sits inside a ScrollContainer must let touches through, or a drag that
starts on it won't scroll on a phone. `PanelContainer` and `Button` default to Mouse
Filter **Stop**, which swallows the drag. `hall_main.refresh()` ends with
`DragScroll.fix_tree(self)` (`Scripts/drag_scroll.gd`), which sets every Stop control
inside a scroll list to **Pass**. Buttons there also get a tap-vs-drag check, so a scroll
that starts on a button scrolls instead of pressing it. A row you can tap extends
`TapPanel` (`Scripts/tap_panel.gd`); a tap on a button inside it belongs to the button,
not the row. Something built outside a refresh, inside a scroll list, needs its own
`DragScroll.fix_tree(...)` call.

### Web updates and the build line

The web build is a PWA, and its service worker serves the game files cache-first, so a
plain reload can keep running an old deploy. `Scripts/hall_web_update.gd` switches to a
waiting deploy at start-up (the page reloads and the saved run comes back), or shows a
toast if one turns up mid-game. The Menu's bottom line (`Scripts/hall_build_info.gd`)
names the commit and time of the build that's running: the deploy workflow writes
`External Content/build_info.txt` (gitignored), and without it the line says "Build dev".
To check a phone, compare that line with the latest commit on `master`.

## Known issues (in the game systems, not changed here)

- Dead adventurers are shown greyed out and can't be picked in this UI, but the game
  systems themselves don't stop them.
- Quest text typos ("ATTACHING") come from the quest data.
