shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Retro Simple Pixel-Art Subterranean Basalt Shader
uniform vec4 rock_color_base : source_color = vec4(0.28, 0.30, 0.35, 1.0);
uniform vec4 rock_color_deep : source_color = vec4(0.16, 0.17, 0.21, 1.0);
uniform vec4 rock_color_strata : source_color = vec4(0.38, 0.32, 0.25, 1.0);
uniform float pixel_density = 16.0; // 16 pixels per meter

varying vec3 v_world_pos;
varying vec3 v_world_normal;

float hash_r(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // Quantize world position to 3D voxel pixel grid
    vec3 p_pos = floor(v_world_pos * pixel_density) / pixel_density;

    float px_noise = hash_r(p_pos);
    float strata = floor(sin(p_pos.y * 1.5 + px_noise * 1.2) * 3.0) / 3.0;

    // 3-step color quantization for retro look
    vec3 col = rock_color_base.rgb;
    if (px_noise < 0.25) {
        col = rock_color_deep.rgb;
    } else if (strata > 0.3) {
        col = rock_color_strata.rgb;
    }

    // Pixelated stepped lighting response
    float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
    float stepped_spec = floor(pow(NdotV, 2.0) * 3.0) / 3.0;

    // Atmospheric silhouette rim enhancement
    float rim = 1.0 - NdotV;
    float stepped_rim = floor(pow(rim, 3.5) * 3.0) / 3.0;
    col += vec3(0.04, 0.05, 0.07) * stepped_rim;

    ALBEDO = col;
    ROUGHNESS = 0.85;
    METALLIC = 0.04;
    SPECULAR = stepped_spec * 0.20;
}
