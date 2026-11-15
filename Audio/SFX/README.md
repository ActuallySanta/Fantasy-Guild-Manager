# Sound effects (drop-in folder)

Drop a sound file into this folder, named exactly as in the tables below, and
the game plays it the next time it starts. Missing files are just silent, so
add them one at a time in any order. The code side is `Globals/sound_effects.gd`
(the `Sfx` autoload).

**How to add a sound**

1. Name the file after the sound, e.g. `shop_buy.ogg`. Lowercase, underscores, no spaces.
2. Put it in this folder (`Audio/SFX/`). With the Godot editor open, it imports on its own.
   Without the editor open, open it once before running so the file gets imported.
3. Commit the sound **and** the `.import` file Godot makes next to it.

- **Formats:** `.ogg` (best for size, especially the web build), `.wav` or `.mp3`.
  If two formats share a name, `.ogg` wins, then `.wav`, then `.mp3`.
- **Variants:** add `shop_buy_2.ogg`, `shop_buy_3.ogg` and so on, up to `_5`.
  The game picks one at random each time, so sounds that repeat a lot (taps,
  coins, Pip) don't get tiring. The plain name (`shop_buy.ogg`) is optional
  when variants exist.
- **Volume:** each sound has a volume and a little random pitch set in `SOUNDS`
  at the top of `sound_effects.gd`. Change the numbers there rather than
  re-exporting the file.
- **Length:** keep UI sounds short (under 0.3 s). The bigger moments, like
  `night_fall`, `day_start`, `victory`, `defeat` and `game_over`, can run 1 to 4 s.
- **Licensing:** keep a note of where each sound came from and its license
  (for example in a `CREDITS.txt` next to this file). Most free packs ask for credit.

Any button that doesn't have its own sound below plays `ui_tap`. When an action
has its own sound, the tap is skipped, so one press never plays two sounds at once.

## The sounds

### Interface

| File name | When it plays | Suggested sound |
|---|---|---|
| `ui_tap` | Any button or card press that has no sound of its own | Soft paper or wood tick |
| `ui_error` | An action that can't be done: a locked tab, a full party, not enough gold, the wrong role for gear, Pip saying "not that one" | Dull thunk or low buzz |
| `tab_switch` | Switching bottom tabs, or the Guild/Items/Upgrades halves | Page flip |
| `page_open` | Opening a hero page, Assign Party, the Menu, the End Day check, Accessibility, Debug or Welcome | Paper unfold or book open |
| `page_close` | Closing any of those | Paper fold or book close |

### Quests (Board and Assign Party)

| File name | When it plays | Suggested sound |
|---|---|---|
| `party_join` | A hero is added to a party | Footstep or armor jingle |
| `party_leave` | A hero is taken out of a party | Lighter or reversed footstep |
| `quest_send` | Send: the SENT stamp | Rubber stamp thump, maybe with a horn blip |
| `quest_deny` | Deny: the DENIED stamp slams down | Heavy stamp slam |
| `quest_undo` | Recall a sent party, or Reconsider a denied quest | Paper slide or rewind swish |

### Guild

| File name | When it plays | Suggested sound |
|---|---|---|
| `hire` | Hiring a hero: the HIRED stamp | Stamp plus a cheer or quill scratch |
| `hire_letter_fly` | The hired letter flies into the Your Guild tab | Paper whoosh |
| `release` | Releasing a hero for good | Door close or a sad sigh |

### Items

| File name | When it plays | Suggested sound |
|---|---|---|
| `shop_buy` | Buying from Grizzle's shop (the coin sound plays too, so leave coins out of this one) | Cash register "ka-ching" or a bag drop |
| `equip` | Putting gear on a hero, or swapping gear | Sword unsheathe or armor clank |
| `unequip` | Taking gear off | Softer clank or cloth rustle |

### Upgrades (Tonight and Build)

| File name | When it plays | Suggested sound |
|---|---|---|
| `building_upgrade` | Upgrading the Armory, Barracks, Training Yard or Hospital | Hammer strikes or construction |
| `training_start` | A hero starts training | Sword swing or grunt |
| `hospital_admit` | A hurt hero goes into a Hospital bed | Bed creak or bandage rip |
| `hospital_discharge` | A hero leaves the Hospital | Door open or relieved sigh |
| `revive` | A fallen hero is brought back | Holy chime or choir swell |

### Gold and standing

| File name | When it plays | Suggested sound |
|---|---|---|
| `gold_spend` | Gold paid for anything (hire, buy, build, revive); a coin flies off the counter | Single coin flip |
| `standing_lose` | Standing lost (denying a quest, releasing a hero) | Low shield clunk or crowd "boo" |
| `coin_land` | At dawn, each coin of the night's earnings landing on the gold counter (several play in a row) | Small coin clink, best with 2 or 3 variants |
| `standing_land` | At dawn, each shield of standing gained landing on its counter | Light metal tink |

### The night and the Day Report

| File name | When it plays | Suggested sound |
|---|---|---|
| `night_fall` | End Day: dusk falls over the screen | Owl hoot, crickets, or a low gong |
| `letter_success` | A report letter's SUCCESS stamp lands | Bright stamp plus a short fanfare |
| `letter_fail` | A report letter's FAILED stamp lands | Stamp plus a descending "wah" |
| `hero_hurt` | A letter's "Hurt" tag stamps in | Grunt or "oof" |
| `hero_died` | A letter's "Died" tag stamps in (the letter shakes) | Solemn bell toll |
| `item_found` | A letter's "Found" tag stamps in (gear found on the quest) | Sparkle or chest open |
| `day_start` | A new day begins (dawn) | Rooster or morning bell |
| `story_day` | The dawn of a story day: the Bone Drake (day 10) and the final battle (day 50). Plays instead of `day_start` | Ominous horn or war drum |
| `danger_warning` | The red "last hero standing" warning appears under the header | Alarm bell or tense sting |

### Endings

| File name | When it plays | Suggested sound |
|---|---|---|
| `game_over` | The guild falls: the Game Over ledger opens | Funeral sting |
| `victory` | The final battle is won: the credits roll | Triumphant fanfare |
| `defeat` | The final battle is lost: the defeat credits roll | Somber low strings |

### Tutorial

| File name | When it plays | Suggested sound |
|---|---|---|
| `pip_talk` | Pip, the tutorial coach, says something new | Cute chirp or gibberish blip, best with variants |

## Adding a new sound

1. Add its name to `SOUNDS` in `Globals/sound_effects.gd`, with a volume and pitch jitter.
2. Call `Sfx.play(&"its_name")` where it should play, or `Sfx.play_after(&"its_name", seconds)`
   to line it up with an animation.
3. Add a row to the table above.
