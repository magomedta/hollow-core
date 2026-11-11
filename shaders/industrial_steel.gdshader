shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Retro Simple Pixel-Art Industrial Steel Shader
uniform vec4 steel_color_base : source_color = vec4(0.18, 0.19, 0.22, 1.0);
uniform vec4 steel_color_worn : source_color = vec4(0.48, 0.50, 0.54, 1.0);
uniform vec4 hazard_yellow : source_color = vec4(0.92, 0.72, 0.12, 1.0);
uniform vec4 hazard_black : source_color = vec4(0.10, 0.10, 0.12, 1.0);
uniform bool has_hazard_stripes = false;
uniform float pixel_density = 24.0;

varying vec3 v_world_pos;

float hash_s(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 p_pos = floor(v_world_pos * pixel_density);

    vec3 col = steel_color_base.rgb + vec3((hash_s(p_pos.xy + p_pos.zy) - 0.5) * 0.06);
    float metallic = 0.90;
    float roughness = 0.45;

    // Bolted collar rings every 24 pixels
    if (mod(p_pos.y, 24.0) == 0.0) {
        col = steel_color_worn.rgb;
        roughness = 0.30;
    }

    if (has_hazard_stripes) {
        // Diagonal warning stripes: 4 pixels yellow, 4 pixels black
        float stripe = mod(p_pos.x + p_pos.y, 8.0);
        if (stripe < 4.0) {
            col = hazard_yellow.rgb;
        } else {
            col = hazard_black.rgb;
        }
        metallic = 0.10;
        roughness = 0.60;
    }

    ALBEDO = col;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = 0.85;
}
