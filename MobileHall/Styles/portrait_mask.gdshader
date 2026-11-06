// Portrait mask: clips a node to the alpha of a mask texture (the round or
// oval portrait mask), drawn over a rect given in the node's own pixels.
// Replaces clip_children, which renders wrong on iPhone Safari (WebGL on the
// Compatibility renderer): portraits spilled out of their frames.
// Used by portrait.gd (the hero art) and overlay_tutorial.gd (Pip's face),
// which set mask_origin/mask_size whenever the node is resized.
shader_type canvas_item;

// The mask art; only its alpha is used.
uniform sampler2D mask_tex : filter_linear;
// Top-left of the mask's rect, in the masked node's local pixels.
uniform vec2 mask_origin = vec2(0.0);
// Size of the mask's rect, in pixels.
uniform vec2 mask_size = vec2(1.0);

varying vec2 local_position;

void vertex() {
	// VERTEX is still in the node's local space here, so this works for
	// TextureRects (any stretch mode) and for shapes drawn in _draw() alike.
	local_position = VERTEX;
}

void fragment() {
	// COLOR already holds the texture times the node's modulate
	vec4 color = COLOR;
	vec2 mask_uv = (local_position - mask_origin) / mask_size;
	// nothing shows outside the mask's rect
	float inside = step(0.0, mask_uv.x) * step(mask_uv.x, 1.0) * step(0.0, mask_uv.y) * step(mask_uv.y, 1.0);
	color.a *= texture(mask_tex, clamp(mask_uv, 0.0, 1.0)).a * inside;
	COLOR = color;
}
