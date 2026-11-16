## A small pixel-art image drawn `pixel_scale` times bigger with sharp pixels.
## Used by every icon in MobileHall/Art/Icons: the art is a 16 x 16 PNG (edit
## it in Aseprite), and the .tres beside it is one of these, which the scenes
## and HallStyle.ICON_FILES point at.
##
## Why: the project draws textures with smooth (linear) filtering, which
## would blur a 16 x 16 icon blown up to 30-44 px, and buttons draw their icon
## at the texture's own size, so a 16 px texture would also come out tiny.
## This texture reports the scaled-up size (16 x 6 = 96, what the icons used to
## be) and draws its source with nearest filtering, so nothing else changes.
##
## Tool script so the editor previews it too.
@tool
class_name PixelIcon
extends Texture2D

## The pixel art (a PNG at its real size, e.g. 16 x 16).
@export var source: Texture2D:
	set(value):
		if source and source.changed.is_connected(emit_changed):
			source.changed.disconnect(emit_changed)
		source = value
		# a re-import of the PNG redraws whatever shows it
		if source:
			source.changed.connect(emit_changed)
		_canvas.diffuse_texture = source
		emit_changed()

## How many screen pixels each art pixel becomes before the node using the
## texture sizes it (6 = a 16 x 16 icon acts like a 96 x 96 one).
@export_range(1, 16) var pixel_scale := 6:
	set(value):
		pixel_scale = value
		emit_changed()

## The source wrapped so it draws with sharp pixels, whatever filter the node
## drawing it uses.
var _canvas := CanvasTexture.new()


func _init() -> void:
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _get_width() -> int:
	return source.get_width() * pixel_scale if source else 0


func _get_height() -> int:
	return source.get_height() * pixel_scale if source else 0


func _has_alpha() -> bool:
	return source.has_alpha() if source else false


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	_canvas.draw_rect(to_canvas_item, Rect2(pos, get_size()), false, modulate, transpose)


func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	_canvas.draw_rect(to_canvas_item, rect, tile, modulate, transpose)


## `src_rect` is in this texture's (scaled-up) pixels, so it's scaled back
## down to the source's.
func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color,
		transpose: bool, clip_uv: bool) -> void:
	var source_rect := Rect2(src_rect.position / pixel_scale, src_rect.size / pixel_scale)
	_canvas.draw_rect_region(to_canvas_item, rect, source_rect, modulate, transpose, clip_uv)
