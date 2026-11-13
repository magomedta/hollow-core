# generate_blender_mobs.py
# High-Fidelity 3D Subterranean Creature Generator for Hollow Core using Blender 4.0
import sys
import math
import os
import bpy
import bmesh
from mathutils import Vector, Euler, Matrix

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, albedo_col, roughness=0.5, metallic=0.0, emission_col=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.inputs['Base Color'].default_value = (*albedo_col[:3], 1.0)
    node_bsdf.inputs['Roughness'].default_value = roughness
    node_bsdf.inputs['Metallic'].default_value = metallic
    
    if emission_col and emission_strength > 0:
        node_bsdf.inputs['Emission Color'].default_value = (*emission_col[:3], 1.0)
        node_bsdf.inputs['Emission Strength'].default_value = emission_strength
        
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def apply_bevel(obj, width=0.02, segments=2):
    mod = obj.modifiers.new(name='Bevel', type='BEVEL')
    mod.width = width
    mod.segments = segments
    mod.limit_method = 'ANGLE'
    mod.angle_limit = math.radians(35)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier='Bevel')

def build_chasm_stalker(output_path):
    print("Building high-detail Chasm Stalker...")
    clear_scene()
    
    # Materials
    mat_chitin = create_pbr_material("StalkerChitin", (0.08, 0.09, 0.11), roughness=0.35, metallic=0.45)
    mat_plates = create_pbr_material("StalkerPlates", (0.04, 0.05, 0.06), roughness=0.45, metallic=0.60)
    mat_fangs = create_pbr_material("StalkerFangs", (0.18, 0.16, 0.14), roughness=0.20, metallic=0.20)
    mat_eye = create_pbr_material("StalkerEye", (0.10, 0.95, 0.85), roughness=0.10, metallic=0.0, emission_col=(0.15, 1.0, 0.88), emission_strength=5.0)
    mat_pulse = create_pbr_material("StalkerPulse", (0.05, 0.70, 0.65), roughness=0.25, metallic=0.1, emission_col=(0.10, 0.80, 0.70), emission_strength=2.5)

    root = bpy.data.objects.new("StalkerModel", None)
    bpy.context.scene.collection.objects.link(root)
    
    # 1. Thorax & Carapace
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.45, location=(0, 0, 1.05))
    thorax = bpy.context.active_object
    thorax.name = "Thorax"
    thorax.scale = (0.75, 1.15, 0.65)
    bpy.ops.object.transform_apply(scale=True)
    thorax.data.materials.append(mat_chitin)
    thorax.parent = root
    
    # Overlapping armored plates on thorax
    for i in range(4):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.42 - i * 0.03, depth=0.16, location=(0, -0.28 + i * 0.22, 1.12 + (1.0 - (i*0.2)**2)*0.08))
        plate = bpy.context.active_object
        plate.name = f"ArmorPlate_{i}"
        plate.scale = (0.85, 0.95, 0.45)
        plate.rotation_euler = (math.radians(-12 + i * 8), 0, 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        apply_bevel(plate, 0.015, 2)
        plate.data.materials.append(mat_plates)
        plate.parent = thorax
        
    # Dorsal Spines along spine
    for i in range(5):
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.06, depth=0.28 - i * 0.03, location=(0, -0.35 + i * 0.20, 1.30))
        spine = bpy.context.active_object
        spine.name = f"DorsalSpine_{i}"
        spine.rotation_euler = (math.radians(25 - i * 5), 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        spine.data.materials.append(mat_plates)
        spine.parent = thorax

    # 2. Abdomen & Segmented Tail
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.40, location=(0, 0.65, 0.95))
    abdomen = bpy.context.active_object
    abdomen.name = "Abdomen"
    abdomen.scale = (0.65, 1.10, 0.55)
    bpy.ops.object.transform_apply(scale=True)
    abdomen.data.materials.append(mat_chitin)
    abdomen.parent = root
    
    # Caudal tail barb
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.08, depth=0.40, location=(0, 1.25, 0.90))
    tail_barb = bpy.context.active_object
    tail_barb.name = "TailBarb"
    tail_barb.rotation_euler = (math.radians(-75), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    tail_barb.data.materials.append(mat_plates)
    tail_barb.parent = abdomen

    # 3. Head & Predatory Mandibles
    head = bpy.data.objects.new("Head", None)
    head.location = (0, -0.60, 1.12)
    bpy.context.scene.collection.objects.link(head)
    head.parent = root
    
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.32, location=(0, 0, 0))
    cranium = bpy.context.active_object
    cranium.name = "Cranium"
    cranium.scale = (0.68, 1.05, 0.62)
    cranium.rotation_euler = (math.radians(-10), 0, 0)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    cranium.data.materials.append(mat_chitin)
    cranium.parent = head
    
    # Sensory Crest Ridge
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.10, depth=0.45, location=(0, -0.05, 0.18))
    crest = bpy.context.active_object
    crest.name = "SensoryCrest"
    crest.scale = (0.35, 1.0, 0.55)
    crest.rotation_euler = (math.radians(-25), 0, 0)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    apply_bevel(crest, 0.015, 2)
    crest.data.materials.append(mat_plates)
    crest.parent = head
    
    # Curved Mandibular Fangs (Left & Right)
    for side, s_name in [(-1, "L"), (1, "R")]:
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.065, depth=0.32, location=(side * 0.16, -0.26, -0.06))
        fang = bpy.context.active_object
        fang.name = f"Fang_{s_name}"
        fang.rotation_euler = (math.radians(35), math.radians(side * -25), math.radians(side * 15))
        bpy.ops.object.transform_apply(rotation=True)
        fang.data.materials.append(mat_fangs)
        fang.parent = head
        
    # Bioluminescent Optical Nodes (4 faceted eyes)
    eye_positions = [
        (-0.14, -0.22, 0.08, 0.055),
        (0.14, -0.22, 0.08, 0.055),
        (-0.09, -0.28, 0.02, 0.042),
        (0.09, -0.28, 0.02, 0.042),
    ]
    for idx, (ex, ey, ez, er) in enumerate(eye_positions):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=er, location=(ex, ey, ez))
        eye = bpy.context.active_object
        eye.name = f"Eye_{idx}"
        eye.data.materials.append(mat_eye)
        eye.parent = head

    # 4. Articulated Legs (Front-Left, Front-Right, Back-Left, Back-Right)
    leg_configs = [
        ("Leg_FL", -1, -0.28, 1.02, 0.35),
        ("Leg_FR",  1, -0.28, 1.02, 0.35),
        ("Leg_BL", -1,  0.35, 0.98, -0.25),
        ("Leg_BR",  1,  0.35, 0.98, -0.25),
    ]
    
    for leg_name, side, y_pos, z_pos, angle_y in leg_configs:
        leg_root = bpy.data.objects.new(leg_name, None)
        leg_root.location = (side * 0.32, y_pos, z_pos)
        bpy.context.scene.collection.objects.link(leg_root)
        leg_root.parent = root
        
        # Coxa / Socket
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.12, location=(0, 0, 0))
        coxa = bpy.context.active_object
        coxa.name = f"{leg_name}_Coxa"
        coxa.data.materials.append(mat_plates)
        coxa.parent = leg_root
        
        # Femur (Angled up and out)
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.075, depth=0.62, location=(side * 0.22, 0, 0.18))
        femur = bpy.context.active_object
        femur.name = f"{leg_name}_Femur"
        femur.rotation_euler = (math.radians(angle_y * 15), math.radians(side * -55), math.radians(side * 10))
        bpy.ops.object.transform_apply(rotation=True)
        apply_bevel(femur, 0.015, 2)
        femur.data.materials.append(mat_chitin)
        femur.parent = leg_root
        
        # Knee Joint
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.09, location=(side * 0.44, 0, 0.36))
        knee = bpy.context.active_object
        knee.name = f"{leg_name}_Knee"
        knee.data.materials.append(mat_plates)
        knee.parent = leg_root
        
        # Tibia (Angled down to ground)
        tibia_end_x = side * 0.65
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.060, depth=0.88, location=(side * 0.55, 0, -0.15))
        tibia = bpy.context.active_object
        tibia.name = f"{leg_name}_Tibia"
        tibia.rotation_euler = (0, math.radians(side * 28), 0)
        bpy.ops.object.transform_apply(rotation=True)
        apply_bevel(tibia, 0.015, 2)
        tibia.data.materials.append(mat_chitin)
        tibia.parent = leg_root
        
        # Foot Claw / Talons (Firmly grounded at Z = -1.0 relative to body, i.e. Z = 0 in world)
        claw_pos = (side * 0.65, 0, -0.62)
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.07, depth=0.28, location=claw_pos)
        claw = bpy.context.active_object
        claw.name = f"{leg_name}_Claw"
        claw.rotation_euler = (math.radians(-30), 0, math.radians(side * 15))
        bpy.ops.object.transform_apply(rotation=True)
        claw.data.materials.append(mat_fangs)
        claw.parent = leg_root

    # 5. Dual Raptorial Fore-Claws (Mantis-like strike appendages)
    for side, s_name in [(-1, "L"), (1, "R")]:
        arm_node = bpy.data.objects.new(f"RaptorArm_{s_name}", None)
        arm_node.location = (side * 0.22, -0.45, 0.90)
        bpy.context.scene.collection.objects.link(arm_node)
        arm_node.parent = root
        
        # Scythe blade
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.05, depth=0.55, location=(side * 0.15, -0.22, -0.12))
        blade = bpy.context.active_object
        blade.name = f"Scythe_{s_name}"
        blade.scale = (0.35, 1.2, 1.0)
        blade.rotation_euler = (math.radians(45), math.radians(side * -25), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        apply_bevel(blade, 0.01, 2)
        blade.data.materials.append(mat_fangs)
        blade.parent = arm_node

    # Smooth shading on all mesh objects
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            for f in obj.data.polygons:
                f.use_smooth = True

    print(f"Exporting Chasm Stalker to {output_path}...")
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=False,
        export_apply=False
    )
    print("Chasm Stalker export complete.")

def build_lithic_crawler(output_path):
    print("Building high-detail Lithic Crawler...")
    clear_scene()
    
    mat_stone = create_pbr_material("CrawlerStone", (0.18, 0.17, 0.19), roughness=0.88, metallic=0.05)
    mat_chitin = create_pbr_material("CrawlerChitin", (0.06, 0.07, 0.08), roughness=0.40, metallic=0.50)
    mat_crystal = create_pbr_material("CrawlerCrystal", (0.65, 0.20, 0.85), roughness=0.15, metallic=0.10, emission_col=(0.75, 0.25, 0.95), emission_strength=4.5)
    mat_calcite = create_pbr_material("CrawlerCalcite", (0.85, 0.88, 0.92), roughness=0.20, metallic=0.05, emission_col=(0.90, 0.92, 0.95), emission_strength=1.5)
    mat_eye = create_pbr_material("CrawlerEye", (0.95, 0.45, 0.05), roughness=0.10, metallic=0.0, emission_col=(1.0, 0.50, 0.10), emission_strength=4.0)

    root = bpy.data.objects.new("CrawlerModel", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Broad Shield Carapace (Domed trilobite/beetle rock mimic)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.55, location=(0, 0, 0.45))
    carapace = bpy.context.active_object
    carapace.name = "Carapace"
    carapace.scale = (1.25, 1.45, 0.55)
    bpy.ops.object.transform_apply(scale=True)
    carapace.data.materials.append(mat_stone)
    carapace.parent = root

    # Faceted Carapace Margins (Armored rim)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.62, minor_radius=0.08, major_segments=16, minor_segments=8, location=(0, 0, 0.32))
    rim = bpy.context.active_object
    rim.name = "CarapaceRim"
    rim.scale = (1.18, 1.38, 0.65)
    bpy.ops.object.transform_apply(scale=True)
    rim.data.materials.append(mat_chitin)
    rim.parent = carapace

    # 2. Dorsal Crystalline Geode Clusters (Amethyst & Calcite nodules erupting from shell)
    crystal_coords = [
        (0.12, 0.15, 0.62, 0.09, 0.26, mat_crystal, 25, 15),
        (-0.16, 0.05, 0.64, 0.08, 0.22, mat_crystal, -20, -10),
        (0.0, -0.18, 0.65, 0.11, 0.32, mat_crystal, 15, -20),
        (-0.18, -0.22, 0.58, 0.07, 0.20, mat_calcite, -30, 25),
        (0.22, -0.08, 0.60, 0.08, 0.24, mat_calcite, 35, 10),
        (0.08, 0.35, 0.52, 0.06, 0.18, mat_crystal, -10, 40)
    ]
    for idx, (cx, cy, cz, rad, h, mat_c, rx, ry) in enumerate(crystal_coords):
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=rad, depth=h, location=(cx, cy, cz))
        c_obj = bpy.context.active_object
        c_obj.name = f"CrystalNodule_{idx}"
        c_obj.rotation_euler = (math.radians(rx), math.radians(ry), 0)
        bpy.ops.object.transform_apply(rotation=True)
        apply_bevel(c_obj, 0.01, 1)
        c_obj.data.materials.append(mat_c)
        c_obj.parent = carapace

    # 3. Head & Heavy Pincers
    head = bpy.data.objects.new("Head", None)
    head.location = (0, -0.68, 0.35)
    bpy.context.scene.collection.objects.link(head)
    head.parent = root

    bpy.ops.mesh.primitive_cube_add(size=0.35, location=(0, 0, 0))
    cr_mesh = bpy.context.active_object
    cr_mesh.name = "HeadMesh"
    cr_mesh.scale = (0.85, 0.75, 0.45)
    bpy.ops.object.transform_apply(scale=True)
    apply_bevel(cr_mesh, 0.03, 2)
    cr_mesh.data.materials.append(mat_chitin)
    cr_mesh.parent = head

    # Eyes (Amber optical clusters)
    for side, s_name in [(-1, "L"), (1, "R")]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.05, location=(side * 0.14, -0.15, 0.06))
        c_eye = bpy.context.active_object
        c_eye.name = f"Eye_{s_name}"
        c_eye.data.materials.append(mat_eye)
        c_eye.parent = head

    # Dual Grasping Chelae / Pincers
    for side, s_name in [(-1, "L"), (1, "R")]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.045, depth=0.36, location=(side * 0.22, -0.28, -0.05))
        pincer = bpy.context.active_object
        pincer.name = f"Pincer_{s_name}"
        pincer.rotation_euler = (math.radians(20), math.radians(side * -35), math.radians(side * 20))
        bpy.ops.object.transform_apply(rotation=True)
        apply_bevel(pincer, 0.015, 2)
        pincer.data.materials.append(mat_chitin)
        pincer.parent = head

    # 4. Six Articulated Arthropod Walking Legs (L1, L2, L3, R1, R2, R3)
    leg_y_offsets = [0.35, 0.0, -0.35]
    for side_idx, (side, s_name) in enumerate([(-1, "L"), (1, "R")]):
        for pair_idx, y_off in enumerate(leg_y_offsets):
            leg_name = f"Leg_{s_name}{pair_idx+1}"
            leg_root = bpy.data.objects.new(leg_name, None)
            leg_root.location = (side * 0.48, y_off, 0.32)
            bpy.context.scene.collection.objects.link(leg_root)
            leg_root.parent = root

            # Femur (arching out and up)
            bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.055, depth=0.46, location=(side * 0.18, 0, 0.12))
            femur = bpy.context.active_object
            femur.name = f"{leg_name}_Femur"
            femur.rotation_euler = (0, math.radians(side * -45), 0)
            bpy.ops.object.transform_apply(rotation=True)
            apply_bevel(femur, 0.01, 2)
            femur.data.materials.append(mat_chitin)
            femur.parent = leg_root

            # Tibia (arching down to ground)
            bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.042, depth=0.55, location=(side * 0.42, 0, -0.10))
            tibia = bpy.context.active_object
            tibia.name = f"{leg_name}_Tibia"
            tibia.rotation_euler = (0, math.radians(side * 35), 0)
            bpy.ops.object.transform_apply(rotation=True)
            apply_bevel(tibia, 0.01, 2)
            tibia.data.materials.append(mat_chitin)
            tibia.parent = leg_root

            # Ground Claw Tip (Planting into stone at Z = 0 in world, i.e. Z = -0.32 relative to root)
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.05, depth=0.18, location=(side * 0.55, 0, -0.28))
            claw = bpy.context.active_object
            claw.name = f"{leg_name}_Claw"
            claw.data.materials.append(mat_stone)
            claw.parent = leg_root

    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            for f in obj.data.polygons:
                f.use_smooth = True

    print(f"Exporting Lithic Crawler to {output_path}...")
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=False,
        export_apply=False
    )
    print("Lithic Crawler export complete.")

def build_cryo_wisp(output_path):
    print("Building high-detail Cryo Wisp...")
    clear_scene()

    mat_ice = create_pbr_material("WispIce", (0.80, 0.92, 1.0), roughness=0.08, metallic=0.15, emission_col=(0.60, 0.85, 1.0), emission_strength=2.2)
    mat_core = create_pbr_material("WispCore", (0.45, 0.85, 1.0), roughness=0.05, metallic=0.0, emission_col=(0.35, 0.85, 1.0), emission_strength=6.0)
    mat_halo = create_pbr_material("WispHalo", (0.90, 0.96, 1.0), roughness=0.10, metallic=0.0, emission_col=(0.80, 0.95, 1.0), emission_strength=4.0)

    root = bpy.data.objects.new("WispModel", None)
    bpy.context.scene.collection.objects.link(root)

    # 1. Crystalline Geode Ice Core
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.28, location=(0, 0, 0))
    core = bpy.context.active_object
    core.name = "Core"
    core.data.materials.append(mat_core)
    core.parent = root

    # 2. Surrounding Outer Ice Prisms (Floating protective shell)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.48, location=(0, 0, 0))
    shell = bpy.context.active_object
    shell.name = "OuterShell"
    shell.scale = (0.95, 0.95, 1.35)
    bpy.ops.object.transform_apply(scale=True)
    apply_bevel(shell, 0.02, 1)
    shell.data.materials.append(mat_ice)
    shell.parent = root

    # 3. Eight Orbiting Satellite Ice Shards
    shard_count = 8
    for i in range(shard_count):
        ang = (i / shard_count) * math.pi * 2.0
        rad = 0.65 + (i % 2) * 0.15
        sz = 0.08 + (i % 3) * 0.04
        height = math.sin(ang * 2.0) * 0.22
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=sz, depth=sz * 2.8, location=(math.cos(ang) * rad, math.sin(ang) * rad, height))
        shard = bpy.context.active_object
        shard.name = f"OrbitShard_{i}"
        shard.rotation_euler = (math.radians(ang * 45), math.radians(30), math.radians(ang * 30))
        bpy.ops.object.transform_apply(rotation=True)
        apply_bevel(shard, 0.01, 1)
        shard.data.materials.append(mat_halo)
        shard.parent = root

    # 4. Spire Pinnacles (Top and bottom stalactite ice needles)
    for sign, s_name in [(1, "Top"), (-1, "Bottom")]:
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.12, depth=0.65, location=(0, 0, sign * 0.55))
        needle = bpy.context.active_object
        needle.name = f"Needle_{s_name}"
        needle.rotation_euler = (math.radians(0 if sign > 0 else 180), 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        needle.data.materials.append(mat_ice)
        needle.parent = root

    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            for f in obj.data.polygons:
                f.use_smooth = True

    print(f"Exporting Cryo Wisp to {output_path}...")
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=False,
        export_apply=False
    )
    print("Cryo Wisp export complete.")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    models_dir = os.path.join(script_dir, "models")
    os.makedirs(models_dir, exist_ok=True)
    
    stalker_path = os.path.join(models_dir, "chasm_stalker.glb")
    crawler_path = os.path.join(models_dir, "lithic_crawler.glb")
    wisp_path = os.path.join(models_dir, "cryo_wisp.glb")
    
    build_chasm_stalker(stalker_path)
    build_lithic_crawler(crawler_path)
    build_cryo_wisp(wisp_path)
    print("ALL 3D MODELS GENERATED AND EXPORTED SUCCESSFULLY!")
