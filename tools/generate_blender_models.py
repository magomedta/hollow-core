# hollow_core/tools/generate_blender_models.py
# High-Fidelity Textured Subterranean Mob Generator using Blender 4.0 BMesh & Smart UV Projection
import bpy
import bmesh
import math
from mathutils import Vector, Matrix
import os

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_textured_material(name, tex_path=None, emit_path=None, roughness=0.5, metallic=0.0, base_col=(0.5, 0.5, 0.5, 1.0)):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    
    if tex_path and os.path.exists(tex_path):
        tex_img = bpy.data.images.load(tex_path)
        tex_node = nodes.new('ShaderNodeTexImage')
        tex_node.image = tex_img
        mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
    else:
        bsdf.inputs['Base Color'].default_value = base_col
        
    if emit_path and os.path.exists(emit_path):
        emit_img = bpy.data.images.load(emit_path)
        emit_node = nodes.new('ShaderNodeTexImage')
        emit_node.image = emit_img
        if 'Emission Color' in bsdf.inputs:
            mat.node_tree.links.new(emit_node.outputs['Color'], bsdf.inputs['Emission Color'])
            bsdf.inputs['Emission Strength'].default_value = 3.5
        elif 'Emission' in bsdf.inputs:
            mat.node_tree.links.new(emit_node.outputs['Color'], bsdf.inputs['Emission'])
            
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    return mat

def create_connected_limb(bm, points, radii, sides=8):
    if len(points) < 2:
        return
    prev_verts = []
    for i, pt in enumerate(points):
        r = radii[i]
        if i < len(points) - 1:
            tan = (points[i+1] - pt).normalized()
        else:
            tan = (pt - points[i-1]).normalized()
            
        up = Vector((0, 0, 1)) if abs(tan.z) < 0.9 else Vector((0, 1, 0))
        right = tan.cross(up).normalized()
        real_up = right.cross(tan).normalized()
        
        curr_ring = []
        for s in range(sides):
            ang = s * (2.0 * math.pi / sides)
            offset = (right * math.cos(ang) + real_up * math.sin(ang)) * r
            v = bm.verts.new(pt + offset)
            curr_ring.append(v)
            
        if prev_verts:
            for s in range(sides):
                next_s = (s + 1) % sides
                bm.faces.new([prev_verts[s], prev_verts[next_s], curr_ring[next_s], curr_ring[s]])
        else:
            bm.faces.new(curr_ring)
        prev_verts = curr_ring
    bm.faces.new(list(reversed(prev_verts)))

def finalize_and_export(obj, output_path):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    # Smart UV projection for continuous texture mapping
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.shade_smooth()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_materials='EXPORT',
        export_normals=True
    )
    print(f"[Blender] Exported high-detail model: {output_path} ({os.path.getsize(output_path)} bytes)")

# ==============================================================================
# 1. CHASM STALKER (Textured Chitin + Scythes + Spines + Articulated Legs)
# ==============================================================================
def build_chasm_stalker(output_dir, tex_dir):
    clear_scene()
    mat_chitin = create_textured_material(
        "StalkerChitin", 
        tex_path=os.path.join(tex_dir, "tex_stalker_chitin.png"),
        emit_path=os.path.join(tex_dir, "tex_stalker_emit.png"),
        roughness=0.35, metallic=0.45
    )
    
    mesh = bpy.data.meshes.new("ChasmStalkerMesh")
    obj = bpy.data.objects.new("ChasmStalker", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat_chitin)
    
    bm = bmesh.new()
    
    # 1. Sculpted Thorax & Abdomen
    body_points = [
        Vector((0, 0.70, 0.85)),   # Head tip / mandibles
        Vector((0, 0.45, 0.95)),   # Neck
        Vector((0, 0.15, 1.05)),   # Mid Thorax
        Vector((0, -0.15, 1.00)),  # Low Thorax
        Vector((0, -0.45, 0.88)),  # Abdomen mid
        Vector((0, -0.75, 0.72)),  # Tail barb base
        Vector((0, -0.98, 0.60))   # Tail tip
    ]
    body_radii = [0.18, 0.28, 0.38, 0.36, 0.30, 0.18, 0.05]
    create_connected_limb(bm, body_points, body_radii, sides=12)
    
    # 2. Dorsal Armor Spines along back
    for s_idx in range(5):
        s_y = 0.30 - s_idx * 0.22
        s_z = 1.05 - s_idx * 0.08
        spine_pts = [Vector((0, s_y, s_z)), Vector((0, s_y - 0.05, s_z + 0.20))]
        create_connected_limb(bm, spine_pts, [0.06, 0.01], sides=6)
    
    # 3. Predatory Scythe Forelimbs (Serrated)
    for side in (-1, 1):
        scythe_points = [
            Vector((side * 0.25, 0.32, 0.95)),
            Vector((side * 0.48, 0.45, 1.18)), # High joint
            Vector((side * 0.45, 0.78, 0.75)), # Scythe blade
            Vector((side * 0.35, 0.92, 0.35))  # Sharp striking point
        ]
        create_connected_limb(bm, scythe_points, [0.08, 0.07, 0.05, 0.008], sides=8)
        # Mandible fangs
        fang_pts = [Vector((side * 0.12, 0.65, 0.82)), Vector((side * 0.08, 0.82, 0.72))]
        create_connected_limb(bm, fang_pts, [0.04, 0.008], sides=6)

    # 4. Four Connected Arched Walking Legs (Planted on ground Z=0.0)
    leg_x_y = [(0.24, 0.15), (0.26, -0.05), (0.25, -0.28), (0.20, -0.52)]
    for idx, (lx, ly) in enumerate(leg_x_y):
        for side in (-1, 1):
            hip = Vector((side * lx, ly, 0.95 - idx * 0.05))
            knee = Vector((side * (lx + 0.38 + idx * 0.04), ly + (0.12 - idx * 0.08), 1.18 - idx * 0.04))
            shin = Vector((side * (lx + 0.54 + idx * 0.05), ly + (0.05 - idx * 0.06), 0.48))
            foot = Vector((side * (lx + 0.62 + idx * 0.06), ly - idx * 0.05, 0.0)) # GROUND CONTACT Z=0!
            create_connected_limb(bm, [hip, knee, shin, foot], [0.075, 0.060, 0.045, 0.015], sides=8)
            
    # 3. Crystal Clusters protruding from Carapace (Continuous geometry)
    for c in range(5):
        ang = c * (2.0 * math.pi / 5.0)
        rad = 0.22 if c > 0 else 0.0
        c_root = Vector((math.cos(ang) * rad, math.sin(ang) * rad - 0.08, 0.52))
        c_tip = Vector((math.cos(ang) * (rad + 0.08), math.sin(ang) * (rad + 0.08) - 0.08, 0.85 + (c % 2) * 0.12))
        create_connected_limb(bm, [c_root, c_tip], [0.08, 0.005], sides=6)
        
    bm.to_mesh(mesh)
    bm.free()
    finalize_and_export(obj, os.path.join(output_dir, "chasm_stalker.glb"))

# ==============================================================================
# 2. LITHIC CRAWLER (Textured Basalt Carapace + Pincers + 6 Legs + Geode)
# ==============================================================================
def build_lithic_crawler(output_dir, tex_dir):
    clear_scene()
    mat_stone = create_textured_material(
        "LithicBasalt", 
        tex_path=os.path.join(tex_dir, "tex_crawler_stone.png"),
        roughness=0.85, metallic=0.15
    )
    
    mesh = bpy.data.meshes.new("LithicCrawlerMesh")
    obj = bpy.data.objects.new("LithicCrawler", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat_stone)
    
    bm = bmesh.new()
    
    # 1. Heavy Armored Dome Shell
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.55)
    for v in bm.verts:
        v.co.x *= 1.15
        v.co.y *= 1.35
        v.co.z *= 0.55
        v.co.z += 0.38
        if v.co.z < 0.15: v.co.z = 0.15
        
    # 2. Front Heavy Crushing Mandibles/Pincers
    for side in (-1, 1):
        pincer_pts = [
            Vector((side * 0.18, 0.65, 0.35)),
            Vector((side * 0.30, 0.85, 0.32)),
            Vector((side * 0.15, 0.95, 0.28))
        ]
        create_connected_limb(bm, pincer_pts, [0.07, 0.06, 0.02], sides=8)

    # 3. Six Connected Sprawled Crab Legs (Ground contact Z=0.0)
    leg_x_y = [(0.40, 0.35), (0.48, 0.0), (0.40, -0.35)]
    for idx, (lx, ly) in enumerate(leg_x_y):
        for side in (-1, 1):
            hip = Vector((side * lx, ly, 0.32))
            knee = Vector((side * (lx + 0.32), ly + (0.08 - idx * 0.08), 0.48))
            foot = Vector((side * (lx + 0.55), ly + (0.12 - idx * 0.12), 0.0))
            create_connected_limb(bm, [hip, knee, foot], [0.08, 0.06, 0.02], sides=8)
            
    # 3. Crystal Clusters protruding from Carapace (Continuous geometry)
    for c in range(5):
        ang = c * (2.0 * math.pi / 5.0)
        rad = 0.22 if c > 0 else 0.0
        c_root = Vector((math.cos(ang) * rad, math.sin(ang) * rad - 0.08, 0.52))
        c_tip = Vector((math.cos(ang) * (rad + 0.08), math.sin(ang) * (rad + 0.08) - 0.08, 0.85 + (c % 2) * 0.12))
        create_connected_limb(bm, [c_root, c_tip], [0.08, 0.005], sides=6)
        
    bm.to_mesh(mesh)
    bm.free()
    finalize_and_export(obj, os.path.join(output_dir, "lithic_crawler.glb"))

# ==============================================================================
# 3. CRYO WISP (Textured Crystal Core + Orbital Ice Rings + Frost Tendril)
# ==============================================================================
def build_cryo_wisp(output_dir, tex_dir):
    clear_scene()
    mat_core = create_textured_material(
        "WispCore", 
        emit_path=os.path.join(tex_dir, "tex_stalker_emit.png"),
        roughness=0.1, metallic=0.2, base_col=(0.6, 0.85, 1.0, 1.0)
    )
    
    mesh = bpy.data.meshes.new("CryoWispMesh")
    obj = bpy.data.objects.new("CryoWisp", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat_core)
    
    bm = bmesh.new()
    
    # 1. Pulsating Crystalline Core
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.34)
    for v in bm.verts:
        v.co.z += 0.85
        
    # 2. Orbital Ice Shards around core
    for s in range(8):
        ang = s * (2.0 * math.pi / 8.0)
        dist = 0.58
        sh_z = 0.85 + math.sin(s * 2.0) * 0.15
        pt1 = Vector((math.cos(ang) * dist, math.sin(ang) * dist, sh_z - 0.15))
        pt2 = Vector((math.cos(ang) * dist, math.sin(ang) * dist, sh_z + 0.15))
        create_connected_limb(bm, [pt1, pt2], [0.05, 0.005], sides=6)
        
    # 3. Trailing Frost Spine below
    spine_pts = [
        Vector((0, 0, 0.70)),
        Vector((0, 0, 0.45)),
        Vector((0, 0, 0.20)),
        Vector((0, 0, 0.02))
    ]
    create_connected_limb(bm, spine_pts, [0.08, 0.05, 0.025, 0.005], sides=8)
    
    # 3. Crystal Clusters protruding from Carapace (Continuous geometry)
    for c in range(5):
        ang = c * (2.0 * math.pi / 5.0)
        rad = 0.22 if c > 0 else 0.0
        c_root = Vector((math.cos(ang) * rad, math.sin(ang) * rad - 0.08, 0.52))
        c_tip = Vector((math.cos(ang) * (rad + 0.08), math.sin(ang) * (rad + 0.08) - 0.08, 0.85 + (c % 2) * 0.12))
        create_connected_limb(bm, [c_root, c_tip], [0.08, 0.005], sides=6)
        
    bm.to_mesh(mesh)
    bm.free()
    finalize_and_export(obj, os.path.join(output_dir, "cryo_wisp.glb"))

# ==============================================================================
# 4. MAGMA BASILISK (NEW MOB: Quadruped Volcanic Reptile with Obsidian Scales)
# ==============================================================================
def build_magma_basilisk(output_dir, tex_dir):
    clear_scene()
    mat_magma = create_textured_material(
        "MagmaSkin", 
        tex_path=os.path.join(tex_dir, "tex_magma_skin.png"),
        emit_path=os.path.join(tex_dir, "tex_magma_emit.png"),
        roughness=0.60, metallic=0.35
    )
    
    mesh = bpy.data.meshes.new("MagmaBasiliskMesh")
    obj = bpy.data.objects.new("MagmaBasilisk", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat_magma)
    
    bm = bmesh.new()
    
    # 1. Long Muscular Reptilian Body & Tail
    body_pts = [
        Vector((0, 0.95, 0.50)),   # Snout tip
        Vector((0, 0.70, 0.58)),   # Horned cranium
        Vector((0, 0.40, 0.65)),   # Neck & shoulders
        Vector((0, 0.05, 0.62)),   # Mid torso
        Vector((0, -0.35, 0.55)),  # Pelvis
        Vector((0, -0.75, 0.45)),  # Tail base
        Vector((0, -1.25, 0.32)),  # Tail mid
        Vector((0, -1.75, 0.18))   # Tail tip
    ]
    body_rad = [0.15, 0.26, 0.35, 0.34, 0.28, 0.18, 0.10, 0.03]
    create_connected_limb(bm, body_pts, body_rad, sides=12)
    
    # 2. Spiky Obsidian Dorsal Crest (Ridge of heat vents)
    for sp in range(7):
        sy = 0.55 - sp * 0.22
        sz = 0.62 - sp * 0.04
        c_pts = [Vector((0, sy, sz)), Vector((0, sy - 0.06, sz + 0.22))]
        create_connected_limb(bm, c_pts, [0.05, 0.008], sides=6)
        
    # 3. Cranial Brow Horns
    for side in (-1, 1):
        horn_pts = [Vector((side * 0.15, 0.65, 0.62)), Vector((side * 0.32, 0.55, 0.85))]
        create_connected_limb(bm, horn_pts, [0.06, 0.01], sides=6)

    # 4. Four Heavy Muscular Walking Legs (Planted on ground Z=0.0)
    leg_coords = [
        (0.28, 0.35, 0.55),  # Front legs
        (0.26, -0.28, 0.50)  # Rear legs
    ]
    for idx, (lx, ly, lz) in enumerate(leg_coords):
        for side in (-1, 1):
            shoulder = Vector((side * lx, ly, lz))
            elbow = Vector((side * (lx + 0.28), ly + 0.08, lz + 0.05))
            knee = Vector((side * (lx + 0.36), ly + 0.05, 0.28))
            foot = Vector((side * (lx + 0.42), ly + (0.10 if idx==0 else -0.08), 0.0)) # GROUND CONTACT!
            create_connected_limb(bm, [shoulder, elbow, knee, foot], [0.10, 0.085, 0.065, 0.025], sides=8)

    # 3. Crystal Clusters protruding from Carapace (Continuous geometry)
    for c in range(5):
        ang = c * (2.0 * math.pi / 5.0)
        rad = 0.22 if c > 0 else 0.0
        c_root = Vector((math.cos(ang) * rad, math.sin(ang) * rad - 0.08, 0.52))
        c_tip = Vector((math.cos(ang) * (rad + 0.08), math.sin(ang) * (rad + 0.08) - 0.08, 0.85 + (c % 2) * 0.12))
        create_connected_limb(bm, [c_root, c_tip], [0.08, 0.005], sides=6)
        
    bm.to_mesh(mesh)
    bm.free()
    finalize_and_export(obj, os.path.join(output_dir, "magma_basilisk.glb"))

# ==============================================================================
# 5. FUNGAL STRIDER (NEW MOB: Tall Bioluminescent Parasol Walker)
# ==============================================================================
def build_fungal_strider(output_dir, tex_dir):
    clear_scene()
    mat_fungal = create_textured_material(
        "FungalSkin", 
        tex_path=os.path.join(tex_dir, "tex_fungal_skin.png"),
        roughness=0.55, metallic=0.10
    )
    
    mesh = bpy.data.meshes.new("FungalStriderMesh")
    obj = bpy.data.objects.new("FungalStrider", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat_fungal)
    
    bm = bmesh.new()
    
    # 1. Broad Parasol Mushroom Cap (Center at Z=1.75)
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.75)
    for v in bm.verts:
        v.co.z *= 0.40
        v.co.z += 1.75
        if v.co.z < 1.60: v.co.z = 1.60 # Concave gill underside
        
    # 2. Central Spore Sac Core
    core_pts = [
        Vector((0, 0, 1.75)),
        Vector((0, 0, 1.45)),
        Vector((0, 0, 1.20))
    ]
    create_connected_limb(bm, core_pts, [0.22, 0.18, 0.12], sides=10)
    
    # 3. Hanging Spore Gills / Tendrils
    for t in range(6):
        ang = t * (2.0 * math.pi / 6.0)
        t_pts = [
            Vector((math.cos(ang) * 0.45, math.sin(ang) * 0.45, 1.60)),
            Vector((math.cos(ang) * 0.42, math.sin(ang) * 0.42, 1.15))
        ]
        create_connected_limb(bm, t_pts, [0.035, 0.005], sides=6)

    # 4. Four Tall Arched Stilt Legs (Reaching down to ground Z=0.0)
    for l_idx in range(4):
        ang = l_idx * (math.pi * 0.5) + math.pi * 0.25
        hip = Vector((math.cos(ang) * 0.22, math.sin(ang) * 0.22, 1.35))
        knee = Vector((math.cos(ang) * 0.75, math.sin(ang) * 0.75, 1.65)) # High arched stilt knee
        foot = Vector((math.cos(ang) * 0.85, math.sin(ang) * 0.85, 0.0))  # Ground contact Z=0!
        create_connected_limb(bm, [hip, knee, foot], [0.075, 0.055, 0.018], sides=8)

    # 3. Crystal Clusters protruding from Carapace (Continuous geometry)
    for c in range(5):
        ang = c * (2.0 * math.pi / 5.0)
        rad = 0.22 if c > 0 else 0.0
        c_root = Vector((math.cos(ang) * rad, math.sin(ang) * rad - 0.08, 0.52))
        c_tip = Vector((math.cos(ang) * (rad + 0.08), math.sin(ang) * (rad + 0.08) - 0.08, 0.85 + (c % 2) * 0.12))
        create_connected_limb(bm, [c_root, c_tip], [0.08, 0.005], sides=6)
        
    bm.to_mesh(mesh)
    bm.free()
    finalize_and_export(obj, os.path.join(output_dir, "fungal_strider.glb"))

# ==============================================================================
# 6. GEODE GOLEM (NEW MOB: Heavy Bipedal Precursor Runic Stone Guardian)
# ==============================================================================
def build_geode_golem(output_dir, tex_dir):
    clear_scene()
    mat_golem = create_textured_material(
        "GolemSlate", 
        tex_path=os.path.join(tex_dir, "tex_golem_slate.png"),
        emit_path=os.path.join(tex_dir, "tex_golem_emit.png"),
        roughness=0.75, metallic=0.45
    )
    
    mesh = bpy.data.meshes.new("GeodeGolemMesh")
    obj = bpy.data.objects.new("GeodeGolem", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat_golem)
    
    bm = bmesh.new()
    
    # 1. Massive Beveled Stone Torso
    torso_pts = [
        Vector((0, 0, 1.70)), # Neck / Crest
        Vector((0, 0, 1.45)), # Broad chest
        Vector((0, 0, 1.15)), # Waist
        Vector((0, 0, 0.95))  # Pelvis
    ]
    torso_rad = [0.30, 0.48, 0.38, 0.32]
    create_connected_limb(bm, torso_pts, torso_rad, sides=10)
    
    # 2. Glowing Runic Eye Monolith (Head)
    head_pts = [Vector((0, 0.15, 1.70)), Vector((0, 0.32, 1.82))]
    create_connected_limb(bm, head_pts, [0.20, 0.12], sides=8)

    # 3. Two Massive Boulder Arms & Fist Claws
    for side in (-1, 1):
        shoulder = Vector((side * 0.52, 0, 1.55))
        elbow = Vector((side * 0.72, 0.05, 1.15))
        fist = Vector((side * 0.65, 0.22, 0.65)) # Heavy swinging boulder fist
        create_connected_limb(bm, [shoulder, elbow, fist], [0.18, 0.15, 0.20], sides=8)

    # 4. Two Sturdy Bipedal Stone Legs (Ground contact Z=0.0)
    for side in (-1, 1):
        hip = Vector((side * 0.22, 0, 0.95))
        knee = Vector((side * 0.26, 0.05, 0.50))
        foot = Vector((side * 0.28, 0.02, 0.0)) # GROUND CONTACT Z=0!
        create_connected_limb(bm, [hip, knee, foot], [0.16, 0.14, 0.18], sides=8)

    # 3. Crystal Clusters protruding from Carapace (Continuous geometry)
    for c in range(5):
        ang = c * (2.0 * math.pi / 5.0)
        rad = 0.22 if c > 0 else 0.0
        c_root = Vector((math.cos(ang) * rad, math.sin(ang) * rad - 0.08, 0.52))
        c_tip = Vector((math.cos(ang) * (rad + 0.08), math.sin(ang) * (rad + 0.08) - 0.08, 0.85 + (c % 2) * 0.12))
        create_connected_limb(bm, [c_root, c_tip], [0.08, 0.005], sides=6)
        
    bm.to_mesh(mesh)
    bm.free()
    finalize_and_export(obj, os.path.join(output_dir, "geode_golem.glb"))

if __name__ == "__main__":
    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "models"))
    tex_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "textures", "mobs"))
    print(f"[Blender] Generating all high-detail textured mobs into: {out_dir}")
    build_chasm_stalker(out_dir, tex_dir)
    build_lithic_crawler(out_dir, tex_dir)
    build_cryo_wisp(out_dir, tex_dir)
    build_magma_basilisk(out_dir, tex_dir)
    build_fungal_strider(out_dir, tex_dir)
    build_geode_golem(out_dir, tex_dir)
    print("[Blender] All textured mobs generated successfully.")
