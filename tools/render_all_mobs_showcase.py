"""
Renders showcase beauty shots for all 9 mobs with studio 3-point lighting and auto-framing.
"""
import bpy
import os
import sys
import math
from mathutils import Vector

OUT_DIR = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/model_showcase"
os.makedirs(OUT_DIR, exist_ok=True)
MODELS_DIR = "hollow_core/models"

MOBS = [
    "chasm_stalker",
    "lithic_crawler",
    "cryo_wisp",
    "magma_basilisk",
    "fungal_strider",
    "geode_golem",
    "abyssal_glider",
    "cave_wyrm",
    "spore_spitter",
]

def setup_render_scene(model_path, out_png):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    # Import GLB
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(model_path))
    
    # Find imported objects
    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    if not mesh_objs:
        print(f"Warning: No mesh found in {model_path}")
        return

    # Calculate collective center and max dimension
    all_bounds = []
    for obj in mesh_objs:
        for corner in obj.bound_box:
            world_c = obj.matrix_world @ Vector(corner)
            all_bounds.append(world_c)

    min_x = min(v.x for v in all_bounds)
    max_x = max(v.x for v in all_bounds)
    min_y = min(v.y for v in all_bounds)
    max_y = max(v.y for v in all_bounds)
    min_z = min(v.z for v in all_bounds)
    max_z = max(v.z for v in all_bounds)

    center = Vector(((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5))
    size = max(max_x - min_x, max_y - min_y, max_z - min_z)
    size = max(size, 0.5)

    # Empty target at center
    target = bpy.data.objects.new("LookTarget", None)
    target.location = center
    bpy.context.collection.objects.link(target)

    # Camera with 3/4 front hero perspective
    cam_dist = size * 2.2
    cam_data = bpy.data.cameras.new("ShowcaseCam")
    cam_data.lens = 50
    cam_obj = bpy.data.objects.new("ShowcaseCam", cam_data)
    
    # Place camera in front of mobs (faces point towards +Y)
    cam_obj.location = center + Vector((cam_dist * 0.85, cam_dist * 1.10, cam_dist * 0.70))
    bpy.context.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Track To Constraint
    track = cam_obj.constraints.new(type='TRACK_TO')
    track.target = target
    track.track_axis = 'TRACK_NEGATIVE_Z'
    track.up_axis = 'UP_Y'

    # 3-Point Studio Lighting
    # Key Light (Warm mineral studio) in front
    key_light = bpy.data.lights.new("KeyLight", type='POINT')
    key_light.energy = 900.0 * (size ** 1.5)
    key_light.color = (1.0, 0.95, 0.90)
    key_obj = bpy.data.objects.new("KeyLight", key_light)
    key_obj.location = center + Vector((size * 1.5, size * 1.8, size * 1.8))
    bpy.context.collection.objects.link(key_obj)

    # Fill Light (Cool subterranean ambient)
    fill_light = bpy.data.lights.new("FillLight", type='POINT')
    fill_light.energy = 450.0 * (size ** 1.5)
    fill_light.color = (0.75, 0.85, 1.0)
    fill_obj = bpy.data.objects.new("FillLight", fill_light)
    fill_obj.location = center + Vector((-size * 1.8, size * 1.2, size * 1.2))
    bpy.context.collection.objects.link(fill_obj)

    # Rim / Back Light (High silhouette contrast) from behind
    rim_light = bpy.data.lights.new("RimLight", type='POINT')
    rim_light.energy = 850.0 * (size ** 1.5)
    rim_light.color = (0.9, 0.95, 1.0)
    rim_obj = bpy.data.objects.new("RimLight", rim_light)
    rim_obj.location = center + Vector((0, -size * 2.2, size * 1.8))
    bpy.context.collection.objects.link(rim_obj)

    # Environment Background (Neutral Slate Gray)
    world = bpy.data.worlds.new("StudioWorld")
    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs['Color'].default_value = (0.16, 0.18, 0.22, 1.0)
        bg_node.inputs['Strength'].default_value = 0.6
    bpy.context.scene.world = world

    # Render Settings
    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    bpy.context.scene.render.resolution_x = 1024
    bpy.context.scene.render.resolution_y = 768
    bpy.context.scene.render.filepath = os.path.abspath(out_png)

    print(f"Rendering {out_png}...")
    bpy.ops.render.render(write_still=True)
    print(f"Done rendering {out_png}")

def main():
    for mob in MOBS:
        glb_path = os.path.join(MODELS_DIR, f"{mob}.glb")
        out_png = os.path.join(OUT_DIR, f"render_{mob}.png")
        if os.path.exists(glb_path):
            setup_render_scene(glb_path, out_png)
        else:
            print(f"Skipping {mob}, file not found: {glb_path}")

if __name__ == "__main__":
    main()
