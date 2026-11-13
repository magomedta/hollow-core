import os

path = 'hollow_core/scripts/lithic_crawler.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

idx_construct = text.find('func _construct_crawler_mesh() -> void:')
idx_phys = text.find('func _physics_process(delta: float) -> void:')

replacement = """func _construct_crawler_mesh() -> void:
\tmodel_root = Node3D.new()
\tmodel_root.name = "CrawlerModel"
\tadd_child(model_root)

\tvar glb_res = load("res://models/lithic_crawler.glb")
\tif glb_res:
\t\tvar glb_inst = glb_res.instantiate()
\t\tglb_inst.name = "BlenderHighDetailMesh"
\t\tmodel_root.add_child(glb_inst)
\t\t
\t\tvar bespoke_mat = StandardMaterial3D.new()
\t\tvar img = Image.load_from_file("res://textures/mobs/tex_lithic_crawler.png")
\t\tif img:
\t\t\tbespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
\t\tbespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
\t\tbespoke_mat.emission_enabled = true
\t\tvar emit_img = Image.load_from_file("res://textures/mobs/tex_lithic_crawler_emit.png")
\t\tif emit_img:
\t\t\tbespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
\t\tbespoke_mat.emission_energy_multiplier = 3.5
\t\t
\t\t_apply_material_recursive(glb_inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
\tif node is MeshInstance3D:
\t\tvar mi: MeshInstance3D = node
\t\tmi.material_override = mat
\tfor child in node.get_children():
\t\t_apply_material_recursive(child, mat)

"""

new_text = text[:idx_construct] + replacement + text[idx_phys:]
with open(path, 'w', encoding='utf-8') as f:
    f.write(new_text)
print("Successfully cleaned up lithic_crawler.gd!")
