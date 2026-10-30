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
| Upgrades forgotten in every version | **Upgrades** tab badge when you can afford something, an Upgrades box on the Board's Today checklist, and the **End Day check** offers affordable upgrades before the day ends |
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
│ content ─ Board | Guild | Upgrades | Shop  (or a screen over them) │
│ action bar ─ "what to do next" + one big button             │
└ nav ─ Board (undecided) · Members (new recruits) · Guild (affordable) · Shop ┘
```

| Screen | What's on it |
|---|---|
| Board (tab) | Today checklist (Recruits / Quests / Upgrades, each tappable), then all quests. Rows show *Pick a party*, *Party picked*, *Sent* or *Denied* with odds and mini portraits |
| Assign Party | Quest strip; quest card; party seats (tap to remove) with live odds; picker sorted best fit first. Adventurers already in another quest's party are hidden unless **Show busy** is on; shown, they say "Picked for / Sent on #N" and move over when tapped. Footer: Deny / Send Party, or Recall / Next Quest, or Board / Reconsider |
| Guild (tab, "Members" in the nav) | A folder with two tabs: Your Guild (roster with health, today's task, all five stats) / Applicants (a stack of letters of introduction; tap one peeking out to read it, Hire on the top one). Bed count links to the Barracks |
| Upgrades (tab, "Guild" in the nav) | A folder with two tabs. **Tonight**: the Training Yard plan (heroes in a slot with a Pow / Def / Wis / Slz picker and Remove; "+ Add a hero" opens who can train, with Add or Move here) and the Hospital plan (heroes in a bed with nights left and Discharge; hurt heroes with nights at home vs in a bed and Admit; fallen heroes, Revive at level 5). Badge = hurt heroes not in a bed. **Build**: the treasury ledger, a plan per building (affordable first) with level diamonds, now/next effect, cost or what's missing, and "coming soon" buildings as rolled-up scrolls. Badge = upgrades you can afford |
| Shop (tab) | Grizzle behind his counter under a striped awning, with a speech bubble and a hanging sign; today's goods as price tags (3 x 2, sold-out ones stamped); a torn-paper Buy bar where the action bar usually is. Groundwork only: nothing can be bought yet |
| Character | Portrait, health, injuries, today's task, five stats with Armory bonus, backstory, Hire for recruits |
| End Day check | Parties going out with odds, denied quests, affordable upgrades with buy buttons |
| Day Report | Totals (succeeded, gold, injuries), an "At home" line (training, healing), one letter per quest with its story |
| Menu | How to play, last night's report, colorblind filter (tap to cycle Off / Red-weak / Green-weak / Blue-yellow, saved to `user://settings.cfg`), reset upgrades (debug) |

## Colorblind filter

`Styles/colorblind_filter.gdshader` is a full-screen daltonize pass on a CanvasLayer
(layer 100) at the bottom of `hall_main.tscn`, so it recolours everything, overlays and
art included. It moves the colour differences a player can't see into ones they can.
It doesn't fake colourblindness. When it's Off the rect is hidden and costs nothing.
`strength` on the material (0-1) softens it.

## Training Yard and Hospital

Both live on the Upgrades tab's **Tonight** half (`Scenes/Rows/home_section.tscn`, one building plan each). The rules
live in `Globals/guild_upgrades.gd` (`run_night()`, called by End Day before the quests
are played out), and the tuning numbers sit at the top of that file.

- **Training:** a hero in a slot gets +`TRAINING_STAT_GAIN` to the stat they picked each
  night. Slots stay filled from day to day. Heroes can be Healthy or Sore, but not in a bed.
  **Trainees can't be sent on quests**: take them out of their slot first. "Move here"
  pulls a hero out of a quest party and into a slot.
- **Healing:** injuries now heal one level at a time. At home each level takes
  `HOME_HEAL_NIGHTS` (Sore 2, Hurt 4, Gravely 6). In a Hospital bed it takes
  `HOSPITAL_RECOVERY_REDUCTION` fewer nights (never less than 1). Heroes in a bed can't
  go on quests, and they go home on their own once they're Healthy.
- **Revive:** Hospital level 5 brings one fallen hero back per run, Gravely hurt and in a bed.
- The Day Report's header has an "At home" line with who trained and who healed.

Looks come from the theme, not from overrides: a label is `TitleLabel`, `CapsLabel`,
`ItalicLabel` (or `TitleLight` / `ItalicLight` / `LabelLight` on wood), a panel is
`PaperCard`, `PlanCard`, `TornPaper`... and a button is `GoldButton`, `WoodButton`,
`PaperButton` or `SealButton`. Pick one in the inspector (*Theme > Type Variation*) rather
than overriding colours or styles on the node, so a reskin reaches it.

## Things to watch in the playtest

- Do players compare quests on the Board, or go straight to Next Quest?
- Do they use the quest strip to move picks around, and does keeping drafts feel right?
- Do they buy upgrades during the day, or only from the End Day check?
- Is the Day Report short enough? Does anyone open the stories?
- Do they notice the Guild badge each morning?

## Files

- `hall_main.tscn` + `Scripts/hall_main.gd`: state, every game action, the shell (header, action bar, nav, toast)
- `Scenes/Tabs/`: Board, Guild, Upgrades, Shop
- `Scenes/Screens/`: Assign Party, Character
- `Scenes/Overlays/`: End Day check, Day Report, Welcome, Menu
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
quests per day, milestone day, toast time). Screens call its actions and never change
game state themselves.

## Known issues (in the game systems, not changed here)

- Dead adventurers are shown greyed out and can't be picked in this UI, but the game
  systems themselves don't stop them.
- Quest text typos ("ATTACHING") come from the quest data.
