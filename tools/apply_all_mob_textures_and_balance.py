# tools/apply_all_mob_textures_and_balance.py
import re

def update_cave_wyrm():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/cave_wyrm.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # Rebalance
    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 45.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 45.0", text)
    text = re.sub(r"@export var burrow_speed: float = \d+\.\d+", "@export var burrow_speed: float = 1.9", text)
    text = re.sub(r"@export var bite_damage: float = \d+\.\d+", "@export var bite_damage: float = 7.0", text)

    # Add bespoke texture loading in _load_model()
    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/cave_wyrm.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/cave_wyrm.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_cave_wyrm.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_cave_wyrm_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.0
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated cave_wyrm.gd")

def update_fungal_strider():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/fungal_strider.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 40.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 40.0", text)

    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/fungal_strider.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/fungal_strider.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_fungal_strider.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_fungal_strider_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.5
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated fungal_strider.gd")

def update_geode_golem():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/geode_golem.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 75.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 75.0", text)
    text = re.sub(r"@export var move_speed: float = \d+\.\d+", "@export var move_speed: float = 1.1", text)
    text = re.sub(r"@export var attack_damage: float = \d+\.\d+", "@export var attack_damage: float = 12.0", text)

    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/geode_golem.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/geode_golem.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_geode_golem.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_geode_golem_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.2
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated geode_golem.gd")

def update_magma_basilisk():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/magma_basilisk.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 45.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 45.0", text)
    text = re.sub(r"@export var move_speed: float = \d+\.\d+", "@export var move_speed: float = 2.2", text)
    text = re.sub(r"@export var attack_damage: float = \d+\.\d+", "@export var attack_damage: float = 8.0", text)

    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/magma_basilisk.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/magma_basilisk.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_magma_basilisk.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_magma_basilisk_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.6
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated magma_basilisk.gd")

def update_pale_stalker():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/pale_stalker.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 35.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 35.0", text)
    text = re.sub(r"@export var crawl_speed: float = \d+\.\d+", "@export var crawl_speed: float = 2.4", text)
    text = re.sub(r"@export var stalk_speed: float = \d+\.\d+", "@export var stalk_speed: float = 1.0", text)
    text = re.sub(r"@export var attack_damage: float = \d+\.\d+", "@export var attack_damage: float = 8.0", text)

    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/pale_lurker.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/pale_lurker.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_pale_lurker.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_pale_lurker_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.5
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated pale_stalker.gd")

def update_spore_spitter():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/spore_spitter.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 30.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 30.0", text)
    text = re.sub(r"@export var acid_damage: float = \d+\.\d+", "@export var acid_damage: float = 6.0", text)

    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/spore_spitter.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/spore_spitter.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_spore_spitter.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_spore_spitter_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.5
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated spore_spitter.gd")

def update_wall_mimic():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/wall_mimic.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 35.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 35.0", text)
    text = re.sub(r"@export var attack_damage: float = \d+\.\d+", "@export var attack_damage: float = 7.0", text)
    text = re.sub(r"@export var lunge_speed: float = \d+\.\d+", "@export var lunge_speed: float = 2.8", text)

    target = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/wall_mimic.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)"""

    replacement = """func _load_model() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "ModelRoot"
\tadd_child(model_root)
\tvar glb = load("res://models/wall_mimic.glb")
\tif glb:
\t\tvar inst = glb.instantiate()
\t\tmodel_root.add_child(inst)
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_wall_mimic.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_wall_mimic_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.2
\t\t_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)"""

    text = text.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated wall_mimic.gd")

def update_chasm_stalker():
    path = "c:/Users/magom/Downloads/twitchst/hollow_core/scripts/chasm_stalker.gd"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"@export var max_health: float = \d+\.\d+", "@export var max_health: float = 40.0", text)
    text = re.sub(r"@export var current_health: float = \d+\.\d+", "@export var current_health: float = 40.0", text)
    text = re.sub(r"@export var walk_speed: float = \d+\.\d+", "@export var walk_speed: float = 1.4", text)
    text = re.sub(r"@export var run_speed: float = \d+\.\d+", "@export var run_speed: float = 2.9", text)
    text = re.sub(r"@export var attack_damage: float = \d+\.\d+", "@export var attack_damage: float = 7.0", text)

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("Updated chasm_stalker.gd")

if __name__ == "__main__":
    update_cave_wyrm()
    update_fungal_strider()
    update_geode_golem()
    update_magma_basilisk()
    update_pale_stalker()
    update_spore_spitter()
    update_wall_mimic()
    update_chasm_stalker()
    print("All mobs successfully updated with bespoke textures and balanced combat stats!")
