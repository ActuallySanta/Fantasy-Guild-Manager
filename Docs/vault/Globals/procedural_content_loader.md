---
source: Globals/procedural_content_loader.gd
class_name: ProceduralContentLoader
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# procedural_content_loader.gd

## Purpose
`ProceduralContentLoader`: a static helper that reads a CSV file into one flat list of strings. `ExternalContentContainer` uses it for the name and backstory files. Not an autoload and has no scene. No doc comments in the file.

## State
None.

## Functions

### _load_info_from_file
`static func _load_info_from_file(_file_path: String, _columns) -> Array[String]` · `Globals/procedural_content_loader.gd:5`

Reads the file with `get_csv_line()`, skips blank lines and appends every cell of each row (the comment says each row should hold a single entry). If the file can't open it prints the error and returns an empty array.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_file_path` | `String` | `res://` path | exported path variables in [[external_content_container#_ready]] |
| `_columns` | untyped | Unused (callers pass 1) | literal `1` |

**Returns:** `Array[String]`. Used as `male_character_names`, `female_character_names`, `andro_character_names` and the backstory arrays.

**Called by:** [[external_content_container#_ready]] (`external_content_container.gd:103-105`, `:107`, `:109-112`).

## Suspected issues
- `_columns` is never used (`procedural_content_loader.gd:5`). A trailing `pass` follows the `return` (line 28).
- Row 0 of each CSV is not skipped, so a header row, if the files have one, would be loaded as data (not checked against the files).
