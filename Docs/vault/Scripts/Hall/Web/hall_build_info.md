---
source: Scripts/Hall/Web/hall_build_info.gd
class_name: HallBuildInfo
extends: RefCounted
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_build_info.gd

## Purpose
`HallBuildInfo`: which build is running, for the Menu's footer line. The deploy workflow (`.github/workflows/deploy-web.yml`, "Stamp the build") writes `BUILD_INFO_PATH` with the commit and time (e.g. `ab12cd3 · 2026-11-04 20:55 UTC`). The file is gitignored, so editor and local runs show "Build dev". [[hall_web_update]] fetches the same file from the live site to see if a newer deploy exists.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUILD_INFO_PATH` | const | `"res://External Content/build_info.txt"`, written by the deploy workflow; on a `res://` path because text data has no UID (shipped by the export presets). |
| `LATEST_WEB_FILE` | const | `"build_info.txt"`, the same stamp on the live site next to `index.html`, relative to the page URL. |
| `LABEL` | const | `"Build %s"`, shown in front of the stamp. |
| `DEV_BUILD` | const | `"dev"`, used when there's no stamp file. |

## Functions

### label
`static func label() -> String` · `Scripts/Hall/Web/hall_build_info.gd:28`

The Menu's build line, e.g. `Build ab12cd3 · 2026-11-04 20:55 UTC`; `Build dev` with no stamp.

**Returns:** `String`, set as `_build_label.text` in [[overlay_menu#setup]].

**Side effects:** none.

**Called by:** [[overlay_menu#setup]] (`overlay_menu.gd:58`).

**Calls:** [[hall_build_info#stamp]].

### stamp
`static func stamp() -> String` · `Scripts/Hall/Web/hall_build_info.gd:33`

Just the stamp text from `BUILD_INFO_PATH` (first line, trimmed), or `DEV_BUILD` if the file is missing or empty.

**Returns:** `String`. [[hall_web_update#_on_check_completed]] compares it with the live stamp; [[overlay_debug#_on_update_checked]] passes it as the "current build" to the update popup.

**Side effects:** reads a file.

**Called by:** [[hall_build_info#label]] (`hall_build_info.gd:29`), [[hall_web_update#_on_check_completed]] (`hall_web_update.gd:110`), [[overlay_debug#_on_update_checked]] (`overlay_debug.gd:186`).

**Calls:** [[hall_build_info#parse_stamp]].

### parse_stamp
`static func parse_stamp(text: String) -> String` · `Scripts/Hall/Web/hall_build_info.gd:43`

The stamp in a `build_info.txt`'s text: its first line, trimmed (`""` if empty). Used for both the bundled and the fetched stamp so they compare the same way.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Whole file text | `FileAccess.get_file_as_string` in `stamp`; the HTTP body in [[hall_web_update#_on_check_completed]] |

**Returns:** `String`.

**Side effects:** none.

**Called by:** [[hall_build_info#stamp]] (`hall_build_info.gd:36`), [[hall_web_update#_on_check_completed]] (`hall_web_update.gd:107`).

**Calls:** nothing.

## Suspected issues
- None found.
