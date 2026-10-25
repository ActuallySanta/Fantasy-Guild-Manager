// Colorblind filter for the Mobile Hall: a full-screen "daltonize" pass.
// It works out what a player with the chosen colour-vision deficiency would
// lose, and moves that lost difference into colours they can still tell
// apart (Fidaner, Lin & Ozguven's daltonization, LMS matrices from Viénot et al.).
// Drawn by the ColorFilter rect in hall_main.tscn; hall_main.gd sets `mode`.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// 0 = off, 1 = protanopia (red-weak), 2 = deuteranopia (green-weak), 3 = tritanopia (blue-yellow)
uniform int mode = 0;
// 0 = no change, 1 = full correction
uniform float strength : hint_range(0.0, 1.0) = 1.0;

vec3 rgb_to_lms(vec3 c) {
	return vec3(
		17.8824 * c.r + 43.5161 * c.g + 4.11935 * c.b,
		3.45565 * c.r + 27.1554 * c.g + 3.86714 * c.b,
		0.0299566 * c.r + 0.184309 * c.g + 1.46709 * c.b);
}

vec3 lms_to_rgb(vec3 lms) {
	return vec3(
		0.0809444479 * lms.x - 0.130504409 * lms.y + 0.116721066 * lms.z,
		-0.0102485335 * lms.x + 0.0540193266 * lms.y - 0.113614708 * lms.z,
		-0.000365296938 * lms.x - 0.00412161469 * lms.y + 0.693511405 * lms.z);
}

// What the colour looks like with the deficiency.
vec3 simulate(vec3 c) {
	vec3 lms = rgb_to_lms(c);
	if (mode == 1) {
		lms.x = 2.02344 * lms.y - 2.52581 * lms.z;
	} else if (mode == 2) {
		lms.y = 0.494207 * lms.x + 1.24827 * lms.z;
	} else if (mode == 3) {
		lms.z = -0.395913 * lms.x + 0.801109 * lms.y;
	}
	return lms_to_rgb(lms);
}

void fragment() {
	vec3 original = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 lost = original - simulate(original);
	// shift the lost difference into channels the player can still see:
	// red-green loss goes into blue, blue-yellow loss goes into red and green
	vec3 shift;
	if (mode == 3) {
		shift = vec3(lost.r + 0.7 * lost.b, lost.g + 0.7 * lost.b, 0.0);
	} else {
		shift = vec3(0.0, 0.7 * lost.r + lost.g, 0.7 * lost.r + lost.b);
	}
	vec3 corrected = clamp(original + shift, 0.0, 1.0);
	COLOR = vec4(mix(original, corrected, strength), 1.0);
}
