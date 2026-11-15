# Fantasy Guild Manager

A phone-first fantasy management game made in Godot 4.7. You run an adventurers' guild:
hire heroes, put together parties for each day's quests, and spend the gold they bring
back on gear and building upgrades. Heroes get hurt, rest up, train and sometimes don't
come back. A Bone Drake arrives on day 10, and the story ends with a final battle on
day 50. Win it and the game rolls credits, then opens an endless freeplay mode with
harder quests.

**Play it in your browser:** <https://www.santibenfer.com/Fantasy-Guild-Manager/>

On a phone, use the browser's **Add to Home Screen** to install it as an app. It runs
full-screen in portrait and works offline after the first visit.

## How to play

Each day follows the same loop:

1. **Board.** See every quest on offer today, with its reward, rank, party size and odds.
2. **Guild.** Hire applicants, check on your heroes, and train or heal them.
3. **Assign Party.** Pick a party for each quest you want to take on (or deny it), and
   watch the odds change as you add heroes.
4. **End Day.** The parties set out. The Day Report tells you how each quest went: gold
   earned, injuries and story.
5. **Upgrades and Items.** Spend gold on buildings (Armory, Barracks, Training Yard,
   Hospital) and gear from the Shop.

The run ends if the guild can never send anyone out again. The big button above the
bottom bar always shows the next step, and Pip, the tutorial guide, walks you through
the first few days.

## Running it from source

1. Install **Godot 4.7** (the standard build, not .NET), from
   [godotengine.org](https://godotengine.org/download) or Steam.
2. Clone the repo:

   ```bash
   git clone https://github.com/ActuallySanta/Fantasy-Guild-Manager.git
   ```

3. Open Godot, choose **Import**, and select `project.godot` in the cloned folder.
4. Press **F5** (Run Project). The main scene is `MobileHall/hall_main.tscn`.

The window starts in portrait (720 × 1280), like a phone. You can resize it.

### Playtest scenarios

`MobileHall/Playtest/` has scenes that start a run partway in, with a preset day, gold,
standing and roster (for example, right before the Bone Drake, or on the Game Over
screen). Open one and press **F6** (Run Current Scene).

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
| `MobileHall/` | The current game UI: the hall scene, tabs, overlays, styles and art. Its [README](MobileHall/README.md) covers the UI's design and rules. |
| `Globals/` | Autoloads that hold the game state: roster, wallet and buildings, day counter, quests, items and shop. |
| `Scripts/` | Game logic: characters, quest generation and results, items. Also the older prototype UI. |
| `External Content/` | Text data: names, backstories, locations, monsters, quest story parts. |
| `Scenes/` | The older prototype UI's scenes. |
| `Sprites/`, `Tilemaps/` | Art. |
| `Builds/` | Committed desktop builds from earlier iterations. |

[CLAUDE.md](CLAUDE.md) has more detail on the architecture and code conventions.
