shader_type canvas_item;

// Paints the black UI Icons SVGs in any colour (modulate can't lighten black).
uniform vec4 tint : source_color;

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);
}
