shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 flame_core_color : source_color = vec4(1.0, 0.95, 0.80, 1.0);
uniform vec4 flame_mid_color : source_color = vec4(1.0, 0.65, 0.16, 1.0);
uniform vec4 flame_outer_color : source_color = vec4(0.88, 0.28, 0.04, 1.0);
uniform float flicker_speed = 8.0;

void fragment() {
    float t = TIME * flicker_speed;
    float flick = sin(t) * 0.04 + cos(t * 1.5) * 0.02;
    
    // Natural teardrop profile centered at flame wick
    vec2 p = UV - vec2(0.5, 0.65);
    float taper = 1.0 + max(0.0, -p.y) * 2.5;
    p.x *= taper;
    
    float dist = length(p * vec2(2.8, 1.6));
    float alpha = smoothstep(0.44, 0.05, dist);
    
    vec3 col = mix(flame_core_color.rgb, flame_mid_color.rgb, smoothstep(0.04, 0.22, dist));
    col = mix(col, flame_outer_color.rgb, smoothstep(0.22, 0.44, dist));
    
    ALBEDO = col;
    EMISSION = col * (0.90 + flick * 0.15);
    ALPHA = clamp(alpha * (0.90 + flick * 0.06), 0.0, 1.0);
}
