shader_type canvas_item;
// Pulsing rim glow used on playable cards and killer moves.
uniform vec4 tint : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float strength = 0.6;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float e = max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * 2.0;
	float rim = smoothstep(0.78, 1.0, e) * (0.6 + 0.4 * sin(TIME * 4.0));
	COLOR = vec4(mix(c.rgb, tint.rgb, rim * strength), c.a);
}
