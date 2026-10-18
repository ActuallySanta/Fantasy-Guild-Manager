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

Generic primitives: flat boxes, Godot's default font, a dark header and nav, white cards.
Colour only carries meaning: each stat has its own colour, green = good / sent,
red = bad / denied, blue = info / to do, yellow = gold, and each quest type and building
has a coloured tag (DUN, ESC, SCT, INT, BOSS / OFF, TRN, HSP, ARM, BRK). The only art is the
project's own `Sprites/Character Icons` and `Sprites/UI Icons`. All colours are in
`Scripts/hall_style.gd` (and the shared boxes in `Styles/`), so a real art pass can
replace them later.

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
| No signal when new recruits arrive (Ledger) | **Guild** badge ("3 new") each morning until you open For Hire |
| Hiring and questing blurred together (Deck) | Guild tab has two clearly separate halves: **Your Guild** / **For Hire** |
| Tutorial skipped Home (Ledger) | Welcome card walks through Board, Guild, Upgrades and the big button, then lands on the Board |
| Small buttons (Flow) | Main buttons are 88–96 px tall, nav tabs 100 px, list rows are tappable as a whole |
| Too much scrolling / decorative art (Ledger) | No decorative art. The Board fits 5 quests without much scrolling. "Coming soon" buildings collapse into one line |
| Quest results are walls of text (Flow) | **Day Report** shows result, gold, party, odds and who got hurt; the full story is behind *Read the story* |

## Layout

```
┌ header ─ Day · Bone Drake countdown · gold · standing · menu ┐
│ content ─ Board | Guild | Upgrades  (or a screen over them) │
│ action bar ─ "what to do next" + one big button             │
└ nav ─ Board (undecided) · Guild (new recruits) · Upgrades (affordable) ┘
```

| Screen | What's on it |
|---|---|
| Board (tab) | Today checklist (Recruits / Quests / Upgrades, each tappable), then all quests. Rows show *Pick a party*, *Party picked*, *Sent* or *Denied* with odds and mini portraits |
| Assign Party | Quest strip; quest card; party seats (tap to remove) with live odds; picker sorted best fit first. Adventurers already in another quest's party are hidden unless **Show busy** is on; shown, they say "Picked for / Sent on #N" and move over when tapped. Footer: Deny / Send Party, or Recall / Next Quest, or Board / Reconsider |
| Guild (tab) | Your Guild (roster with health, today's task, all five stats) / For Hire (recruit cards with Hire). Bed count links to the Barracks |
| Upgrades (tab) | Wallet, affordable buildings first, level pips, now/next effect, cost or what's missing |
| Character | Portrait, health, injuries, today's task, five stats with Armory bonus, backstory, Hire for recruits |
| End Day check | Parties going out with odds, denied quests, affordable upgrades with buy buttons |
| Day Report | Totals (succeeded, gold, injuries), one short card per quest, story on demand |
| Menu | How to play, last night's report, reset upgrades (debug) |

## Things to watch in the playtest

- Do players compare quests on the Board, or go straight to Next Quest?
- Do they use the quest strip to move picks around, and does keeping drafts feel right?
- Do they buy upgrades during the day, or only from the End Day check?
- Is the Day Report short enough? Does anyone open the stories?
- Do they notice the Guild badge each morning?

## Files

- `hall_main.tscn` + `Scripts/hall_main.gd`: state, every game action, the shell (header, action bar, nav, toast)
- `Scenes/Tabs/`: Board, Guild, Upgrades
- `Scenes/Screens/`: Assign Party, Character
- `Scenes/Overlays/`: End Day check, Day Report, Welcome, Menu
- `Scenes/Rows/`: list rows (quest row, quest tab, party seat, picker row, roster / hire cards, upgrade card, Today box, plan row, upgrade suggestion, report entry, story line)
- `Scenes/Components/`: chip, portrait, stat strip, odds bar
- `Styles/` + `hall_theme.tres`: shared boxes and the base theme
- `Scripts/hall_style.gd`: colours, stat / injury / odds tables, quest-type and building tags, icon table, text helpers, restyles

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
- Injuries never heal yet (Hospital isn't implemented).
- Quest text typos ("ATTACHING") come from the quest data.
