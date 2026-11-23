---
source: Scripts/UI/Components/pixel_icon.gd
class_name: PixelIcon
extends: Texture2D
scene: ""
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# pixel_icon.gd

## Purpose
A small pixel-art image drawn `pixel_scale` times bigger with sharp pixels. Used by every icon in `Sprites/Hall Icons/`: the art is a 16 x 16 PNG, and the `.tres` beside it (for example `flag.tres`) is one of these, which scenes and `HallStyle.ICON_FILES` point at. The project draws textures with smooth filtering, which would blur a 16 x 16 icon blown up to 30-44 px, and buttons draw their icon at the texture's own size, so a plain 16 px texture would come out tiny. This texture reports the scaled-up size (16 x 6 = 96) and draws its source with nearest filtering. It is a `@tool` script so the editor previews it. It is a resource script with no scene, and is used by 28 `.tres` files under `Sprites/Hall Icons/`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `source` | export var | The pixel art (a PNG at its real size). Its setter reconnects `changed` so a re-import redraws whatever shows it, updates `_canvas.diffuse_texture` and emits `changed`. |
| `pixel_scale` | export var | How many screen pixels each art pixel becomes (1 to 16, default 6; a 16 x 16 icon acts like 96 x 96). The setter emits `changed`. |
| `_canvas` | var | A `CanvasTexture` wrapping `source` with `TEXTURE_FILTER_NEAREST`, used to draw. |

## Functions

### _init
`func _init() -> void` · `Scripts/UI/Components/pixel_icon.gd:41`

Sets the wrapped canvas texture's filter to nearest. Called by the engine when the resource is created or loaded.

**Called by:** the engine.

### _get_width
`func _get_width() -> int` · `Scripts/UI/Components/pixel_icon.gd:45`

Source width times `pixel_scale`, or 0 with no source. Called by the engine (Texture2D virtual).

**Called by:** the engine.

### _get_height
`func _get_height() -> int` · `Scripts/UI/Components/pixel_icon.gd:49`

Source height times `pixel_scale`, or 0 with no source. Called by the engine (Texture2D virtual).

**Called by:** the engine.

### _has_alpha
`func _has_alpha() -> bool` · `Scripts/UI/Components/pixel_icon.gd:53`

Whether the source has alpha (false with no source). Called by the engine.

**Called by:** the engine.

### _draw
`func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void` · `Scripts/UI/Components/pixel_icon.gd:57`

Draws the icon at its scaled-up size through the nearest-filtered canvas texture. Called by the engine when a node draws this texture.

**Called by:** the engine.

### _draw_rect
`func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void` · `Scripts/UI/Components/pixel_icon.gd:61`

Draws the icon stretched into `rect`. Called by the engine.

**Called by:** the engine.

### _draw_rect_region
`func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void` · `Scripts/UI/Components/pixel_icon.gd:67`

`src_rect` is in this texture's scaled-up pixels, so it is divided by `pixel_scale` back to the source's before drawing. Called by the engine.

**Called by:** the engine.

## Suspected issues
- None found.
