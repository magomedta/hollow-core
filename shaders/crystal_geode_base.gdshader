shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Radiant Geode Socket Bed Shader
uniform vec4 rock_color : source_color = vec4(0.10, 0.11, 0.14, 1.0);
uniform vec4 vein_glow_color : source_color = vec4(0.12, 0.85, 0.95, 1.0);

varying vec3 v_world_pos;
varying vec3 v_local_pos;

float hash_geo(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_local_pos = VERTEX;
}

void fragment() {
    // Center radial fissures feeding the crystals
    float dist_center = length(v_local_pos.xz);
    float angle = atan(v_local_pos.z, v_local_pos.x);
    
    // Web of bioluminescent mineral veins
    float vein_pattern = abs(sin(angle * 6.0 + dist_center * 4.0)) * 0.5;
    float vein = smoothstep(0.42, 0.48, vein_pattern) * (1.0 - smoothstep(0.0, 1.6, dist_center));
    
    vec3 col = rock_color.rgb;
    col = mix(col, vein_glow_color.rgb * 0.8, vein * 0.7);
    
    ALBEDO = col;
    ROUGHNESS = mix(0.82, 0.25, vein);
    SPECULAR = mix(0.18, 0.85, vein);
    EMISSION = vein_glow_color.rgb * vein * 1.6;
}
