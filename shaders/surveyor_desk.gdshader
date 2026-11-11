shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Retro Simple Pixel-Art Surveyor Plotting Table Shader
uniform vec4 wood_rim_color : source_color = vec4(0.24, 0.14, 0.08, 1.0);
uniform vec4 map_parchment_color : source_color = vec4(0.82, 0.76, 0.62, 1.0);
uniform vec4 map_ink_color : source_color = vec4(0.18, 0.22, 0.28, 1.0);
uniform vec4 brass_trim_color : source_color = vec4(0.72, 0.56, 0.28, 1.0);

varying vec3 v_local_pos;
varying vec3 v_local_normal;

float hash_d(vec2 p) {
    p = fract(p * vec2(234.34, 435.34));
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
    v_local_pos = VERTEX;
    v_local_normal = NORMAL;
}

void fragment() {
    vec3 abs_n = abs(v_local_normal);
    vec3 col = wood_rim_color.rgb;
    float roughness = 0.80;
    float metallic = 0.02;

    if (v_local_normal.y > 0.5) {
        // TOP SURFACE: 48x32 pixel grid
        vec2 uv = (v_local_pos.xz + vec2(0.8, 0.45)) / vec2(1.6, 0.9);
        vec2 p_uv = floor(uv * vec2(48.0, 32.0));

        // Wood rim (3 pixels on each side)
        bool is_rim = (p_uv.x < 3.0 || p_uv.x >= 45.0 || p_uv.y < 3.0 || p_uv.y >= 29.0);
        bool is_corner = (p_uv.x < 6.0 || p_uv.x >= 42.0) && (p_uv.y < 6.0 || p_uv.y >= 26.0);

        if (is_corner) {
            col = brass_trim_color.rgb;
            metallic = 0.85;
            roughness = 0.35;
        } else if (is_rim) {
            col = wood_rim_color.rgb;
        } else {
            // Parchment map with 1-pixel ink contour lines and grid
            col = map_parchment_color.rgb + vec3((hash_d(p_uv) - 0.5) * 0.08);

            // 1-pixel grid every 6 pixels
            if (mod(p_uv.x, 6.0) == 0.0 || mod(p_uv.y, 6.0) == 0.0) {
                col = mix(col, map_ink_color.rgb, 0.45);
            }

            // Topographical contour loops
            float elev = sin(p_uv.x * 0.4) * 3.0 + cos(p_uv.y * 0.5) * 3.0;
            if (mod(floor(elev), 2.0) == 0.0) {
                col = map_ink_color.rgb;
            }

            // Compass circle in center
            vec2 c_rel = p_uv - vec2(24.0, 16.0);
            float d = length(c_rel);
            if (d >= 5.5 && d <= 7.0) {
                col = map_ink_color.rgb;
            }
        }
    } else {
        // SIDES: Dark mahogany casing with pixelated drawers
        vec2 side_uv;
        if (abs_n.x > 0.5) {
            side_uv = floor((v_local_pos.zy + vec2(0.45, 0.5)) * 32.0);
        } else {
            side_uv = floor((v_local_pos.xy + vec2(0.8, 0.5)) * 32.0);
        }

        col = wood_rim_color.rgb + vec3((hash_d(side_uv) - 0.5) * 0.06);

        // Drawer seam lines on front (y = 10, y = 20)
        if (v_local_normal.z < -0.5) {
            if (side_uv.y == 10.0 || side_uv.y == 20.0) {
                col = wood_rim_color.rgb * 0.4;
            }
            // Brass pull handles
            if ((side_uv.y == 15.0 || side_uv.y == 5.0) && (side_uv.x >= 12.0 && side_uv.x <= 16.0 || side_uv.x >= 32.0 && side_uv.x <= 36.0)) {
                col = brass_trim_color.rgb;
                metallic = 0.85;
                roughness = 0.35;
            }
        }
    }

    ALBEDO = col;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = mix(0.15, 0.85, metallic);
}
