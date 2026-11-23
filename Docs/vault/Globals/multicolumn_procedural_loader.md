---
source: Globals/multicolumn_procedural_loader.gd
class_name: MultiColumnLoader
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# multicolumn_procedural_loader.gd

## Purpose
`MultiColumnLoader`: static helpers that read pipe-delimited (`|`) text files, either one column from every line or one whole line split into columns. Not an autoload and has no scene. `ExternalContentContainer` uses it for monsters, locations and quest stories, and `Region` uses it for location and monster lists. No doc comments in the file.

## State
None.

## Functions

### _load_info_from_file
`static func _load_info_from_file(_file_path: String, _columns, col_idx) -> Array[String]` · `Globals/multicolumn_procedural_loader.gd:5`

Reads the file line by line, skips empty lines, splits each on `|` and collects column `col_idx` (when the line has that many columns). If the file can't open, it prints the error and returns an empty array.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_file_path` | `String` | `res://` path | exported path variables in [[external_content_container#_ready]] |
| `_columns` | untyped | Unused (callers pass 1) | literal `1` |
| `col_idx` | untyped | Column to read (0-based) | loop index or literal in the caller |

**Returns:** `Array[String]`, one value per line. Used to build the per-column lists (`monster_test_names`, `location_names`).

**Called by:** [[external_content_container#_ready]] (`external_content_container.gd:114-116`, `:130`), [[quest_Manager#_ready]] (`quest_Manager.gd:24-25`, function not confirmed), [[region_resource#_init]] (`region_resource.gd:48-76`).

### _load_info_from_rows
`static func _load_info_from_rows(_file_path: String, row_idx) -> Array[String]` · `Globals/multicolumn_procedural_loader.gd:31`

Reads the whole file, splits it on newlines and returns line `row_idx` split on `|`. Returns `[]` for an out-of-range row or a blank row. If the file can't open it prints the error and returns an empty array.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_file_path` | `String` | `res://` path | exported path variables in [[external_content_container#_ready]] |
| `row_idx` | untyped | Line number (0-based) | loop index (`range(16)`, `range(7)`, `range(22)`) |

**Returns:** `Array[String]`, the columns of that row. These rows become `quest_story`, `milestone_story`, `minor_story` and `minor_vars`, which the `get_*_Story` functions read.

**Called by:** [[external_content_container#_ready]] (`external_content_container.gd:119`, `:123`, `:127`, `:133`).

## Suspected issues
- `_load_info_from_file` ignores its `_columns` parameter, and both functions end with an unreachable `pass` (`:29`, `:57`).
- `_load_info_from_rows` re-reads the whole file for every row (called 16+7+22+22 times), which is slow-ish but only at startup.
