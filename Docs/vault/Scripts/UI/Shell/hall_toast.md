---
source: Scripts/UI/Shell/hall_toast.gd
class_name: HallToast
extends: PanelContainer
scene: "[[hall_toast (scene)]]"
systems: ["[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_toast.gd

## Purpose
A short message just above the nav that fades out. It starts hidden; [[hall_main#show_toast]] puts messages up. Unlike other views it has no `setup` or `refresh`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SHOW_SECONDS` | const | Seconds a toast stays fully visible (2.2). |
| `FADE_SECONDS` | const | Seconds the fade-out takes (0.4). |
| `_tween` | var | The fade of the toast showing now; killed when a new toast replaces it. |
| `_label` | var | `%ToastLabel`. |

## Functions

### show_message
`func show_message(message: String) -> void` · `Scripts/UI/Shell/hall_toast.gd:29`

Shows `message`, replacing any toast already up, then fades it out.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `message` | `String` | Text to show | the `message` argument of [[hall_main#show_toast]] (`hall_main.gd:1877`), which overlays, [[hall_web_update]] and the playtest scenario call |

**Returns:** nothing.

**Side effects:** sets the label text, makes the toast visible at full alpha, runs [[hall_fx#appear]], kills any running tween, then tweens an interval of `SHOW_SECONDS`, a fade of `modulate:a` to 0 over `FADE_SECONDS`, and finally `hide`.

**Called by:** [[hall_main#show_toast]] (`hall_main.gd:1877`).

**Calls:** [[hall_fx#appear]].

## Suspected issues
- None found.
