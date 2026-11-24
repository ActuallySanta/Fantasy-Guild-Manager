# Quest Travel Loading Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## Executive summary

End Day gets a full-screen "Going on a quest" screen. The night is still rolled and saved at once, as it is today. Then a new overlay shows with an animated walker slot, cycling dots and a `quest_travel` ambience. After a random 2 to 4 seconds a "View quest report" button fades in. Pressing it stops the sound and runs today's dusk curtain into the report, boss crawl or credits.

There are three tasks:
1. `Sfx.stop()` and the `quest_travel` sound name.
2. The overlay scene and its script.
3. Wiring the overlay into `hall_main`, plus a skip flag that the playtest bridge and the two existing night tests use. This task also adds a new headless test and updates the docs.

No art or audio files are created.

**Goal:** Add a "Going on a quest" loading screen between End Day and the night's results. It lasts a random length and ends with a "View quest report" button.

**Architecture:** `HallMain.end_day()` passes the curtain call it makes today to a new `_go_on_quest(then: Callable)`. That function opens the overlay through state (`is_quest_travel_open`) and the usual refresh. The overlay owns the timing, the animation and the sound. Its button calls `HallMain.close_quest_travel()`, which runs the stored callable, and the curtain's peak callbacks clear the state. A `skip_quest_travel` flag on `HallMain` calls `then` straight away, for the bridge and the tests.

**Tech Stack:** Godot 4.7 GDScript. Headless tests use `tools/tests/run_test.sh` (`TestCase`).

**Spec:** `docs/superpowers/specs/2026-11-24-quest-travel-loading-screen-design.md`

## Global Constraints

- Generate no image, animation or audio files. Every visual and audio element is an empty slot or a drop-in name.
- Text constants are exact: `"Going on a quest"` for the title and `"View quest report"` for the button.
- Timing tunables live at the top of the overlay script: `TRAVEL_MIN_SECONDS := 2.0` and `TRAVEL_MAX_SECONDS := 4.0`, with `##` docs and units.
- Taps before the button appears do nothing. There is no skip.
- Rolling, payouts, `night_save` and `save_now()` don't change. The night is saved before the overlay shows, and the overlay state is never saved.
- `hall_main.gd` (1,918 lines) only gets state, two small actions and refresh lines. The timing and animation live in the overlay script.
- Follow the project conventions in CLAUDE.md:
  - header comment naming the scene
  - `TEXT` and `NODES` sections
  - `%Unique` names
  - `setup(hall)` / `refresh()`
  - the scene loaded by uid, with the path in a comment
  - hand-written `.tscn` files carry `uid=` in their header and on each `ext_resource`
  - `##` doc comments throughout

## Review Focus

1. **A double tap on the button** must not run the curtain twice. Test: press twice in one frame, then check the report opens once and `is_night_falling` ends false.
2. **The final battle (day 50)** goes through the overlay too, and the credits still open after the press (the defeat curtain is unchanged). Test: run day 50 with travel on and check that `shown_credits` gets filled after the press.
3. **Reduce motion on:** the screen and timer still run, the button appears without a fade, and the press still works (the curtain calls at_peak at once). Test: a reduce-motion pass of the main flow.
4. **Existing night tests and the rules bridge** must not hang waiting on a button. `boss_crawl_test`, `report_roam_test` and `AgentBridgeActions.end_day` set `skip_quest_travel`. Verify by running both existing tests.
5. **The End Day confirm sheet, Menu and other overlays** stay hidden while the travel screen is up. Count the travel screen as "report open" in `_refresh_overlays`. Check this by code review in Task 3.

---

### Task 1: `Sfx.stop()` and the `quest_travel` sound

**Files:**
- Modify: `Globals/sound_effects.gd`. Add a `SOUNDS` entry under `# ---- the night and the Day Report`, track the sound name per voice in `_play_now`, and add `stop()` after `cancel_scheduled()`.
- Modify: `Audio/SFX/README.md`. Add a row after `night_fall`.
- Test: `tools/tests/sfx_stop_test.gd` and `.tscn`

**Interfaces:**
- Produces: `Sfx.stop(sound_name: StringName) -> void`, which stops every voice currently playing that name and does nothing if none is. Also produces `&"quest_travel"` in `SOUNDS` as `{"volume_db": -4.0, "pitch_jitter": 0.0}`.

- [ ] **Step 1: Write the failing test** `tools/tests/sfx_stop_test.gd` (`extends TestCase`), with a `.tscn` shaped like `boss_crawl_test.tscn` that has its own `uid`:
  - Inject a stream: `Sfx._streams[&"quest_travel"] = [_silent_wav(2.0)]`. The helper builds an `AudioStreamWAV` with 16-bit mono 22050 Hz, `data` of zero bytes for that many seconds.
  - `Sfx.play(&"quest_travel")` and `Sfx.play(&"ui_tap")`, then wait one frame.
  - `check(_voices_playing(&"quest_travel") == 1, "quest_travel plays")`. The `_voices_playing` helper counts `Sfx._voices` that are `playing` with `Sfx._voice_sounds[i] == name`.
  - `Sfx.stop(&"quest_travel")`, then `check(_voices_playing(&"quest_travel") == 0, "stop silences it")`.
  - `Sfx.stop(&"victory")` with nothing playing must not error. `check(true, "stop with nothing playing is safe")`.
  - Restore `_streams` afterwards.
  - If the dummy audio driver reports `playing == false` straight after `play()`, assert on `_voice_sounds` and `stream_paused`/`stop` effects instead, and note it in the test header.
- [ ] **Step 2: Run it and confirm it fails.** Run `bash tools/tests/run_test.sh sfx_stop`. Expected: FAIL or a script error on `stop` / `_voice_sounds`.
- [ ] **Step 3: Implement it.**
  - Add `var _voice_sounds: Array[StringName]` and size it to `VOICE_COUNT` in `_ready`.
  - Set `_voice_sounds[_voices.find(voice)] = sound_name` in `_play_now`.
  - `stop(sound_name)` calls `.stop()` on each voice that is playing whose entry matches.
  - Add the `SOUNDS` entry.
  - README row: `| \`quest_travel\` | The "Going on a quest" screen after End Day, until View quest report is pressed | Marching boots, distant clashes, wind on the road (2-4 s or longer; set Loop on import to fill a long wait) |`.
- [ ] **Step 4: Run it and confirm it passes.** Run `bash tools/tests/run_test.sh sfx_stop`. Expected: every `TEST` line passes, exit 0.
- [ ] **Step 5: Commit.** Message: `feat: Sfx.stop and the quest_travel ambience name`.

### Task 2: The quest travel overlay

**Files:**
- Create: `Scenes/Overlays/Day/overlay_quest_travel.tscn`. Pick header uid `uid://b7qtr4velscn1`. Its `ext_resource` points to the script with `uid="uid://c7qtr4velgd01"`.
- Create: `Scripts/UI/Overlays/Day/overlay_quest_travel.gd` and `overlay_quest_travel.gd.uid` (content `uid://c7qtr4velgd01`).

**Interfaces:**
- Consumes: `Sfx.stop(&"quest_travel")` (Task 1), `HallFx.reduce_motion`, `HallStyle.style_button(button, "gold", size)`, `HallMain.DUSK_INK`, and `hall.close_quest_travel()` (made in Task 3, so this task can't run alone. Its check is Task 3's test).
- Produces:
  - `setup(main: HallMain) -> void`
  - `refresh() -> void`: starts a trip if one isn't running.
  - `is_button_shown() -> bool`
  - `trip_seconds: float`: the rolled length, read by the test.
  - Node names `%Bg`, `%Backdrop`, `%WalkerHolder`, `%Walker`, `%Title`, `%ContinueButton`.

**Scene** (root `OverlayQuestTravel` is a `Control` set to full rect, with the script attached):
- `Bg`: a `ColorRect` set to full rect, with the color `#26304A` (`DUSK_INK`).
- `Backdrop`: a `TextureRect` set to full rect, `expand_mode` ignore size, `stretch_mode` keep-aspect-covered, and no texture.
- `WalkerHolder`: a `Control`, 260×260 and centred slightly above the middle (anchors 0.5, offsets ±130, centre about y 0.42). Inside it, `Walker` is an `AnimatedSprite2D` at (130, 130) with a sub-resource `SpriteFrames` that has a `default` animation, loop on, speed 8, no frames.
- `Title`: a centred `Label` under the holder.
- `ContinueButton`: a `Button` near the bottom (like the boss crawl's footer), `visible = false`.

**Script behavior:**
- `TEXT_TITLE := "Going on a quest"`, `TEXT_CONTINUE := "View quest report"`.
- The `MOTION` tunables are `TRAVEL_MIN_SECONDS := 2.0`, `TRAVEL_MAX_SECONDS := 4.0`, `BOB_PIXELS := 10.0`, `BOB_HZ := 1.6`, `DOT_SECONDS := 0.4` (time per dot step), `BUTTON_FADE_SECONDS := 0.25` and `BUTTON_FONT_SIZE := 46`.
- `refresh()` starts a trip when `_is_trip_running` is false. Starting a trip:
  - sets `trip_seconds = randf_range(TRAVEL_MIN_SECONDS, TRAVEL_MAX_SECONDS)`
  - hides and disables the button
  - plays `Sfx.play(&"quest_travel")`
  - plays `%Walker` if its `sprite_frames` has frames in `default`
  - starts a `get_tree().create_timer(trip_seconds)`, which shows the button when it fires
  - guards the timer with a trip counter, so an old timer can't show a later trip's button
- Showing the button: it's visible and enabled. Its `modulate.a` tweens from 0 to 1 over `BUTTON_FADE_SECONDS`, or is set to 1 at once with reduce motion.
- `_process(delta)`, only while visible and running:
  - The title shows `TEXT_TITLE` plus 0 to 3 dots, stepping every `DOT_SECONDS`. With reduce motion it's fixed at `TEXT_TITLE + "..."`.
  - `%Walker.position.y = 130 + sin(elapsed * TAU * BOB_HZ) * BOB_PIXELS`. With reduce motion it's 130.
- On press:
  - Return if `_is_trip_running` is false.
  - Set `_is_trip_running = false`, disable the button, stop the walker, call `Sfx.stop(&"quest_travel")`, then call `hall.close_quest_travel()`.
  - The `ui_tap` plays on its own, since the press plays no action sound.
- Hidden while a trip is running (`visibility_changed`): stop the sound and reset `_is_trip_running`, so the next night starts fresh.

- [ ] **Step 1: Write the scene and script as above.** It calls `hall.close_quest_travel()`, which doesn't exist until Task 3, so the script won't parse yet. Don't commit or run tests here: Task 3's tests check it, and Task 3's commit includes these files.

### Task 3: Wire it into the night, bridge and tests, plus docs

**Files:**
- Modify `Scripts/Hall/hall_main.gd`:
  - state, near `shown_boss_crawl`, about line 234
  - `@onready` list, about line 394
  - `end_day()`, lines 1532-1577
  - `_show_final_credits()`, lines 1586-1609
  - `_refresh_overlays()` and `_all_overlays()`, lines 1870-1895
- Modify `Scenes/hall_main.tscn`: add an `ext_resource` for the new scene, and instance `OverlayQuestTravel` after `OverlayBossCrawl` with the same unique / visible=false / z_index 10 settings.
- Modify `Scripts/Playtest/agent_bridge_actions.gd` `end_day()`: set `hall.skip_quest_travel = true` before `hall.end_day()`.
- Modify `tools/tests/boss_crawl_test.gd` `_make_hall` and `tools/tests/report_roam_test.gd` (its hall setup): set `hall.skip_quest_travel = true`.
- Test: create `tools/tests/quest_travel_test.gd` and `.tscn`.
- Docs: `Docs/hall_design.md`. Add a "Quest travel" row in the screens table before "Boss crawl" (around line 67), and mention it where the night's flow is described.

**Interfaces:**
- Consumes: the Task 2 overlay API.
- Produces on `HallMain`:
  - `var is_quest_travel_open := false`
  - `var skip_quest_travel := false` (`##` doc: set by the rules bridge and headless tests so End Day goes straight to the curtain)
  - `var _after_quest_travel: Callable`
  - `func close_quest_travel() -> void`
  - `func _go_on_quest(then: Callable) -> void`

**Behavior:**
- `_go_on_quest(then)`: if `skip_quest_travel`, call `then.call()` and return. Otherwise store `then`, set `is_quest_travel_open = true` and `queue_refresh()`.
- `close_quest_travel()`: return if `_after_quest_travel` isn't valid. Otherwise take it, clear it, and call it. This is what makes a double press run once.
- In `end_day()`, the last line becomes `_go_on_quest(func() -> void: HallFx.curtain(fx_layer, DUSK_INK, show_report, 0.92, DUSK_IN_SECONDS, DUSK_OUT_SECONDS))`. `show_report` adds `is_quest_travel_open = false` beside `is_night_falling = false`.
- In `_show_final_credits()`, wrap both curtain branches the same way inside one `_go_on_quest` call. `show_credits` adds `is_quest_travel_open = false`.
- In `_refresh_overlays()`, add `_quest_travel_overlay.visible = is_quest_travel_open` and fold `is_quest_travel_open` into `is_report_open`, so the end check, Menu and other overlays hide. Add the overlay to `_all_overlays()`.

- [ ] **Step 1: Write the failing test** `tools/tests/quest_travel_test.gd`. Build the hall the way `boss_crawl_test._make_hall` does, with travel left on, and send one sure-win quest on day 3.
  - Normal night:
    - After `end_day()` and one frame, check `hall.is_quest_travel_open`, that `shown_report.is_empty()` and that the overlay is visible.
    - `check(ov.trip_seconds >= 2.0 and ov.trip_seconds <= 4.0, "trip length in range")`.
    - One frame later, `check(not ov.is_button_shown(), "button hidden at first")`.
    - Calling `hall.close_quest_travel()` is fine here, because the button guards taps and not the action.
    - Instead, wait until `ov.is_button_shown()` (timeout 5 s) and `check` it.
    - Emit the button's `pressed` twice in one frame, then wait for the night as in `boss_crawl_test._wait_for_night`.
    - `check(not hall.shown_report.is_empty(), "report opens after the press")`, `check(not hall.is_quest_travel_open, "travel closed")`, `check(not hall.is_night_falling, "night settled")`.
  - Skip flag: on a fresh hall with `skip_quest_travel = true`, `end_day()` never opens the travel screen and the report opens. `check(not hall.is_quest_travel_open ...)`.
  - Reduce motion: `hall.set_reduce_motion(true)` and repeat the normal night. The button appears, and the report opens after the press. Reset reduce motion afterwards.
  - Final battle: day `HallMain.FINAL_DAY`, send the final quest, wait for the button, press it, then `check(not hall.shown_credits.is_empty(), "credits open after the press")`.
- [ ] **Step 2: Run it and confirm it fails.** Run `bash tools/tests/run_test.sh quest_travel`. Expected: FAIL or a script error on `is_quest_travel_open`.
- [ ] **Step 3: Implement the `hall_main` state and actions, the scene instance, the bridge flag, the existing-test flags and the `hall_design.md` lines as listed.**
- [ ] **Step 4: Run the tests and confirm they pass.** Run `bash tools/tests/run_test.sh quest_travel`, `bash tools/tests/run_test.sh boss_crawl`, `bash tools/tests/run_test.sh report_roam` and `bash tools/tests/run_test.sh smoke`. Expected: all exit 0.
- [ ] **Step 5: Manual check.** Run `Scenes/hall_main.tscn` (or a playtest scenario), send a party and tap End Day. Check:
  - the dusk screen shows "Going on a quest" with cycling dots
  - the button appears after 2-4 s and taps before it do nothing
  - pressing it fades into the Day Report
- [ ] **Step 6: Commit** Task 2's and Task 3's files together. Message: `feat: Going on a quest screen between End Day and the report`.
