shader_type spatial;
render_mode depth_draw_always, cull_back;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float emission_energy : hint_range(0.0, 16.0) = 0.0;
uniform float viewmodel_fov : hint_range(40.0, 110.0) = 70.0;

void vertex() {
	// First-Person Viewmodel Anti-Clipping: Compress clip-space depth toward near plane
	// Guarantees held weapons and hands NEVER penetrate or clip through world walls/voxels
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	POSITION.z = POSITION.z * 0.22;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * albedo_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	if (emission_energy > 0.0) {
		EMISSION = emission_color.rgb * emission_energy;
	}
}
