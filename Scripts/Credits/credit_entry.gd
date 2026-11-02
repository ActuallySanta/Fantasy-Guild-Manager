## One line of the team credits at the end of the story (overlay_credits.gd).
## Lives inside CreditsList.entries; edit it in the Godot inspector.
class_name CreditEntry
extends Resource

## The heading this person is listed under ("Programming", "Art", "Special Thanks").
## Entries with the same section are shown together under one heading.
@export var section: String = ""
## The person's (or group's) name as it should appear on screen.
@export var name: String = ""
## What they did. Shown under their name; leave empty for a name-only line.
@export_multiline var contribution: String = ""
