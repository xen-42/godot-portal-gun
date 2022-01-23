shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport_texture;
uniform sampler2D noise;
uniform vec4 portal_colour : hint_color;
uniform float scale = 1.0;

void fragment() {
	vec4 colour = texture(viewport_texture, SCREEN_UV);
	float x = UV.x - 0.51;
	float y = (UV.y - 0.53)/3.0;
	x += texture(noise, UV + vec2(TIME/40.0, 0.0)).r/50.0;
	y += texture(noise, UV + vec2(0.0, TIME/40.0)).r/50.0;
	float r = sqrt(x*x + y*y);
	if (r > 0.1 * scale) {
		colour.rgba = vec4(0.0, 0.0, 0.0, 0.0);
	} else if (r > 0.09 * scale) {
		colour.rgba = portal_colour;
	}
	
	ALBEDO = colour.rgb;
	ALPHA = colour.a;
}
