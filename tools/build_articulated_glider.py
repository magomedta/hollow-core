
import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_extruded_segment(bm, start_pt, end_pt, radius_start, radius_end, segments=8):
    """Creates a smooth connecting cylinder between two 3D points."""
    dir_vec = (end_pt - start_pt)
    dist = dir_vec.length
    if dist < 0.001:
        return
    z_axis = Vector((0, 0, 1))
    rot_quat = z_axis.rotation_difference(dir_vec)
    center = (start_pt + end_pt) * 0.5
    matrix = Matrix.Translation(center) @ rot_quat.to_matrix().to_4x4()
    
    # Generate circular rings
    ring1 = []
    ring2 = []
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

# =========================================================================
# 1. CHASM STALKER (Segmented predatory arthropod with scythes & mandibles)
# =========================================================================
def build_chasm_stalker():
    mesh = bpy.data.meshes.new("ChasmStalkerMesh")
    obj = bpy.data.objects.new("ChasmStalker", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (Predatory skull)
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.35, matrix=Matrix.Translation((0, 0.8, 0.85)) @ Matrix.Scale(0.7, 4, Vector((1, 0, 0))) @ Matrix.Scale(1.3, 4, Vector((0, 1, 0))))
    
    # 2 Forward Mandibles
    for side in (-1, 1):
        p0 = Vector((side * 0.18, 1.1, 0.8))
        p1 = Vector((side * 0.28, 1.35, 0.72))
        p2 = Vector((side * 0.08, 1.45, 0.65))
        create_extruded_segment(bm, p0, p1, 0.06, 0.04, 6)
        create_extruded_segment(bm, p1, p2, 0.04, 0.01, 6)

    # Segmented Carapace / Thorax (3 overlapping dorsal plates with dorsal spines)
    for seg_idx, (y_pos, z_pos, rad_x, rad_y, rad_z) in enumerate([
        (0.4, 0.95, 0.42, 0.35, 0.35),
        (0.0, 1.02, 0.50, 0.42, 0.38),
        (-0.45, 0.96, 0.44, 0.38, 0.35),
    ]):
        mat = Matrix.Translation((0, y_pos, z_pos)) @ Matrix.Scale(rad_x, 4, Vector((1,0,0))) @ Matrix.Scale(rad_y, 4, Vector((0,1,0))) @ Matrix.Scale(rad_z, 4, Vector((0,0,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat)
        # Dorsal crest spine
        p_base = Vector((0, y_pos, z_pos + rad_z * 0.9))
        p_tip = Vector((0, y_pos - 0.1, z_pos + rad_z + 0.28))
        create_extruded_segment(bm, p_base, p_tip, 0.07, 0.01, 6)

    # Segmented Abdomen
    for seg_idx, (y_pos, z_pos, scale_val) in enumerate([
        (-0.85, 0.85, 0.36),
        (-1.20, 0.75, 0.28),
        (-1.50, 0.68, 0.18),
    ]):
        mat = Matrix.Translation((0, y_pos, z_pos)) @ Matrix.Scale(scale_val, 4, Vector((1,1,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat)

    # 2 Forward Raptorial Scythe Arms
    for side in (-1, 1):
        shoulder = Vector((side * 0.35, 0.55, 0.9))
        elbow = Vector((side * 0.75, 0.95, 1.25))
        wrist = Vector((side * 0.45, 1.45, 0.75))
        scythe_tip = Vector((side * 0.2, 1.55, 0.25))
        create_extruded_segment(bm, shoulder, elbow, 0.10, 0.08, 6)
        create_extruded_segment(bm, elbow, wrist, 0.08, 0.06, 6)
        create_extruded_segment(bm, wrist, scythe_tip, 0.07, 0.01, 6)

    # 6 Jointed Walking Legs touching Z=0
    leg_anchors = [
        (0.35, 0.30, 0.90, 0.95, 0.45, 1.35, 1.25, 0.55),
        (0.42, -0.05, 0.95, 1.15, -0.10, 1.45, 1.40, -0.20),
        (0.38, -0.40, 0.90, 1.05, -0.65, 1.30, 1.30, -0.80),
    ]
    for (ax, ay, az, kx, ky, kz, fx, fy) in leg_anchors:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            create_extruded_segment(bm, hip, knee, 0.08, 0.05, 6)
            create_extruded_segment(bm, knee, foot, 0.05, 0.02, 6)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 2. LITHIC CRAWLER (Basalt crab with amethyst geode cluster & heavy pincers)
# =========================================================================
def build_lithic_crawler():
    mesh = bpy.data.meshes.new("LithicCrawlerMesh")
    obj = bpy.data.objects.new("LithicCrawler", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Heavy faceted basalt dome carapace
    mat = Matrix.Translation((0, 0, 0.55)) @ Matrix.Scale(0.95, 4, Vector((1,0,0))) @ Matrix.Scale(0.85, 4, Vector((0,1,0))) @ Matrix.Scale(0.48, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat)

    # Amethyst Crystal Geode Clusters sprouting from back
    crystal_spikes = [
        (0.0, 0.1, 0.95, 0.0, 0.15, 0.55, 0.16),
        (0.28, 0.22, 0.88, 0.35, 0.45, 0.45, 0.14),
        (-0.25, 0.18, 0.90, -0.32, 0.38, 0.50, 0.15),
        (0.18, -0.22, 0.86, 0.25, -0.35, 0.40, 0.12),
        (-0.22, -0.25, 0.85, -0.30, -0.40, 0.42, 0.13),
        (0.0, -0.15, 0.92, 0.05, -0.20, 0.48, 0.15),
    ]
    for (ox, oy, oz, tx, ty, l, r) in crystal_spikes:
        base_pt = Vector((ox, oy, oz))
        tip_pt = base_pt + Vector((tx, ty, l))
        create_extruded_segment(bm, base_pt, tip_pt, r, 0.01, 6)

    # 2 Heavy Crushing Basalt Pincers in Front
    for side in (-1, 1):
        shoulder = Vector((side * 0.45, 0.65, 0.50))
        elbow = Vector((side * 0.80, 0.95, 0.48))
        palm = Vector((side * 0.55, 1.25, 0.45))
        create_extruded_segment(bm, shoulder, elbow, 0.15, 0.12, 6)
        create_extruded_segment(bm, elbow, palm, 0.12, 0.18, 6)
        # 2 pincer claws per claw
        claw1_tip = palm + Vector((side * 0.15, 0.35, 0.05))
        claw2_tip = palm + Vector((-side * 0.10, 0.35, -0.05))
        create_extruded_segment(bm, palm, claw1_tip, 0.08, 0.02, 6)
        create_extruded_segment(bm, palm, claw2_tip, 0.07, 0.02, 6)

    # 6 Basalt Articulated Legs planted on Z=0
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
            create_extruded_segment(bm, hip, knee, 0.12, 0.09, 6)
            create_extruded_segment(bm, knee, foot, 0.09, 0.04, 6)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 3. CRYO WISP (Multi-faceted icosahedron ice core + 8 orbiting shards)
# =========================================================================
def build_cryo_wisp():
    mesh = bpy.data.meshes.new("CryoWispMesh")
    obj = bpy.data.objects.new("CryoWisp", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Central faceted crystalline core
    mat_core = Matrix.Translation((0, 0, 1.25)) @ Matrix.Scale(0.55, 4, Vector((1,1,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=mat_core)

    # Inner dense ice seed
    mat_seed = Matrix.Translation((0, 0, 1.25)) @ Matrix.Scale(0.28, 4, Vector((1,1,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat_seed)

    # 8 Orbiting Crystalline Permafrost Shards
    for i in range(8):
        angle = (2.0 * math.pi * i) / 8.0
        r = 0.95 + 0.15 * math.sin(i * 1.7)
        z = 1.25 + 0.35 * math.cos(i * 2.1)
        sx = r * math.cos(angle)
        sy = r * math.sin(angle)
        p_base = Vector((sx, sy, z - 0.25))
        p_center = Vector((sx, sy, z))
        p_tip = Vector((sx, sy, z + 0.35))
        create_extruded_segment(bm, p_base, p_center, 0.02, 0.11, 5)
        create_extruded_segment(bm, p_center, p_tip, 0.11, 0.01, 5)

    # Trailing Frost Ice Tail
    p_last = Vector((0, 0, 0.85))
    for t_idx in range(5):
        curl_x = 0.12 * math.sin(t_idx * 1.3)
        curl_y = 0.10 * math.cos(t_idx * 1.5)
        p_next = Vector((curl_x, curl_y, 0.85 - (t_idx + 1) * 0.16))
        create_extruded_segment(bm, p_last, p_next, 0.10 - t_idx * 0.018, 0.08 - t_idx * 0.016, 6)
        p_last = p_next

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 4. MAGMA BASILISK (Quadruped volcanic drake with horned skull & tail)
# =========================================================================
def build_magma_basilisk():
    mesh = bpy.data.meshes.new("MagmaBasiliskMesh")
    obj = bpy.data.objects.new("MagmaBasilisk", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (Horned reptilian skull)
    head_mat = Matrix.Translation((0, 1.20, 0.72)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.55, 4, Vector((0,1,0))) @ Matrix.Scale(0.28, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=head_mat)

    # Horns
    for side in (-1, 1):
        hb = Vector((side * 0.22, 1.15, 0.88))
        ht = Vector((side * 0.38, 0.85, 1.15))
        create_extruded_segment(bm, hb, ht, 0.08, 0.01, 6)

    # Fanged Lower Jaw
    jaw_mat = Matrix.Translation((0, 1.30, 0.55)) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.40, 4, Vector((0,1,0))) @ Matrix.Scale(0.12, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=jaw_mat)

    # Neck & Muscular Torso Segments
    body_nodes = [
        (0.85, 0.72, 0.38, 0.40),
        (0.40, 0.75, 0.48, 0.45),
        (-0.10, 0.72, 0.52, 0.44),
        (-0.60, 0.65, 0.45, 0.38),
    ]
    for seg_idx, (y, z, rx, rz) in enumerate(body_nodes):
        bmat = Matrix.Translation((0, y, z)) @ Matrix.Scale(rx, 4, Vector((1,0,0))) @ Matrix.Scale(0.42, 4, Vector((0,1,0))) @ Matrix.Scale(rz, 4, Vector((0,0,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=bmat)
        # Obsidian dorsal spines along spine
        sp_base = Vector((0, y, z + rz * 0.85))
        sp_tip = Vector((0, y - 0.12, z + rz + 0.25))
        create_extruded_segment(bm, sp_base, sp_tip, 0.08, 0.01, 5)

    # 4 Muscular Reptilian Legs planted on Z=0
    leg_coords = [
        (0.48, 0.65, 0.68, 0.95, 0.75, 0.55, 1.05, 0.85),   # Front Left
        (0.48, -0.45, 0.65, 0.95, -0.55, 0.55, 1.05, -0.65), # Rear Left
    ]
    for (ax, ay, az, kx, ky, kz, fx, fy) in leg_coords:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            create_extruded_segment(bm, hip, knee, 0.15, 0.11, 6)
            create_extruded_segment(bm, knee, foot, 0.11, 0.06, 6)
            # Claws
            for c_angle in (-0.25, 0.0, 0.25):
                c_dir = Vector((math.sin(c_angle), math.cos(c_angle), 0))
                c_tip = foot + c_dir * 0.18
                create_extruded_segment(bm, foot, c_tip, 0.04, 0.01, 4)

    # Spiked Articulated Tail
    p_prev = Vector((0, -0.85, 0.60))
    for t_idx in range(5):
        y_pos = -0.85 - (t_idx + 1) * 0.40
        z_pos = 0.60 - t_idx * 0.08 + 0.05 * math.sin(t_idx)
        x_pos = 0.15 * math.sin(t_idx * 1.2)
        p_curr = Vector((x_pos, y_pos, z_pos))
        create_extruded_segment(bm, p_prev, p_curr, 0.22 - t_idx * 0.035, 0.18 - t_idx * 0.035, 6)
        # Tail side spike
        for side in (-1, 1):
            sp_tip = p_curr + Vector((side * 0.25, -0.1, 0.1))
            create_extruded_segment(bm, p_curr, sp_tip, 0.05, 0.01, 4)
        p_prev = p_curr

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 5. FUNGAL STRIDER (Mycena strider with parasol cap & tall stilt legs)
# =========================================================================
def build_fungal_strider():
    mesh = bpy.data.meshes.new("FungalStriderMesh")
    obj = bpy.data.objects.new("FungalStrider", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Parasol Mushroom Cap (Wide wavy dome)
    cap_mat = Matrix.Translation((0, 0, 2.25)) @ Matrix.Scale(1.35, 4, Vector((1,0,0))) @ Matrix.Scale(1.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0, matrix=cap_mat)

    # Under-cap Spore Gills Hub
    gills_mat = Matrix.Translation((0, 0, 2.05)) @ Matrix.Scale(1.10, 4, Vector((1,0,0))) @ Matrix.Scale(1.10, 4, Vector((0,1,0))) @ Matrix.Scale(0.15, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=gills_mat)

    # Central Stem / Torso
    p_top = Vector((0, 0, 2.10))
    p_bot = Vector((0, 0, 1.55))
    create_extruded_segment(bm, p_top, p_bot, 0.35, 0.28, 8)

    # Hanging Spore Tendrils
    for i in range(8):
        angle = (2.0 * math.pi * i) / 8.0
        rad = 0.75 + 0.15 * math.sin(i * 2.3)
        t_base = Vector((rad * math.cos(angle), rad * math.sin(angle), 2.05))
        t_tip = Vector((rad * math.cos(angle) * 0.8, rad * math.sin(angle) * 0.8, 1.25 - 0.2 * (i % 3)))
        create_extruded_segment(bm, t_base, t_tip, 0.05, 0.01, 5)

    # 4 Tall Arched Mycelium Stilt Legs planted on Z=0
    for i in range(4):
        angle = (math.pi / 4.0) + (i * math.pi / 2.0)
        hip = Vector((0.25 * math.cos(angle), 0.25 * math.sin(angle), 1.65))
        knee = Vector((1.05 * math.cos(angle), 1.05 * math.sin(angle), 1.95))
        foot = Vector((1.25 * math.cos(angle), 1.25 * math.sin(angle), 0.0))
        create_extruded_segment(bm, hip, knee, 0.12, 0.09, 6)
        create_extruded_segment(bm, knee, foot, 0.09, 0.04, 6)
        # Root claws spreading on ground
        for root_rot in (-0.4, 0.4):
            root_dir = Vector((math.cos(angle + root_rot), math.sin(angle + root_rot), 0))
            root_tip = foot + root_dir * 0.25
            create_extruded_segment(bm, foot, root_tip, 0.04, 0.01, 4)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 6. GEODE GOLEM (Precursor stone guardian with boulder fists & runes)
# =========================================================================
def build_geode_golem():
    mesh = bpy.data.meshes.new("GeodeGolemMesh")
    obj = bpy.data.objects.new("GeodeGolem", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Monolith Head with Visor Slit
    head_mat = Matrix.Translation((0, 0, 2.35)) @ Matrix.Scale(0.38, 4, Vector((1,0,0))) @ Matrix.Scale(0.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.32, 4, Vector((0,0,1)))
    bmesh.ops.create_cube(bm, size=1.0, matrix=head_mat)

    # Massive Chiseled Masonry Torso
    torso_mat = Matrix.Translation((0, 0, 1.70)) @ Matrix.Scale(0.95, 4, Vector((1,0,0))) @ Matrix.Scale(0.65, 4, Vector((0,1,0))) @ Matrix.Scale(0.85, 4, Vector((0,0,1)))
    bmesh.ops.create_cube(bm, size=1.0, matrix=torso_mat)

    # Shoulder Pauldrons
    for side in (-1, 1):
        p_mat = Matrix.Translation((side * 0.78, 0, 2.05)) @ Matrix.Scale(0.45, 4, Vector((1,0,0))) @ Matrix.Scale(0.48, 4, Vector((0,1,0))) @ Matrix.Scale(0.38, 4, Vector((0,0,1)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=p_mat)

    # Arm Segments & Boulder Fists
    for side in (-1, 1):
        shoulder = Vector((side * 0.75, 0, 1.85))
        elbow = Vector((side * 0.95, 0.10, 1.25))
        wrist = Vector((side * 0.85, 0.25, 0.65))
        create_extruded_segment(bm, shoulder, elbow, 0.22, 0.19, 6)
        create_extruded_segment(bm, elbow, wrist, 0.19, 0.25, 6)
        # Heavy boulder fist
        fist_mat = Matrix.Translation(wrist) @ Matrix.Scale(0.32, 4, Vector((1,1,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=fist_mat)

    # Pelvis Block
    pelvis_mat = Matrix.Translation((0, 0, 1.10)) @ Matrix.Scale(0.72, 4, Vector((1,0,0))) @ Matrix.Scale(0.52, 4, Vector((0,1,0))) @ Matrix.Scale(0.35, 4, Vector((0,0,1)))
    bmesh.ops.create_cube(bm, size=1.0, matrix=pelvis_mat)

    # 2 Pillar Masonry Legs planted on Z=0
    for side in (-1, 1):
        hip = Vector((side * 0.38, 0, 1.00))
        knee = Vector((side * 0.40, -0.05, 0.55))
        ankle = Vector((side * 0.42, 0, 0.15))
        create_extruded_segment(bm, hip, knee, 0.24, 0.21, 6)
        create_extruded_segment(bm, knee, ankle, 0.21, 0.23, 6)
        # Flat stone foot slab on Z=0
        foot_mat = Matrix.Translation((side * 0.42, 0.08, 0.10)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.48, 4, Vector((0,1,0))) @ Matrix.Scale(0.18, 4, Vector((0,0,1)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=foot_mat)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 7. NEW: ABYSSAL GLIDER (Пещерный Крылан / Flying cave gargoyle predator)
# =========================================================================
def build_abyssal_glider():
    mesh = bpy.data.meshes.new("AbyssalGliderMesh")
    obj = bpy.data.objects.new("AbyssalGlider", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (Bat skull with prominent echolocating ears)
    head_mat = Matrix.Translation((0, 0.45, 1.35)) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.32, 4, Vector((0,1,0))) @ Matrix.Scale(0.22, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=head_mat)

    # Pointed Echolocating Ears
    for side in (-1, 1):
        ear_base = Vector((side * 0.18, 0.40, 1.45))
        ear_tip = Vector((side * 0.32, 0.35, 1.78))
        create_extruded_segment(bm, ear_base, ear_tip, 0.08, 0.01, 5)

    # Torso & Ribcage
    torso_mat = Matrix.Translation((0, 0.10, 1.15)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.26, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=torso_mat)

    # Broad Bat-Like Wings
    for side in (-1, 1):
        shoulder = Vector((side * 0.22, 0.15, 1.25))
        elbow = Vector((side * 0.85, 0.20, 1.40))
        wrist = Vector((side * 1.55, 0.10, 1.48))
        create_extruded_segment(bm, shoulder, elbow, 0.09, 0.07, 6)
        create_extruded_segment(bm, elbow, wrist, 0.07, 0.05, 6)

        # 3 Wing Finger Struts
        f1_tip = wrist + Vector((side * 0.65, 0.30, 0.20))
        f2_tip = wrist + Vector((side * 0.55, -0.20, -0.45))
        f3_tip = wrist + Vector((side * 0.20, -0.45, -0.65))
        create_extruded_segment(bm, wrist, f1_tip, 0.04, 0.01, 4)
        create_extruded_segment(bm, wrist, f2_tip, 0.04, 0.01, 4)
        create_extruded_segment(bm, wrist, f3_tip, 0.04, 0.01, 4)

        # Wing Membrane connecting struts
        v_wrist = bm.verts.new(wrist)
        v_f1 = bm.verts.new(f1_tip)
        v_f2 = bm.verts.new(f2_tip)
        v_f3 = bm.verts.new(f3_tip)
        v_torso = bm.verts.new(Vector((side * 0.18, -0.10, 0.95)))
        bm.faces.new([v_wrist, v_f1, v_f2])
        bm.faces.new([v_wrist, v_f2, v_f3])
        bm.faces.new([v_wrist, v_f3, v_torso])

    # Hanging Gripping Talons
    for side in (-1, 1):
        hip = Vector((side * 0.15, -0.05, 0.85))
        knee = Vector((side * 0.20, -0.15, 0.55))
        foot = Vector((side * 0.18, -0.10, 0.25))
        create_extruded_segment(bm, hip, knee, 0.07, 0.05, 5)
        create_extruded_segment(bm, knee, foot, 0.05, 0.03, 5)
        for c in range(3):
            c_tip = foot + Vector((0.08 * (c - 1), 0.10, -0.12))
            create_extruded_segment(bm, foot, c_tip, 0.03, 0.01, 4)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 8. NEW: DEEP CAVE WYRM (Пещерный Червь / Segmented burrower with fanged maw)
# =========================================================================
def build_cave_wyrm():
    mesh = bpy.data.meshes.new("CaveWyrmMesh")
    obj = bpy.data.objects.new("CaveWyrm", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Dynamic Serpentine / Burrowing Arched Pose
    # Head at (0, 1.2, 0.8), curving down and back
    num_segs = 9
    pts = [
        Vector((0.0, 1.20, 0.85)),   # Head
        Vector((0.25, 0.85, 0.95)),
        Vector((0.35, 0.40, 0.80)),
        Vector((0.15, -0.05, 0.55)),
        Vector((-0.18, -0.45, 0.40)),
        Vector((-0.30, -0.85, 0.32)),
        Vector((-0.15, -1.25, 0.25)),
        Vector((0.08, -1.60, 0.18)),
        Vector((0.0, -1.95, 0.08)),   # Tail tip
    ]
    radii = [0.42, 0.45, 0.46, 0.44, 0.40, 0.35, 0.28, 0.20, 0.08]

    for i in range(num_segs - 1):
        create_extruded_segment(bm, pts[i], pts[i+1], radii[i], radii[i+1], segments=10)

    # Circular Fanged Maw at pts[0]
    head_center = pts[0]
    head_forward = Vector((0, 1, -0.2)).normalized()
    head_up = Vector((0, 0.2, 1)).normalized()
    head_right = head_forward.cross(head_up).normalized()

    # 12 Razor Teeth in Maw
    for t_idx in range(12):
        angle = (2.0 * math.pi * t_idx) / 12.0
        r_pos = head_center + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.34
        t_tip = head_center + head_forward * 0.22 + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.18
        create_extruded_segment(bm, r_pos, t_tip, 0.05, 0.01, 4)

    # 6 Sensory Facial Barbels
    for b_idx in range(6):
        angle = (2.0 * math.pi * b_idx) / 6.0
        b_base = head_center + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.42
        b_tip = b_base + head_forward * 0.35 + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.30
        create_extruded_segment(bm, b_base, b_tip, 0.04, 0.01, 4)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 9. NEW: ACID SPORE-SPITTER (Кислотный Споровик / Rooted plant-fungal trap)
# =========================================================================
def build_spore_spitter():
    mesh = bpy.data.meshes.new("SporeSpitterMesh")
    obj = bpy.data.objects.new("SporeSpitter", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Rooted Ground Pedestal
    ped_mat = Matrix.Translation((0, 0, 0.25)) @ Matrix.Scale(0.65, 4, Vector((1,0,0))) @ Matrix.Scale(0.65, 4, Vector((0,1,0))) @ Matrix.Scale(0.25, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=ped_mat)

    # 4 Woody Anchor Roots spreading into ground Z=0
    for i in range(4):
        angle = i * (math.pi / 2.0)
        r_base = Vector((0.45 * math.cos(angle), 0.45 * math.sin(angle), 0.25))
        r_mid = Vector((0.95 * math.cos(angle), 0.95 * math.sin(angle), 0.15))
        r_tip = Vector((1.30 * math.cos(angle), 1.30 * math.sin(angle), 0.0))
        create_extruded_segment(bm, r_base, r_mid, 0.12, 0.08, 5)
        create_extruded_segment(bm, r_mid, r_tip, 0.08, 0.02, 5)

    # 5 Protective Organic Leaf Petals cupping bulb
    for i in range(5):
        angle = (2.0 * math.pi * i) / 5.0
        p_base = Vector((0.35 * math.cos(angle), 0.35 * math.sin(angle), 0.35))
        p_mid = Vector((0.75 * math.cos(angle), 0.75 * math.sin(angle), 0.75))
        p_tip = Vector((0.55 * math.cos(angle), 0.55 * math.sin(angle), 1.35))
        create_extruded_segment(bm, p_base, p_mid, 0.15, 0.12, 5)
        create_extruded_segment(bm, p_mid, p_tip, 0.12, 0.02, 5)

    # Swollen Translucent Acid Sac (Central bulb)
    sac_mat = Matrix.Translation((0, 0, 0.95)) @ Matrix.Scale(0.55, 4, Vector((1,0,0))) @ Matrix.Scale(0.55, 4, Vector((0,1,0))) @ Matrix.Scale(0.70, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=sac_mat)

    # Acidic Discharge Nozzle (Maw orifice)
    n_base = Vector((0, 0, 1.45))
    n_tip = Vector((0, 0, 1.85))
    create_extruded_segment(bm, n_base, n_tip, 0.28, 0.18, 8)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# MAIN EXPORT ROUTINE
# =========================================================================
def main():
    MODELS_DIR = "hollow_core/models"
    TEX_DIR = "hollow_core/textures/mobs"
    os.makedirs(MODELS_DIR, exist_ok=True)

    mob_configs = [
        ("chasm_stalker", build_chasm_stalker, "tex_stalker_pixel.png", "tex_stalker_pixel_emit.png"),
        ("lithic_crawler", build_lithic_crawler, "tex_crawler_pixel.png", "tex_crawler_pixel_emit.png"),
        ("cryo_wisp", build_cryo_wisp, "tex_cryo_pixel.png", "tex_cryo_pixel_emit.png"),
        ("magma_basilisk", build_magma_basilisk, "tex_magma_pixel.png", "tex_magma_pixel_emit.png"),
        ("fungal_strider", build_fungal_strider, "tex_fungal_pixel.png", "tex_fungal_pixel_emit.png"),
        ("geode_golem", build_geode_golem, "tex_golem_pixel.png", "tex_golem_pixel_emit.png"),
        ("abyssal_glider", build_abyssal_glider, "tex_glider_pixel.png", "tex_glider_pixel_emit.png"),
        ("cave_wyrm", build_cave_wyrm, "tex_wyrm_pixel.png", "tex_wyrm_pixel_emit.png"),
        ("spore_spitter", build_spore_spitter, "tex_spitter_pixel.png", "tex_spitter_pixel_emit.png"),
    ]

    for name, builder_fn, base_tex, emit_tex in mob_configs:
        print(f"--> Building and exporting {name}...")
        reset_scene()
        obj = builder_fn()
        apply_smart_uv(obj)

        base_path = os.path.join(TEX_DIR, base_tex)
        emit_path = os.path.join(TEX_DIR, emit_tex) if emit_tex else None
        setup_pixel_pbr_material(obj, f"M_{name}", base_path, emit_path)

        out_glb = os.path.join(MODELS_DIR, f"{name}.glb")
        bpy.ops.export_scene.gltf(
            filepath=os.path.abspath(out_glb),
            export_format='GLB',
            use_selection=False,
            export_apply=True
        )
        print(f"Exported: {out_glb}")

if __name__ == "__main__":
    main()
def apply_smart_uv(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')


def setup_pixel_pbr_material(obj, mat_name, base_tex_path, emit_tex_path=None, emit_strength=2.5, roughness=0.6):
    mat = bpy.data.materials.new(name=mat_name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = roughness
    if 'Specular IOR Level' in bsdf.inputs:
        bsdf.inputs['Specular IOR Level'].default_value = 0.25
    elif 'Specular' in bsdf.inputs:
        bsdf.inputs['Specular'].default_value = 0.25

    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    # Base Color Texture (Closest / Pixel-Art Filter)
    if os.path.exists(base_tex_path):
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = bpy.data.images.load(os.path.abspath(base_tex_path))
        tex_node.interpolation = 'Closest'  # Enforce crisp in-game pixel art style
        links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

    # Emission Texture
    if emit_tex_path and os.path.exists(emit_tex_path):
        emit_node = nodes.new(type='ShaderNodeTexImage')
        emit_node.image = bpy.data.images.load(os.path.abspath(emit_tex_path))
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

def apply_smart_uv(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')

def create_extruded_segment(bm, start_pt, end_pt, radius_start, radius_end, segments=8):
    """Creates a smooth connecting cylinder between two 3D points."""
    dir_vec = (end_pt - start_pt)
    dist = dir_vec.length
    if dist < 0.001:
        return
    z_axis = Vector((0, 0, 1))
    rot_quat = z_axis.rotation_difference(dir_vec)
    center = (start_pt + end_pt) * 0.5
    matrix = Matrix.Translation(center) @ rot_quat.to_matrix().to_4x4()
    
    # Generate circular rings
    ring1 = []
    ring2 = []
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

# =========================================================================
# 1. CHASM STALKER (Segmented predatory arthropod with scythes & mandibles)
# =========================================================================
def build_chasm_stalker():
    mesh = bpy.data.meshes.new("ChasmStalkerMesh")
    obj = bpy.data.objects.new("ChasmStalker", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (Predatory skull)
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.35, matrix=Matrix.Translation((0, 0.8, 0.85)) @ Matrix.Scale(0.7, 4, Vector((1, 0, 0))) @ Matrix.Scale(1.3, 4, Vector((0, 1, 0))))
    
    # 2 Forward Mandibles
    for side in (-1, 1):
        p0 = Vector((side * 0.18, 1.1, 0.8))
        p1 = Vector((side * 0.28, 1.35, 0.72))
        p2 = Vector((side * 0.08, 1.45, 0.65))
        create_extruded_segment(bm, p0, p1, 0.06, 0.04, 6)
        create_extruded_segment(bm, p1, p2, 0.04, 0.01, 6)

    # Segmented Carapace / Thorax (3 overlapping dorsal plates with dorsal spines)
    for seg_idx, (y_pos, z_pos, rad_x, rad_y, rad_z) in enumerate([
        (0.4, 0.95, 0.42, 0.35, 0.35),
        (0.0, 1.02, 0.50, 0.42, 0.38),
        (-0.45, 0.96, 0.44, 0.38, 0.35),
    ]):
        mat = Matrix.Translation((0, y_pos, z_pos)) @ Matrix.Scale(rad_x, 4, Vector((1,0,0))) @ Matrix.Scale(rad_y, 4, Vector((0,1,0))) @ Matrix.Scale(rad_z, 4, Vector((0,0,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat)
        # Dorsal crest spine
        p_base = Vector((0, y_pos, z_pos + rad_z * 0.9))
        p_tip = Vector((0, y_pos - 0.1, z_pos + rad_z + 0.28))
        create_extruded_segment(bm, p_base, p_tip, 0.07, 0.01, 6)

    # Segmented Abdomen
    for seg_idx, (y_pos, z_pos, scale_val) in enumerate([
        (-0.85, 0.85, 0.36),
        (-1.20, 0.75, 0.28),
        (-1.50, 0.68, 0.18),
    ]):
        mat = Matrix.Translation((0, y_pos, z_pos)) @ Matrix.Scale(scale_val, 4, Vector((1,1,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat)

    # 2 Forward Raptorial Scythe Arms
    for side in (-1, 1):
        shoulder = Vector((side * 0.35, 0.55, 0.9))
        elbow = Vector((side * 0.75, 0.95, 1.25))
        wrist = Vector((side * 0.45, 1.45, 0.75))
        scythe_tip = Vector((side * 0.2, 1.55, 0.25))
        create_extruded_segment(bm, shoulder, elbow, 0.10, 0.08, 6)
        create_extruded_segment(bm, elbow, wrist, 0.08, 0.06, 6)
        create_extruded_segment(bm, wrist, scythe_tip, 0.07, 0.01, 6)

    # 6 Jointed Walking Legs touching Z=0
    leg_anchors = [
        (0.35, 0.30, 0.90, 0.95, 0.45, 1.35, 1.25, 0.55),
        (0.42, -0.05, 0.95, 1.15, -0.10, 1.45, 1.40, -0.20),
        (0.38, -0.40, 0.90, 1.05, -0.65, 1.30, 1.30, -0.80),
    ]
    for (ax, ay, az, kx, ky, kz, fx, fy) in leg_anchors:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            create_extruded_segment(bm, hip, knee, 0.08, 0.05, 6)
            create_extruded_segment(bm, knee, foot, 0.05, 0.02, 6)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 2. LITHIC CRAWLER (Basalt crab with amethyst geode cluster & heavy pincers)
# =========================================================================
def build_lithic_crawler():
    mesh = bpy.data.meshes.new("LithicCrawlerMesh")
    obj = bpy.data.objects.new("LithicCrawler", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Heavy faceted basalt dome carapace
    mat = Matrix.Translation((0, 0, 0.55)) @ Matrix.Scale(0.95, 4, Vector((1,0,0))) @ Matrix.Scale(0.85, 4, Vector((0,1,0))) @ Matrix.Scale(0.48, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat)

    # Amethyst Crystal Geode Clusters sprouting from back
    crystal_spikes = [
        (0.0, 0.1, 0.95, 0.0, 0.15, 0.55, 0.16),
        (0.28, 0.22, 0.88, 0.35, 0.45, 0.45, 0.14),
        (-0.25, 0.18, 0.90, -0.32, 0.38, 0.50, 0.15),
        (0.18, -0.22, 0.86, 0.25, -0.35, 0.40, 0.12),
        (-0.22, -0.25, 0.85, -0.30, -0.40, 0.42, 0.13),
        (0.0, -0.15, 0.92, 0.05, -0.20, 0.48, 0.15),
    ]
    for (ox, oy, oz, tx, ty, l, r) in crystal_spikes:
        base_pt = Vector((ox, oy, oz))
        tip_pt = base_pt + Vector((tx, ty, l))
        create_extruded_segment(bm, base_pt, tip_pt, r, 0.01, 6)

    # 2 Heavy Crushing Basalt Pincers in Front
    for side in (-1, 1):
        shoulder = Vector((side * 0.45, 0.65, 0.50))
        elbow = Vector((side * 0.80, 0.95, 0.48))
        palm = Vector((side * 0.55, 1.25, 0.45))
        create_extruded_segment(bm, shoulder, elbow, 0.15, 0.12, 6)
        create_extruded_segment(bm, elbow, palm, 0.12, 0.18, 6)
        # 2 pincer claws per claw
        claw1_tip = palm + Vector((side * 0.15, 0.35, 0.05))
        claw2_tip = palm + Vector((-side * 0.10, 0.35, -0.05))
        create_extruded_segment(bm, palm, claw1_tip, 0.08, 0.02, 6)
        create_extruded_segment(bm, palm, claw2_tip, 0.07, 0.02, 6)

    # 6 Basalt Articulated Legs planted on Z=0
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
            create_extruded_segment(bm, hip, knee, 0.12, 0.09, 6)
            create_extruded_segment(bm, knee, foot, 0.09, 0.04, 6)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 3. CRYO WISP (Multi-faceted icosahedron ice core + 8 orbiting shards)
# =========================================================================
def build_cryo_wisp():
    mesh = bpy.data.meshes.new("CryoWispMesh")
    obj = bpy.data.objects.new("CryoWisp", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Central faceted crystalline core
    mat_core = Matrix.Translation((0, 0, 1.25)) @ Matrix.Scale(0.55, 4, Vector((1,1,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=mat_core)

    # Inner dense ice seed
    mat_seed = Matrix.Translation((0, 0, 1.25)) @ Matrix.Scale(0.28, 4, Vector((1,1,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=mat_seed)

    # 8 Orbiting Crystalline Permafrost Shards
    for i in range(8):
        angle = (2.0 * math.pi * i) / 8.0
        r = 0.95 + 0.15 * math.sin(i * 1.7)
        z = 1.25 + 0.35 * math.cos(i * 2.1)
        sx = r * math.cos(angle)
        sy = r * math.sin(angle)
        p_base = Vector((sx, sy, z - 0.25))
        p_center = Vector((sx, sy, z))
        p_tip = Vector((sx, sy, z + 0.35))
        create_extruded_segment(bm, p_base, p_center, 0.02, 0.11, 5)
        create_extruded_segment(bm, p_center, p_tip, 0.11, 0.01, 5)

    # Trailing Frost Ice Tail
    p_last = Vector((0, 0, 0.85))
    for t_idx in range(5):
        curl_x = 0.12 * math.sin(t_idx * 1.3)
        curl_y = 0.10 * math.cos(t_idx * 1.5)
        p_next = Vector((curl_x, curl_y, 0.85 - (t_idx + 1) * 0.16))
        create_extruded_segment(bm, p_last, p_next, 0.10 - t_idx * 0.018, 0.08 - t_idx * 0.016, 6)
        p_last = p_next

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 4. MAGMA BASILISK (Quadruped volcanic drake with horned skull & tail)
# =========================================================================
def build_magma_basilisk():
    mesh = bpy.data.meshes.new("MagmaBasiliskMesh")
    obj = bpy.data.objects.new("MagmaBasilisk", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (Horned reptilian skull)
    head_mat = Matrix.Translation((0, 1.20, 0.72)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.55, 4, Vector((0,1,0))) @ Matrix.Scale(0.28, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=head_mat)

    # Horns
    for side in (-1, 1):
        hb = Vector((side * 0.22, 1.15, 0.88))
        ht = Vector((side * 0.38, 0.85, 1.15))
        create_extruded_segment(bm, hb, ht, 0.08, 0.01, 6)

    # Fanged Lower Jaw
    jaw_mat = Matrix.Translation((0, 1.30, 0.55)) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.40, 4, Vector((0,1,0))) @ Matrix.Scale(0.12, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=jaw_mat)

    # Neck & Muscular Torso Segments
    body_nodes = [
        (0.85, 0.72, 0.38, 0.40),
        (0.40, 0.75, 0.48, 0.45),
        (-0.10, 0.72, 0.52, 0.44),
        (-0.60, 0.65, 0.45, 0.38),
    ]
    for seg_idx, (y, z, rx, rz) in enumerate(body_nodes):
        bmat = Matrix.Translation((0, y, z)) @ Matrix.Scale(rx, 4, Vector((1,0,0))) @ Matrix.Scale(0.42, 4, Vector((0,1,0))) @ Matrix.Scale(rz, 4, Vector((0,0,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=bmat)
        # Obsidian dorsal spines along spine
        sp_base = Vector((0, y, z + rz * 0.85))
        sp_tip = Vector((0, y - 0.12, z + rz + 0.25))
        create_extruded_segment(bm, sp_base, sp_tip, 0.08, 0.01, 5)

    # 4 Muscular Reptilian Legs planted on Z=0
    leg_coords = [
        (0.48, 0.65, 0.68, 0.95, 0.75, 0.55, 1.05, 0.85),   # Front Left
        (0.48, -0.45, 0.65, 0.95, -0.55, 0.55, 1.05, -0.65), # Rear Left
    ]
    for (ax, ay, az, kx, ky, kz, fx, fy) in leg_coords:
        for side in (-1, 1):
            hip = Vector((side * ax, ay, az))
            knee = Vector((side * kx, ky, kz))
            foot = Vector((side * fx, fy, 0.0))
            create_extruded_segment(bm, hip, knee, 0.15, 0.11, 6)
            create_extruded_segment(bm, knee, foot, 0.11, 0.06, 6)
            # Claws
            for c_angle in (-0.25, 0.0, 0.25):
                c_dir = Vector((math.sin(c_angle), math.cos(c_angle), 0))
                c_tip = foot + c_dir * 0.18
                create_extruded_segment(bm, foot, c_tip, 0.04, 0.01, 4)

    # Spiked Articulated Tail
    p_prev = Vector((0, -0.85, 0.60))
    for t_idx in range(5):
        y_pos = -0.85 - (t_idx + 1) * 0.40
        z_pos = 0.60 - t_idx * 0.08 + 0.05 * math.sin(t_idx)
        x_pos = 0.15 * math.sin(t_idx * 1.2)
        p_curr = Vector((x_pos, y_pos, z_pos))
        create_extruded_segment(bm, p_prev, p_curr, 0.22 - t_idx * 0.035, 0.18 - t_idx * 0.035, 6)
        # Tail side spike
        for side in (-1, 1):
            sp_tip = p_curr + Vector((side * 0.25, -0.1, 0.1))
            create_extruded_segment(bm, p_curr, sp_tip, 0.05, 0.01, 4)
        p_prev = p_curr

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 5. FUNGAL STRIDER (Mycena strider with parasol cap & tall stilt legs)
# =========================================================================
def build_fungal_strider():
    mesh = bpy.data.meshes.new("FungalStriderMesh")
    obj = bpy.data.objects.new("FungalStrider", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Parasol Mushroom Cap (Wide wavy dome)
    cap_mat = Matrix.Translation((0, 0, 2.25)) @ Matrix.Scale(1.35, 4, Vector((1,0,0))) @ Matrix.Scale(1.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0, matrix=cap_mat)

    # Under-cap Spore Gills Hub
    gills_mat = Matrix.Translation((0, 0, 2.05)) @ Matrix.Scale(1.10, 4, Vector((1,0,0))) @ Matrix.Scale(1.10, 4, Vector((0,1,0))) @ Matrix.Scale(0.15, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=gills_mat)

    # Central Stem / Torso
    p_top = Vector((0, 0, 2.10))
    p_bot = Vector((0, 0, 1.55))
    create_extruded_segment(bm, p_top, p_bot, 0.35, 0.28, 8)

    # Hanging Spore Tendrils
    for i in range(8):
        angle = (2.0 * math.pi * i) / 8.0
        rad = 0.75 + 0.15 * math.sin(i * 2.3)
        t_base = Vector((rad * math.cos(angle), rad * math.sin(angle), 2.05))
        t_tip = Vector((rad * math.cos(angle) * 0.8, rad * math.sin(angle) * 0.8, 1.25 - 0.2 * (i % 3)))
        create_extruded_segment(bm, t_base, t_tip, 0.05, 0.01, 5)

    # 4 Tall Arched Mycelium Stilt Legs planted on Z=0
    for i in range(4):
        angle = (math.pi / 4.0) + (i * math.pi / 2.0)
        hip = Vector((0.25 * math.cos(angle), 0.25 * math.sin(angle), 1.65))
        knee = Vector((1.05 * math.cos(angle), 1.05 * math.sin(angle), 1.95))
        foot = Vector((1.25 * math.cos(angle), 1.25 * math.sin(angle), 0.0))
        create_extruded_segment(bm, hip, knee, 0.12, 0.09, 6)
        create_extruded_segment(bm, knee, foot, 0.09, 0.04, 6)
        # Root claws spreading on ground
        for root_rot in (-0.4, 0.4):
            root_dir = Vector((math.cos(angle + root_rot), math.sin(angle + root_rot), 0))
            root_tip = foot + root_dir * 0.25
            create_extruded_segment(bm, foot, root_tip, 0.04, 0.01, 4)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 6. GEODE GOLEM (Precursor stone guardian with boulder fists & runes)
# =========================================================================
def build_geode_golem():
    mesh = bpy.data.meshes.new("GeodeGolemMesh")
    obj = bpy.data.objects.new("GeodeGolem", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Monolith Head with Visor Slit
    head_mat = Matrix.Translation((0, 0, 2.35)) @ Matrix.Scale(0.38, 4, Vector((1,0,0))) @ Matrix.Scale(0.35, 4, Vector((0,1,0))) @ Matrix.Scale(0.32, 4, Vector((0,0,1)))
    bmesh.ops.create_cube(bm, size=1.0, matrix=head_mat)

    # Massive Chiseled Masonry Torso
    torso_mat = Matrix.Translation((0, 0, 1.70)) @ Matrix.Scale(0.95, 4, Vector((1,0,0))) @ Matrix.Scale(0.65, 4, Vector((0,1,0))) @ Matrix.Scale(0.85, 4, Vector((0,0,1)))
    bmesh.ops.create_cube(bm, size=1.0, matrix=torso_mat)

    # Shoulder Pauldrons
    for side in (-1, 1):
        p_mat = Matrix.Translation((side * 0.78, 0, 2.05)) @ Matrix.Scale(0.45, 4, Vector((1,0,0))) @ Matrix.Scale(0.48, 4, Vector((0,1,0))) @ Matrix.Scale(0.38, 4, Vector((0,0,1)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=p_mat)

    # Arm Segments & Boulder Fists
    for side in (-1, 1):
        shoulder = Vector((side * 0.75, 0, 1.85))
        elbow = Vector((side * 0.95, 0.10, 1.25))
        wrist = Vector((side * 0.85, 0.25, 0.65))
        create_extruded_segment(bm, shoulder, elbow, 0.22, 0.19, 6)
        create_extruded_segment(bm, elbow, wrist, 0.19, 0.25, 6)
        # Heavy boulder fist
        fist_mat = Matrix.Translation(wrist) @ Matrix.Scale(0.32, 4, Vector((1,1,1)))
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=fist_mat)

    # Pelvis Block
    pelvis_mat = Matrix.Translation((0, 0, 1.10)) @ Matrix.Scale(0.72, 4, Vector((1,0,0))) @ Matrix.Scale(0.52, 4, Vector((0,1,0))) @ Matrix.Scale(0.35, 4, Vector((0,0,1)))
    bmesh.ops.create_cube(bm, size=1.0, matrix=pelvis_mat)

    # 2 Pillar Masonry Legs planted on Z=0
    for side in (-1, 1):
        hip = Vector((side * 0.38, 0, 1.00))
        knee = Vector((side * 0.40, -0.05, 0.55))
        ankle = Vector((side * 0.42, 0, 0.15))
        create_extruded_segment(bm, hip, knee, 0.24, 0.21, 6)
        create_extruded_segment(bm, knee, ankle, 0.21, 0.23, 6)
        # Flat stone foot slab on Z=0
        foot_mat = Matrix.Translation((side * 0.42, 0.08, 0.10)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.48, 4, Vector((0,1,0))) @ Matrix.Scale(0.18, 4, Vector((0,0,1)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=foot_mat)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 7. NEW: ABYSSAL GLIDER (Пещерный Крылан / Flying cave gargoyle predator)
# =========================================================================
def build_abyssal_glider():
    mesh = bpy.data.meshes.new("AbyssalGliderMesh")
    obj = bpy.data.objects.new("AbyssalGlider", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Head (Bat skull with prominent echolocating ears)
    head_mat = Matrix.Translation((0, 0.45, 1.35)) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.32, 4, Vector((0,1,0))) @ Matrix.Scale(0.22, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=head_mat)

    # Pointed Echolocating Ears
    for side in (-1, 1):
        ear_base = Vector((side * 0.18, 0.40, 1.45))
        ear_tip = Vector((side * 0.32, 0.35, 1.78))
        create_extruded_segment(bm, ear_base, ear_tip, 0.08, 0.01, 5)

    # Torso & Ribcage
    torso_mat = Matrix.Translation((0, 0.10, 1.15)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.26, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=torso_mat)

    # Broad Bat-Like Wings
    for side in (-1, 1):
        shoulder = Vector((side * 0.22, 0.15, 1.25))
        elbow = Vector((side * 0.85, 0.20, 1.40))
        wrist = Vector((side * 1.55, 0.10, 1.48))
        create_extruded_segment(bm, shoulder, elbow, 0.09, 0.07, 6)
        create_extruded_segment(bm, elbow, wrist, 0.07, 0.05, 6)

        # 3 Wing Finger Struts
        f1_tip = wrist + Vector((side * 0.65, 0.30, 0.20))
        f2_tip = wrist + Vector((side * 0.55, -0.20, -0.45))
        f3_tip = wrist + Vector((side * 0.20, -0.45, -0.65))
        create_extruded_segment(bm, wrist, f1_tip, 0.04, 0.01, 4)
        create_extruded_segment(bm, wrist, f2_tip, 0.04, 0.01, 4)
        create_extruded_segment(bm, wrist, f3_tip, 0.04, 0.01, 4)

        # Wing Membrane connecting struts
        v_wrist = bm.verts.new(wrist)
        v_f1 = bm.verts.new(f1_tip)
        v_f2 = bm.verts.new(f2_tip)
        v_f3 = bm.verts.new(f3_tip)
        v_torso = bm.verts.new(Vector((side * 0.18, -0.10, 0.95)))
        bm.faces.new([v_wrist, v_f1, v_f2])
        bm.faces.new([v_wrist, v_f2, v_f3])
        bm.faces.new([v_wrist, v_f3, v_torso])

    # Hanging Gripping Talons
    for side in (-1, 1):
        hip = Vector((side * 0.15, -0.05, 0.85))
        knee = Vector((side * 0.20, -0.15, 0.55))
        foot = Vector((side * 0.18, -0.10, 0.25))
        create_extruded_segment(bm, hip, knee, 0.07, 0.05, 5)
        create_extruded_segment(bm, knee, foot, 0.05, 0.03, 5)
        for c in range(3):
            c_tip = foot + Vector((0.08 * (c - 1), 0.10, -0.12))
            create_extruded_segment(bm, foot, c_tip, 0.03, 0.01, 4)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 8. NEW: DEEP CAVE WYRM (Пещерный Червь / Segmented burrower with fanged maw)
# =========================================================================
def build_cave_wyrm():
    mesh = bpy.data.meshes.new("CaveWyrmMesh")
    obj = bpy.data.objects.new("CaveWyrm", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Dynamic Serpentine / Burrowing Arched Pose
    # Head at (0, 1.2, 0.8), curving down and back
    num_segs = 9
    pts = [
        Vector((0.0, 1.20, 0.85)),   # Head
        Vector((0.25, 0.85, 0.95)),
        Vector((0.35, 0.40, 0.80)),
        Vector((0.15, -0.05, 0.55)),
        Vector((-0.18, -0.45, 0.40)),
        Vector((-0.30, -0.85, 0.32)),
        Vector((-0.15, -1.25, 0.25)),
        Vector((0.08, -1.60, 0.18)),
        Vector((0.0, -1.95, 0.08)),   # Tail tip
    ]
    radii = [0.42, 0.45, 0.46, 0.44, 0.40, 0.35, 0.28, 0.20, 0.08]

    for i in range(num_segs - 1):
        create_extruded_segment(bm, pts[i], pts[i+1], radii[i], radii[i+1], segments=10)

    # Circular Fanged Maw at pts[0]
    head_center = pts[0]
    head_forward = Vector((0, 1, -0.2)).normalized()
    head_up = Vector((0, 0.2, 1)).normalized()
    head_right = head_forward.cross(head_up).normalized()

    # 12 Razor Teeth in Maw
    for t_idx in range(12):
        angle = (2.0 * math.pi * t_idx) / 12.0
        r_pos = head_center + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.34
        t_tip = head_center + head_forward * 0.22 + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.18
        create_extruded_segment(bm, r_pos, t_tip, 0.05, 0.01, 4)

    # 6 Sensory Facial Barbels
    for b_idx in range(6):
        angle = (2.0 * math.pi * b_idx) / 6.0
        b_base = head_center + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.42
        b_tip = b_base + head_forward * 0.35 + (head_right * math.cos(angle) + head_up * math.sin(angle)) * 0.30
        create_extruded_segment(bm, b_base, b_tip, 0.04, 0.01, 4)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# 9. NEW: ACID SPORE-SPITTER (Кислотный Споровик / Rooted plant-fungal trap)
# =========================================================================
def build_spore_spitter():
    mesh = bpy.data.meshes.new("SporeSpitterMesh")
    obj = bpy.data.objects.new("SporeSpitter", mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()

    # Rooted Ground Pedestal
    ped_mat = Matrix.Translation((0, 0, 0.25)) @ Matrix.Scale(0.65, 4, Vector((1,0,0))) @ Matrix.Scale(0.65, 4, Vector((0,1,0))) @ Matrix.Scale(0.25, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=ped_mat)

    # 4 Woody Anchor Roots spreading into ground Z=0
    for i in range(4):
        angle = i * (math.pi / 2.0)
        r_base = Vector((0.45 * math.cos(angle), 0.45 * math.sin(angle), 0.25))
        r_mid = Vector((0.95 * math.cos(angle), 0.95 * math.sin(angle), 0.15))
        r_tip = Vector((1.30 * math.cos(angle), 1.30 * math.sin(angle), 0.0))
        create_extruded_segment(bm, r_base, r_mid, 0.12, 0.08, 5)
        create_extruded_segment(bm, r_mid, r_tip, 0.08, 0.02, 5)

    # 5 Protective Organic Leaf Petals cupping bulb
    for i in range(5):
        angle = (2.0 * math.pi * i) / 5.0
        p_base = Vector((0.35 * math.cos(angle), 0.35 * math.sin(angle), 0.35))
        p_mid = Vector((0.75 * math.cos(angle), 0.75 * math.sin(angle), 0.75))
        p_tip = Vector((0.55 * math.cos(angle), 0.55 * math.sin(angle), 1.35))
        create_extruded_segment(bm, p_base, p_mid, 0.15, 0.12, 5)
        create_extruded_segment(bm, p_mid, p_tip, 0.12, 0.02, 5)

    # Swollen Translucent Acid Sac (Central bulb)
    sac_mat = Matrix.Translation((0, 0, 0.95)) @ Matrix.Scale(0.55, 4, Vector((1,0,0))) @ Matrix.Scale(0.55, 4, Vector((0,1,0))) @ Matrix.Scale(0.70, 4, Vector((0,0,1)))
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=sac_mat)

    # Acidic Discharge Nozzle (Maw orifice)
    n_base = Vector((0, 0, 1.45))
    n_tip = Vector((0, 0, 1.85))
    create_extruded_segment(bm, n_base, n_tip, 0.28, 0.18, 8)

    bm.to_mesh(mesh)
    bm.free()
    return obj

# =========================================================================
# MAIN EXPORT ROUTINE
# =========================================================================
def main():
    MODELS_DIR = "hollow_core/models"
    TEX_DIR = "hollow_core/textures/mobs"
    os.makedirs(MODELS_DIR, exist_ok=True)

    mob_configs = [
        ("chasm_stalker", build_chasm_stalker, "tex_stalker_pixel.png", "tex_stalker_pixel_emit.png"),
        ("lithic_crawler", build_lithic_crawler, "tex_crawler_pixel.png", "tex_crawler_pixel_emit.png"),
        ("cryo_wisp", build_cryo_wisp, "tex_cryo_pixel.png", "tex_cryo_pixel_emit.png"),
        ("magma_basilisk", build_magma_basilisk, "tex_magma_pixel.png", "tex_magma_pixel_emit.png"),
        ("fungal_strider", build_fungal_strider, "tex_fungal_pixel.png", "tex_fungal_pixel_emit.png"),
        ("geode_golem", build_geode_golem, "tex_golem_pixel.png", "tex_golem_pixel_emit.png"),
        ("abyssal_glider", build_abyssal_glider, "tex_glider_pixel.png", "tex_glider_pixel_emit.png"),
        ("cave_wyrm", build_cave_wyrm, "tex_wyrm_pixel.png", "tex_wyrm_pixel_emit.png"),
        ("spore_spitter", build_spore_spitter, "tex_spitter_pixel.png", "tex_spitter_pixel_emit.png"),
    ]

    for name, builder_fn, base_tex, emit_tex in mob_configs:
        print(f"--> Building and exporting {name}...")
        reset_scene()
        obj = builder_fn()
        apply_smart_uv(obj)

        base_path = os.path.join(TEX_DIR, base_tex)
        emit_path = os.path.join(TEX_DIR, emit_tex) if emit_tex else None
        setup_pixel_pbr_material(obj, f"M_{name}", base_path, emit_path)

        out_glb = os.path.join(MODELS_DIR, f"{name}.glb")
        bpy.ops.export_scene.gltf(
            filepath=os.path.abspath(out_glb),
            export_format='GLB',
            use_selection=False,
            export_apply=True
        )
        print(f"Exported: {out_glb}")

if __name__ == "__main__":
    main()

reset_scene()

TEX_DIR = 'hollow_core/textures/mobs'
MODELS_DIR = 'hollow_core/models'

# 1. Main Body
mesh_body = bpy.data.meshes.new('GliderBodyMesh')
obj_body = bpy.data.objects.new('Body', mesh_body)
bpy.context.collection.objects.link(obj_body)
bm_body = bmesh.new()

# Bat Skull
head_mat = Matrix.Translation((0, 0.45, 1.35)) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.32, 4, Vector((0,1,0))) @ Matrix.Scale(0.22, 4, Vector((0,0,1)))
bmesh.ops.create_icosphere(bm_body, subdivisions=2, radius=1.0, matrix=head_mat)

# Ears
for side in (-1, 1):
    ear_base = Vector((side * 0.18, 0.40, 1.45))
    ear_tip = Vector((side * 0.32, 0.35, 1.78))
    create_extruded_segment(bm_body, ear_base, ear_tip, 0.08, 0.01, 5)

# Torso
torso_mat = Matrix.Translation((0, 0.10, 1.15)) @ Matrix.Scale(0.32, 4, Vector((1,0,0))) @ Matrix.Scale(0.26, 4, Vector((0,1,0))) @ Matrix.Scale(0.45, 4, Vector((0,0,1)))
bmesh.ops.create_icosphere(bm_body, subdivisions=2, radius=1.0, matrix=torso_mat)

# Talons
for side in (-1, 1):
    hip = Vector((side * 0.15, -0.05, 0.85))
    knee = Vector((side * 0.20, -0.15, 0.55))
    foot = Vector((side * 0.18, -0.10, 0.25))
    create_extruded_segment(bm_body, hip, knee, 0.07, 0.05, 5)
    create_extruded_segment(bm_body, knee, foot, 0.05, 0.03, 5)
    for c in range(3):
        c_tip = foot + Vector((0.08 * (c - 1), 0.10, -0.12))
        create_extruded_segment(bm_body, foot, c_tip, 0.03, 0.01, 4)

bm_body.to_mesh(mesh_body)
bm_body.free()

# 2. Articulated Wings (Left and Right)
wing_objs = []
for side, w_name in ((1, 'Wing_L'), (-1, 'Wing_R')):
    pivot = Vector((side * 0.22, 0.15, 1.25))
    mesh_w = bpy.data.meshes.new(f'{w_name}Mesh')
    obj_w = bpy.data.objects.new(w_name, mesh_w)
    obj_w.location = pivot
    bpy.context.collection.objects.link(obj_w)
    obj_w.parent = obj_body

    bm_w = bmesh.new()
    shoulder_rel = Vector((0, 0, 0))
    elbow_rel = Vector((side * 0.63, 0.05, 0.15))
    wrist_rel = Vector((side * 1.33, -0.05, 0.23))
    create_extruded_segment(bm_w, shoulder_rel, elbow_rel, 0.09, 0.07, 6)
    create_extruded_segment(bm_w, elbow_rel, wrist_rel, 0.07, 0.05, 6)

    # 3 Finger Struts
    f1_tip = wrist_rel + Vector((side * 0.65, 0.30, 0.20))
    f2_tip = wrist_rel + Vector((side * 0.55, -0.20, -0.45))
    f3_tip = wrist_rel + Vector((side * 0.20, -0.45, -0.65))
    create_extruded_segment(bm_w, wrist_rel, f1_tip, 0.04, 0.01, 4)
    create_extruded_segment(bm_w, wrist_rel, f2_tip, 0.04, 0.01, 4)
    create_extruded_segment(bm_w, wrist_rel, f3_tip, 0.04, 0.01, 4)

    # Membrane
    v_wrist = bm_w.verts.new(wrist_rel)
    v_f1 = bm_w.verts.new(f1_tip)
    v_f2 = bm_w.verts.new(f2_tip)
    v_f3 = bm_w.verts.new(f3_tip)
    v_torso = bm_w.verts.new(Vector((0, -0.25, -0.30)))
    bm_w.faces.new([v_wrist, v_f1, v_f2])
    bm_w.faces.new([v_wrist, v_f2, v_f3])
    bm_w.faces.new([v_wrist, v_f3, v_torso])

    bm_w.to_mesh(mesh_w)
    bm_w.free()
    wing_objs.append(obj_w)

# Materials and Smart UV
base_path = os.path.join(TEX_DIR, 'tex_glider_pixel.png')
emit_path = os.path.join(TEX_DIR, 'tex_glider_pixel_emit.png')

for o in [obj_body] + wing_objs:
    apply_smart_uv(o)
    setup_pixel_pbr_material(o, f'M_{o.name}', base_path, emit_path)

out_glb = os.path.join(MODELS_DIR, 'abyssal_glider.glb')
bpy.ops.export_scene.gltf(
    filepath=os.path.abspath(out_glb),
    export_format='GLB',
    use_selection=False,
    export_apply=False
)
print('SUCCESSFULLY EXPORTED ARTICULATED ABYSSAL GLIDER!')
