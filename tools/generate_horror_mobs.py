"""
Generates horrifying, grotesque subterranean horror mobs in Blender 4.0:
1. Pale Lurker (Бледный Скиталец): Emaciated eyeless humanoid with needle claws, hunched spine, protruding ribs.
2. Wall Mimic (Каменный Мимик): Jagged rock geode that splits into a gaping fanged maw with reaching tendrils.
3. Bloat Horror (Чумной Гнойник): Pulsating bulbous fleshy tumor with blind sensory pits.
"""
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector, Matrix, Euler

MODELS_DIR = "hollow_core/models"
TEX_DIR = "hollow_core/textures"
OUT_SHOWCASE = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/model_showcase"
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(OUT_SHOWCASE, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def setup_pixel_mat(obj, mat_name, tex_file, emit_color=None, emit_strength=0.0):
    mat = bpy.data.materials.new(name=mat_name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.75
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    tex_path = os.path.join(TEX_DIR, tex_file)
    if os.path.exists(tex_path):
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = bpy.data.images.load(os.path.abspath(tex_path))
        tex_node.interpolation = 'Closest'
        links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

    if emit_color and emit_strength > 0:
        if 'Emission Color' in bsdf.inputs:
            bsdf.inputs['Emission Color'].default_value = emit_color
            bsdf.inputs['Emission Strength'].default_value = emit_strength

    obj.data.materials.append(mat)
    return mat

def create_extruded_segment(bm, start_pt, end_pt, radius_start, radius_end, segments=6):
    dir_vec = (end_pt - start_pt)
    dist = dir_vec.length
    if dist < 0.001: return
    z_axis = Vector((0, 0, 1))
    rot_quat = z_axis.rotation_difference(dir_vec)
    ring1, ring2 = [], []
    for i in range(segments):
        angle = (2.0 * math.pi * i) / segments
        ca, sa = math.cos(angle), math.sin(angle)
        p1 = start_pt + rot_quat @ Vector((ca * radius_start, sa * radius_start, 0))
        p2 = end_pt + rot_quat @ Vector((ca * radius_end, sa * radius_end, 0))
        ring1.append(bm.verts.new(p1))
        ring2.append(bm.verts.new(p2))
    for i in range(segments):
        ni = (i + 1) % segments
        bm.faces.new([ring1[i], ring1[ni], ring2[ni], ring2[i]])

# 1. PALE LURKER (Horrific emaciated blind cave humanoid)
def build_pale_lurker():
    mesh = bpy.data.meshes.new("PaleLurkerMesh")
    obj = bpy.data.objects.new("PaleLurker", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Gaunt, featureless skull with open gaping maw
    head_mat = Matrix.Translation((0, 0.45, 1.85)) @ Matrix.Scale(0.22, 4, Vector((1,0,0))) @ Matrix.Scale(0.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.28, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=head_mat)

    # Gaping hollow jaw
    jaw_mat = Matrix.Translation((0, 0.62, 1.65)) @ Matrix.Scale(0.18, 4, Vector((1,0,0))) @ Matrix.Scale(0.25, 4, Vector((0,1,0))) @ Matrix.Scale(0.15, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=jaw_mat)

    # Sharp needle teeth
    for i in range(8):
        angle = (math.pi * i) / 7.0
        t_base = Vector((0.15 * math.cos(angle), 0.65 + 0.1 * math.sin(angle), 1.75))
        t_tip = t_base + Vector((0, 0.05, -0.12))
        create_extruded_segment(bm, t_base, t_tip, 0.02, 0.005, 4)

    # Emaciated, hunched torso with visible spine nodes
    p_spine = [
        Vector((0, 0.30, 1.70)),
        Vector((0, 0.15, 1.45)),
        Vector((0, 0.00, 1.15)),
        Vector((0, -0.10, 0.85)),
    ]
    for i in range(len(p_spine)-1):
        create_extruded_segment(bm, p_spine[i], p_spine[i+1], 0.22 - i*0.02, 0.20 - i*0.02, 6)

    # Protruding bony ribs
    for i in range(4):
        z_rib = 1.60 - i * 0.15
        for side in (-1, 1):
            r_base = Vector((0, 0.20 - i*0.05, z_rib))
            r_mid = Vector((side * 0.28, 0.28 - i*0.05, z_rib - 0.04))
            r_end = Vector((side * 0.12, 0.35 - i*0.05, z_rib - 0.08))
            create_extruded_segment(bm, r_base, r_mid, 0.03, 0.02, 4)
            create_extruded_segment(bm, r_mid, r_end, 0.02, 0.015, 4)

    # Extremely long, spindly arms with needle fingers reaching ground
    for side in (-1, 1):
        shoulder = Vector((side * 0.32, 0.20, 1.60))
        elbow = Vector((side * 0.65, 0.10, 1.05))
        wrist = Vector((side * 0.55, 0.40, 0.35))
        create_extruded_segment(bm, shoulder, elbow, 0.08, 0.06, 5)
        create_extruded_segment(bm, elbow, wrist, 0.06, 0.04, 5)
        # 4 elongated needle claws scratching ground Z=0
        for f in range(4):
            f_tip = wrist + Vector((side * (0.08 + f*0.04), 0.25 + f*0.05, -0.35))
            create_extruded_segment(bm, wrist, f_tip, 0.025, 0.005, 4)

    # Twisted, crouching hind legs
    for side in (-1, 1):
        hip = Vector((side * 0.18, -0.10, 0.85))
        knee = Vector((side * 0.42, -0.35, 0.55))
        ankle = Vector((side * 0.35, 0.10, 0.20))
        foot = Vector((side * 0.32, 0.35, 0.0))
        create_extruded_segment(bm, hip, knee, 0.09, 0.07, 5)
        create_extruded_segment(bm, knee, ankle, 0.07, 0.05, 5)
        create_extruded_segment(bm, ankle, foot, 0.05, 0.03, 5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pixel_mat(obj, "M_PaleLurker", "calcite_crystal.png") # Pale chalky/bony texture
    return obj

# 2. WALL MIMIC (Disguised ore boulder that splits into a horrific fanged trap)
def build_wall_mimic():
    mesh = bpy.data.meshes.new("WallMimicMesh")
    obj = bpy.data.objects.new("WallMimic", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Upper rocky jaw
    up_mat = Matrix.Translation((0, 0, 0.95)) @ Matrix.Rotation(math.radians(-32), 4, 'X') @ Matrix.Scale(0.85, 4, Vector((1,0,0))) @ Matrix.Scale(0.75, 4, Vector((0,1,0))) @ Matrix.Scale(0.55, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=up_mat)

    # Lower rocky jaw
    dn_mat = Matrix.Translation((0, 0, 0.35)) @ Matrix.Rotation(math.radians(25), 4, 'X') @ Matrix.Scale(0.85, 4, Vector((1,0,0))) @ Matrix.Scale(0.85, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=dn_mat)

    # Horrific rows of teeth in upper jaw
    for i in range(10):
        angle = (math.pi * i) / 9.0
        t_base = Vector((0.65 * math.cos(angle), 0.55 + 0.4 * math.sin(angle), 1.05))
        t_tip = t_base + Vector((0, -0.15, -0.45))
        create_extruded_segment(bm, t_base, t_tip, 0.06, 0.01, 4)

    # Teeth in lower jaw
    for i in range(10):
        angle = (math.pi * i) / 9.0
        t_base = Vector((0.65 * math.cos(angle), 0.65 + 0.4 * math.sin(angle), 0.35))
        t_tip = t_base + Vector((0, -0.15, 0.45))
        create_extruded_segment(bm, t_base, t_tip, 0.06, 0.01, 4)

    # Fleshy reaching grasping tendrils inside mouth
    for t_idx in range(5):
        angle = (math.pi * t_idx) / 4.0
        p_base = Vector((0.35 * math.cos(angle), 0.1, 0.65))
        p_mid = Vector((0.55 * math.cos(angle), 0.6, 0.70))
        p_tip = Vector((0.75 * math.cos(angle), 1.15, 0.60))
        create_extruded_segment(bm, p_base, p_mid, 0.08, 0.05, 5)
        create_extruded_segment(bm, p_mid, p_tip, 0.05, 0.015, 5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pixel_mat(obj, "M_WallMimic", "gold_ore.png", emit_color=(1.0, 0.2, 0.1, 1.0), emit_strength=1.5)
    return obj

def render_showcase(obj, name):
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("Cam", cam_data)
    cam.location = Vector((3.5, 4.0, 2.5))
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    target = bpy.data.objects.new("Target", None)
    target.location = Vector((0, 0, 1.0))
    bpy.context.collection.objects.link(target)

    tr = cam.constraints.new(type='TRACK_TO')
    tr.target = target
    tr.track_axis = 'TRACK_NEGATIVE_Z'
    tr.up_axis = 'UP_Y'

    # Light
    l = bpy.data.lights.new("Light", type='POINT')
    l.energy = 800.0
    l.color = (1.0, 0.95, 0.85)
    lo = bpy.data.objects.new("Light", l)
    lo.location = Vector((2, 3, 3))
    bpy.context.collection.objects.link(lo)

    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    bpy.context.scene.render.resolution_x = 1024
    bpy.context.scene.render.resolution_y = 768
    out_png = os.path.join(OUT_SHOWCASE, f"render_{name}.png")
    bpy.context.scene.render.filepath = os.path.abspath(out_png)
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_png}")

def main():
    # 1. Pale Lurker
    reset_scene()
    lurker = build_pale_lurker()
    out_glb = os.path.join(MODELS_DIR, "pale_lurker.glb")
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(out_glb), export_format='GLB', export_apply=True)
    render_showcase(lurker, "pale_lurker")

    # 2. Wall Mimic
    reset_scene()
    mimic = build_wall_mimic()
    out_glb = os.path.join(MODELS_DIR, "wall_mimic.glb")
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(out_glb), export_format='GLB', export_apply=True)
    render_showcase(mimic, "wall_mimic")

if __name__ == "__main__":
    main()
