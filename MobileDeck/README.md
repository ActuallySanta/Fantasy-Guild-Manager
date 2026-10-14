# Mobile Deck UI (playtest variant)

A phone-first UI for the guild game built as a **swipeable card deck** (Reigns / Tinder style),
in dark mode. It is the third layout alongside `MobileLedger/` (tabs) and `MobileFlow/`
(guided steps). It is **UI only**: it runs on the existing systems (`CharacterContainer`,
`GuildCharacter`, `CreatedQuest`, `GameState`, `GuildUpgrades`, `DayBar`'s scoring helpers)
and changes none of them.

- **Run it:** open `MobileDeck/deck_main.tscn` and press *Run Current Scene* (F6).
  The project's main scene is unchanged. Swiping works with mouse drag or touch.

## How a day plays

Each day is a stack of cards, with dots at the top showing progress
(green = party sent, red = denied, blue = current card):

| Card | Swipe right / button | Swipe left / button |
|---|---|---|
| Recruit (big portrait, stats, backstory line) | Hire (free) | Pass |
| Quest (type, rank, gold, favored stat, party slots, live success %) | Send party | Deny |
| End of day (today's plan, upgrades, last report) | n/a: tap **End Day** | n/a |

- **Roster tray** (bottom): your guild is always visible. On a quest card, tap someone
  to put them on the card; tap them on the card to take them off. On other cards, tap for details.
- A right swipe that isn't allowed yet (no party, or guild full) springs back and says why.
- **Back** returns to the previous card and undoes its decision. Tapping a quest on the
  End of day card does the same for that quest.
- **Upgrades** (header) and **?** (how to play) open bottom sheets from anywhere.
- Recruit cards are skipped once the guild is full.

## Things to watch in the playtest (vs. the other two layouts)

- Do players discover swiping, or only use the buttons?
- Is it clear that the tray adds people to the quest card?
- Does the deck feel faster? Do players deny quests too casually when it's one flick?
- Do players open Upgrades from the header, or only from the End of day card?

## Look

Dark mode, rounded cards, Godot's default font. Colour only carries meaning: each stat has
its own colour, green = good / hire / send, red = bad / pass / deny, yellow = gold,
blue = selected / info, and health runs green → yellow → orange → red. Art is only the project's
own `Sprites/Character Icons` and `Sprites/UI Icons` (recoloured by a small shader, since the
SVGs are black).

## Files

- `deck_main.tscn` + `Scripts/deck_main.gd`: state, game-flow calls, the deck, swipe handling, roster tray
- `Scenes/Cards/`: what's printed on recruit / quest / end-of-day cards
- `Scenes/Sheets/`: upgrades, character details, how-to-play
- `Scenes/Overlays/overlay_report.tscn`: the day report
- `Scenes/Rows/`: progress dot, tray tile, party slots, plan row, upgrade row, report entry
- `Scenes/Components/`: chip, stat row, portrait
- `Styles/` + `deck_theme.tres`: shared boxes, icon tint materials and the base theme
- `icon_tint.gdshader`: recolours the black UI icon SVGs
- `Scripts/deck_style.gd`: all colours, plus the few restyles that depend on game state

### Editing the scenes

Every screen, row and widget is an authored scene you can open and edit in the
Godot editor. Nothing is built from code at runtime: scripts only fill in text,
show/hide nodes and instance row scenes for lists (one row per quest, character,
etc.). Shared boxes (panels, buttons, chips) are `.tres` files in `Styles/`, so
changing one restyles it everywhere; chips, stat rows and gauges are `@tool`
components with exported colours/sizes so they preview in the editor.
