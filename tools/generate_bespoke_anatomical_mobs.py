"""
Complete Subterranean Horror & Creature Generator for Hollow Core.
Maps bespoke hand-crafted 128x128 pixel-art textures to anatomical geometry:
- Top-Left (U: 0.0..0.5, V: 0.5..1.0): Head / Face (drawn eyes, teeth, fangs, horns)
- Top-Right (U: 0.5..1.0, V: 0.5..1.0): Dorsal Carapace / Spine / Ribs
- Bottom-Left (U: 0.0..0.5, V: 0.0..0.5): Limbs / Joints / Claws / Scythes
- Bottom-Right (U: 0.5..1.0, V: 0.0..0.5): Underbelly / Crystals / Core / Maw
"""
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector, Matrix

MODELS_DIR = "hollow_core/models"
TEX_DIR = "hollow_core/textures/mobs"
OUT_SHOWCASE = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/model_showcase"
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(OUT_SHOWCASE, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def setup_pbr_material(obj, mat_name, base_tex, emit_tex=None, emit_strength=3.0):
    mat = bpy.data.materials.new(name=mat_name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.70
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    base_path = os.path.join(TEX_DIR, base_tex)
    if os.path.exists(base_path):
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = bpy.data.images.load(os.path.abspath(base_path))
        tex_node.interpolation = 'Closest' # Crisp pixel-art filter
        links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

    if emit_tex:
        emit_path = os.path.join(TEX_DIR, emit_tex)
        if os.path.exists(emit_path):
            emit_node = nodes.new(type='ShaderNodeTexImage')
            emit_node.image = bpy.data.images.load(os.path.abspath(emit_path))
            emit_node.interpolation = 'Closest'
            if 'Emission Color' in bsdf.inputs:
                links.new(emit_node.outputs['Color'], bsdf.inputs['Emission Color'])
                bsdf.inputs['Emission Strength'].default_value = emit_strength
            elif 'Emission' in bsdf.inputs:
                links.new(emit_node.outputs['Color'], bsdf.inputs['Emission'])

    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)
    return mat

def create_icosphere_faces(bm, matrix, radius=1.0, subdivisions=2):
    old_faces = set(bm.faces)
    bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius, matrix=matrix)
    return list(set(bm.faces) - old_faces)

def create_cube_faces(bm, matrix, size=1.0):
    old_faces = set(bm.faces)
    bmesh.ops.create_cube(bm, size=size, matrix=matrix)
    return list(set(bm.faces) - old_faces)

def create_extruded_cylinder(bm, start_pt, end_pt, radius_start, radius_end, segments=6):
    dir_vec = (end_pt - start_pt)
    dist = dir_vec.length
    if dist < 0.001: return []
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
    
    new_faces = []
    for i in range(segments):
        ni = (i + 1) % segments
        f = bm.faces.new([ring1[i], ring1[ni], ring2[ni], ring2[i]])
        new_faces.append(f)
    return new_faces

def map_faces_to_uv(bm, faces, u_min, v_min, u_max, v_max):
    uv_layer = bm.loops.layers.uv.verify()
    if not faces: return
    verts = set()
    for f in faces:
        for v in f.verts:
            verts.add(v)
    if not verts: return
    min_x = min(v.co.x for v in verts)
    max_x = max(v.co.x for v in verts)
    min_z = min(v.co.z for v in verts)
    max_z = max(v.co.z for v in verts)
    dx = max(max_x - min_x, 0.001)
    dz = max(max_z - min_z, 0.001)

    for f in faces:
        for loop in f.loops:
            vx = loop.vert.co.x
            vz = loop.vert.co.z
            norm_u = (vx - min_x) / dx
            norm_v = (vz - min_z) / dz
            loop[uv_layer].uv = Vector((
                u_min + norm_u * (u_max - u_min),
                v_min + norm_v * (v_max - v_min)
            ))

# 1. PALE LURKER (Horror Ghoul)
def build_pale_lurker():
    mesh = bpy.data.meshes.new("PaleLurkerMesh")
    obj = bpy.data.objects.new("PaleLurker", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> Sunken sockets & needle teeth)
    head_mat = Matrix.Translation((0, 0.45, 1.85)) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.28, 4, Vector((0,0,1)))
    head_faces = create_icosphere_faces(bm, head_mat, radius=1.0, subdivisions=2)
    map_faces_to_uv(bm, head_faces, 0.0, 0.5, 0.5, 1.0)

    # Spine & Exposed Ribs (UV Top-Right: [0.5, 1.0] x [0.5, 1.0])
    torso_faces = []
    p_spine = [
        Vector((0, 0.30, 1.70)),
        Vector((0, 0.15, 1.45)),
        Vector((0, 0.00, 1.15)),
        Vector((0, -0.10, 0.85)),
    ]
    for i in range(len(p_spine)-1):
        torso_faces.extend(create_extruded_cylinder(bm, p_spine[i], p_spine[i+1], 0.22 - i*0.02, 0.20 - i*0.02, 6))

    for i in range(4):
        z_rib = 1.60 - i * 0.15
        for side in (-1, 1):
            r_base = Vector((0, 0.20 - i*0.05, z_rib))
            r_mid = Vector((side * 0.28, 0.28 - i*0.05, z_rib - 0.04))
            r_end = Vector((side * 0.12, 0.35 - i*0.05, z_rib - 0.08))
            torso_faces.extend(create_extruded_cylinder(bm, r_base, r_mid, 0.03, 0.02, 4))
            torso_faces.extend(create_extruded_cylinder(bm, r_mid, r_end, 0.02, 0.015, 4))
    map_faces_to_uv(bm, torso_faces, 0.5, 0.5, 1.0, 1.0)

    # Spindly Limbs & Needle Claws (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    limb_faces = []
    for side in (-1, 1):
        # Spindly arms
        shoulder = Vector((side * 0.32, 0.20, 1.60))
        elbow = Vector((side * 0.65, 0.10, 1.05))
        wrist = Vector((side * 0.55, 0.40, 0.35))
        limb_faces.extend(create_extruded_cylinder(bm, shoulder, elbow, 0.08, 0.06, 5))
        limb_faces.extend(create_extruded_cylinder(bm, elbow, wrist, 0.06, 0.04, 5))
        for f in range(4):
            f_tip = wrist + Vector((side * (0.08 + f*0.04), 0.25 + f*0.05, -0.35))
            limb_faces.extend(create_extruded_cylinder(bm, wrist, f_tip, 0.025, 0.005, 4))
        # Crouched legs
        hip = Vector((side * 0.18, -0.10, 0.85))
        knee = Vector((side * 0.42, -0.35, 0.55))
        ankle = Vector((side * 0.35, 0.10, 0.20))
        foot = Vector((side * 0.32, 0.35, 0.0))
        limb_faces.extend(create_extruded_cylinder(bm, hip, knee, 0.09, 0.07, 5))
        limb_faces.extend(create_extruded_cylinder(bm, knee, ankle, 0.07, 0.05, 5))
        limb_faces.extend(create_extruded_cylinder(bm, ankle, foot, 0.05, 0.03, 5))
    map_faces_to_uv(bm, limb_faces, 0.0, 0.0, 0.5, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_PaleLurker", "tex_pale_lurker.png", "tex_pale_lurker_emit.png")
    return obj

# 2. CHASM STALKER (Arachnid Apex Predator)
def build_chasm_stalker():
    mesh = bpy.data.meshes.new("ChasmStalkerMesh")
    obj = bpy.data.objects.new("ChasmStalker", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> 8 cyan eyes & razor mandibles)
    head_mat = Matrix.Translation((0, 0.8, 0.85)) @ Matrix.Scale(0.38, 4, Vector((1,0,0))) @ Matrix.Scale(0.55, 4, Vector((0,1,0))) @ Matrix.Scale(0.32, 4, Vector((0,0,1)))
    head_faces = create_icosphere_faces(bm, head_mat, radius=1.0, subdivisions=2)
    map_faces_to_uv(bm, head_faces, 0.0, 0.5, 0.5, 1.0)

    # Dorsal Carapace & Abdomen (UV Top-Right: [0.5, 1.0] x [0.5, 1.0])
    torso_faces = []
    for y_pos, z_pos, rx, ry, rz in [
        (0.4, 0.95, 0.42, 0.35, 0.35),
        (0.0, 1.02, 0.50, 0.42, 0.38),
        (-0.45, 0.96, 0.44, 0.38, 0.35),
        (-0.85, 0.85, 0.36, 0.32, 0.30),
        (-1.20, 0.75, 0.28, 0.25, 0.24),
    ]:
        mat = Matrix.Translation((0, y_pos, z_pos)) @ Matrix.Scale(rx, 4, Vector((1,0,0))) @ Matrix.Scale(ry, 4, Vector((0,1,0))) @ Matrix.Scale(rz, 4, Vector((0,0,1)))
        torso_faces.extend(create_icosphere_faces(bm, mat, radius=1.0, subdivisions=2))
    map_faces_to_uv(bm, torso_faces, 0.5, 0.5, 1.0, 1.0)

    # 6 Jointed Legs + 2 Raptor Scythe Arms (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    limb_faces = []
    for side in (-1, 1):
        shoulder = Vector((side * 0.35, 0.55, 0.9))
        elbow = Vector((side * 0.75, 0.95, 1.25))
        wrist = Vector((side * 0.45, 1.45, 0.75))
        scythe_tip = Vector((side * 0.2, 1.55, 0.25))
        limb_faces.extend(create_extruded_cylinder(bm, shoulder, elbow, 0.10, 0.08, 6))
        limb_faces.extend(create_extruded_cylinder(bm, elbow, wrist, 0.08, 0.06, 6))
        limb_faces.extend(create_extruded_cylinder(bm, wrist, scythe_tip, 0.07, 0.01, 6))
    leg_coords = [
        (0.35, 0.30, 0.90, 0.95, 0.45, 1.35, 1.25, 0.55),
        (0.42, -0.05, 0.95, 1.15, -0.10, 1.45, 1.40, -0.20),
        (0.38, -0.40, 0.90, 1.05, -0.65, 1.30, 1.30, -0.80),
    ]
    for (ax, ay, az, kx, ky, kz, fx, fy) in leg_coords:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            limb_faces.extend(create_extruded_cylinder(bm, hip, knee, 0.08, 0.05, 6))
            limb_faces.extend(create_extruded_cylinder(bm, knee, foot, 0.05, 0.02, 6))
    map_faces_to_uv(bm, limb_faces, 0.0, 0.0, 0.5, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_ChasmStalker", "tex_chasm_stalker.png", "tex_chasm_stalker_emit.png")
    return obj

# 3. LITHIC CRAWLER (Basalt Crab)
def build_lithic_crawler():
    mesh = bpy.data.meshes.new("LithicCrawlerMesh")
    obj = bpy.data.objects.new("LithicCrawler", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> 4 amber eyes)
    head_mat = Matrix.Translation((0, 0.75, 0.50)) @ Matrix.Scale(0.42, 4, Vector((1,0,0))) @ Matrix.Scale(0.28, 4, Vector((0,1,0))) @ Matrix.Scale(0.24, 4, Vector((0,0,1)))
    head_faces = create_icosphere_faces(bm, head_mat, radius=1.0, subdivisions=2)
    map_faces_to_uv(bm, head_faces, 0.0, 0.5, 0.5, 1.0)

    # Dorsal Basalt Shell (UV Top-Right: [0.5, 1.0] x [0.5, 1.0])
    shell_mat = Matrix.Translation((0, 0, 0.55)) @ Matrix.Scale(0.95, 4, Vector((1,0,0))) @ Matrix.Scale(0.85, 4, Vector((0,1,0))) @ Matrix.Scale(0.48, 4, Vector((0,0,1)))
    shell_faces = create_icosphere_faces(bm, shell_mat, radius=1.0, subdivisions=2)
    map_faces_to_uv(bm, shell_faces, 0.5, 0.5, 1.0, 1.0)

    # 6 Legs (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    limb_faces = []
    legs = [
        (0.60, 0.40, 0.45, 1.10, 0.65, 0.65, 1.35, 0.75),
        (0.70, 0.00, 0.45, 1.25, 0.05, 0.68, 1.50, 0.10),
        (0.62, -0.40, 0.45, 1.15, -0.55, 0.62, 1.40, -0.65),
    ]
    for (ax, ay, az, kx, ky, kz, fx, fy) in legs:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            limb_faces.extend(create_extruded_cylinder(bm, hip, knee, 0.12, 0.09, 6))
            limb_faces.extend(create_extruded_cylinder(bm, knee, foot, 0.09, 0.04, 6))
    map_faces_to_uv(bm, limb_faces, 0.0, 0.0, 0.5, 0.5)

    # Pincers & Amethyst Spikes (UV Bottom-Right: [0.5, 1.0] x [0.0, 0.5])
    special_faces = []
    for ox, oy, oz, tx, ty, l, r in [
        (0.0, 0.1, 0.95, 0.0, 0.15, 0.55, 0.16),
        (0.28, 0.22, 0.88, 0.35, 0.45, 0.45, 0.14),
        (-0.25, 0.18, 0.90, -0.32, 0.38, 0.50, 0.15),
        (0.18, -0.22, 0.86, 0.25, -0.35, 0.40, 0.12),
        (-0.22, -0.25, 0.85, -0.30, -0.40, 0.42, 0.13),
    ]:
        special_faces.extend(create_extruded_cylinder(bm, Vector((ox, oy, oz)), Vector((ox+tx, oy+ty, oz+l)), r, 0.01, 6))
    for side in (-1, 1):
        shoulder = Vector((side * 0.45, 0.65, 0.50))
        elbow = Vector((side * 0.80, 0.95, 0.48))
        palm = Vector((side * 0.55, 1.25, 0.45))
        special_faces.extend(create_extruded_cylinder(bm, shoulder, elbow, 0.15, 0.12, 6))
        special_faces.extend(create_extruded_cylinder(bm, elbow, palm, 0.12, 0.18, 6))
        c1 = palm + Vector((side * 0.15, 0.35, 0.05))
        c2 = palm + Vector((-side * 0.10, 0.35, -0.05))
        special_faces.extend(create_extruded_cylinder(bm, palm, c1, 0.08, 0.02, 6))
        special_faces.extend(create_extruded_cylinder(bm, palm, c2, 0.07, 0.02, 6))
    map_faces_to_uv(bm, special_faces, 0.5, 0.0, 1.0, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_LithicCrawler", "tex_lithic_crawler.png", "tex_lithic_crawler_emit.png")
    return obj

# 4. MAGMA BASILISK (Reptilian Drake)
def build_magma_basilisk():
    mesh = bpy.data.meshes.new("MagmaBasiliskMesh")
    obj = bpy.data.objects.new("MagmaBasilisk", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head & Horns (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> Yellow slit eyes & magma fangs)
    head_mat = Matrix.Translation((0, 1.20, 0.72)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.55, 4, Vector((0,1,0))) @ Matrix.Scale(0.28, 4, Vector((0,0,1)))
    head_faces = create_icosphere_faces(bm, head_mat, radius=1.0, subdivisions=2)
    for side in (-1, 1):
        hb = Vector((side * 0.22, 1.15, 0.88))
        ht = Vector((side * 0.38, 0.85, 1.15))
        head_faces.extend(create_extruded_cylinder(bm, hb, ht, 0.08, 0.01, 6))
    map_faces_to_uv(bm, head_faces, 0.0, 0.5, 0.5, 1.0)

    # Dorsal Body & Spines (UV Top-Right: [0.5, 1.0] x [0.5, 1.0] -> Magma veins & scales)
    body_faces = []
    body_nodes = [
        (0.85, 0.72, 0.38, 0.40),
        (0.40, 0.75, 0.48, 0.45),
        (-0.10, 0.72, 0.52, 0.44),
        (-0.60, 0.65, 0.45, 0.38),
    ]
    for y, z, rx, rz in body_nodes:
        bmat = Matrix.Translation((0, y, z)) @ Matrix.Scale(rx, 4, Vector((1,0,0))) @ Matrix.Scale(0.42, 4, Vector((0,1,0))) @ Matrix.Scale(rz, 4, Vector((0,0,1)))
        body_faces.extend(create_icosphere_faces(bm, bmat, radius=1.0, subdivisions=2))
        sp_base = Vector((0, y, z + rz * 0.85))
        sp_tip = Vector((0, y - 0.12, z + rz + 0.25))
        body_faces.extend(create_extruded_cylinder(bm, sp_base, sp_tip, 0.08, 0.01, 5))
    map_faces_to_uv(bm, body_faces, 0.5, 0.5, 1.0, 1.0)

    # Muscular Clawed Legs (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    limb_faces = []
    for (ax, ay, az, kx, ky, kz, fx, fy) in [
        (0.48, 0.65, 0.68, 0.95, 0.75, 0.55, 1.05, 0.85),
        (0.48, -0.45, 0.65, 0.95, -0.55, 0.55, 1.05, -0.65),
    ]:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            limb_faces.extend(create_extruded_cylinder(bm, hip, knee, 0.15, 0.11, 6))
            limb_faces.extend(create_extruded_cylinder(bm, knee, foot, 0.11, 0.06, 6))
            for c_angle in (-0.25, 0.0, 0.25):
                c_dir = Vector((math.sin(c_angle), math.cos(c_angle), 0))
                limb_faces.extend(create_extruded_cylinder(bm, foot, foot + c_dir * 0.18, 0.04, 0.01, 4))
    map_faces_to_uv(bm, limb_faces, 0.0, 0.0, 0.5, 0.5)

    # Tail & Underbelly (UV Bottom-Right: [0.5, 1.0] x [0.0, 0.5])
    tail_faces = []
    p_prev = Vector((0, -0.85, 0.60))
    for t_idx in range(5):
        y_pos = -0.85 - (t_idx + 1) * 0.40
        z_pos = 0.60 - t_idx * 0.08 + 0.05 * math.sin(t_idx)
        p_curr = Vector((0.15 * math.sin(t_idx * 1.2), y_pos, z_pos))
        tail_faces.extend(create_extruded_cylinder(bm, p_prev, p_curr, 0.22 - t_idx * 0.035, 0.18 - t_idx * 0.035, 6))
        for side in (-1, 1):
            tail_faces.extend(create_extruded_cylinder(bm, p_curr, p_curr + Vector((side * 0.25, -0.1, 0.1)), 0.05, 0.01, 4))
        p_prev = p_curr
    map_faces_to_uv(bm, tail_faces, 0.5, 0.0, 1.0, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_MagmaBasilisk", "tex_magma_basilisk.png", "tex_magma_basilisk_emit.png")
    return obj

# 5. GEODE GOLEM (Subterranean Crystalline Brute)
def build_geode_golem():
    mesh = bpy.data.meshes.new("GeodeGolemMesh")
    obj = bpy.data.objects.new("GeodeGolem", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> Glowing amethyst mono-eye)
    head_mat = Matrix.Translation((0, 0.35, 2.10)) @ Matrix.Scale(0.35, 4, Vector((1,0,0))) @ Matrix.Scale(0.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.32, 4, Vector((0,0,1)))
    head_faces = create_cube_faces(bm, head_mat, size=1.0)
    map_faces_to_uv(bm, head_faces, 0.0, 0.5, 0.5, 1.0)

    # Torso with Geode Fissure Heart (UV Top-Right: [0.5, 1.0] x [0.5, 1.0])
    torso_mat = Matrix.Translation((0, 0.10, 1.45)) @ Matrix.Scale(0.85, 4, Vector((1,0,0))) @ Matrix.Scale(0.65, 4, Vector((0,1,0))) @ Matrix.Scale(0.95, 4, Vector((0,0,1)))
    torso_faces = create_cube_faces(bm, torso_mat, size=1.0)
    map_faces_to_uv(bm, torso_faces, 0.5, 0.5, 1.0, 1.0)

    # Massive Stone Arms & Knuckles (UV Bottom-Right: [0.5, 1.0] x [0.0, 0.5])
    arm_faces = []
    for side in (-1, 1):
        shoulder = Vector((side * 0.95, 0.10, 1.70))
        elbow = Vector((side * 1.15, 0.20, 1.10))
        fist = Vector((side * 1.05, 0.40, 0.45))
        arm_faces.extend(create_extruded_cylinder(bm, shoulder, elbow, 0.28, 0.24, 6))
        arm_faces.extend(create_extruded_cylinder(bm, elbow, fist, 0.24, 0.32, 6))
    map_faces_to_uv(bm, arm_faces, 0.5, 0.0, 1.0, 0.5)

    # Pillar Legs (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    leg_faces = []
    for side in (-1, 1):
        hip = Vector((side * 0.45, 0.0, 0.95))
        foot = Vector((side * 0.45, 0.10, 0.0))
        leg_faces.extend(create_extruded_cylinder(bm, hip, foot, 0.28, 0.32, 6))
    map_faces_to_uv(bm, leg_faces, 0.0, 0.0, 0.5, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_GeodeGolem", "tex_geode_golem.png", "tex_geode_golem_emit.png")
    return obj

# 6. FUNGAL STRIDER (Mycena Parasol Strider)
def build_fungal_strider():
    mesh = bpy.data.meshes.new("FungalStriderMesh")
    obj = bpy.data.objects.new("FungalStrider", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Parasol Mushroom Cap (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> Glowing cyan spore dots)
    cap_mat = Matrix.Translation((0, 0, 2.65)) @ Matrix.Scale(1.20, 4, Vector((1,0,0))) @ Matrix.Scale(1.20, 4, Vector((0,1,0))) @ Matrix.Scale(0.40, 4, Vector((0,0,1)))
    cap_faces = create_icosphere_faces(bm, cap_mat, radius=1.0, subdivisions=2)
    map_faces_to_uv(bm, cap_faces, 0.0, 0.5, 0.5, 1.0)

    # Under-Cap Spore Gills (UV Top-Right: [0.5, 1.0] x [0.5, 1.0])
    gill_mat = Matrix.Translation((0, 0, 2.45)) @ Matrix.Scale(1.05, 4, Vector((1,0,0))) @ Matrix.Scale(1.05, 4, Vector((0,1,0))) @ Matrix.Scale(0.15, 4, Vector((0,0,1)))
    gill_faces = create_icosphere_faces(bm, gill_mat, radius=1.0, subdivisions=2)
    map_faces_to_uv(bm, gill_faces, 0.5, 0.5, 1.0, 1.0)

    # Central Stalk & Spore Pods (UV Bottom-Right: [0.5, 1.0] x [0.0, 0.5])
    stalk_faces = []
    stalk_faces.extend(create_extruded_cylinder(bm, Vector((0,0,2.4)), Vector((0,0,1.5)), 0.25, 0.18, 6))
    for pod_z in (2.1, 1.8):
        for ang in (0.5, 2.2, 4.0):
            p_mat = Matrix.Translation((math.cos(ang)*0.25, math.sin(ang)*0.25, pod_z)) @ Matrix.Scale(0.12, 4, Vector((1,1,1)))
            stalk_faces.extend(create_icosphere_faces(bm, p_mat, radius=1.0, subdivisions=1))
    map_faces_to_uv(bm, stalk_faces, 0.5, 0.0, 1.0, 0.5)

    # 4 Slender Stilt Legs (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    leg_faces = []
    for ang in (math.pi*0.25, math.pi*0.75, math.pi*1.25, math.pi*1.75):
        hip = Vector((math.cos(ang)*0.25, math.sin(ang)*0.25, 1.5))
        knee = Vector((math.cos(ang)*0.95, math.sin(ang)*0.95, 1.1))
        foot = Vector((math.cos(ang)*0.85, math.sin(ang)*0.85, 0.0))
        leg_faces.extend(create_extruded_cylinder(bm, hip, knee, 0.07, 0.05, 5))
        leg_faces.extend(create_extruded_cylinder(bm, knee, foot, 0.05, 0.025, 5))
    map_faces_to_uv(bm, leg_faces, 0.0, 0.0, 0.5, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_FungalStrider", "tex_fungal_strider.png", "tex_fungal_strider_emit.png")
    return obj

# 7. WALL MIMIC (Disguised Rock Mimic with Gaping Maw)
def build_wall_mimic():
    mesh = bpy.data.meshes.new("WallMimicMesh")
    obj = bpy.data.objects.new("WallMimic", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Gaping Maw & Mineral Teeth (UV Top-Left: [0.0, 0.5] x [0.5, 1.0] -> Yellow eyes & bloody fangs)
    maw_mat = Matrix.Translation((0, 0.35, 0.70)) @ Matrix.Scale(0.48, 4, Vector((1,0,0))) @ Matrix.Scale(0.20, 4, Vector((0,1,0))) @ Matrix.Scale(0.40, 4, Vector((0,0,1)))
    maw_faces = create_cube_faces(bm, maw_mat, size=1.0)
    # Upper & lower fangs
    for x in (-0.35, -0.15, 0.05, 0.25):
        t_top = Vector((x, 0.42, 0.85))
        t_tip = Vector((x+0.05, 0.40, 0.65))
        maw_faces.extend(create_extruded_cylinder(bm, t_top, t_tip, 0.05, 0.01, 4))
        b_bot = Vector((x+0.08, 0.42, 0.55))
        b_tip = Vector((x+0.05, 0.40, 0.72))
        maw_faces.extend(create_extruded_cylinder(bm, b_bot, b_tip, 0.05, 0.01, 4))
    map_faces_to_uv(bm, maw_faces, 0.0, 0.5, 0.5, 1.0)

    # Cracked Rock Shell / Upper Jaw (UV Top-Right: [0.5, 1.0] x [0.5, 1.0])
    shell_mat = Matrix.Translation((0, -0.05, 0.85)) @ Matrix.Scale(0.85, 4, Vector((1,0,0))) @ Matrix.Scale(0.75, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
    shell_faces = create_cube_faces(bm, shell_mat, size=1.0)
    map_faces_to_uv(bm, shell_faces, 0.5, 0.5, 1.0, 1.0)

    # Prehensile Tendrils / Tongue (UV Bottom-Left: [0.0, 0.5] x [0.0, 0.5])
    tendril_faces = []
    t_prev = Vector((0, 0.30, 0.65))
    for seg in range(4):
        t_curr = Vector((0.15 * math.sin(seg*1.5), 0.55 + seg*0.35, 0.60 - seg*0.08))
        tendril_faces.extend(create_extruded_cylinder(bm, t_prev, t_curr, 0.12 - seg*0.02, 0.10 - seg*0.02, 6))
        t_prev = t_curr
    map_faces_to_uv(bm, tendril_faces, 0.0, 0.0, 0.5, 0.5)

    # Boulder Base (UV Bottom-Right: [0.5, 1.0] x [0.0, 0.5])
    base_mat = Matrix.Translation((0, 0, 0.25)) @ Matrix.Scale(0.95, 4, Vector((1,0,0))) @ Matrix.Scale(0.85, 4, Vector((0,1,0))) @ Matrix.Scale(0.35, 4, Vector((0,0,1)))
    base_faces = create_cube_faces(bm, base_mat, size=1.0)
    map_faces_to_uv(bm, base_faces, 0.5, 0.0, 1.0, 0.5)

    bm.to_mesh(mesh)
    bm.free()
    setup_pbr_material(obj, "M_WallMimic", "tex_wall_mimic.png", "tex_wall_mimic_emit.png")
    return obj

def render_model(obj, name):
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 45
    cam = bpy.data.objects.new("Cam", cam_data)
    
    # Adaptive camera position based on creature bounds
    z_center = 0.9
    cam_pos = Vector((2.8, 3.2, 2.0))
    if name == "fungal_strider":
        z_center = 1.6
        cam_pos = Vector((3.6, 4.2, 2.8))
    elif name == "pale_lurker":
        z_center = 1.1
        cam_pos = Vector((2.8, 3.4, 2.2))
    elif name == "geode_golem":
        z_center = 1.3
        cam_pos = Vector((3.2, 3.6, 2.3))

    cam.location = cam_pos
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    target = bpy.data.objects.new("Target", None)
    target.location = Vector((0, 0, z_center))
    bpy.context.collection.objects.link(target)

    tr = cam.constraints.new(type='TRACK_TO')
    tr.target = target
    tr.track_axis = 'TRACK_NEGATIVE_Z'
    tr.up_axis = 'UP_Y'

    # Key Light (Warm Cave Torchlight)
    l = bpy.data.lights.new("Light", type='POINT')
    l.energy = 850.0
    l.color = (1.0, 0.92, 0.82)
    lo = bpy.data.objects.new("Light", l)
    lo.location = Vector((2.2, 2.5, 2.5))
    bpy.context.collection.objects.link(lo)

    # Rim / Fill Light (Cool Subterranean Fog)
    l2 = bpy.data.lights.new("FillLight", type='POINT')
    l2.energy = 350.0
    l2.color = (0.6, 0.8, 1.0)
    lo2 = bpy.data.objects.new("FillLight", l2)
    lo2.location = Vector((-2.5, 1.5, 1.8))
    bpy.context.collection.objects.link(lo2)

    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    bpy.context.scene.render.resolution_x = 1024
    bpy.context.scene.render.resolution_y = 768
    out_png = os.path.join(OUT_SHOWCASE, f"render_{name}.png")
    bpy.context.scene.render.filepath = os.path.abspath(out_png)
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_png}")

def main():
    mobs = [
        ("pale_lurker", build_pale_lurker),
        ("chasm_stalker", build_chasm_stalker),
        ("lithic_crawler", build_lithic_crawler),
        ("magma_basilisk", build_magma_basilisk),
        ("geode_golem", build_geode_golem),
        ("fungal_strider", build_fungal_strider),
        ("wall_mimic", build_wall_mimic),
    ]
    for name, builder in mobs:
        reset_scene()
        print(f"--> Building bespoke UV horror mob: {name}...")
        obj = builder()
        out_glb = os.path.join(MODELS_DIR, f"{name}.glb")
        bpy.ops.export_scene.gltf(filepath=os.path.abspath(out_glb), export_format='GLB', export_apply=True)
        render_model(obj, name)

if __name__ == "__main__":
    main()
