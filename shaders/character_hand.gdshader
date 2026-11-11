shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Retro Pixel-Art Character Expedition Hand & Sleeve Shader
uniform vec4 sleeve_color : source_color = vec4(0.24, 0.28, 0.22, 1.0); // Canvas expedition olive
uniform vec4 cuff_leather_color : source_color = vec4(0.20, 0.14, 0.09, 1.0); // Dark saddle leather
uniform vec4 glove_color : source_color = vec4(0.32, 0.22, 0.14, 1.0); // Worn work leather
uniform vec4 stitch_color : source_color = vec4(0.70, 0.62, 0.48, 1.0); // Heavy linen stitching

uniform float pixel_density = 48.0;

varying vec3 v_local_pos;
varying vec3 v_local_normal;

float hash_p(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    v_local_pos = VERTEX;
    v_local_normal = NORMAL;
}

void fragment() {
    // Quantize 2D projection to crisp retro pixel grid
    vec2 raw_uv = v_local_pos.xy + v_local_pos.zy;
    vec2 p_uv = floor(raw_uv * pixel_density) / pixel_density;

    vec3 col = glove_color.rgb;
    float roughness = 0.85;
    float metallic = 0.02;

    float pixel_noise = (hash_p(p_uv) - 0.5) * 0.10;

    // Y coordinate determines sleeve vs cuff vs glove
    if (v_local_pos.y < -0.08) {
        // Sleeve (Canvas jacket)
        col = sleeve_color.rgb + vec3(pixel_noise);
        roughness = 0.90;
        
        // Pixelated cuff seam
        if (v_local_pos.y > -0.11) {
            col = cuff_leather_color.rgb;
        }
    } else if (v_local_pos.y < -0.04) {
        // Wristband (Leather strap & stitching)
        col = cuff_leather_color.rgb + vec3(pixel_noise * 0.5);
        if (fract(p_uv.x * 24.0) < 0.25) {
            col = stitch_color.rgb;
        }
        roughness = 0.70;
    } else {
        // Glove (Stitched work leather)
        col = glove_color.rgb + vec3(pixel_noise);
        // Finger knuckle seams
        if (fract(v_local_pos.y * 32.0) < 0.08) {
            col = cuff_leather_color.rgb * 0.8;
        }
    }

    // Retro pixelated stepped lighting
    float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
    float stepped_rim = floor(pow(1.0 - NdotV, 3.0) * 4.0) / 4.0;
    col += vec3(stepped_rim * 0.12);

    ALBEDO = col;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = 0.20;
}
