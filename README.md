# Fantasy Guild Manager

A phone-first fantasy management game made in Godot 4.7. You run an adventurers' guild:
hire heroes, put together parties for each day's quests, and spend the gold they bring
back on gear and building upgrades. Heroes get hurt, rest up, train and sometimes don't
come back. Bosses arrive on set days (the Bone Drake on day 10, the Necromancer on 20,
the Demon Generals on 30 and 40), and the story ends with the Demon King on day 50. Win
it and the game rolls credits, then opens an endless freeplay mode with harder quests.

**Play it in your browser:** <https://www.santibenfer.com/Fantasy-Guild-Manager/>

On a phone, use the browser's **Add to Home Screen** to install it as an app. It runs
full-screen in portrait and works offline after the first visit.

## How to play

A new run opens with a short story crawl about how you inherited the guild. After that,
each day follows the same loop:

1. **Quests.** See every quest on offer today, with its reward, rank, party size and odds.
2. **Guild.** Hire applicants, check on your heroes, and train or heal them.
3. **Assign Party.** Pick a party for each quest you want to take on (or deny it), and
   watch the odds change as you add heroes. Pinning a hero sends the quest.
4. **End Day.** The parties set out. The Day Report tells you how each quest went: gold
   earned, injuries and story.
5. **Upgrades and Items.** Spend gold on buildings (Armory, Barracks, Training Yard,
   Hospital) and gear from the Shop.

The run ends if the guild can never send anyone out again. The End Day button sits
at the bottom of the Quests tab, and Pip, the tutorial guide, walks you through
the first few days.

## Running it from source

1. Install **Godot 4.7** (the standard build, not .NET), from
   [godotengine.org](https://godotengine.org/download) or Steam.
2. Clone the repo:

   ```bash
   git clone https://github.com/ActuallySanta/Fantasy-Guild-Manager.git
   ```

3. Open Godot, choose **Import**, and select `project.godot` in the cloned folder.
4. Press **F5** (Run Project). The main scene is `Scenes/hall_main.tscn`.

The window starts in portrait (720 × 1280), like a phone. You can resize it.

### Playtest scenarios

`Scenes/Playtest/` has scenes that start a run partway in, with a preset day, gold,
standing and roster (for example, right before the Bone Drake, or on the Game Over
screen). Open one and press **F6** (Run Current Scene).

### AI playtesters

Eight AI personas can play the game and report back: four read the game's numbers
(min-maxer, cautious-planner, reckless-gambler, typical-player) and four play by
screenshot and tap only (first-timer, skimmer, accessibility, genre-veteran). In Claude
Code, run `/playtest` (arguments: `personas=`, `runs=`, `seed=`, `label=`, `days=`). It
works in a scratch copy of the project and writes `Docs/playtests/<date>-<label>.md`
(see `Docs/playtests/README.md`). The scripts are in `tools/playtest/`.

### Saving while developing

By default every launch starts a fresh Day 1. To keep your run between launches, open
the Menu, then **Debug tools**, and tick **Save runs**. Debug tools also has cheats
(skip days, add gold, max buildings and so on) and **Check for update** for the web
build.

## Builds

- **Web:** every push to `master` builds the `Web` export preset and deploys it to
  GitHub Pages (`.github/workflows/deploy-web.yml`). You can also run it by hand from
  the Actions tab with **Run workflow**.
- **Desktop:** older Windows, macOS and Linux builds are in `Builds/`. To make new ones,
  use **Project > Export** in the editor.

## Project layout

| Folder | What's in it |
|---|---|
| `Scenes/` | Every scene: the hall (`hall_main.tscn`), tabs, screens, overlays, rows, components and playtest scenarios. |
| `Scripts/` | `UI/`: each scene's script, in matching folders. `Hall/`: the hall's state, rules, saving and style. Plus the game logic: characters, quest generation and scoring, items, credits data. |
| `Globals/` | Autoloads that hold the game state: roster, wallet and buildings, day counter, quests, items and shop. |
| `External Content/` | Text data: names, backstories, locations, monsters, quest story parts. |
| `Sprites/` | Every image: UI textures and icons, character and item icons, the Shop tab's art. Its [README](Sprites/README.md) covers swapping art. |
| `Fonts/`, `Themes/` | The fonts, and the UI theme with one StyleBox per surface. |
| `Data/` | The team credits shown in the credits roll. |
| `Docs/` | [hall_design.md](Docs/hall_design.md): the UI's design and rules; `playtests/` holds the AI playtest reports; `vault/` is an Obsidian vault of code docs (every script, function and scene, plus system flow diagrams), kept current with `/docs-vault`. |
| `tools/` | `playtest/`: the shell scripts and tests behind the AI playtesters (`/playtest`). `docs/`: `index_functions.py`, the function and scene index behind `Docs/vault`. |
| `Audio/` | Sound effects (drop-in folder; see its README). |
| `Builds/` | Committed desktop builds from earlier iterations. |

[CLAUDE.md](CLAUDE.md) has more detail on the architecture and code conventions.
