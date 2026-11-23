---
systems_scripts: ["[[hall_main]]", "[[screen_assign]]", "[[pick_row]]", "[[party_slot]]", "[[quest_row]]", "[[quest_tab]]", "[[tab_board]]", "[[overlay_move_confirm]]", "[[overlay_end_day]]", "[[quest_scoring]]", "[[quest_resource]]", "[[hall_rules]]", "[[guild_upgrades]]"]
scenes: ["[[screen_assign (scene)]]", "[[pick_row (scene)]]", "[[party_slot (scene)]]", "[[quest_row (scene)]]", "[[quest_tab (scene)]]", "[[tab_board (scene)]]", "[[overlay_move_confirm (scene)]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [system]
---

# Party Drafting and Assignment

## Purpose
How the player picks who goes on which quest. Each of today's quests is an entry in `hall.quest_entries` with a `party` and a `state` (open, sent, denied). The Assign Party screen shows one quest at a time: tap an adventurer in the picker to pin them to the party (pinning anyone sends an open quest), tap a filled seat to take them out, or Deny / Recall the quest. A quest takes between one and three heroes, set by the quest's `maxAdventurers`.

## Entry points
- Tap a quest row on the Board: `pressed` on the row (`quest_row.gd:65`, bound to its index) calls [[hall_main#open_assign]]. The quest strip tab does the same (`quest_tab.gd:27`).
- Tap End Day with a quest undecided: [[hall_main#open_end_check]] opens the first undecided quest with [[hall_main#open_assign]].
- Tap an adventurer in the picker: `pressed` on the row ([[pick_row#setup]], `pick_row.gd:58`) calls [[hall_main#toggle_in_party]], or [[overlay_move_confirm#open]] first when the hero is on another quest.
- Tap a filled seat: [[party_slot#setup]] connects `pressed` to [[hall_main#toggle_in_party]].
- Footer buttons: [[screen_assign#_on_left_button_pressed]] (Recall, Deny or Quests) and [[screen_assign#_on_right_button_pressed]] (Reconsider or Back).

## Flow
### 1. Pinning a hero
```mermaid
sequenceDiagram
  participant SA as screen_assign
  participant PR as pick_row
  participant HM as hall_main
  participant QS as QuestScoring
  SA->>HM: "party_size_limit(entry)"
  HM->>QS: "get_slot_count(entry.quest)"
  QS-->>HM: "int slots"
  HM-->>SA: "int seats to draw"
  PR->>HM: "toggle_in_party(character)"
  HM->>HM: "current_quest_entry()"
  HM->>HM: "party_size_limit(entry)"
  HM->>HM: "_remove_from_party(other entry, character) if moved"
  HM->>HM: "entry.party.append(character), state SENT"
  HM->>HM: "queue_refresh()"
  HM-->>SA: "refresh() redraws seats and odds"
```

### 2. Deny, recall, move on
```mermaid
flowchart TD
  A["Assign Party shows quest N"] --> B{"entry.state"}
  B -- "open" --> C["Deny: deny_quest()"]
  B -- "sent" --> D["Recall: recall_party()"]
  B -- "denied" --> E["Reconsider: reconsider_quest()"]
  C --> F["stamp hold, then _go_to_next_undecided()"]
  D --> A
  E --> A
  F --> G{"undecided quest left?"}
  G -- yes --> A
  G -- no --> H["close to the Board"]
```

## Steps
| # | When | Function | Takes (from) | Returns (to) | Side effects |
|---|---|---|---|---|---|
| 1 | Day starts | [[hall_main#_generate_quests]] | `GameState.day`, standing, `is_freeplay` | nothing; `quest_entries` → steps 2, 4 | Replaces every entry (see [[Day Cycle]]) |
| 2 | Board or Assign Party draws | [[hall_main#party_size_limit]] | `entry` (from `quest_entries`; [[hall_main#current_quest_entry]] or the row's own entry) | `int` slots → step 3 (limit check) and the number of seats in [[screen_assign#_show_party]] | none |
| 2b | In step 2 | [[quest_scoring#get_slot_count]] | `entry.quest` | `int`: `maxAdventurers`, or `DEFAULT_PARTY_SIZE` (2) when not above 0 → step 2 | none. `maxAdventurers` is set in [[quest_resource#_init]] (1-2 up to day 5, then 1-3; scripted and boss quests set their own) |
| 3 | Player taps a hero (picker or seat) | [[hall_main#toggle_in_party]] | `character` from [[pick_row#setup]], [[party_slot#setup]], or [[overlay_move_confirm]] after confirming | nothing; edited `entry.party` and `entry.state` → steps 5, 6 | Refuses dead, patient, training heroes and a full party (error toast); a solo quest replaces its hero; a hero in another party is moved ([[hall_main#_remove_from_party]]); an `OPEN` quest becomes `SENT`; sets `pending_fx`, plays sound |
| 3b | In step 3 | [[hall_main#_remove_from_party]] | `entry`, `character` from step 3 | nothing | Removes the hero; a `SENT` quest left empty goes back to `OPEN` |
| 4 | Picker draws | [[hall_main#can_go_on_quests]] and [[screen_assign#_pick_group]] | `character` from [[hall_main#roster]] | `bool` / group `int` → picker order in [[screen_assign#_show_picker]] | none |
| 5 | After any change | [[hall_main#queue_refresh]] then [[hall_main#refresh]] | called by step 3 | nothing | Redraws [[screen_assign#refresh]], row strips, header; autosave |
| 6 | Seats and odds draw | [[screen_assign#_show_party]] | `entry.party` from step 3 | nothing | One [[party_slot#setup]] per seat; odds from [[hall_main#success_chance]] (see [[Success Chance]]) |
| 7 | Player taps Deny | [[hall_main#deny_quest]] | nothing (current entry) | nothing; `entry.state = DENIED` → step 8 | Costs standing ([[hall_rules#standing_for_deny]]), clears the party, stamps DENIED; refused on the final battle |
| 8 | After the stamp hold | [[hall_main#_hold_then_move_on]] → [[hall_main#_after_stamp]] → [[hall_main#_go_to_next_undecided]] | `decided_index` from step 7 | nothing | Shows the next undecided quest ([[hall_main#next_undecided_index]]) or the Board |
| 9 | Player taps Recall | [[hall_main#recall_party]] | nothing (current entry) | nothing | Clears the party, state `OPEN` |
| 10 | Player taps Reconsider | [[hall_main#reconsider_quest]] | nothing | nothing | State `OPEN` (the standing lost isn't returned) |
| 11 | Player taps End Day | [[hall_main#undecided_count]] in [[hall_main#end_day]] | states of `quest_entries` | `int`; any undecided blocks [[hall_main#end_day]] and [[hall_main#open_end_check]] opens that quest | Parties of `SENT` entries are what the night plays ([[hall_main#sent_entries]]) |

## Branches
```mermaid
flowchart TD
  A{"hero already in this party?"} -- yes --> B["remove (stop)"]
  A -- no --> C{"dead, patient or training?"}
  C -- yes --> D["error toast, refused"]
  C -- no --> E{"limit > 1 and party full?"}
  E -- yes --> D
  E -- no --> F{"limit == 1?"}
  F -- yes --> G["clear party, hero replaces"]
  F -- no --> H["append"]
  G --> I{"hero in another quest's party?"}
  H --> I
  I -- yes --> J["remove from it, moved toast"]
  I -- no --> K["append, OPEN becomes SENT"]
  J --> K
```

## Tuning knobs
| Constant | Where | Effect |
|---|---|---|
| `DEFAULT_PARTY_SIZE` | [[quest_scoring]] | Slots when a quest doesn't set `maxAdventurers` |
| `maxAdventurers` rolls | [[quest_resource#_init]] | 1-2 up to day 5, then 1-3 |
| `HIDE_BUSY_OPTION` | [[screen_assign]] | `false`: busy adventurers are always listed (at the bottom) |
| `STAMP_HOLD_SECONDS` | [[hall_main]] | Pause after Deny before the next quest shows |

## Gotchas
- There is no Send button: pinning anyone sends an open quest ([[hall_main#_send_picked_drafts]] converts old saves that held a draft).
- A hero belongs to at most one party; pinning someone already on another quest moves them (the picker asks first through [[overlay_move_confirm]]).
- Dead, hospitalized and training heroes can't go ([[hall_main#can_go_on_quests]]); [[guild_upgrades#is_patient]] and [[guild_upgrades#is_training]] decide the last two.
- The final battle can't be denied.
- `quest_entries` is replaced when the day starts, so an open Assign Party screen whose quest vanished closes itself ([[hall_main#_refresh_content]]).
