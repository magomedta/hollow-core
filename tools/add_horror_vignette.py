import sys

path = 'hollow_core/scripts/hud.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add vignette_node variable
target_var = 'var ui_font: Font'
repl_var = '''var ui_font: Font
var vignette_node: Control'''

# 2. Add vignette to _build_ui_nodes
target_build = '''\tvar root = Control.new()
\troot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\troot.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tadd_child(root)'''

repl_build = '''\tvar root = Control.new()
\troot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\troot.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tadd_child(root)

\t# Horror Atmosphere Vignette Overlay (Dark edges, subtle breathing pulse, critical blood pulse)
\tvignette_node = Control.new()
\tvignette_node.name = "HorrorVignette"
\tvignette_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tvignette_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
\troot.add_child(vignette_node)
\tvignette_node.draw.connect(_draw_horror_vignette)'''

# 3. Add queue_redraw in _process
target_proc = '''\t# Real-time FPS & Performance Monitoring'''
repl_proc = '''\tif vignette_node:
\t\tvignette_node.queue_redraw()

\t# Real-time FPS & Performance Monitoring'''

# 4. Add _draw_horror_vignette method at the end
vignette_func = '''

func _draw_horror_vignette() -> void:
\tif vignette_node == null: return
\tvar size = vignette_node.get_viewport_rect().size
\tvar border_w = 160.0
\tvar border_h = 120.0

\tvar base_alpha = 0.22
\tvar is_critical = (current_hp < 35.0)
\tvar tint = Color(0.01, 0.01, 0.02)

\tif is_critical:
\t\tvar pulse = (sin(Time.get_ticks_msec() * 0.005) * 0.5 + 0.5)
\t\tbase_alpha = lerp(0.20, 0.55, pulse)
\t\ttint = Color(0.35, 0.02, 0.02)

\tfor i in range(5):
\t\tvar step_pct = float(i + 1) / 5.0
\t\tvar step_alpha = base_alpha * (1.0 - float(i) / 5.0)
\t\tvar col = Color(tint.r, tint.g, tint.b, step_alpha)
\t\tvar inset_x = border_w * (1.0 - step_pct)
\t\tvar inset_y = border_h * (1.0 - step_pct)
\t\tvignette_node.draw_rect(Rect2(0, inset_y, size.x, border_h / 5.0), col)
\t\tvignette_node.draw_rect(Rect2(0, size.y - inset_y - (border_h / 5.0), size.x, border_h / 5.0), col)
\t\tvignette_node.draw_rect(Rect2(inset_x, 0, border_w / 5.0, size.y), col)
\t\tvignette_node.draw_rect(Rect2(size.x - inset_x - (border_w / 5.0), 0, border_w / 5.0, size.y), col)
'''

assert target_var in content, "target_var not found"
assert target_build in content, "target_build not found"
assert target_proc in content, "target_proc not found"

content = content.replace(target_var, repl_var, 1)
content = content.replace(target_build, repl_build, 1)
content = content.replace(target_proc, repl_proc, 1)
content += vignette_func

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Added horror vignette cleanly! New line count: {len(content.splitlines())}")
