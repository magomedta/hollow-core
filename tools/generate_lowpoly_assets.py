# tools/generate_lowpoly_assets.py
import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler

MODELS_DIR = r"c:\Users\magom\Downloads\twitchst\hollow_core\models"
os.makedirs(MODELS_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, albedo_rgb, roughness=0.7, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (*albedo_rgb, 1.0)
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    return mat

def build_cassette_tape():
    clear_scene()
    print("[Blender] Building low-poly Compact Cassette model...")
    
    w, h, d = 0.100, 0.012, 0.064
    
    mat_shell = create_pbr_material("CassetteShellMat", (0.13, 0.14, 0.16), roughness=0.55, metallic=0.1)
    mat_label = create_pbr_material("CassetteLabelMat", (0.84, 0.80, 0.70), roughness=0.85, metallic=0.0)
    mat_tape = create_pbr_material("CassetteTapeMat", (0.22, 0.12, 0.08), roughness=0.40, metallic=0.1)
    mat_spool = create_pbr_material("CassetteSpoolMat", (0.92, 0.92, 0.89), roughness=0.45, metallic=0.0)
    mat_window = create_pbr_material("CassetteWindowMat", (0.05, 0.07, 0.08), roughness=0.15, metallic=0.2)
    
    # Base shell
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    shell = bpy.context.active_object
    shell.name = "CassetteShell"
    shell.scale = (w, d, h)
    bpy.ops.object.transform_apply(scale=True)
    shell.data.materials.append(mat_shell)
    
    # Head guide taper at bottom
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    guide = bpy.context.active_object
    guide.name = "TapeHeadGuide"
    guide.scale = (0.064, 0.0135, 0.014)
    guide.location = (0.0, 0.0, -0.028)
    bpy.ops.object.transform_apply(location=True, scale=True)
    guide.data.materials.append(mat_shell)
    
    # Paper label plate (front face)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    label = bpy.context.active_object
    label.name = "PaperLabel"
    label.scale = (0.088, 0.001, 0.046)
    label.location = (0.0, 0.0062, 0.004)
    bpy.ops.object.transform_apply(location=True, scale=True)
    label.data.materials.append(mat_label)
    
    # Center inspection window
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    win = bpy.context.active_object
    win.name = "CenterWindow"
    win.scale = (0.046, 0.0015, 0.020)
    win.location = (0.0, 0.0065, 0.004)
    bpy.ops.object.transform_apply(location=True, scale=True)
    win.data.materials.append(mat_window)
    
    # Spools and tape
    for sx in [-0.021, 0.021]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.0075, depth=0.013, vertices=8)
        spool = bpy.context.active_object
        spool.name = f"SpoolHub_{'L' if sx < 0 else 'R'}"
        spool.location = (sx, 0.0, 0.004)
        spool.rotation_euler = (math.pi * 0.5, 0, 0)
        bpy.ops.object.transform_apply(location=True, rotation=True)
        spool.data.materials.append(mat_spool)
        
        tape_r = 0.014 if sx < 0 else 0.011
        bpy.ops.mesh.primitive_cylinder_add(radius=tape_r, depth=0.009, vertices=8)
        tape = bpy.context.active_object
        tape.name = f"TapeReel_{'L' if sx < 0 else 'R'}"
        tape.location = (sx, 0.0, 0.004)
        tape.rotation_euler = (math.pi * 0.5, 0, 0)
        bpy.ops.object.transform_apply(location=True, rotation=True)
        tape.data.materials.append(mat_tape)
    
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = shell
    bpy.ops.object.join()
    shell.name = "CassetteTape"
    
    out_path = os.path.join(MODELS_DIR, "cassette_tape.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB')
    print(f"[Blender] Saved: {out_path} ({os.path.getsize(out_path)} bytes)")

def build_first_person_arm():
    clear_scene()
    print("[Blender] Building authentic retro Low-Poly First-Person Arm & Hand...")
    
    # Palette: Charcoal-slate heavy expedition wool, warm saddle leather glove, dark wrist cuff
    mat_sleeve = create_pbr_material("SleeveWoolMat", (0.16, 0.19, 0.22), roughness=0.92, metallic=0.0)
    mat_cuff = create_pbr_material("LeatherCuffMat", (0.22, 0.15, 0.10), roughness=0.75, metallic=0.0)
    mat_glove = create_pbr_material("SaddleLeatherGloveMat", (0.42, 0.28, 0.16), roughness=0.65, metallic=0.05)
    mat_buckle = create_pbr_material("BrassBuckleMat", (0.80, 0.65, 0.28), roughness=0.35, metallic=0.85)

    # In Blender:
    # glTF X = Blender X (Right)
    # glTF Y = Blender Z (Up)
    # glTF Z = -Blender Y (Backward towards camera)
    #
    # We want forearm to extend from Hand at (0, 0, 0) to Elbow at:
    # Godot: (+0.14 right, -0.20 down, +0.45 backward offscreen)
    # Therefore in Blender coordinates:
    # Blender X = +0.14
    # Blender Z = -0.20
    # Blender Y = -0.45
    bm = bmesh.new()
    
    segments = [
        # (center_vec, radius_x, radius_cross)
        (Vector((0.14, -0.45, -0.20)), 0.054, 0.050), # Elbow / shoulder off-screen
        (Vector((0.10, -0.32, -0.14)), 0.048, 0.044), # Upper forearm
        (Vector((0.06, -0.20, -0.09)), 0.042, 0.038), # Mid forearm
        (Vector((0.03, -0.10, -0.04)), 0.036, 0.033), # Lower forearm
        (Vector((0.01, -0.03, -0.01)), 0.032, 0.029), # Wrist joint
    ]
    
    rings = []
    n_verts = 8
    for pos, rx, ry in segments:
        ring = []
        for i in range(n_verts):
            ang = i * (2.0 * math.pi / n_verts)
            # Normal plane perpendicular to arm direction
            vx = pos.x + math.cos(ang) * rx
            vy = pos.y + math.sin(ang) * ry * 0.7
            vz = pos.z + math.sin(ang) * ry * 0.7
            vert = bm.verts.new((vx, vy, vz))
            ring.append(vert)
        rings.append(ring)
    
    for r in range(len(rings) - 1):
        for i in range(n_verts):
            v0 = rings[r][i]
            v1 = rings[r][(i + 1) % n_verts]
            v2 = rings[r + 1][(i + 1) % n_verts]
            v3 = rings[r + 1][i]
            bm.faces.new([v0, v1, v2, v3])
    # Cap the off-screen elbow end
    bm.faces.new(rings[0])
    
    mesh = bpy.data.meshes.new("SleeveMesh")
    bm.to_mesh(mesh)
    bm.free()
    
    sleeve_obj = bpy.data.objects.new("ArmSleeve", mesh)
    bpy.context.scene.collection.objects.link(sleeve_obj)
    sleeve_obj.data.materials.append(mat_sleeve)

    # 2. Leather Wrist Cuff
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.032, vertices=10)
    cuff_obj = bpy.context.active_object
    cuff_obj.name = "WristCuff"
    cuff_obj.location = (0.015, -0.04, -0.015)
    cuff_obj.rotation_euler = (math.radians(-25), math.radians(15), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True)
    cuff_obj.data.materials.append(mat_cuff)
    
    # Brass buckle
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    buckle = bpy.context.active_object
    buckle.name = "CuffBuckle"
    buckle.scale = (0.008, 0.012, 0.006)
    buckle.location = (0.046, -0.04, -0.015)
    bpy.ops.object.transform_apply(location=True, scale=True)
    buckle.data.materials.append(mat_buckle)

    # 3. Low-Poly Gloved Hand Palm
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    palm = bpy.context.active_object
    palm.name = "HandPalm"
    palm.scale = (0.052, 0.048, 0.036)
    palm.location = (0.0, 0.0, 0.0)
    bpy.ops.object.transform_apply(location=True, scale=True)
    palm.data.materials.append(mat_glove)

    # 4. Curled Fingers wrapped around grip
    bpy.ops.mesh.primitive_cylinder_add(radius=0.016, depth=0.048, vertices=8)
    fingers = bpy.context.active_object
    fingers.name = "CurledFingers"
    fingers.location = (0.0, 0.024, -0.014)
    fingers.rotation_euler = (0, 0, math.pi * 0.5)
    fingers.scale = (1.1, 0.85, 1.0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    fingers.data.materials.append(mat_glove)

    # 5. Opposing Thumb
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    thumb = bpy.context.active_object
    thumb.name = "Thumb"
    thumb.scale = (0.016, 0.028, 0.018)
    thumb.location = (-0.025, 0.012, 0.012)
    thumb.rotation_euler = (math.radians(-20), math.radians(25), math.radians(15))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    thumb.data.materials.append(mat_glove)

    # Join arm and hand into single articulated First-Person Arm mesh
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = sleeve_obj
    bpy.ops.object.join()
    sleeve_obj.name = "FirstPersonArm"
    
    out_path = os.path.join(MODELS_DIR, "first_person_arm.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB')
    print(f"[Blender] Saved: {out_path} ({os.path.getsize(out_path)} bytes)")

if __name__ == "__main__":
    build_cassette_tape()
    build_first_person_arm()
