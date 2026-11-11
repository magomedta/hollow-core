shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Clean Retro Pixel-Art Wood Plank Shader (32 pixels per meter, Zero Noise)
uniform vec4 wood_color_base : source_color = vec4(0.45, 0.31, 0.18, 1.0);
uniform vec4 wood_color_alt : source_color = vec4(0.40, 0.27, 0.15, 1.0);
uniform vec4 wood_color_dark : source_color = vec4(0.20, 0.12, 0.06, 1.0);
uniform vec4 nail_color : source_color = vec4(0.14, 0.14, 0.16, 1.0);

uniform float pixel_density = 32.0;
uniform float plank_width = 0.30;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    vec2 raw_uv;
    if (abs(v_world_normal.y) > 0.5) {
        raw_uv = v_world_pos.xz;
    } else if (abs(v_world_normal.x) > 0.5) {
        raw_uv = v_world_pos.zy;
    } else {
        raw_uv = v_world_pos.xy;
    }

    vec2 p = floor(raw_uv * pixel_density);

    // Plank index and relative coordinates
    float plank_pixel_w = floor(plank_width * pixel_density);
    float p_idx = floor(p.x / plank_pixel_w);
    float p_u = mod(p.x, plank_pixel_w);

    // Seam between planks (1 pixel wide)
    bool is_seam = (p_u == 0.0);

    // Staggered end joint every 64 pixels (~2.0m)
    float stagger = mod(p_idx * 17.0, 64.0);
    float joint_v = mod(p.y + stagger, 64.0);
    bool is_joint = (joint_v == 0.0);

    // Clean alternating plank shades
    vec3 col = (mod(p_idx, 2.0) == 0.0) ? wood_color_base.rgb : wood_color_alt.rgb;

    if (is_seam || is_joint) {
        col = wood_color_dark.rgb;
    }

    // 1-pixel iron nails at plank ends
    if ((joint_v == 2.0 || joint_v == 62.0) && (p_u == 3.0 || p_u == plank_pixel_w - 4.0)) {
        col = nail_color.rgb;
    }

    ALBEDO = col;
    ROUGHNESS = 0.82;
    METALLIC = 0.02;
    SPECULAR = 0.15;
}
