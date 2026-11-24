---
tags: [home]
---

# Fantasy Guild Manager: code docs

This vault documents how the game's code works: every script and function, every scene, and how the major systems flow. The `docs-writer` agent maintains it, and the `/docs-vault` skill runs it. Each script note lists who calls what with `file:line`; each system note shows a flow as a sequence diagram plus a steps table whose "Returns (to)" lines up with a later step's "Takes (from)".

## Systems

- [[Boot and Autoload Order]]: the eight autoloads in order, then the hall's start-up.
- [[Day Cycle]]: one day from End Day through the night, the Day Report and the dawn.
- [[Hiring Characters]]: where new heroes come from, the daily For Hire pool and its prices.
- [[Party Drafting and Assignment]]: picking who goes on which quest on the Assign Party screen.
- [[Success Chance]]: how a party becomes one win chance, and where that number is shown.
- [[Quest Generation and Difficulty]]: how the day's quests, ranks, bosses and the difficulty staircase are built.
- [[Quest Resolution and Injuries]]: playing a quest out: gold, standing, Pluck, injuries, deaths and found items.
- [[Night - Training Hospital Revive]]: the night's training, healing, Hospital bill and reviving the fallen.
- [[Economy and Wallet]]: where gold and standing come from, where they go, and what each unlocks.
- [[Items and Shop]]: gear: the daily shop, rarity from standing, buying and role-locked equipping.
- [[Saving Migration and Backup Codes]]: the run's save file, version migration, and save codes for backups.
- [[Run End]]: danger warnings, Game Over, the final battle, credits and freeplay.
- [[UI Motion and Feedback]]: animations, counters, the dusk wash, crawls, sounds, Reduced Motion and Text size.
- [[UI Architecture and Refresh]]: how views get `setup(hall)` and `refresh()`, and how tabs and features unlock.
- [[Playtest Bridge]]: scenario scenes and the file bridge the AI playtesters drive.

## Scene tree
`hall_main (scene)` is the root of the game; every other game scene hangs under it. Solid lines (`-->`) are scenes placed in the editor; dotted lines (`-.->`) are scenes instanced at runtime by a script (rows built inside a tab's or overlay's `refresh`). Components such as `chip`, `portrait`, `divider` and `stat_strip` appear under every parent that uses them. The diagrams are split by area to stay readable.


### The hall's direct children
Every scene placed in `hall_main.tscn` (nothing is instanced under it at runtime).

```mermaid
flowchart TD
  hall_main["hall_main (scene)"]
  hall_header["hall_header (scene)"]
  hall_nav["hall_nav (scene)"]
  hall_toast["hall_toast (scene)"]
  overlay_accessibility["overlay_accessibility (scene)"]
  overlay_backup["overlay_backup (scene)"]
  overlay_boss_crawl["overlay_boss_crawl (scene)"]
  overlay_credits["overlay_credits (scene)"]
  overlay_debug["overlay_debug (scene)"]
  overlay_end_day["overlay_end_day (scene)"]
  overlay_game_over["overlay_game_over (scene)"]
  overlay_intro["overlay_intro (scene)"]
  overlay_menu["overlay_menu (scene)"]
  overlay_quest_travel["overlay_quest_travel (scene)"]
  overlay_report["overlay_report (scene)"]
  overlay_welcome["overlay_welcome (scene)"]
  screen_assign["screen_assign (scene)"]
  screen_character["screen_character (scene)"]
  tab_board["tab_board (scene)"]
  tab_guild["tab_guild (scene)"]
  tab_items["tab_items (scene)"]
  tab_upgrades["tab_upgrades (scene)"]
  hall_main --> hall_header
  hall_main --> hall_nav
  hall_main --> hall_toast
  hall_main --> overlay_accessibility
  hall_main --> overlay_backup
  hall_main --> overlay_boss_crawl
  hall_main --> overlay_credits
  hall_main --> overlay_debug
  hall_main --> overlay_end_day
  hall_main --> overlay_game_over
  hall_main --> overlay_intro
  hall_main --> overlay_menu
  hall_main --> overlay_quest_travel
  hall_main --> overlay_report
  hall_main --> overlay_welcome
  hall_main --> screen_assign
  hall_main --> screen_character
  hall_main --> tab_board
  hall_main --> tab_guild
  hall_main --> tab_items
  hall_main --> tab_upgrades
```

### Shell: header and popups
```mermaid
flowchart TD
  hall_header["hall_header (scene)"]
  hall_main["hall_main (scene)"]
  hall_nav["hall_nav (scene)"]
  hall_toast["hall_toast (scene)"]
  popup_gold["popup_gold (scene)"]
  popup_standing["popup_standing (scene)"]
  hall_main --> hall_header
  hall_main --> hall_nav
  hall_main --> hall_toast
  hall_header --> popup_gold
  hall_header --> popup_standing
```

### Board and Guild tabs
```mermaid
flowchart TD
  chip["chip (scene)"]
  hall_main["hall_main (scene)"]
  hire_card["hire_card (scene)"]
  hire_peek["hire_peek (scene)"]
  home_heading["home_heading (scene)"]
  member_card["member_card (scene)"]
  portrait["portrait (scene)"]
  quest_row["quest_row (scene)"]
  seal_button["seal_button (scene)"]
  stat_strip["stat_strip (scene)"]
  tab_board["tab_board (scene)"]
  tab_guild["tab_guild (scene)"]
  today_item["today_item (scene)"]
  hall_main --> tab_board
  hall_main --> tab_guild
  tab_board --> today_item
  tab_board -.-> quest_row
  quest_row --> chip
  quest_row -.-> portrait
  tab_guild -.-> hire_card
  hire_card --> portrait
  hire_card --> seal_button
  tab_guild -.-> hire_peek
  tab_guild -.-> home_heading
  tab_guild -.-> member_card
  member_card --> chip
  member_card --> portrait
  member_card --> stat_strip
  stat_strip --> chip
```

### Items and Upgrades tabs
```mermaid
flowchart TD
  chip["chip (scene)"]
  equip_pick_row["equip_pick_row (scene)"]
  gear_row["gear_row (scene)"]
  hall_main["hall_main (scene)"]
  home_heading["home_heading (scene)"]
  home_row["home_row (scene)"]
  home_section["home_section (scene)"]
  overlay_equip_picker["overlay_equip_picker (scene)"]
  overlay_gear_confirm["overlay_gear_confirm (scene)"]
  pack_tile["pack_tile (scene)"]
  portrait["portrait (scene)"]
  rolled_tag["rolled_tag (scene)"]
  shop_tile["shop_tile (scene)"]
  tab_items["tab_items (scene)"]
  tab_pack["tab_pack (scene)"]
  tab_shop["tab_shop (scene)"]
  tab_upgrades["tab_upgrades (scene)"]
  upgrade_card["upgrade_card (scene)"]
  hall_main --> tab_items
  hall_main --> tab_upgrades
  tab_items --> tab_pack
  tab_pack --> overlay_equip_picker
  overlay_equip_picker -.-> equip_pick_row
  equip_pick_row --> portrait
  tab_pack --> overlay_gear_confirm
  overlay_gear_confirm --> portrait
  overlay_gear_confirm -.-> gear_row
  tab_pack --> portrait
  tab_pack -.-> pack_tile
  pack_tile --> portrait
  tab_items --> tab_shop
  tab_shop -.-> shop_tile
  tab_upgrades --> home_section
  home_section -.-> home_heading
  home_section -.-> home_row
  home_row --> chip
  home_row --> portrait
  tab_upgrades -.-> rolled_tag
  tab_upgrades -.-> upgrade_card
```

### Screens
```mermaid
flowchart TD
  chip["chip (scene)"]
  divider["divider (scene)"]
  gear_row["gear_row (scene)"]
  hall_main["hall_main (scene)"]
  odds_bar["odds_bar (scene)"]
  overlay_move_confirm["overlay_move_confirm (scene)"]
  party_slot["party_slot (scene)"]
  pick_row["pick_row (scene)"]
  portrait["portrait (scene)"]
  quest_tab["quest_tab (scene)"]
  screen_assign["screen_assign (scene)"]
  screen_character["screen_character (scene)"]
  stat_strip["stat_strip (scene)"]
  hall_main --> screen_assign
  hall_main --> screen_character
  screen_assign --> chip
  screen_assign --> divider
  screen_assign --> odds_bar
  screen_assign --> overlay_move_confirm
  screen_assign -.-> party_slot
  party_slot --> chip
  party_slot --> portrait
  screen_assign -.-> pick_row
  pick_row --> portrait
  pick_row --> stat_strip
  stat_strip --> chip
  screen_assign -.-> quest_tab
  screen_character --> chip
  screen_character --> portrait
  screen_character -.-> gear_row
```

### Day overlays
```mermaid
flowchart TD
  beat_row["beat_row (scene)"]
  chip["chip (scene)"]
  crawl_sections["crawl_sections (scene)"]
  divider["divider (scene)"]
  hall_main["hall_main (scene)"]
  overlay_boss_crawl["overlay_boss_crawl (scene)"]
  overlay_end_day["overlay_end_day (scene)"]
  overlay_intro["overlay_intro (scene)"]
  overlay_quest_travel["overlay_quest_travel (scene)"]
  overlay_report["overlay_report (scene)"]
  overlay_welcome["overlay_welcome (scene)"]
  plan_row["plan_row (scene)"]
  report_entry["report_entry (scene)"]
  suggest_row["suggest_row (scene)"]
  hall_main --> overlay_end_day
  hall_main --> overlay_report
  hall_main --> overlay_boss_crawl
  hall_main --> overlay_quest_travel
  hall_main --> overlay_intro
  hall_main --> overlay_welcome
  overlay_end_day -.-> plan_row
  overlay_end_day -.-> suggest_row
  overlay_report --> chip
  overlay_report -.-> report_entry
  report_entry --> divider
  report_entry -.-> beat_row
  report_entry -.-> chip
  overlay_boss_crawl --> crawl_sections
```

### Run End and Menu overlays
```mermaid
flowchart TD
  crawl_sections["crawl_sections (scene)"]
  divider["divider (scene)"]
  hall_main["hall_main (scene)"]
  overlay_accessibility["overlay_accessibility (scene)"]
  overlay_backup["overlay_backup (scene)"]
  overlay_credits["overlay_credits (scene)"]
  overlay_debug["overlay_debug (scene)"]
  overlay_game_over["overlay_game_over (scene)"]
  overlay_menu["overlay_menu (scene)"]
  overlay_update_confirm["overlay_update_confirm (scene)"]
  roll_call_row["roll_call_row (scene)"]
  stat_tile["stat_tile (scene)"]
  hall_main --> overlay_credits
  hall_main --> overlay_game_over
  hall_main --> overlay_menu
  hall_main --> overlay_accessibility
  hall_main --> overlay_backup
  hall_main --> overlay_debug
  overlay_credits --> crawl_sections
  overlay_credits --> divider
  overlay_credits --> stat_tile
  overlay_credits -.-> roll_call_row
  overlay_game_over --> divider
  overlay_game_over --> stat_tile
  overlay_game_over -.-> roll_call_row
  overlay_debug --> overlay_update_confirm
```

### Playtest run scenes
Top-level run scenes under `Scenes/Playtest/` with no parent. Each places the hall as a child.
```mermaid
flowchart TD
  agent_bridge["agent_bridge (scene)"]
  scenario_final_battle["scenario_final_battle (scene)"]
  scenario_game_over["scenario_game_over (scene)"]
  scenario_low_standing["scenario_low_standing (scene)"]
  scenario_milestone_day["scenario_milestone_day (scene)"]
  hall_main["hall_main (scene)"]
  agent_bridge --> hall_main
  scenario_final_battle --> hall_main
  scenario_game_over --> hall_main
  scenario_low_standing --> hall_main
  scenario_milestone_day --> hall_main
```


## Scripts by folder
- **Globals**: [[character_container]], [[external_content_container]], [[game_state]], [[guild_upgrades]], [[item_container]], [[item_shop]], [[multicolumn_procedural_loader]], [[procedural_content_loader]], [[sound_effects]]
- **Scripts/Character Generator**: [[character_resource]]
- **Scripts/Credits**: [[credit_entry]], [[credits_list]]
- **Scripts/Hall**: [[hall_main]]
- **Scripts/Hall/Debug**: [[hall_debug]], [[run_logger]]
- **Scripts/Hall/Rules**: [[hall_gear]], [[hall_ledger]], [[hall_rules]], [[hall_wallet]], [[hire_scaling]]
- **Scripts/Hall/Save**: [[hall_save]], [[hall_save_transfer]], [[hall_settings]], [[hall_web_files]]
- **Scripts/Hall/Style**: [[hall_font_scale]], [[hall_fx]], [[hall_style]]
- **Scripts/Hall/Web**: [[hall_build_info]], [[hall_web_update]]
- **Scripts/Item System**: [[active_items]], [[passive_item]], [[standard_item]]
- **Scripts/Playtest**: [[agent_bridge]], [[agent_bridge_actions]], [[agent_bridge_eyes]], [[agent_bridge_state]], [[playtest_scenario]]
- **Scripts/Quest Creator**: [[quest_Manager]], [[quest_injuries]], [[quest_resource]], [[quest_scoring]], [[region_resource]]
- **Scripts/UI/Components**: [[chip]], [[crawl_roll]], [[crawl_sections]], [[drag_scroll]], [[odds_bar]], [[pixel_icon]], [[portrait]], [[stat_strip]], [[stat_tile]], [[tap_panel]]
- **Scripts/UI/Overlays/Day**: [[overlay_boss_crawl]], [[overlay_end_day]], [[overlay_intro]], [[overlay_move_confirm]], [[overlay_quest_travel]], [[overlay_report]], [[overlay_tutorial]], [[overlay_welcome]]
- **Scripts/UI/Overlays/Items**: [[overlay_equip_picker]], [[overlay_gear_confirm]]
- **Scripts/UI/Overlays/Menu**: [[overlay_accessibility]], [[overlay_backup]], [[overlay_debug]], [[overlay_menu]], [[overlay_update_confirm]]
- **Scripts/UI/Overlays/Run End**: [[overlay_credits]], [[overlay_game_over]]
- **Scripts/UI/Rows/Buildings**: [[home_row]], [[home_section]], [[upgrade_card]]
- **Scripts/UI/Rows/Day End**: [[beat_row]], [[plan_row]], [[report_entry]], [[roll_call_row]], [[suggest_row]]
- **Scripts/UI/Rows/Heroes**: [[hire_card]], [[member_card]]
- **Scripts/UI/Rows/Items**: [[equip_pick_row]], [[gear_row]], [[pack_tile]], [[shop_tile]]
- **Scripts/UI/Rows/Quests**: [[party_slot]], [[pick_row]], [[quest_row]], [[quest_tab]], [[today_item]]
- **Scripts/UI/Screens**: [[screen_assign]], [[screen_character]]
- **Scripts/UI/Shell**: [[hall_nav]], [[hall_toast]]
- **Scripts/UI/Shell/Header**: [[hall_header]], [[header_popup]], [[popup_gold]], [[popup_standing]]
- **Scripts/UI/Tabs**: [[tab_board]], [[tab_guild]], [[tab_items]], [[tab_pack]], [[tab_shop]], [[tab_upgrades]]


## Scenes by folder
- **Scenes**: [[hall_main (scene)]]
- **Scenes/Components**: [[chip (scene)]], [[crawl_sections (scene)]], [[divider (scene)]], [[odds_bar (scene)]], [[portrait (scene)]], [[rolled_tag (scene)]], [[seal_button (scene)]], [[stat_strip (scene)]], [[stat_tile (scene)]]
- **Scenes/Overlays/Day**: [[overlay_boss_crawl (scene)]], [[overlay_end_day (scene)]], [[overlay_intro (scene)]], [[overlay_move_confirm (scene)]], [[overlay_quest_travel (scene)]], [[overlay_report (scene)]], [[overlay_welcome (scene)]]
- **Scenes/Overlays/Items**: [[overlay_equip_picker (scene)]], [[overlay_gear_confirm (scene)]]
- **Scenes/Overlays/Menu**: [[overlay_accessibility (scene)]], [[overlay_backup (scene)]], [[overlay_debug (scene)]], [[overlay_menu (scene)]], [[overlay_update_confirm (scene)]]
- **Scenes/Overlays/Run End**: [[overlay_credits (scene)]], [[overlay_game_over (scene)]]
- **Scenes/Playtest**: [[agent_bridge (scene)]], [[scenario_final_battle (scene)]], [[scenario_game_over (scene)]], [[scenario_low_standing (scene)]], [[scenario_milestone_day (scene)]]
- **Scenes/Rows/Buildings**: [[home_heading (scene)]], [[home_row (scene)]], [[home_section (scene)]], [[upgrade_card (scene)]]
- **Scenes/Rows/Day End**: [[beat_row (scene)]], [[plan_row (scene)]], [[report_entry (scene)]], [[roll_call_row (scene)]], [[suggest_row (scene)]]
- **Scenes/Rows/Heroes**: [[hire_card (scene)]], [[hire_peek (scene)]], [[member_card (scene)]]
- **Scenes/Rows/Items**: [[equip_pick_row (scene)]], [[gear_row (scene)]], [[pack_tile (scene)]], [[shop_tile (scene)]]
- **Scenes/Rows/Quests**: [[party_slot (scene)]], [[pick_row (scene)]], [[quest_row (scene)]], [[quest_tab (scene)]], [[today_item (scene)]]
- **Scenes/Screens**: [[screen_assign (scene)]], [[screen_character (scene)]]
- **Scenes/Shell**: [[hall_nav (scene)]], [[hall_toast (scene)]]
- **Scenes/Shell/Header**: [[hall_header (scene)]], [[popup_gold (scene)]], [[popup_standing (scene)]]
- **Scenes/Tabs**: [[tab_board (scene)]], [[tab_guild (scene)]], [[tab_items (scene)]], [[tab_pack (scene)]], [[tab_shop (scene)]], [[tab_upgrades (scene)]]


## Tests
`tools/tests/*_test.tscn` (run with `bash tools/tests/run_test.sh <name>`). Listed here only, not documented.
