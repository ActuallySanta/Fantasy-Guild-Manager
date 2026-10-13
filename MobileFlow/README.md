# Mobile Flow UI (playtest variant)

A phone-first UI for the guild game, built as a **guided day loop** instead of the
tab layout in `MobileLedger/`. It is **UI only**: it runs on the existing systems
(`CharacterContainer`, `GuildCharacter`, `CreatedQuest`, `GameState`, `GuildUpgrades`,
`DayBar`'s scoring helpers) and changes none of them.

- **Run it:** open `MobileFlow/flow_main.tscn` and press *Run Current Scene* (F6).
  The project's main scene is unchanged.

## Layout

Every day walks through three steps, shown in a step bar under the header
(each step can also be tapped directly):

| Step | What's on screen | Main button (bottom bar) |
|---|---|---|
| 1. Hire | Today's recruits, each with colour-coded stats and a Hire button. Skipped automatically when nobody can be hired. | Next: Quests |
| 2. Quests | **One quest per screen**: type, rank, gold, party size, favored stat; the party slots and live success chance; the roster sorted by best fit, tap to add/remove. Numbered squares jump between quests (grey = undecided, green = party set, red = denied). | Deny / Send party, which moves straight to the next undecided quest |
| 3. End Day | Today's plan (tap a row to go back to that quest), upgrades, last night's report. | End Day (locked until every quest is decided) |

The **Guild** button in the header opens roster / for hire / upgrades from any step,
and character details open from there or from "Details" on a recruit.

## Things to watch in the playtest (vs. the tab layout)

- Do players understand what to do next without being told (step bar + one main button)?
- Is one-quest-at-a-time faster or slower than scanning a list of quests?
- Do players find upgrades when they live in the End Day step instead of their own tab?
- Do players use the Guild button, or ignore the roster?

## Look

Flat grey boxes, Godot's default font. Colour only carries meaning: each stat has its own
colour, green = good / go, red = bad / deny, yellow = gold, blue = info / current, and
health runs green → yellow → orange → red. Art is only the project's own
`Sprites/Character Icons` and `Sprites/UI Icons`.

## Files

- `Scripts/flow_main.gd`: state, game-flow calls, header / step bar / footer shell
- `Scripts/flow_style.gd`: widget helpers and all colours
- `Scripts/step_hire.gd`, `step_quest.gd`, `step_end.gd`: the three steps
- `Scripts/sheet_guild.gd`, `sheet_character.gd`: Guild sheet and character details
- `Scripts/overlay_report.gd`, `overlay_intro.gd`: day report and first-launch intro
