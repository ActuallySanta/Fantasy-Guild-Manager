# Quest travel loading screen: design

## Executive summary

Between tapping End Day and the Day Report, show a short loading screen. It reads "Going on a quest", has an animated element, and plays a background sound. After a random 2 to 4 seconds, a button appears, and the result only shows when the player presses it, so they choose the moment it lands. It's a new authored overlay scene. All art and sound are slots that Santi fills in: no assets are generated. Gameplay, saving and the report itself don't change.

## Intent

Ending the day feels flat at the moment. The dice roll and the report opens in under a second. A short "the party is out there" beat adds a little action and suspense before the result. The random length keeps the player from timing it.

## Goals

- A full-screen "Going on a quest" screen shows on every night: regular nights, boss nights and the final battle.
- After a random time between `TRAVEL_MIN_SECONDS` (2.0) and `TRAVEL_MAX_SECONDS` (4.0), documented tunables, a button appears (label "View quest report", a `TEXT` constant). Nothing happens until the player presses it.
- An animated element (for example walking boots or clashing swords) plays on the screen.
- A background sound plays while the screen is up and stops when the button is pressed.
- After the press, the existing dusk curtain opens the report, boss crawl or credits exactly as it does now.

## Non-goals and anti-goals

- No generated music, sound or images. Santi supplies them.
- No change to how quests are rolled, paid out or saved.
- Tapping doesn't skip the wait. Until the button appears, taps do nothing, because skipping would undercut the suspense.
- It must not slow down the AI playtest bridge.
- With no art or sound dropped in yet, it must still look intentional and not broken.

## Approaches

- **A. New overlay scene (chosen).** `Scenes/Overlays/Day/overlay_quest_travel.tscn`, with its script at `Scripts/UI/Overlays/Day/overlay_quest_travel.gd`, follows the authored-scene pattern of the boss crawl and the report. It has room for art and an animation, and its text stays in the script's `TEXT` section.
- **B. Stretch `HallFx.curtain`.** This is the smallest change, but it leaves no place for art or animation, puts the text in code, and vanishes when Reduce motion is on. Rejected.

## Design

**Flow** (`hall_main.gd` `end_day()`). Rolling, saving the night and `night_fall` stay as they are. The difference is that the overlay now shows first. It holds a timer for a random duration from `randf_range(TRAVEL_MIN_SECONDS, TRAVEL_MAX_SECONDS)`. When the timer runs out, the overlay fades in `%Continue` (a quick fade; instant with Reduce motion). The walker and the ambience keep going while it waits. Pressing it calls back into hall_main, which runs the existing curtain into `show_report` / `show_credits`. `is_night_falling` stays true the whole time, so End Day can't be tapped twice. Keep the new code in `hall_main.gd` to a few lines, because that file is already over its size limit. The timing lives in the overlay.

**Overlay scene contents** (all of these are slots Santi fills in):
- `%Backdrop`: a full-screen `TextureRect` with no texture, over a `DUSK_INK`-coloured `ColorRect`, so it looks fine with no art.
- `%Continue`: a hall-themed button, hidden and not clickable until the timer ends. It's pressed once only, so a double tap can't open the report twice. Its press plays the usual `ui_tap`.
- `%Walker`: an `AnimatedSprite2D` (or a `TextureRect` driven by a `SpriteFrames`) with an empty `SpriteFrames` resource. Santi adds frames of boots or swords and it loops.
- A code-driven motion on `%Walker`: a small looping bob or stride tween, so a single still image still feels alive.
- `%Title`: a label reading "Going on a quest", with dots that cycle (". .. ...") so something moves even before any art exists.

**Sound.** Add a new `Sfx` name, `quest_travel`, to `SOUNDS` and `Audio/SFX/README.md` as a drop-in ambience file. `Sfx` gains a `stop(sound_name)` that stops any voice currently playing that sound. The overlay plays it on show and stops it when the button is pressed. If the file is shorter than the wait, it isn't looped (Santi can set loop on the file's import if they want it to). A missing file stays silent, as usual.

**Reduce motion.** The screen and its timer still show. The bob tween and cycling dots are turned off. The sprite animation still plays, because it's Santi's art and not UI motion (a builder may pause it instead if that reads better).

**Save and resume.** No change. The night is saved before the overlay shows, so quitting mid-load reopens straight to the report.

**AI playtest bridge.** The bridge skips the overlay, for example through a flag on `HallMain` that the bridge sets so the overlay is skipped entirely (no wait, no button), so rules-mode playtests run at today's speed.

**Docs.** Update the night / Day Report flow in `Docs/hall_design.md`. The README is unaffected (not a new tab or setting).

## Left to the builder

- Whether `%Walker` is an `AnimatedSprite2D` inside a `Control` holder or a `TextureRect` that swaps frames, and where it sits on the screen.
- The exact bob amplitude and timing, and the dot-cycle speed, as named constants.
- How the bridge flag is named and set.
