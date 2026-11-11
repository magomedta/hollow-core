shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Retro Simple Pixel-Art Bioluminescence Shader
uniform vec4 base_color : source_color = vec4(0.04, 0.20, 0.30, 1.0);
uniform vec4 emission_color : source_color = vec4(0.12, 0.85, 0.95, 1.0);
uniform vec4 inner_glow_color : source_color = vec4(0.35, 0.98, 0.88, 1.0);
uniform float emission_energy = 1.65;
uniform float pulse_speed = 0.85;

void fragment() {
    float time_pulse = sin(TIME * pulse_speed + floor(VERTEX.y * 8.0) * 0.25) * 0.5 + 0.5;
    float current_emission = emission_energy * (0.85 + time_pulse * 0.3);

    // Stepped retro fresnel rim
    float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
    float fresnel = floor(pow(1.0 - NdotV, 2.0) * 4.0) / 4.0;

    vec3 col = mix(base_color.rgb, inner_glow_color.rgb, 0.30 + fresnel * 0.4);
    ALBEDO = col;
    ROUGHNESS = 0.25;
    SPECULAR = 0.65;
    METALLIC = 0.08;

    vec3 glow = mix(emission_color.rgb, inner_glow_color.rgb, fresnel) * current_emission;
    EMISSION = glow;
}
