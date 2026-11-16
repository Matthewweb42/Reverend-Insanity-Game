shader_type canvas_item;
// Procedural ink-wash backdrop: layered drifting fbm "mist", faint distant mountain ridges and a vignette.
uniform vec4 paper : source_color = vec4(0.11, 0.09, 0.075, 1.0);
uniform vec4 ink : source_color = vec4(0.02, 0.018, 0.015, 1.0);
uniform vec4 glow : source_color = vec4(0.55, 0.42, 0.22, 1.0);
uniform float mountains = 1.0;
uniform float speed = 0.015;
uniform float glow_amount = 0.12;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	vec2 q = vec2(fbm(uv * 3.0 + t), fbm(uv * 3.0 - t + 4.7));
	float mist = fbm(uv * 2.2 + q * 1.6 + vec2(t * 2.0, 0.0));
	vec3 col = mix(ink.rgb, paper.rgb, smoothstep(0.15, 0.95, mist));
	// distant ridges, drawn as soft dark bands near the bottom
	if (mountains > 0.0) {
		for (int k = 0; k < 3; k++) {
			float fk = float(k);
			float h = 0.62 + fk * 0.11 + 0.08 * fbm(vec2(uv.x * (2.0 + fk) + fk * 3.1, fk));
			float ridge = smoothstep(h, h + 0.015, uv.y);
			col = mix(col, ink.rgb * (1.2 - fk * 0.25) + paper.rgb * (0.15 + fk * 0.08), ridge * (0.45 + fk * 0.12) * mountains);
		}
	}
	// warm lantern glow from the top and a vignette
	col += glow.rgb * glow_amount * smoothstep(0.9, 0.0, distance(uv, vec2(0.5, 0.15)));
	float vig = smoothstep(1.05, 0.35, distance(uv, vec2(0.5)));
	col *= mix(0.55, 1.0, vig);
	// paper grain
	col += (hash(uv * 900.0 + floor(TIME * 2.0)) - 0.5) * 0.018;
	COLOR = vec4(col, 1.0);
}
