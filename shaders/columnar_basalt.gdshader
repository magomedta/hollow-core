shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Retro Simple Pixel-Art Columnar Basalt Shader
uniform vec4 basalt_primary : source_color = vec4(0.16, 0.17, 0.20, 1.0);
uniform vec4 basalt_joint : source_color = vec4(0.05, 0.05, 0.07, 1.0);
uniform vec4 basalt_iron : source_color = vec4(0.26, 0.18, 0.12, 1.0);
uniform float pixel_density = 20.0;

varying vec3 v_world_pos;

float hash_cb(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 p_pos = floor(v_world_pos * pixel_density) / pixel_density;

    // Horizontal joint cracks every 18 pixels
    float joint_idx = mod(floor(v_world_pos.y * pixel_density), 18.0);
    bool is_joint = (joint_idx == 0.0);

    float px_noise = hash_cb(p_pos.xy + p_pos.zy);
    vec3 col = basalt_primary.rgb + vec3((px_noise - 0.5) * 0.08);

    if (is_joint) {
        col = basalt_joint.rgb;
    } else if (joint_idx <= 2.0) {
        col = basalt_iron.rgb;
    }

    ALBEDO = col;
    ROUGHNESS = 0.80;
    METALLIC = 0.05;
    SPECULAR = 0.20;
}
