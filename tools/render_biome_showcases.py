"""
Renders atmospheric, finished 3D biome showcase dioramas in Blender 4.0.
Each biome shows its authentic voxel block palette, lighting atmosphere, geological formations,
and native mob inhabitants.
"""
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector, Matrix, Euler

OUT_DIR = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/biome_showcase"
os.makedirs(OUT_DIR, exist_ok=True)
TEX_DIR = "hollow_core/textures"
MODELS_DIR = "hollow_core/models"

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_voxel_cube(name, location, texture_name, emit_color=None, emit_strength=0.0):
    mesh = bpy.data.meshes.new(f"Mesh_{name}")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(location))
    bm.to_mesh(mesh)
    bm.free()

    # Smart UV
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.01)
    bpy.ops.object.mode_set(mode='OBJECT')

    # Material
    mat = bpy.data.materials.new(name=f"Mat_{name}")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.8
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    tex_path = os.path.join(TEX_DIR, texture_name)
    if os.path.exists(tex_path):
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = bpy.data.images.load(os.path.abspath(tex_path))
        tex_node.interpolation = 'Closest'
        links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

    if emit_color and emit_strength > 0:
        if 'Emission Color' in bsdf.inputs:
            bsdf.inputs['Emission Color'].default_value = emit_color
            bsdf.inputs['Emission Strength'].default_value = emit_strength
        elif 'Emission' in bsdf.inputs:
            bsdf.inputs['Emission'].default_value = emit_color

    obj.data.materials.append(mat)
    return obj

def import_mob(glb_name, location, scale=1.0, yaw=0.0):
    path = os.path.join(MODELS_DIR, f"{glb_name}.glb")
    if not os.path.exists(path):
        print(f"Warning: GLB not found {path}")
        return None
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(path))
    imported = [obj for obj in bpy.context.selected_objects if obj.type == 'MESH']
    for obj in imported:
        obj.location = location
        obj.scale = Vector((scale, scale, scale))
        obj.rotation_euler.z = yaw
    return imported

def setup_camera_and_render(out_png, cam_pos, look_at, bg_color, lights_config):
    # Camera
    cam_data = bpy.data.cameras.new("BiomeCam")
    cam_data.lens = 42
    cam_obj = bpy.data.objects.new("BiomeCam", cam_data)
    cam_obj.location = cam_pos
    bpy.context.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Target
    target = bpy.data.objects.new("CamTarget", None)
    target.location = look_at
    bpy.context.collection.objects.link(target)

    track = cam_obj.constraints.new(type='TRACK_TO')
    track.target = target
    track.track_axis = 'TRACK_NEGATIVE_Z'
    track.up_axis = 'UP_Y'

    # Environment
    world = bpy.data.worlds.new("BiomeWorld")
    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs['Color'].default_value = bg_color
        bg_node.inputs['Strength'].default_value = 0.4
    bpy.context.scene.world = world

    # Lights
    for (pos, col, energy, l_type) in lights_config:
        l_data = bpy.data.lights.new("Light", type=l_type)
        l_data.color = col
        l_data.energy = energy
        l_obj = bpy.data.objects.new("Light", l_data)
        l_obj.location = pos
        bpy.context.collection.objects.link(l_obj)

    # Render
    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    bpy.context.scene.render.resolution_x = 1024
    bpy.context.scene.render.resolution_y = 768
    bpy.context.scene.render.filepath = os.path.abspath(out_png)
    print(f"Rendering {out_png}...")
    bpy.ops.render.render(write_still=True)
    print(f"Done rendering {out_png}")

# =========================================================================
# 1. BIOME: SURFACE BOREAS & GLACIAL CRYOSPHERE (Ледниковый Криосферный Биом)
# =========================================================================
def render_glacial_biome():
    reset_scene()
    out_png = os.path.join(OUT_DIR, "biome_01_glacial_cryosphere.png")
    
    # Permafrost floor and glacial spires
    for x in range(-3, 4):
        for y in range(-3, 4):
            create_voxel_cube("IceFloor", Vector((x, y, 0)), "permafrost_ice.png")
    # Calcite crystal columns
    for z in range(1, 4):
        create_voxel_cube("IcePillarL", Vector((-3, 1, z)), "calcite_crystal.png")
        create_voxel_cube("IcePillarR", Vector((3, -1, z)), "calcite_crystal.png")
    # Hanging ice ceiling blocks
    for x in range(-3, 4):
        create_voxel_cube("IceCeil", Vector((x, 3, 4)), "permafrost_ice.png")

    # Inhabitant: Cryo Wisp floating in center
    import_mob("cryo_wisp", Vector((0, 0, 1.6)), scale=0.9)

    lights = [
        (Vector((2, -3, 4)), (0.6, 0.85, 1.0), 900.0, 'POINT'),   # Ice cyan key
        (Vector((-3, 2, 3)), (0.4, 0.6, 0.9), 400.0, 'POINT'),    # Cool ambient
        (Vector((0, 0, 1.8)), (0.5, 0.9, 1.0), 300.0, 'POINT'),   # Wisp inner glow
    ]
    setup_camera_and_render(
        out_png,
        cam_pos=Vector((5.5, -6.5, 4.5)),
        look_at=Vector((0, 0, 1.5)),
        bg_color=(0.04, 0.08, 0.14, 1.0),
        lights_config=lights
    )

# =========================================================================
# 2. BIOME: FUNGAL MYCENA HOLLOWS (Грибные Индиговые Низины)
# =========================================================================
def render_fungal_biome():
    reset_scene()
    out_png = os.path.join(OUT_DIR, "biome_02_fungal_mycena_hollows.png")

    # Mossy stone floor & lichen roots
    for x in range(-4, 4):
        for y in range(-4, 4):
            tex = "mossy_stone.png" if (x+y)%2 == 0 else "lichen_root.png"
            create_voxel_cube("FungalFloor", Vector((x, y, 0)), tex)

    # Giant glowing mushroom blocks
    create_voxel_cube("MushroomCap1", Vector((-2, 2, 1)), "biolum_mushroom.png", emit_color=(0.1, 0.9, 1.0, 1.0), emit_strength=2.0)
    create_voxel_cube("MushroomCap2", Vector((-2, 2, 2)), "biolum_mushroom.png", emit_color=(0.1, 0.9, 1.0, 1.0), emit_strength=2.0)
    create_voxel_cube("MushroomCap3", Vector((2, -2, 1)), "biolum_mushroom.png", emit_color=(0.1, 0.9, 1.0, 1.0), emit_strength=2.0)

    # Inhabitants: Fungal Strider + Acid Spore-Spitter
    import_mob("fungal_strider", Vector((0.5, 0.5, 0.5)), scale=0.85, yaw=0.5)
    import_mob("spore_spitter", Vector((-1.8, -1.8, 0.5)), scale=0.75, yaw=-0.8)

    lights = [
        (Vector((-2, 2, 3)), (0.0, 0.8, 1.0), 800.0, 'POINT'),    # Intense bioluminescent cyan
        (Vector((3, -3, 3)), (0.4, 0.2, 0.7), 400.0, 'POINT'),    # Violet spore ambient
        (Vector((1, 2, 4)), (0.3, 0.5, 0.7), 350.0, 'POINT'),
    ]
    setup_camera_and_render(
        out_png,
        cam_pos=Vector((6.0, -7.0, 5.0)),
        look_at=Vector((0, 0, 1.6)),
        bg_color=(0.02, 0.03, 0.06, 1.0),
        lights_config=lights
    )

# =========================================================================
# 3. BIOME: AMETHYST & CALCITE CRYSTAL POCKET (Аметистово-Геодовые Каверны)
# =========================================================================
def render_amethyst_biome():
    reset_scene()
    out_png = os.path.join(OUT_DIR, "biome_03_amethyst_calcite_pocket.png")

    # Deep basalt and andesite floor
    for x in range(-3, 4):
        for y in range(-3, 4):
            tex = "deep_basalt.png" if abs(x) > 1 else "andesite_rock.png"
            create_voxel_cube("BasaltFloor", Vector((x, y, 0)), tex)

    # Amethyst crystal cluster geode wall
    for z in range(1, 4):
        for x in range(-3, 1):
            create_voxel_cube("AmethystWall", Vector((x, 3, z)), "crystal_amethyst.png", emit_color=(0.8, 0.3, 1.0, 1.0), emit_strength=1.5)
    for z in range(1, 3):
        create_voxel_cube("CalciteCluster", Vector((2, 2, z)), "calcite_crystal.png")

    # Inhabitant: Lithic Crawler crawling amidst the crystals
    import_mob("lithic_crawler", Vector((0.2, -0.2, 0.5)), scale=1.0, yaw=-0.4)

    lights = [
        (Vector((-1, 2, 3.5)), (0.85, 0.35, 1.0), 850.0, 'POINT'), # Amethyst purple glow
        (Vector((3, -2, 3)), (0.5, 0.6, 0.9), 450.0, 'POINT'),     # Calcite rim
        (Vector((0, -3, 2)), (0.8, 0.7, 0.6), 300.0, 'POINT'),     # Lantern warm glow
    ]
    setup_camera_and_render(
        out_png,
        cam_pos=Vector((5.2, -6.0, 4.2)),
        look_at=Vector((0, 0, 1.2)),
        bg_color=(0.03, 0.02, 0.05, 1.0),
        lights_config=lights
    )

# =========================================================================
# 4. BIOME: PRECURSOR SANCTUARY & CONDUITS (Святилище Предтеч)
# =========================================================================
def render_precursor_biome():
    reset_scene()
    out_png = os.path.join(OUT_DIR, "biome_04_precursor_sanctuary.png")

    # Slate brick floor with precursor conduit cross
    for x in range(-3, 4):
        for y in range(-3, 4):
            is_conduit = (x == 0 or y == 0)
            tex = "precursor_conduit.png" if is_conduit else "slate_brick.png"
            emit = (0.0, 0.9, 1.0, 1.0) if is_conduit else None
            create_voxel_cube("RuinFloor", Vector((x, y, 0)), tex, emit_color=emit, emit_strength=2.2 if is_conduit else 0.0)

    # Ancient ruined portal archway
    for z in range(1, 5):
        create_voxel_cube("PillarL", Vector((-2, 2, z)), "slate_brick.png")
        create_voxel_cube("PillarR", Vector((2, 2, z)), "slate_brick.png")
    create_voxel_cube("ArchTopL", Vector((-1, 2, 4)), "precursor_conduit.png", emit_color=(0.0, 0.9, 1.0, 1.0), emit_strength=2.0)
    create_voxel_cube("ArchTopR", Vector((1, 2, 4)), "precursor_conduit.png", emit_color=(0.0, 0.9, 1.0, 1.0), emit_strength=2.0)
    create_voxel_cube("ArchCore", Vector((0, 2, 4)), "precursor_conduit.png", emit_color=(1.0, 0.8, 0.2, 1.0), emit_strength=3.5)

    # Inhabitant: Geode Golem standing guard
    import_mob("geode_golem", Vector((0, 1.2, 0.5)), scale=0.85, yaw=0.0)

    lights = [
        (Vector((0, 2, 4.5)), (0.0, 0.85, 1.0), 950.0, 'POINT'),  # Precursor blue conduit energy
        (Vector((0, 1, 2.5)), (1.0, 0.85, 0.3), 500.0, 'POINT'),  # Golden relic core glow
        (Vector((4, -4, 3)), (0.4, 0.45, 0.55), 400.0, 'POINT'),  # Chiseled masonry ambient
    ]
    setup_camera_and_render(
        out_png,
        cam_pos=Vector((5.5, -6.5, 4.8)),
        look_at=Vector((0, 1.0, 1.8)),
        bg_color=(0.02, 0.03, 0.04, 1.0),
        lights_config=lights
    )

# =========================================================================
# 5. BIOME: MOLTEN MAGMA RESERVOIR & SULFUR CALDERA (Вулканический Разлом)
# =========================================================================
def render_magma_biome():
    reset_scene()
    out_png = os.path.join(OUT_DIR, "biome_05_magma_sulfur_caldera.png")

    # Magma & sulfur floor
    for x in range(-3, 4):
        for y in range(-3, 4):
            if abs(x) <= 1:
                create_voxel_cube("MagmaRiver", Vector((x, y, 0)), "magma_rock.png", emit_color=(1.0, 0.45, 0.05, 1.0), emit_strength=3.0)
            elif x > 1:
                create_voxel_cube("SulfurBank", Vector((x, y, 0)), "sulfur_block.png")
            else:
                create_voxel_cube("BasaltCrag", Vector((x, y, 0)), "deep_basalt.png")

    # Volcanic obsidian spires
    create_voxel_cube("MagmaPillar1", Vector((-3, 1, 1)), "magma_rock.png", emit_color=(1.0, 0.4, 0.0, 1.0), emit_strength=2.5)
    create_voxel_cube("MagmaPillar2", Vector((-3, 1, 2)), "deep_basalt.png")

    # Inhabitant: Magma Basilisk patrolling the lava fissure
    import_mob("magma_basilisk", Vector((0.0, 0.0, 0.5)), scale=0.9, yaw=0.3)

    lights = [
        (Vector((0, 0, 1.5)), (1.0, 0.35, 0.05), 1100.0, 'POINT'), # Fierce molten lava underglow
        (Vector((3, 2, 3)), (0.9, 0.85, 0.2), 500.0, 'POINT'),     # Sulfur steam ambient
        (Vector((-3, -3, 3)), (0.3, 0.15, 0.1), 300.0, 'POINT'),
    ]
    setup_camera_and_render(
        out_png,
        cam_pos=Vector((5.2, -6.2, 4.2)),
        look_at=Vector((0, 0, 1.2)),
        bg_color=(0.06, 0.02, 0.01, 1.0),
        lights_config=lights
    )

# =========================================================================
# 6. BIOME: BASALTIC DEEPSLATE & CHASM TRENCH (Базальтовые Расщелины)
# =========================================================================
def render_abyss_trench_biome():
    reset_scene()
    out_png = os.path.join(OUT_DIR, "biome_06_basaltic_chasm_trench.png")

    # Deepslate rock & gravel floor
    for x in range(-3, 4):
        for y in range(-3, 4):
            tex = "deepslate_rock.png" if y >= 0 else "cavern_gravel.png"
            create_voxel_cube("TrenchFloor", Vector((x, y, 0)), tex)

    # Chasm wall rising behind
    for z in range(1, 4):
        for x in range(-3, 4):
            create_voxel_cube("ChasmWall", Vector((x, 3, z)), "cobblestone_shale.png")

    # Inhabitants: Chasm Stalker on the prowl + Deep Cave Wyrm surfacing
    import_mob("chasm_stalker", Vector((-1.0, 0.5, 0.5)), scale=0.85, yaw=-0.5)
    import_mob("cave_wyrm", Vector((1.5, -0.5, 0.5)), scale=0.8, yaw=0.8)

    lights = [
        (Vector((2, -3, 3)), (0.7, 0.65, 0.55), 750.0, 'POINT'),  # Cold karst exploration light
        (Vector((-2, 2, 3)), (0.2, 0.6, 0.8), 350.0, 'POINT'),   # Distant phosphor gleam
        (Vector((0, -1, 4)), (0.35, 0.38, 0.45), 300.0, 'POINT'),
    ]
    setup_camera_and_render(
        out_png,
        cam_pos=Vector((5.4, -6.5, 4.2)),
        look_at=Vector((0, 0.5, 1.4)),
        bg_color=(0.02, 0.02, 0.03, 1.0),
        lights_config=lights
    )

def main():
    print("--> Commencing 3D Biome Showcase Rendering...")
    render_glacial_biome()
    render_fungal_biome()
    render_amethyst_biome()
    render_precursor_biome()
    render_magma_biome()
    render_abyss_trench_biome()
    print("All 6 Biome Showcase Dioramas successfully rendered!")

if __name__ == "__main__":
    main()
