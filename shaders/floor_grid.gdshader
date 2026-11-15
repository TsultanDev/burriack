shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.035, 0.045, 0.07, 1.0);
uniform vec4 line_color : source_color = vec4(0.16, 0.75, 0.85, 1.0);
uniform float cell_size = 2.0;
uniform float line_width = 0.045;
uniform float glow : hint_range(0.0, 4.0) = 0.7;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_position.xz / cell_size;
	vec2 grid = abs(fract(coord - 0.5) - 0.5);
	vec2 aa = fwidth(coord) * 1.5;
	vec2 lines = smoothstep(vec2(line_width) - aa, vec2(line_width) + aa, grid);
	float mask = 1.0 - (lines.x * lines.y);
	vec3 color = mix(base_color.rgb, line_color.rgb, mask);
	ALBEDO = color;
	EMISSION = line_color.rgb * mask * glow;
	ROUGHNESS = 0.72;
	METALLIC = 0.15;
}
