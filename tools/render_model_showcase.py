# hollow_core/tools/render_model_showcase.py
import bpy
import math
import os

MODELS = [
    ("chasm_stalker.glb", "render_chasm_stalker.png", (0, 0, 0.7), 3.0),
    ("lithic_crawler.glb", "render_lithic_crawler.png", (0, 0, 0.35), 2.2),
    ("cryo_wisp.glb", "render_cryo_wisp.png", (0, 0, 0.6), 2.4),
    ("magma_basilisk.glb", "render_magma_basilisk.png", (0, 0, 0.45), 3.4),
    ("fungal_strider.glb", "render_fungal_strider.png", (0, 0, 1.1), 3.2),
    ("geode_golem.glb", "render_geode_golem.png", (0, 0, 1.0), 3.2),
    ("prospector_pickaxe.glb", "render_prospector_pickaxe.png", (0, 0, 0.0), 1.2),
    ("expedition_lantern.glb", "render_expedition_lantern.png", (0, 0, 0.05), 0.9),
]

def render_model(glb_path, out_png, look_at=(0, 0, 0), cam_dist=2.5):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    # 1. Import model
    bpy.ops.import_scene.gltf(filepath=glb_path)
    
    # 2. Create Target Empty at look_at
    target_empty = bpy.data.objects.new("TargetEmpty", None)
    target_empty.location = look_at
    bpy.context.scene.collection.objects.link(target_empty)
    
    # 3. Create Camera with Track To constraint
    cam_data = bpy.data.cameras.new("StudioCamera")
    cam_data.lens = 45.0
    cam_obj = bpy.data.objects.new("StudioCamera", cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    # Place camera in front-right-high
    cam_obj.location = (look_at[0] + cam_dist * 0.75, look_at[1] - cam_dist * 0.85, look_at[2] + cam_dist * 0.55)
    
    track = cam_obj.constraints.new(type='TRACK_TO')
    track.target = target_empty
    track.track_axis = 'TRACK_NEGATIVE_Z'
    track.up_axis = 'UP_Y'
    
    # 4. Sun & Rim Lighting (Clean, bright studio setup)
    sun1_data = bpy.data.lights.new(name="SunKey", type='SUN')
    sun1_data.energy = 5.0
    sun1_data.color = (1.0, 0.96, 0.90)
    sun1_obj = bpy.data.objects.new(name="SunKey", object_data=sun1_data)
    sun1_obj.rotation_euler = (math.radians(45), math.radians(15), math.radians(-40))
    bpy.context.scene.collection.objects.link(sun1_obj)
    
    sun2_data = bpy.data.lights.new(name="SunFill", type='SUN')
    sun2_data.energy = 2.5
    sun2_data.color = (0.75, 0.85, 1.0)
    sun2_obj = bpy.data.objects.new(name="SunFill", object_data=sun2_data)
    sun2_obj.rotation_euler = (math.radians(35), math.radians(-25), math.radians(50))
    bpy.context.scene.collection.objects.link(sun2_obj)
    
    rim_data = bpy.data.lights.new(name="PointRim", type='POINT')
    rim_data.energy = 250.0
    rim_data.color = (0.9, 0.95, 1.0)
    rim_obj = bpy.data.objects.new(name="PointRim", object_data=rim_data)
    rim_obj.location = (look_at[0] - 1.2, look_at[1] + 1.8, look_at[2] + 1.2)
    bpy.context.scene.collection.objects.link(rim_obj)
    
    # 5. Render settings
    scene = bpy.context.scene
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.filepath = out_png
    
    world = bpy.data.worlds.new("StudioWorld")
    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs['Color'].default_value = (0.08, 0.09, 0.11, 1.0)
        bg_node.inputs['Strength'].default_value = 1.0
    scene.world = world
    
    bpy.ops.render.render(write_still=True)
    print(f"[BlenderRender] Successfully rendered: {out_png}")

if __name__ == "__main__":
    models_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "models"))
    out_dir = r"C:\Users\magom\.gemini\antigravity\brain\0542bc81-f515-4a83-9026-0d1a0ef0a4de\model_showcase"
    os.makedirs(out_dir, exist_ok=True)
    
    for glb_name, png_name, target, dist in MODELS:
        glb_p = os.path.join(models_dir, glb_name)
        out_p = os.path.join(out_dir, png_name)
        if os.path.exists(glb_p):
            render_model(glb_p, out_p, target, dist)
        else:
            print(f"[BlenderRender] Missing: {glb_p}")
    print("[BlenderRender] All renders finished!")
