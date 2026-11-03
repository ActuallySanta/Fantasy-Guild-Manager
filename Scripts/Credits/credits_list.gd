## The team credits shown at the end of the final battle's credits roll
## (overlay_credits.gd), for both the victory and the defeat versions.
## Data: MobileHall/Data/credits.tres
##
## HOW TO ADD YOUR CREDITS (no code needed):
##   1. In the FileSystem dock, double-click MobileHall/Data/credits.tres.
##   2. In the Inspector, expand Entries and click "Add Element".
##   3. Click the new empty slot and choose "New CreditEntry".
##   4. Expand it and fill in Section, Name and Contribution.
##   5. Drag elements up and down to reorder them. Sections appear in the
##      order their first entry appears; entries in the same section are
##      grouped under one heading.
##   6. Save (Ctrl+S). Run the game and win (or lose) the final battle to see it,
##      or run MobileHall/Playtest/scenario_final_battle.tscn.
class_name CreditsList
extends Resource

## Every credited person, in on-screen order (see the steps above).
@export var entries: Array[CreditEntry] = []


## The entries grouped by section, keeping the order each section first appears in.
## Returns an Array of {section: String, entries: Array[CreditEntry]}.
## Empty entries (no name) are skipped, so a half-filled slot never shows a blank line.
func sections() -> Array:
	var groups: Array = []
	var group_by_section := {}
	for entry in entries:
		if entry == null or entry.name.strip_edges().is_empty():
			continue
		if not group_by_section.has(entry.section):
			group_by_section[entry.section] = {"section": entry.section, "entries": []}
			groups.append(group_by_section[entry.section])
		group_by_section[entry.section].entries.append(entry)
	return groups
