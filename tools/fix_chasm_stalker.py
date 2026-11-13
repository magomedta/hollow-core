import os

path = 'hollow_core/scripts/chasm_stalker.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

idx_ready = text.find('func _ready() -> void:')
idx_phys = text.find('func _physics_process(delta: float) -> void:')

replacement = """func _ready() -> void:
\tadd_to_group("enemies")
\t_setup_collision()
\t_construct_chasm_stalker_mesh()
\t_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	col.name = "Collision"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		if player_ref.has_signal("acoustic_noise_emitted"):
			player_ref.acoustic_noise_emitted.connect(_on_acoustic_noise_emitted)

func _construct_chasm_stalker_mesh() -> void:
	model_root = Node3D.new()
	model_root.name = "StalkerModel"
	add_child(model_root)

	var glb_res = load("res://models/chasm_stalker.glb")
	if glb_res:
		var glb_inst = glb_res.instantiate()
		glb_inst.name = "BlenderHighDetailMesh"
		model_root.add_child(glb_inst)
		
		var bespoke_mat = StandardMaterial3D.new()
		bespoke_mat.albedo_texture = load("res://textures/mobs/tex_chasm_stalker.png")
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		bespoke_mat.emission_texture = load("res://textures/mobs/tex_chasm_stalker_emit.png")
		bespoke_mat.emission_energy_multiplier = 3.5
		
		_apply_material_recursive(glb_inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		mi.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

"""

new_text = text[:idx_ready] + replacement + text[idx_phys:]
with open(path, 'w', encoding='utf-8') as f:
    f.write(new_text)
print("Successfully cleaned up chasm_stalker.gd!")
