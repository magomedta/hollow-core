shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Clean Retro Pixel-Art Cargo Crate (32x32 pixel grid per face, Zero Noise)
uniform vec4 crate_wood_base : source_color = vec4(0.42, 0.28, 0.16, 1.0);
uniform vec4 crate_wood_frame : source_color = vec4(0.28, 0.18, 0.10, 1.0);
uniform vec4 crate_wood_dark : source_color = vec4(0.18, 0.11, 0.06, 1.0);
uniform vec4 iron_bracket_color : source_color = vec4(0.18, 0.18, 0.22, 1.0);
uniform vec4 rivet_color : source_color = vec4(0.55, 0.58, 0.65, 1.0);
uniform vec4 stencil_color : source_color = vec4(0.88, 0.76, 0.24, 1.0);

varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
    v_local_pos = VERTEX;
    v_local_normal = NORMAL;
}

void fragment() {
    vec2 raw_uv;
    vec3 abs_n = abs(v_local_normal);
    if (abs_n.x > 0.5) {
        raw_uv = v_local_pos.zy + 0.5;
    } else if (abs_n.y > 0.5) {
        raw_uv = v_local_pos.xz + 0.5;
    } else {
        raw_uv = v_local_pos.xy + 0.5;
    }

    // Exact 32x32 pixel coordinates (0 to 31)
    vec2 p = floor(clamp(raw_uv, 0.0, 0.999) * 32.0);

    // Outer framing border (4 pixels)
    bool is_border = (p.x < 4.0 || p.x >= 28.0 || p.y < 4.0 || p.y >= 28.0);
    // 1-pixel dark seam between frame and inner panel
    bool is_frame_seam = (p.x == 3.0 || p.x == 28.0 || p.y == 3.0 || p.y == 28.0);

    // Diagonal cross brace (2 pixels wide)
    bool is_diag = abs(p.x - p.y) <= 1.0 && !is_border;
    bool is_diag_shadow = (p.x - p.y == 2.0) && !is_border;

    // Inner vertical board grooves every 6 pixels
    bool is_board_groove = (mod(p.x, 6.0) == 0.0) && !is_border && !is_diag;

    // Corner L-shaped iron bracket plates (6x6 pixels in each corner)
    vec2 c = min(p, 31.0 - p);
    bool is_bracket = (c.x < 6.0 && c.y < 6.0 && (c.x < 4.0 || c.y < 4.0));
    bool is_rivet = (c == vec2(1.0, 1.0) || c == vec2(1.0, 4.0) || c == vec2(4.0, 1.0));

    // Base color selection (Clean retro pixel-art)
    vec3 col = crate_wood_base.rgb;
    if (is_border || is_diag) {
        col = crate_wood_frame.rgb;
    }
    if (is_frame_seam || is_diag_shadow || is_board_groove) {
        col = crate_wood_dark.rgb;
    }

    // Stenciled pixel-art expedition marking on side faces
    if (abs_n.y < 0.5 && !is_border && !is_diag) {
        if (p.y >= 14.0 && p.y <= 17.0 && p.x >= 10.0 && p.x <= 21.0) {
            // Clean pixel letter shapes
            if (mod(p.x, 3.0) != 0.0) {
                col = stencil_color.rgb;
            }
        }
    }

    float metallic = 0.02;
    float roughness = 0.82;

    if (is_bracket) {
        col = iron_bracket_color.rgb;
        metallic = 0.85;
        roughness = 0.40;
        if (is_rivet) {
            col = rivet_color.rgb;
            roughness = 0.20;
        }
    }

    ALBEDO = col;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = mix(0.15, 0.80, metallic);
}
