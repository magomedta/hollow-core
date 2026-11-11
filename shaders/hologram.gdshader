shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, unshaded;

uniform vec4 holo_color : source_color = vec4(0.95, 0.75, 0.22, 0.55);
uniform float grid_frequency : hint_range(1.0, 40.0) = 12.0;
uniform float scanline_speed : hint_range(0.0, 10.0) = 2.5;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;
uniform float pulse_speed : hint_range(0.0, 8.0) = 3.0;

varying vec3 v_world_pos;
varying vec3 v_model_pos;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_model_pos = VERTEX;
}

void fragment() {
    // Model-space 3D grid wireframe pattern
    vec3 grid = abs(fract(v_model_pos * grid_frequency) - 0.5);
    vec3 grid_lines = 1.0 - smoothstep(vec3(0.02), vec3(0.08), grid);
    float grid_mask = max(max(grid_lines.x, grid_lines.y), grid_lines.z);

    // Subtle horizontal scanline wave
    float scanline = sin(v_world_pos.y * 14.0 - TIME * scanline_speed) * 0.5 + 0.5;

    // View-angle Fresnel glow
    float NdotV = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
    float fresnel = pow(1.0 - NdotV, fresnel_power);

    // Subtle rhythmic pulse
    float pulse = sin(TIME * pulse_speed) * 0.08 + 0.92;

    // Combine into sleek diegetic holographic preview with strong visibility
    float alpha = (0.40 + grid_mask * 0.45 + fresnel * 0.35 + scanline * 0.15) * holo_color.a * pulse;
    alpha = clamp(alpha, 0.0, 0.95);

    vec3 col = holo_color.rgb * (1.2 + fresnel * 0.5 + grid_mask * 0.4);

    ALBEDO = col;
    ALPHA = alpha;
}
