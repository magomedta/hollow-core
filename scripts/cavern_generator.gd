# scripts/cavern_generator.gd
extends Node3D

const OreNodeClass = preload("res://scripts/ore_node.gd")
const MinableBlockClass = preload("res://scripts/minable_block.gd")
const BuildingSystemClass = preload("res://scripts/building_system.gd")
const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")
const DroppedItemClass = preload("res://scripts/dropped_item.gd")

@export var cavern_width: float = 110.0
@export var cavern_length: float = 140.0
@export var cavern_height: float = 65.0
@export var seed_val: int = 1337
@export var use_voxel_terrain: bool = true

# Diverse 64x64 Materials
var deep_basalt_material: StandardMaterial3D
var cobblestone_material: StandardMaterial3D
var mossy_stone_material: StandardMaterial3D
var slate_brick_material: StandardMaterial3D
var gravel_material: StandardMaterial3D
var wood_plank_material: StandardMaterial3D
var hewn_timber_material: StandardMaterial3D
var crate_material: StandardMaterial3D
var brass_material: StandardMaterial3D
var industrial_steel_material: StandardMaterial3D
var hazard_steel_material: StandardMaterial3D
var columnar_basalt_material: StandardMaterial3D
var bio_material: StandardMaterial3D
var bio_crystal_material: StandardMaterial3D

func _ready() -> void:
	_init_materials()
	_generate_cavern()

func _init_materials() -> void:
	# 1. Deep Basalt (Vault ceiling, chasm floor)
	deep_basalt_material = StandardMaterial3D.new()
	deep_basalt_material.albedo_texture = PixelTextureGenerator.get_deep_basalt_texture()
	deep_basalt_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	deep_basalt_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	deep_basalt_material.uv1_triplanar = true
	deep_basalt_material.uv1_world_triplanar = true
	deep_basalt_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	deep_basalt_material.uv1_triplanar_sharpness = 150.0
	deep_basalt_material.roughness = 0.88
	deep_basalt_material.metallic = 0.02

	# 2. Cobblestone Shale (Main upper cavern floor)
	cobblestone_material = StandardMaterial3D.new()
	cobblestone_material.albedo_texture = PixelTextureGenerator.get_cobblestone_texture()
	cobblestone_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cobblestone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cobblestone_material.uv1_triplanar = true
	cobblestone_material.uv1_world_triplanar = true
	cobblestone_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	cobblestone_material.uv1_triplanar_sharpness = 150.0
	cobblestone_material.roughness = 0.85
	cobblestone_material.metallic = 0.03

	# 3. Mossy Damp Stone (Lichen grotto & moisture pockets)
	mossy_stone_material = StandardMaterial3D.new()
	mossy_stone_material.albedo_texture = PixelTextureGenerator.get_mossy_stone_texture()
	mossy_stone_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mossy_stone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mossy_stone_material.uv1_triplanar = true
	mossy_stone_material.uv1_world_triplanar = true
	mossy_stone_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mossy_stone_material.uv1_triplanar_sharpness = 150.0
	mossy_stone_material.roughness = 0.90

	# 4. Slate Brick (East Plateau Precursor Ruins)
	slate_brick_material = StandardMaterial3D.new()
	slate_brick_material.albedo_texture = PixelTextureGenerator.get_slate_brick_texture()
	slate_brick_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	slate_brick_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	slate_brick_material.uv1_triplanar = true
	slate_brick_material.uv1_world_triplanar = true
	slate_brick_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	slate_brick_material.uv1_triplanar_sharpness = 150.0
	slate_brick_material.roughness = 0.80

	# 5. Cavern Gravel & Loam (Outpost plateau ground)
	gravel_material = StandardMaterial3D.new()
	gravel_material.albedo_texture = PixelTextureGenerator.get_cavern_gravel_texture()
	gravel_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	gravel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	gravel_material.uv1_triplanar = true
	gravel_material.uv1_world_triplanar = true
	gravel_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	gravel_material.uv1_triplanar_sharpness = 150.0
	gravel_material.roughness = 0.95

	# 6. Wood Planks
	wood_plank_material = StandardMaterial3D.new()
	wood_plank_material.albedo_texture = PixelTextureGenerator.get_wood_plank_texture()
	wood_plank_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	wood_plank_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wood_plank_material.uv1_triplanar = true
	wood_plank_material.uv1_world_triplanar = true
	wood_plank_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	wood_plank_material.uv1_triplanar_sharpness = 150.0
	wood_plank_material.roughness = 0.85

	# 7. Hewn Timber Logs
	hewn_timber_material = StandardMaterial3D.new()
	hewn_timber_material.albedo_texture = PixelTextureGenerator.get_hewn_timber_texture()
	hewn_timber_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hewn_timber_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	hewn_timber_material.uv1_triplanar = true
	hewn_timber_material.uv1_world_triplanar = true
	hewn_timber_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	hewn_timber_material.uv1_triplanar_sharpness = 150.0
	hewn_timber_material.roughness = 0.88

	# 8. Expedition Cargo Crate
	crate_material = StandardMaterial3D.new()
	crate_material.albedo_texture = PixelTextureGenerator.get_crate_texture()
	crate_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	crate_material.roughness = 0.80

	# 9. Monolithic Columnar Basalt (Triplanar enabled, zero stretching on columns & arches!)
	columnar_basalt_material = StandardMaterial3D.new()
	columnar_basalt_material.albedo_texture = PixelTextureGenerator.get_deep_basalt_texture()
	columnar_basalt_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	columnar_basalt_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	columnar_basalt_material.uv1_triplanar = true
	columnar_basalt_material.uv1_world_triplanar = true
	columnar_basalt_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	columnar_basalt_material.uv1_triplanar_sharpness = 150.0
	columnar_basalt_material.roughness = 0.82
	columnar_basalt_material.metallic = 0.04

	# 10. Industrial Steel
	industrial_steel_material = StandardMaterial3D.new()
	industrial_steel_material.albedo_texture = PixelTextureGenerator.get_industrial_steel_texture()
	industrial_steel_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	industrial_steel_material.roughness = 0.50
	industrial_steel_material.metallic = 0.80

	# 11. Safety Hazard Steel
	hazard_steel_material = StandardMaterial3D.new()
	hazard_steel_material.albedo_texture = PixelTextureGenerator.get_hazard_steel_texture()
	hazard_steel_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hazard_steel_material.uv1_triplanar = true
	hazard_steel_material.uv1_world_triplanar = true
	hazard_steel_material.uv1_scale = Vector3(2.0, 2.0, 2.0)
	hazard_steel_material.roughness = 0.55
	hazard_steel_material.metallic = 0.40

	# 12. Weathered Antique Brass
	brass_material = StandardMaterial3D.new()
	brass_material.albedo_texture = PixelTextureGenerator.get_lantern_brass_texture()
	brass_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	brass_material.roughness = 0.45
	brass_material.metallic = 0.80

	# 13. Bioluminescent Flora
	bio_material = StandardMaterial3D.new()
	bio_material.albedo_texture = PixelTextureGenerator.get_phosphor_texture()
	bio_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	bio_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bio_material.emission_enabled = true
	bio_material.emission_texture = PixelTextureGenerator.get_phosphor_texture()
	bio_material.emission_energy_multiplier = 2.4
	bio_material.roughness = 0.30

	# 14. Radiant Crystal Geodes
	bio_crystal_material = StandardMaterial3D.new()
	bio_crystal_material.albedo_texture = PixelTextureGenerator.get_phosphor_texture()
	bio_crystal_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	bio_crystal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bio_crystal_material.emission_enabled = true
	bio_crystal_material.emission_texture = PixelTextureGenerator.get_phosphor_texture()
	bio_crystal_material.emission_energy_multiplier = 2.8
	bio_crystal_material.roughness = 0.20
	bio_crystal_material.metallic = 0.10

func get_floor_height(x: float, z: float) -> float:
	# Undulating basin base terrain: gentle natural geological swells
	var base_h = 3.2 + sin(x * 0.08) * 1.1 + cos(z * 0.06) * 1.3 + sin((x + z) * 0.14) * 0.4

	# 1. Tier 1 & 2: Elevated West Terrace & Natural Descending Trail Ramp
	# Sturdy rock bluff plateau at y ≈ 15.0 for x <= -24.0, smoothly sloping down to basin at x >= -12.0
	if x < -12.0:
		var t = clamp((-x - 12.0) / 12.0, 0.0, 1.0)
		var st = t * t * (3.0 - 2.0 * t)
		base_h = lerp(base_h, 15.0 + sin(z * 0.08) * 0.25, st)

	# 2. Tier 4: Elevated East Plateau (Precursor Ruins at x >= 18.0)
	# Smooth rising slate bedrock terrace at y ≈ 11.2 for x >= 27.0
	if x > 18.0:
		var t = clamp((x - 18.0) / 9.0, 0.0, 1.0)
		var st = t * t * (3.0 - 2.0 * t)
		base_h = lerp(base_h, 11.0 + cos(z * 0.08) * 0.35, st)

	# 3. Tier 4: The Great Abyssal Rift / Chasm Canyon (z between 8.0 and 25.0, x between -9.5 and 22.5)
	# Drops smoothly into a deep, solid basalt canyon floor at y ≈ -11.0 to -12.0
	if z > 7.5 and z < 25.5 and x > -9.5 and x < 22.5:
		var z_center = 16.5
		var z_rad = 8.5
		var t_z = clamp(1.0 - abs(z - z_center) / z_rad, 0.0, 1.0)
		var smooth_z = t_z * t_z * (3.0 - 2.0 * t_z)

		var t_x = 1.0
		if x < -3.5:
			t_x = clamp((x - (-9.5)) / 6.0, 0.0, 1.0)
			t_x = t_x * t_x * (3.0 - 2.0 * t_x)
		elif x > 15.5:
			t_x = clamp((22.5 - x) / 7.0, 0.0, 1.0)
			t_x = t_x * t_x * (3.0 - 2.0 * t_x)

		var chasm_drop = 15.0 * smooth_z * t_x
		base_h -= chasm_drop

	return base_h

func get_vault_height(x: float, z: float) -> float:
	var r_x = cavern_width * 0.52
	var r_y = cavern_height
	var norm_x = clamp(x / r_x, -0.98, 0.98)
	var theta = acos(-norm_x)
	var disp = sin(theta * 6.0) * 1.8 + cos(z * 0.08) * 2.0 + sin(theta * 3.0 + z * 0.04) * 1.2
	return sin(theta) * (r_y + disp) - 1.0

func _generate_cavern() -> void:
	# 1. Main Vaulted Cavern Shell (Only if not using dynamic voxel world)
	if not use_voxel_terrain:
		_build_cavern_shell()

	# 2. Abyssal Chasm and 3D Monolithic Basalt Bridge
	_build_chasm_and_bridge()

	# 3. Colossal Columnar Basalt Columns
	_build_monolithic_columns()

	# 4. Speleothem Fields (Stalactites & Stalagmites with outward winding)
	_build_speleothem_fields()

	# 5. Bioluminescent Flora & Crystal Geodes
	_build_bioluminescent_clusters()

	# 6. Abandoned Expedition Outpost (Crafting Bench, Destructible Timber Crates, Descent Trail)
	_build_expedition_outpost()

	# 7. Ancient Precursor Ruins on East Plateau
	_build_precursor_ruins()

	# 8. Ambient Subterranean Spores
	_build_ambient_spores()

	# 9. Procedural Mineral Veins & Ore Nodes
	_build_mineral_veins()

	# 10. Minable Cobblestone Outcrops
	_build_minable_rock_outcrops()

	# 11. Atmospheric Subterranean Basin Floor Illumination (No Floating Objects!)
	_build_basin_illumination()

# ----------------------------------------------------------------------
# 1. CAVERN SHELL WITH BIOME-DIFFERENTIATED FLOORS AND VERIFIED WINDINGS
# ----------------------------------------------------------------------
func _build_cavern_shell() -> void:
	var shell_root = Node3D.new()
	shell_root.name = "CavernShellGroup"
	add_child(shell_root)

	var nx = 56
	var nz = 68
	var dx = cavern_width / float(nx)
	var dz = cavern_length / float(nz)
	var half_w = cavern_width * 0.5
	var half_l = cavern_length * 0.5

	# Biome SurfaceTools
	var st_gravel = SurfaceTool.new()      # West Outpost Bluff
	var st_cobble = SurfaceTool.new()      # Main Cavern Basin
	var st_moss   = SurfaceTool.new()      # Moss beds
	var st_chasm  = SurfaceTool.new()      # Deep Basalt Chasm
	var st_ruins  = SurfaceTool.new()      # East Precursor Plateau

	st_gravel.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_cobble.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_moss.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_chasm.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_ruins.begin(Mesh.PRIMITIVE_TRIANGLES)

	st_gravel.set_material(gravel_material)
	st_cobble.set_material(cobblestone_material)
	st_moss.set_material(mossy_stone_material)
	st_chasm.set_material(deep_basalt_material)
	st_ruins.set_material(slate_brick_material)

	# 1A. Floor Geometry with Mathematically Verified Outward Normal (+Y)
	for i in range(nx):
		for j in range(nz):
			var x0 = -half_w + i * dx
			var x1 = -half_w + (i + 1) * dx
			var z0 = -half_l + j * dz
			var z1 = -half_l + (j + 1) * dz

			var y00 = get_floor_height(x0, z0)
			var y10 = get_floor_height(x1, z0)
			var y11 = get_floor_height(x1, z1)
			var y01 = get_floor_height(x0, z1)

			var v00 = Vector3(x0, y00, z0)
			var v10 = Vector3(x1, y10, z0)
			var v11 = Vector3(x1, y11, z1)
			var v01 = Vector3(x0, y01, z1)

			var mid_x = (x0 + x1) * 0.5
			var mid_z = (z0 + z1) * 0.5
			var target_st = st_cobble

			if mid_x < -20.0:
				target_st = st_gravel
			elif mid_x > 22.0:
				target_st = st_ruins
			elif mid_z > 8.5 and mid_z < 24.5 and mid_x > -8.5 and mid_x < 21.5:
				target_st = st_chasm
			elif (abs(mid_x - 12.0) < 6.0 and abs(mid_z + 12.0) < 6.0) or (abs(mid_x + 8.0) < 5.0 and abs(mid_z + 28.0) < 6.0):
				target_st = st_moss

			# Winding: v00 -> v11 -> v01 and v00 -> v10 -> v11 (+Y normal pointing upward into cavern)
			target_st.set_uv(Vector2(x0 * 0.05, z0 * 0.05))
			target_st.add_vertex(v00)
			target_st.set_uv(Vector2(x1 * 0.05, z1 * 0.05))
			target_st.add_vertex(v11)
			target_st.set_uv(Vector2(x0 * 0.05, z1 * 0.05))
			target_st.add_vertex(v01)

			target_st.set_uv(Vector2(x0 * 0.05, z0 * 0.05))
			target_st.add_vertex(v00)
			target_st.set_uv(Vector2(x1 * 0.05, z0 * 0.05))
			target_st.add_vertex(v10)
			target_st.set_uv(Vector2(x1 * 0.05, z1 * 0.05))
			target_st.add_vertex(v11)

	var floor_tools = [
		{"st": st_gravel, "name": "Floor_OutpostGravel", "mat": gravel_material},
		{"st": st_cobble, "name": "Floor_MainCobblestone", "mat": cobblestone_material},
		{"st": st_moss,   "name": "Floor_MossyGrotto",     "mat": mossy_stone_material},
		{"st": st_chasm,  "name": "Floor_DeepAbyss",       "mat": deep_basalt_material},
		{"st": st_ruins,  "name": "Floor_EastRuins",      "mat": slate_brick_material}
	]

	for ft in floor_tools:
		var st_obj: SurfaceTool = ft["st"]
		st_obj.generate_normals()
		st_obj.generate_tangents()
		var m = st_obj.commit()
		var mi = MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = ft["mat"]
		mi.name = ft["name"]
		shell_root.add_child(mi)
		mi.create_trimesh_collision()

	# 1B. Arched Vault Dome (Facing inward/downward: -Y normal)
	var vault_st = SurfaceTool.new()
	vault_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	vault_st.set_material(deep_basalt_material)

	var n_theta = 44
	var n_length = 54
	var d_len = cavern_length / float(n_length)

	for j in range(n_length):
		var z_cur = -half_l + j * d_len
		var z_next = -half_l + (j + 1) * d_len

		for t in range(n_theta):
			var theta0 = float(t) / float(n_theta) * PI
			var theta1 = float(t + 1) / float(n_theta) * PI

			var v_c00 = _vault_point(theta0, z_cur)
			var v_c10 = _vault_point(theta1, z_cur)
			var v_c11 = _vault_point(theta1, z_next)
			var v_c01 = _vault_point(theta0, z_next)

			# Inward winding: v_c00 -> v_c11 -> v_c10 and v_c00 -> v_c01 -> v_c11
			vault_st.set_uv(Vector2(v_c00.x * 0.04, v_c00.y * 0.04))
			vault_st.add_vertex(v_c00)
			vault_st.set_uv(Vector2(v_c11.x * 0.04, v_c11.y * 0.04))
			vault_st.add_vertex(v_c11)
			vault_st.set_uv(Vector2(v_c10.x * 0.04, v_c10.y * 0.04))
			vault_st.add_vertex(v_c10)

			vault_st.set_uv(Vector2(v_c00.x * 0.04, v_c00.y * 0.04))
			vault_st.add_vertex(v_c00)
			vault_st.set_uv(Vector2(v_c01.x * 0.04, v_c01.y * 0.04))
			vault_st.add_vertex(v_c01)
			vault_st.set_uv(Vector2(v_c11.x * 0.04, v_c11.y * 0.04))
			vault_st.add_vertex(v_c11)

	# 1C. Sealed End Walls
	for i in range(nx):
		var x0 = -half_w + i * dx
		var x1 = -half_w + (i + 1) * dx

		# North end wall (z = -half_l, facing south / +Z)
		var z_north = -half_l
		var yf0_n = get_floor_height(x0, z_north)
		var yf1_n = get_floor_height(x1, z_north)
		var yc0_n = get_vault_height(x0, z_north)
		var yc1_n = get_vault_height(x1, z_north)

		var v_fn0 = Vector3(x0, yf0_n, z_north)
		var v_fn1 = Vector3(x1, yf1_n, z_north)
		var v_cn0 = Vector3(x0, yc0_n, z_north)
		var v_cn1 = Vector3(x1, yc1_n, z_north)

		# Normal +Z into cave: v_fn0 -> v_cn1 -> v_fn1 and v_fn0 -> v_cn0 -> v_cn1
		vault_st.set_uv(Vector2(x0 * 0.05, yf0_n * 0.05))
		vault_st.add_vertex(v_fn0)
		vault_st.set_uv(Vector2(x1 * 0.05, yc1_n * 0.05))
		vault_st.add_vertex(v_cn1)
		vault_st.set_uv(Vector2(x1 * 0.05, yf1_n * 0.05))
		vault_st.add_vertex(v_fn1)

		vault_st.set_uv(Vector2(x0 * 0.05, yf0_n * 0.05))
		vault_st.add_vertex(v_fn0)
		vault_st.set_uv(Vector2(x0 * 0.05, yc0_n * 0.05))
		vault_st.add_vertex(v_cn0)
		vault_st.set_uv(Vector2(x1 * 0.05, yc1_n * 0.05))
		vault_st.add_vertex(v_cn1)

		# South end wall (z = +half_l, facing north / -Z)
		var z_south = half_l
		var yf0_s = get_floor_height(x0, z_south)
		var yf1_s = get_floor_height(x1, z_south)
		var yc0_s = get_vault_height(x0, z_south)
		var yc1_s = get_vault_height(x1, z_south)

		var v_fs0 = Vector3(x0, yf0_s, z_south)
		var v_fs1 = Vector3(x1, yf1_s, z_south)
		var v_cs0 = Vector3(x0, yc0_s, z_south)
		var v_cs1 = Vector3(x1, yc1_s, z_south)

		# Normal -Z into cave: v_fs0 -> v_fs1 -> v_cs1 and v_fs0 -> v_cs1 -> v_cs0
		vault_st.set_uv(Vector2(x0 * 0.05, yf0_s * 0.05))
		vault_st.add_vertex(v_fs0)
		vault_st.set_uv(Vector2(x1 * 0.05, yf1_s * 0.05))
		vault_st.add_vertex(v_fs1)
		vault_st.set_uv(Vector2(x1 * 0.05, yc1_s * 0.05))
		vault_st.add_vertex(v_cs1)

		vault_st.set_uv(Vector2(x0 * 0.05, yf0_s * 0.05))
		vault_st.add_vertex(v_fs0)
		vault_st.set_uv(Vector2(x1 * 0.05, yc1_s * 0.05))
		vault_st.add_vertex(v_cs1)
		vault_st.set_uv(Vector2(x0 * 0.05, yc0_s * 0.05))
		vault_st.add_vertex(v_cs0)

	vault_st.generate_normals()
	vault_st.generate_tangents()
	var vault_mesh = vault_st.commit()

	var vault_inst = MeshInstance3D.new()
	vault_inst.mesh = vault_mesh
	vault_inst.material_override = deep_basalt_material
	vault_inst.name = "VaultDomeAndWalls"
	shell_root.add_child(vault_inst)
	vault_inst.create_trimesh_collision()

func _vault_point(theta: float, z: float) -> Vector3:
	var r_x = cavern_width * 0.52
	var r_y = cavern_height
	var disp = sin(theta * 6.0) * 1.8 + cos(z * 0.08) * 2.0 + sin(theta * 3.0 + z * 0.04) * 1.2
	var x = -cos(theta) * (r_x + disp * 0.4)
	var y = sin(theta) * (r_y + disp) - 1.0
	return Vector3(x, y, z)

# ----------------------------------------------------------------------
# 2. MONUMENTAL 3D BASALT ARCH BRIDGE OVER THE CHASM
# ----------------------------------------------------------------------
func _build_chasm_and_bridge() -> void:
	var bridge_st = SurfaceTool.new()
	bridge_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	bridge_st.set_material(columnar_basalt_material)

	var n_segs = 24
	var bridge_w = 4.8
	var start_z = 5.5
	var end_z = 27.5

	var y_start = get_floor_height(0.0, start_z)
	var y_end = get_floor_height(0.0, end_z)

	for i in range(n_segs):
		var t0 = float(i) / float(n_segs)
		var t1 = float(i + 1) / float(n_segs)
		var z0 = lerp(start_z, end_z, t0)
		var z1 = lerp(start_z, end_z, t1)

		var arch0 = sin(t0 * PI) * 1.6
		var arch1 = sin(t1 * PI) * 1.6
		var y0_top = lerp(y_start, y_end, t0) + arch0 + 0.35
		var y1_top = lerp(y_start, y_end, t1) + arch1 + 0.35
		var y0_bot = y0_top - (1.5 + sin(t0 * PI) * 1.8)
		var y1_bot = y1_top - (1.5 + sin(t1 * PI) * 1.8)

		var xl = -bridge_w * 0.5
		var xr = bridge_w * 0.5

		var v_tl0 = Vector3(xl, y0_top, z0)
		var v_tr0 = Vector3(xr, y0_top, z0)
		var v_tl1 = Vector3(xl, y1_top, z1)
		var v_tr1 = Vector3(xr, y1_top, z1)

		var v_bl0 = Vector3(xl, y0_bot, z0)
		var v_br0 = Vector3(xr, y0_bot, z0)
		var v_bl1 = Vector3(xl, y1_bot, z1)
		var v_br1 = Vector3(xr, y1_bot, z1)

		# Top deck (normal +Y)
		bridge_st.set_uv(Vector2(0.0, t0 * 4.0))
		bridge_st.add_vertex(v_tl0)
		bridge_st.set_uv(Vector2(1.0, t1 * 4.0))
		bridge_st.add_vertex(v_tr1)
		bridge_st.set_uv(Vector2(0.0, t1 * 4.0))
		bridge_st.add_vertex(v_tl1)

		bridge_st.set_uv(Vector2(0.0, t0 * 4.0))
		bridge_st.add_vertex(v_tl0)
		bridge_st.set_uv(Vector2(1.0, t0 * 4.0))
		bridge_st.add_vertex(v_tr0)
		bridge_st.set_uv(Vector2(1.0, t1 * 4.0))
		bridge_st.add_vertex(v_tr1)

		# Underside (normal -Y)
		bridge_st.set_uv(Vector2(0.0, t0 * 4.0))
		bridge_st.add_vertex(v_bl0)
		bridge_st.set_uv(Vector2(0.0, t1 * 4.0))
		bridge_st.add_vertex(v_bl1)
		bridge_st.set_uv(Vector2(1.0, t1 * 4.0))
		bridge_st.add_vertex(v_br1)

		bridge_st.set_uv(Vector2(0.0, t0 * 4.0))
		bridge_st.add_vertex(v_bl0)
		bridge_st.set_uv(Vector2(1.0, t1 * 4.0))
		bridge_st.add_vertex(v_br1)
		bridge_st.set_uv(Vector2(1.0, t0 * 4.0))
		bridge_st.add_vertex(v_br0)

		# Left wall (normal -X)
		bridge_st.set_uv(Vector2(t0 * 4.0, 0.0))
		bridge_st.add_vertex(v_tl0)
		bridge_st.set_uv(Vector2(t1 * 4.0, 1.0))
		bridge_st.add_vertex(v_bl1)
		bridge_st.set_uv(Vector2(t0 * 4.0, 1.0))
		bridge_st.add_vertex(v_bl0)

		bridge_st.set_uv(Vector2(t0 * 4.0, 0.0))
		bridge_st.add_vertex(v_tl0)
		bridge_st.set_uv(Vector2(t1 * 4.0, 0.0))
		bridge_st.add_vertex(v_tl1)
		bridge_st.set_uv(Vector2(t1 * 4.0, 1.0))
		bridge_st.add_vertex(v_bl1)

		# Right wall (normal +X)
		bridge_st.set_uv(Vector2(t0 * 4.0, 0.0))
		bridge_st.add_vertex(v_tr0)
		bridge_st.set_uv(Vector2(t0 * 4.0, 1.0))
		bridge_st.add_vertex(v_br0)
		bridge_st.set_uv(Vector2(t1 * 4.0, 1.0))
		bridge_st.add_vertex(v_br1)

		bridge_st.set_uv(Vector2(t0 * 4.0, 0.0))
		bridge_st.add_vertex(v_tr0)
		bridge_st.set_uv(Vector2(t1 * 4.0, 1.0))
		bridge_st.add_vertex(v_br1)
		bridge_st.set_uv(Vector2(t1 * 4.0, 0.0))
		bridge_st.add_vertex(v_tr1)

	bridge_st.generate_normals()
	bridge_st.generate_tangents()
	var bridge_mesh = bridge_st.commit()

	var bridge_node = MeshInstance3D.new()
	bridge_node.mesh = bridge_mesh
	bridge_node.name = "BasaltBridge"
	add_child(bridge_node)
	bridge_node.create_trimesh_collision()

	# Massive Stone Bridge Abutments locking into north and south canyon rims
	for abutment_info in [
		{"z": start_z - 1.4, "y": y_start},
		{"z": end_z + 1.4, "y": y_end}
	]:
		var abutment = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(bridge_w + 1.8, 14.0, 4.2)
		abutment.mesh = a_box
		abutment.material_override = columnar_basalt_material
		abutment.position = Vector3(0.0, abutment_info["y"] - 6.0, abutment_info["z"])
		bridge_node.add_child(abutment)
		abutment.create_trimesh_collision()

	# Sturdy Stone Parapet Guards along bridge edges
	for i in range(n_segs):
		var t = (float(i) + 0.5) / float(n_segs)
		var p_z = lerp(start_z, end_z, t)
		var arch = sin(t * PI) * 1.6
		var p_y = lerp(y_start, y_end, t) + arch + 0.35 + 0.45
		var seg_len = (end_z - start_z) / float(n_segs) * 1.02

		for side_x in [-bridge_w * 0.5 + 0.20, bridge_w * 0.5 - 0.20]:
			var parapet = MeshInstance3D.new()
			var p_box = BoxMesh.new()
			p_box.size = Vector3(0.40, 0.85, seg_len)
			parapet.mesh = p_box
			parapet.material_override = slate_brick_material
			parapet.position = Vector3(side_x, p_y, p_z)
			bridge_node.add_child(parapet)
			parapet.create_trimesh_collision()

	# Chasm ethereal blue glow and mist illumination
	var abyss_light = OmniLight3D.new()
	abyss_light.position = Vector3(0, -6.5, 16.5)
	abyss_light.light_color = Color(0.10, 0.75, 0.96)
	abyss_light.light_energy = 3.6
	abyss_light.omni_range = 56.0
	abyss_light.omni_attenuation = 0.85
	add_child(abyss_light)

	# Luminous Abyssal Phosphor Beds on the canyon floor beneath the bridge
	for cx in [-5.5, 5.5]:
		var canyon_bed = MeshInstance3D.new()
		var cb_box = BoxMesh.new()
		cb_box.size = Vector3(3.2, 0.8, 8.0)
		canyon_bed.mesh = cb_box
		canyon_bed.material_override = bio_material
		canyon_bed.position = Vector3(cx, -11.4, 16.5)
		bridge_node.add_child(canyon_bed)
		canyon_bed.create_trimesh_collision()

# ----------------------------------------------------------------------
# 3. COLOSSAL COLUMNAR BASALT COLUMNS (PERIPHERAL ANCHORS - NO CLIPPING)
# ----------------------------------------------------------------------
func _build_monolithic_columns() -> void:
	var column_coords = [
		Vector2(-38.0, 10.0),
		Vector2(-16.0, -32.0),
		Vector2(20.0, -26.0),
		Vector2(24.0, 30.0),
		Vector2(-18.0, 30.0)
	]

	for pos in column_coords:
		var x = pos.x
		var z = pos.y
		var min_ground = get_floor_height(x, z)
		for dx in [-4.5, 0.0, 4.5]:
			for dz in [-4.5, 0.0, 4.5]:
				min_ground = min(min_ground, get_floor_height(x + dx, z + dz))
		var base_y = min(-20.0, min_ground - 12.0)
		var top_y = get_vault_height(x, z) + 8.0
		var height = top_y - base_y

		var col_mesh = _generate_basalt_column_mesh(height, 3.8, 10)
		var col_inst = MeshInstance3D.new()
		col_inst.mesh = col_mesh
		col_inst.material_override = columnar_basalt_material
		col_inst.position = Vector3(x, base_y, z)
		col_inst.name = "Column_%d_%d" % [int(x), int(z)]
		add_child(col_inst)
		col_inst.create_trimesh_collision()

		# Grounded flared basalt base pedestal
		var buttress = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 4.2
		b_cyl.bottom_radius = 5.8
		b_cyl.height = 4.5
		b_cyl.radial_segments = 10
		buttress.mesh = b_cyl
		buttress.material_override = columnar_basalt_material
		buttress.position = Vector3(x, min_ground - 0.5, z)
		add_child(buttress)
		buttress.create_trimesh_collision()

func _generate_basalt_column_mesh(height: float, radius: float, sides: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var n_rings = 14
	var dy = height / float(n_rings)

	for r in range(n_rings):
		var y0 = r * dy
		var y1 = (r + 1) * dy
		var t0 = float(r) / float(n_rings)
		var t1 = float(r + 1) / float(n_rings)

		var joint0 = 1.0 - 0.05 * pow(sin(t0 * PI * 10.0), 6.0)
		var joint1 = 1.0 - 0.05 * pow(sin(t1 * PI * 10.0), 6.0)
		var r0 = radius * joint0 * (1.0 + sin(t0 * PI) * 0.12)
		var r1 = radius * joint1 * (1.0 + sin(t1 * PI) * 0.12)

		for s in range(sides):
			var a0 = float(s) / float(sides) * TAU
			var a1 = float(s + 1) / float(sides) * TAU
			var u0 = float(s) / float(sides)
			var u1 = float(s + 1) / float(sides)
			var v0 = t0 * 6.0
			var v1 = t1 * 6.0

			var v00 = Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var v10 = Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var v11 = Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			var v01 = Vector3(cos(a0) * r1, y1, sin(a0) * r1)

			# Outward winding: v00 -> v10 -> v11 and v00 -> v11 -> v01
			st.set_uv(Vector2(u0, v0))
			st.add_vertex(v00)
			st.set_uv(Vector2(u1, v0))
			st.add_vertex(v10)
			st.set_uv(Vector2(u1, v1))
			st.add_vertex(v11)

			st.set_uv(Vector2(u0, v0))
			st.add_vertex(v00)
			st.set_uv(Vector2(u1, v1))
			st.add_vertex(v11)
			st.set_uv(Vector2(u0, v1))
			st.add_vertex(v01)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

# ----------------------------------------------------------------------
# 4. SPELEOTHEM FIELDS (OUTWARD NORMAL VERIFIED & GROUND-SEALED)
# ----------------------------------------------------------------------
func _build_speleothem_fields() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	# 4A. Hanging Stalactites from ceiling
	for i in range(48):
		var x = rng.randf_range(-cavern_width * 0.40, cavern_width * 0.40)
		var z = rng.randf_range(-cavern_length * 0.40, cavern_length * 0.40)
		var height = rng.randf_range(7.0, 20.0)
		var radius = rng.randf_range(1.4, 3.2)

		var ceiling_y = get_vault_height(x, z)
		var spire_mesh = _generate_speleothem_mesh(height, radius, 8, 5, true)

		var inst = MeshInstance3D.new()
		inst.mesh = spire_mesh
		inst.material_override = columnar_basalt_material
		inst.position = Vector3(x, ceiling_y + 1.2, z)
		inst.rotation.y = rng.randf_range(0.0, TAU)
		inst.name = "Stalactite_%d" % i
		add_child(inst)
		inst.create_trimesh_collision()

	# 4B. Rising Stalagmites (Placed strictly on gentle terrain, well away from player paths)
	for i in range(32):
		var x = rng.randf_range(-cavern_width * 0.38, cavern_width * 0.38)
		var z = rng.randf_range(-cavern_length * 0.38, cavern_length * 0.38)

		# Skip near Outpost bluff and descent trail
		if x < -10.0 and z < 5.0:
			continue
		# Skip the entire Great Abyssal Rift and Chasm zone
		if x > -14.0 and x < 26.0 and z > 4.0 and z < 32.0:
			continue
		# Skip near East Precursor Ruins
		if x > 18.0 and abs(z) < 14.0:
			continue

		# Slope check: sample 4 cardinal offsets by 2.0m (gentle terrain only)
		var f_c = get_floor_height(x, z)
		var f_xp = get_floor_height(x + 2.0, z)
		var f_xm = get_floor_height(x - 2.0, z)
		var f_zp = get_floor_height(x, z + 2.0)
		var f_zm = get_floor_height(x, z - 2.0)
		var max_diff = max(abs(f_xp - f_c), abs(f_xm - f_c), abs(f_zp - f_c), abs(f_zm - f_c))
		if max_diff > 0.55:
			continue

		var min_surrounding_y = min(f_c, min(f_xp, min(f_xm, min(f_zp, f_zm))))
		var height = rng.randf_range(4.0, 9.0)
		var radius = rng.randf_range(1.2, 2.0)

		var spire_mesh = _generate_speleothem_mesh(height, radius, 8, 5, false)

		var inst = MeshInstance3D.new()
		inst.mesh = spire_mesh
		inst.material_override = columnar_basalt_material
		inst.position = Vector3(x, min_surrounding_y - 1.5, z)
		inst.rotation.y = rng.randf_range(0.0, TAU)
		inst.name = "Stalagmite_%d" % i
		add_child(inst)
		inst.create_trimesh_collision()

func _generate_speleothem_mesh(height: float, base_radius: float, sides: int, rings: int, is_hanging: bool) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_verts: Array = []
	var ring_uvs: Array = []

	var skirt_y = 2.0 if is_hanging else -2.5
	var skirt_row: Array[Vector3] = []
	var skirt_uv: Array[Vector2] = []
	for s in range(sides):
		var a = float(s) / float(sides) * TAU
		skirt_row.append(Vector3(cos(a) * (base_radius * 1.15), skirt_y, sin(a) * (base_radius * 1.15)))
		skirt_uv.append(Vector2(float(s) / float(sides), 0.0))
	ring_verts.append(skirt_row)
	ring_uvs.append(skirt_uv)

	for r in range(rings + 1):
		var t = float(r) / float(rings)
		var taper = pow(1.0 - t, 0.72) * (1.0 + 0.10 * sin(t * PI * 3.0))
		var r_t = base_radius * taper
		var y = (-height * t) if is_hanging else (height * t)

		var v_row: Array[Vector3] = []
		var uv_row: Array[Vector2] = []
		for s in range(sides):
			var a = float(s) / float(sides) * TAU
			var crag = (sin(a * 3.0 + t * 4.0) * 0.08 + cos(a * 2.0 - t * 2.0) * 0.06) * r_t
			var final_r = max(0.01, r_t + crag)
			v_row.append(Vector3(cos(a) * final_r, y, sin(a) * final_r))
			uv_row.append(Vector2(float(s) / float(sides), (t + 0.2) * 3.0))

		ring_verts.append(v_row)
		ring_uvs.append(uv_row)

	var total_ring_count = ring_verts.size() - 1

	for r in range(total_ring_count):
		var t0 = float(r) / float(total_ring_count)
		var t1 = float(r + 1) / float(total_ring_count)

		for s in range(sides):
			var s_next = (s + 1) % sides
			var v00 = ring_verts[r][s]
			var v10 = ring_verts[r][s_next]
			var v11 = ring_verts[r + 1][s_next]
			var v01 = ring_verts[r + 1][s]

			var u0 = float(s) / float(sides)
			var u1 = float(s + 1) / float(sides)

			if is_hanging:
				st.set_uv(Vector2(u0, t0 * 3.0))
				st.add_vertex(v00)
				st.set_uv(Vector2(u1, t1 * 3.0))
				st.add_vertex(v11)
				st.set_uv(Vector2(u1, t0 * 3.0))
				st.add_vertex(v10)

				st.set_uv(Vector2(u0, t0 * 3.0))
				st.add_vertex(v00)
				st.set_uv(Vector2(u0, t1 * 3.0))
				st.add_vertex(v01)
				st.set_uv(Vector2(u1, t1 * 3.0))
				st.add_vertex(v11)
			else:
				st.set_uv(Vector2(u0, t0 * 3.0))
				st.add_vertex(v00)
				st.set_uv(Vector2(u1, t0 * 3.0))
				st.add_vertex(v10)
				st.set_uv(Vector2(u1, t1 * 3.0))
				st.add_vertex(v11)

				st.set_uv(Vector2(u0, t0 * 3.0))
				st.add_vertex(v00)
				st.set_uv(Vector2(u1, t1 * 3.0))
				st.add_vertex(v11)
				st.set_uv(Vector2(u0, t1 * 3.0))
				st.add_vertex(v01)

	var apex_y = -height if is_hanging else height
	var apex = Vector3(0, apex_y, 0)
	var last_ring_idx = total_ring_count
	for s in range(sides):
		var s_next = (s + 1) % sides
		var v_cur = ring_verts[last_ring_idx][s]
		var v_nxt = ring_verts[last_ring_idx][s_next]
		var u0 = float(s) / float(sides)
		var u1 = float(s + 1) / float(sides)

		if is_hanging:
			st.set_uv(Vector2(u0, 3.2))
			st.add_vertex(v_cur)
			st.set_uv(Vector2(u1, 3.2))
			st.add_vertex(v_nxt)
			st.set_uv(Vector2(0.5, 3.5))
			st.add_vertex(apex)
		else:
			st.set_uv(Vector2(u0, 3.2))
			st.add_vertex(v_cur)
			st.set_uv(Vector2(0.5, 3.5))
			st.add_vertex(apex)
			st.set_uv(Vector2(u1, 3.2))
			st.add_vertex(v_nxt)

	var base_center = Vector3(0, skirt_y, 0)
	for s in range(sides):
		var s_next = (s + 1) % sides
		var v0 = ring_verts[0][s]
		var v1 = ring_verts[0][s_next]
		if is_hanging:
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(base_center)
			st.set_uv(Vector2(float(s_next) / float(sides), 0.0))
			st.add_vertex(v1)
			st.set_uv(Vector2(float(s) / float(sides), 0.0))
			st.add_vertex(v0)
		else:
			st.set_uv(Vector2(float(s) / float(sides), 0.0))
			st.add_vertex(v0)
			st.set_uv(Vector2(float(s_next) / float(sides), 0.0))
			st.add_vertex(v1)
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(base_center)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

# ----------------------------------------------------------------------
# 5. BIOLUMINESCENT CLUSTERS (MOSS MOUNDS, CRYSTALS & SHROOMS)
# ----------------------------------------------------------------------
func _build_bioluminescent_clusters() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val + 99

	var cluster_specs = [
		{ "x": 14.0, "z": -14.0 },
		{ "x": 2.0, "z": -16.0 },
		{ "x": -6.0, "z": -5.0 },
		{ "x": 16.0, "z": -6.0 },
		{ "x": 6.0, "z": -24.0 },
		{ "x": -10.0, "z": -24.0 },
		{ "x": 16.0, "z": 36.0 },
		{ "x": -12.0, "z": 36.0 }
	]

	for i in range(cluster_specs.size()):
		var spec = cluster_specs[i]
		var floor_y = get_floor_height(spec.x, spec.z)

		var cluster_root = Node3D.new()
		cluster_root.name = "BioCluster_%d" % i
		cluster_root.position = Vector3(spec.x, floor_y, spec.z)
		add_child(cluster_root)

		# Grounded moss base mound (deep foundation into bedrock)
		var mound = MeshInstance3D.new()
		var m_cyl = CylinderMesh.new()
		m_cyl.top_radius = 2.2
		m_cyl.bottom_radius = 3.6
		m_cyl.height = 3.6
		m_cyl.radial_segments = 8
		mound.mesh = m_cyl
		mound.material_override = mossy_stone_material
		mound.position = Vector3(0, -1.4, 0)
		cluster_root.add_child(mound)
		mound.create_trimesh_collision()

		# Crystal geode needles
		for c in range(7):
			var c_mesh = _generate_crystal_mesh(rng.randf_range(1.8, 3.6), rng.randf_range(0.25, 0.50))
			var c_inst = MeshInstance3D.new()
			c_inst.mesh = c_mesh
			c_inst.material_override = bio_crystal_material
			c_inst.position = Vector3(
				rng.randf_range(-1.1, 1.1),
				rng.randf_range(0.25, 0.55),
				rng.randf_range(-1.1, 1.1)
			)
			c_inst.rotation = Vector3(
				rng.randf_range(-0.25, 0.25),
				rng.randf_range(0.0, TAU),
				rng.randf_range(-0.25, 0.25)
			)
			cluster_root.add_child(c_inst)

		# Phosphor mushrooms
		for m in range(7):
			var shroom = _generate_mushroom_node(rng)
			shroom.position = Vector3(
				rng.randf_range(-1.8, 1.8),
				0.0,
				rng.randf_range(-1.8, 1.8)
			)
			cluster_root.add_child(shroom)

		# Atmospheric localized cyan glow
		var light = OmniLight3D.new()
		light.light_color = Color(0.12, 0.85, 0.96)
		light.light_energy = 2.8
		light.light_indirect_energy = 2.6
		light.omni_range = 32.0
		light.omni_attenuation = 0.85
		light.shadow_enabled = true
		light.shadow_bias = 0.08
		light.position = Vector3(0, 1.2, 0)
		cluster_root.add_child(light)

func _generate_crystal_mesh(height: float, radius: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var sides = 6
	var apex = Vector3(0, height, 0)
	var body_h = height * 0.72

	for s in range(sides):
		var a0 = float(s) / float(sides) * TAU
		var a1 = float(s + 1) / float(sides) * TAU
		var u0 = float(s) / float(sides)
		var u1 = float(s + 1) / float(sides)

		var v0 = Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var v1 = Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var v0_t = Vector3(cos(a0) * radius, body_h, sin(a0) * radius)
		var v1_t = Vector3(cos(a1) * radius, body_h, sin(a1) * radius)

		var n_body = (v0_t - v0).cross(v1 - v0).normalized()
		st.set_normal(n_body)

		st.set_uv(Vector2(u0, 0.0))
		st.add_vertex(v0)
		st.set_uv(Vector2(u1, 0.7))
		st.add_vertex(v1_t)
		st.set_uv(Vector2(u1, 0.0))
		st.add_vertex(v1)

		st.set_uv(Vector2(u0, 0.0))
		st.add_vertex(v0)
		st.set_uv(Vector2(u0, 0.7))
		st.add_vertex(v0_t)
		st.set_uv(Vector2(u1, 0.7))
		st.add_vertex(v1_t)

		var n_tip = (apex - v0_t).cross(v1_t - v0_t).normalized()
		st.set_normal(n_tip)

		st.set_uv(Vector2(u0, 0.7))
		st.add_vertex(v0_t)
		st.set_uv(Vector2((u0 + u1) * 0.5, 1.0))
		st.add_vertex(apex)
		st.set_uv(Vector2(u1, 0.7))
		st.add_vertex(v1_t)

	st.generate_tangents()
	return st.commit()

func _generate_mushroom_node(rng: RandomNumberGenerator) -> Node3D:
	var root = Node3D.new()
	var height = rng.randf_range(0.5, 1.3)
	var cap_r = rng.randf_range(0.32, 0.60)

	var stalk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = cap_r * 0.20
	cyl.bottom_radius = cap_r * 0.32
	cyl.height = height
	stalk.mesh = cyl
	stalk.position = Vector3(0, height * 0.5, 0)
	var stalk_mat = StandardMaterial3D.new()
	stalk_mat.albedo_color = Color(0.14, 0.18, 0.20)
	stalk_mat.roughness = 0.85
	stalk.material_override = stalk_mat
	root.add_child(stalk)

	var cap = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = cap_r
	sphere.height = cap_r * 0.70
	sphere.is_hemisphere = true
	cap.mesh = sphere
	cap.material_override = bio_material
	cap.position = Vector3(0, height, 0)
	root.add_child(cap)

	return root

# ----------------------------------------------------------------------
# 6. EXPEDITION OUTPOST BLUFF (TIER 1) & ILLUMINATED DESCENT TRAIL (TIER 2)
# ----------------------------------------------------------------------
func _build_expedition_outpost() -> void:
	var outpost = Node3D.new()
	outpost.name = "ExpeditionOutpost"
	var outpost_y = get_floor_height(-32.0, -12.0)
	# Rest directly on the sturdy rock bluff
	outpost.position = Vector3(-32.0, outpost_y + 0.15, -12.0)
	add_child(outpost)

	# 1. Sturdy Stone Foundation Curb beneath the wooden deck
	var foundation = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(9.2, 0.60, 10.2)
	foundation.mesh = f_box
	foundation.material_override = cobblestone_material
	foundation.position = Vector3(0.0, -0.30, 0.0)
	outpost.add_child(foundation)
	foundation.create_trimesh_collision()

	# 2. Main Camp Wooden Deck
	var deck = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(8.6, 0.28, 9.6)
	deck.mesh = box
	deck.material_override = wood_plank_material
	deck.position = Vector3(0.0, 0.14, 0.0)
	outpost.add_child(deck)
	deck.create_trimesh_collision()

	# 3. Solid Natural Cliff Wall Backdrop behind the Camp (eliminating black void looking West)
	var cliff_wall = MeshInstance3D.new()
	var cw_box = BoxMesh.new()
	cw_box.size = Vector3(1.4, 10.0, 13.0)
	cliff_wall.mesh = cw_box
	cliff_wall.material_override = deep_basalt_material
	cliff_wall.position = Vector3(-4.4, 4.5, 0.0)
	outpost.add_child(cliff_wall)
	cliff_wall.create_trimesh_collision()

	# Cantilevered timber roof shelter over workbench & supply crates
	var shed_roof = MeshInstance3D.new()
	var sr_box = BoxMesh.new()
	sr_box.size = Vector3(3.6, 0.22, 10.4)
	shed_roof.mesh = sr_box
	shed_roof.material_override = wood_plank_material
	shed_roof.position = Vector3(-2.4, 3.6, 0.0)
	outpost.add_child(shed_roof)
	shed_roof.create_trimesh_collision()

	# Sturdy roof support posts against cliff
	for rz in [-4.6, 4.6]:
		var r_post = MeshInstance3D.new()
		var rp_mesh = BoxMesh.new()
		rp_mesh.size = Vector3(0.20, 3.6, 0.20)
		r_post.mesh = rp_mesh
		r_post.material_override = hewn_timber_material
		r_post.position = Vector3(-0.7, 1.8, rz)
		outpost.add_child(r_post)
		r_post.create_trimesh_collision()

	# Warm expedition wall sconces mounted on cliff wall
	for wz in [-2.6, 2.6]:
		var sconce = OmniLight3D.new()
		sconce.position = Vector3(-3.6, 2.4, wz)
		sconce.light_color = Color(1.0, 0.78, 0.45)
		sconce.light_energy = 2.2
		sconce.omni_range = 16.0
		sconce.shadow_enabled = true
		outpost.add_child(sconce)

	# 4. Open-Air Rugged Hewn Timber Guardrails (Slender posts and rails, zero visual obstruction)
	# Helper: North Rail (length 8.0)
	for px in [-3.8, -1.2, 1.2, 3.8]:
		var p_inst = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.14, 1.05, 0.14)
		p_inst.mesh = p_box
		p_inst.material_override = hewn_timber_material
		p_inst.position = Vector3(px, 0.525, -4.65)
		outpost.add_child(p_inst)
		p_inst.create_trimesh_collision()

	var n_top_rail = MeshInstance3D.new()
	var n_tr_box = BoxMesh.new()
	n_tr_box.size = Vector3(7.8, 0.08, 0.12)
	n_top_rail.mesh = n_tr_box
	n_top_rail.material_override = hewn_timber_material
	n_top_rail.position = Vector3(0.0, 0.95, -4.65)
	outpost.add_child(n_top_rail)

	var n_mid_rail = MeshInstance3D.new()
	var n_mr_box = BoxMesh.new()
	n_mr_box.size = Vector3(7.8, 0.05, 0.08)
	n_mid_rail.mesh = n_mr_box
	n_mid_rail.material_override = hewn_timber_material
	n_mid_rail.position = Vector3(0.0, 0.48, -4.65)
	outpost.add_child(n_mid_rail)

	# South Rail (length 8.0)
	for px in [-3.8, -1.2, 1.2, 3.8]:
		var p_inst = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.14, 1.05, 0.14)
		p_inst.mesh = p_box
		p_inst.material_override = hewn_timber_material
		p_inst.position = Vector3(px, 0.525, 4.65)
		outpost.add_child(p_inst)
		p_inst.create_trimesh_collision()

	var s_top_rail = MeshInstance3D.new()
	var s_tr_box = BoxMesh.new()
	s_tr_box.size = Vector3(7.8, 0.08, 0.12)
	s_top_rail.mesh = s_tr_box
	s_top_rail.material_override = hewn_timber_material
	s_top_rail.position = Vector3(0.0, 0.95, 4.65)
	outpost.add_child(s_top_rail)

	var s_mid_rail = MeshInstance3D.new()
	var s_mr_box = BoxMesh.new()
	s_mr_box.size = Vector3(7.8, 0.05, 0.08)
	s_mid_rail.mesh = s_mr_box
	s_mid_rail.material_override = hewn_timber_material
	s_mid_rail.position = Vector3(0.0, 0.48, 4.65)
	outpost.add_child(s_mid_rail)

	# East Rail North Segment (Z: -4.65 to -1.6, length 3.05)
	for pz in [-4.65, -3.1, -1.6]:
		var p_inst = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.14, 1.05, 0.14)
		p_inst.mesh = p_box
		p_inst.material_override = hewn_timber_material
		p_inst.position = Vector3(4.15, 0.525, pz)
		outpost.add_child(p_inst)
		p_inst.create_trimesh_collision()

	var en_top_rail = MeshInstance3D.new()
	var en_tr_box = BoxMesh.new()
	en_tr_box.size = Vector3(0.12, 0.08, 3.05)
	en_top_rail.mesh = en_tr_box
	en_top_rail.material_override = hewn_timber_material
	en_top_rail.position = Vector3(4.15, 0.95, -3.125)
	outpost.add_child(en_top_rail)

	var en_mid_rail = MeshInstance3D.new()
	var en_mr_box = BoxMesh.new()
	en_mr_box.size = Vector3(0.08, 0.05, 3.05)
	en_mid_rail.mesh = en_mr_box
	en_mid_rail.material_override = hewn_timber_material
	en_mid_rail.position = Vector3(4.15, 0.48, -3.125)
	outpost.add_child(en_mid_rail)

	# East Rail South Segment (Z: 1.6 to 4.65, length 3.05)
	for pz in [1.6, 3.1, 4.65]:
		var p_inst = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.14, 1.05, 0.14)
		p_inst.mesh = p_box
		p_inst.material_override = hewn_timber_material
		p_inst.position = Vector3(4.15, 0.525, pz)
		outpost.add_child(p_inst)
		p_inst.create_trimesh_collision()

	var es_top_rail = MeshInstance3D.new()
	var es_tr_box = BoxMesh.new()
	es_tr_box.size = Vector3(0.12, 0.08, 3.05)
	es_top_rail.mesh = es_tr_box
	es_top_rail.material_override = hewn_timber_material
	es_top_rail.position = Vector3(4.15, 0.95, 3.125)
	outpost.add_child(es_top_rail)

	var es_mid_rail = MeshInstance3D.new()
	var es_mr_box = BoxMesh.new()
	es_mr_box.size = Vector3(0.08, 0.05, 3.05)
	es_mid_rail.mesh = es_mr_box
	es_mid_rail.material_override = hewn_timber_material
	es_mid_rail.position = Vector3(4.15, 0.48, 3.125)
	outpost.add_child(es_mid_rail)

	# Two monumental timber gateposts framing the 3.2m wide descent trail portal
	for pz in [-1.6, 1.6]:
		var gatepost = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.16
		p_cyl.bottom_radius = 0.18
		p_cyl.height = 1.45
		gatepost.mesh = p_cyl
		gatepost.material_override = hewn_timber_material
		gatepost.position = Vector3(4.15, 0.725, pz)
		outpost.add_child(gatepost)
		gatepost.create_trimesh_collision()

		# Gatepost brass lantern
		var gp_light = OmniLight3D.new()
		gp_light.position = Vector3(4.15, 1.6, pz)
		gp_light.light_color = Color(1.0, 0.82, 0.48)
		gp_light.light_energy = 2.0
		gp_light.omni_range = 14.0
		outpost.add_child(gp_light)

	# 5. MINABLE EXPEDITION CRATES (Harvestable Timber for Step 1 Onboarding!)
	# 4 Timber Supply Crates neatly organized by the sheltered cliff wall
	var timber_crate_positions = [
		Vector3(-3.1, 0.65, -1.3),
		Vector3(-3.1, 0.65, 0.0),
		Vector3(-3.1, 0.65, 1.3),
		Vector3(-3.1, 1.75, 0.0)
	]
	for cp in timber_crate_positions:
		var crate = MinableBlockClass.new()
		crate.max_durability = 45.0
		crate.drop_type = DroppedItemClass.ItemType.TIMBER
		crate.drop_amount = 3
		crate.position = cp

		var c_mesh_inst = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(1.1, 1.1, 1.1)
		c_mesh_inst.mesh = c_mesh
		c_mesh_inst.material_override = crate_material
		crate.add_child(c_mesh_inst)

		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = Vector3(1.1, 1.1, 1.1)
		col.shape = col_box
		crate.add_child(col)

		outpost.add_child(crate)

	# 5. Surveyor Plotting Table & Blueprint Workbench (KEY [C])
	var desk = MeshInstance3D.new()
	var d_mesh = BoxMesh.new()
	d_mesh.size = Vector3(1.6, 1.0, 0.9)
	desk.mesh = d_mesh
	desk.material_override = wood_plank_material
	desk.position = Vector3(-1.8, 0.65, -2.5)
	outpost.add_child(desk)
	desk.create_trimesh_collision()

	var plaque = MeshInstance3D.new()
	var pl_mesh = BoxMesh.new()
	pl_mesh.size = Vector3(1.2, 0.04, 0.7)
	plaque.mesh = pl_mesh
	plaque.material_override = brass_material
	plaque.position = Vector3(-1.8, 1.18, -2.5)
	plaque.rotation_degrees = Vector3(22, 0, 0)
	outpost.add_child(plaque)

	# Warm camp lantern
	var camp_lamp = OmniLight3D.new()
	camp_lamp.position = Vector3(-1.8, 2.2, -2.5)
	camp_lamp.light_color = Color(1.0, 0.74, 0.38)
	camp_lamp.light_energy = 2.4
	camp_lamp.light_indirect_energy = 2.0
	camp_lamp.omni_range = 22.0
	camp_lamp.omni_attenuation = 0.85
	camp_lamp.shadow_enabled = true
	camp_lamp.shadow_bias = 0.08
	outpost.add_child(camp_lamp)

	# 6. Engineered Descent Trail: Solid Wood & Stone Steps bedded into the natural rock slope
	var stair_steps = 14
	var start_pos = Vector3(-27.8, outpost.position.y, -12.0)
	var end_pos = Vector3(-13.0, get_floor_height(-13.0, -12.0) + 0.15, -12.0)

	for s_idx in range(stair_steps):
		var t = float(s_idx) / float(stair_steps)
		var step_x = lerp(start_pos.x, end_pos.x, t)
		var step_z = -12.0
		var ground_y = get_floor_height(step_x, step_z)
		var step_y = ground_y + 0.12

		# Wooden tread
		var step_plat = MeshInstance3D.new()
		var step_mesh = BoxMesh.new()
		step_mesh.size = Vector3(1.3, 0.24, 2.8)
		step_plat.mesh = step_mesh
		step_plat.material_override = wood_plank_material
		step_plat.position = Vector3(step_x, step_y, step_z)
		add_child(step_plat)
		step_plat.create_trimesh_collision()

		# Solid stone riser base beneath tread
		var stone_riser = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(1.3, 0.35, 2.8)
		stone_riser.mesh = r_box
		stone_riser.material_override = cobblestone_material
		stone_riser.position = Vector3(step_x, step_y - 0.20, step_z)
		add_child(stone_riser)

		# Sturdy timber handrail posts along both sides of descent trail
		if s_idx % 3 == 0 or s_idx == stair_steps - 1:
			for side_z in [-13.5, -10.5]:
				var sp = MeshInstance3D.new()
				var sp_mesh = BoxMesh.new()
				sp_mesh.size = Vector3(0.12, 1.05, 0.12)
				sp.mesh = sp_mesh
				sp.material_override = hewn_timber_material
				sp.position = Vector3(step_x, step_y + 0.525, side_z)
				add_child(sp)
				sp.create_trimesh_collision()

	# 7. Illuminated Trail Navigation Lantern Posts flanking the descent path
	var trail_posts = [
		Vector3(-25.5, 0.0, -13.8),
		Vector3(-21.0, 0.0, -13.8),
		Vector3(-17.0, 0.0, -13.8),
		Vector3(-13.0, 0.0, -13.8)
	]
	for tp in trail_posts:
		var py = get_floor_height(tp.x, tp.z)
		var post = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.12
		p_cyl.bottom_radius = 0.14
		p_cyl.height = 2.4
		p_cyl.radial_segments = 6
		post.mesh = p_cyl
		post.material_override = hewn_timber_material
		post.position = Vector3(tp.x, py + 1.2, tp.z)
		add_child(post)
		post.create_trimesh_collision()

		var lantern_post_light = OmniLight3D.new()
		lantern_post_light.position = Vector3(tp.x, py + 2.3, tp.z)
		lantern_post_light.light_color = Color(1.0, 0.82, 0.48)
		lantern_post_light.light_energy = 2.4
		lantern_post_light.omni_range = 18.0
		lantern_post_light.omni_attenuation = 0.85
		lantern_post_light.shadow_enabled = true
		add_child(lantern_post_light)


# ----------------------------------------------------------------------
# 7. ANCIENT PRECURSOR RUINS ON EAST PLATEAU
# ----------------------------------------------------------------------
func _build_precursor_ruins() -> void:
	var ruins = Node3D.new()
	ruins.name = "PrecursorRuins"
	var plateau_y = get_floor_height(32.0, 0.0)
	ruins.position = Vector3(32.0, plateau_y, 0.0)
	add_child(ruins)

	# Solid Bedrock Foundation Plinth beneath Courtyard
	var foundation = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(12.8, 2.6, 12.8)
	foundation.mesh = f_box
	foundation.material_override = slate_brick_material
	foundation.position = Vector3(0.0, -1.15, 0.0)
	ruins.add_child(foundation)
	foundation.create_trimesh_collision()

	# Flagstone Courtyard
	var courtyard = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(12.0, 0.35, 12.0)
	courtyard.mesh = c_box
	courtyard.material_override = slate_brick_material
	courtyard.position = Vector3(0.0, 0.17, 0.0)
	ruins.add_child(courtyard)
	courtyard.create_trimesh_collision()

	# Archaic Slate Brick Pillars & Archway (Framed along Z axis, facing West approach!)
	for pz in [-3.5, 3.5]:
		var pillar = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(1.8, 8.5, 1.8)
		pillar.mesh = p_mesh
		pillar.material_override = slate_brick_material
		pillar.position = Vector3(0.0, 4.25, pz)
		ruins.add_child(pillar)
		pillar.create_trimesh_collision()

	var arch_beam = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(2.2, 1.4, 8.8)
	arch_beam.mesh = b_mesh
	arch_beam.material_override = slate_brick_material
	arch_beam.position = Vector3(0.0, 9.2, 0.0)
	ruins.add_child(arch_beam)
	arch_beam.create_trimesh_collision()

	# Central Precursor Altar (Goal of Phase 4/5 Delving!)
	var altar = MeshInstance3D.new()
	var a_mesh = CylinderMesh.new()
	a_mesh.top_radius = 1.2
	a_mesh.bottom_radius = 1.6
	a_mesh.height = 1.2
	a_mesh.radial_segments = 8
	altar.mesh = a_mesh
	altar.material_override = slate_brick_material
	altar.position = Vector3(0.0, 0.6, 0.0)
	ruins.add_child(altar)
	altar.create_trimesh_collision()

	# Resonant Celestial Archway Energy Pillar
	var energy_beam = MeshInstance3D.new()
	var eb_mesh = CylinderMesh.new()
	eb_mesh.top_radius = 1.3
	eb_mesh.bottom_radius = 1.6
	eb_mesh.height = 18.0
	eb_mesh.radial_segments = 8
	energy_beam.mesh = eb_mesh

	var eb_mat = StandardMaterial3D.new()
	eb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eb_mat.albedo_color = Color(1.0, 0.82, 0.35, 0.45)
	eb_mat.emission_enabled = true
	eb_mat.emission = Color(1.0, 0.78, 0.28)
	eb_mat.emission_energy_multiplier = 3.2
	eb_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	energy_beam.material_override = eb_mat
	energy_beam.position = Vector3(0.0, 9.0, 0.0)
	ruins.add_child(energy_beam)

	# Relic glow light
	var relic_light = OmniLight3D.new()
	relic_light.position = Vector3(0, 4.0, 0)
	relic_light.light_color = Color(1.0, 0.80, 0.30)
	relic_light.light_energy = 3.5
	relic_light.omni_range = 35.0
	relic_light.shadow_enabled = true
	ruins.add_child(relic_light)

# ----------------------------------------------------------------------
# 8. AMBIENT SUBTERRANEAN SPORES
# ----------------------------------------------------------------------
func _build_ambient_spores() -> void:
	var particles = GPUParticles3D.new()
	particles.name = "SubterraneanSpores"
	particles.amount = 350
	particles.lifetime = 14.0
	particles.preprocess = 6.0
	particles.visibility_aabb = AABB(Vector3(-60, -30, -75), Vector3(120, 95, 150))

	var p_mat = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(cavern_width * 0.44, cavern_height * 0.38, cavern_length * 0.44)
	p_mat.direction = Vector3(0.05, 0.4, 0.0)
	p_mat.spread = 40.0
	p_mat.initial_velocity_min = 0.15
	p_mat.initial_velocity_max = 0.45
	p_mat.gravity = Vector3(0.0, 0.02, 0.0)
	p_mat.scale_min = 0.04
	p_mat.scale_max = 0.12
	p_mat.color = Color(0.45, 0.88, 1.0, 0.65)

	var grad_tex = GradientTexture2D.new()
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.5, 0.95, 1.0, 0.85), Color(0.1, 0.6, 0.9, 0.35), Color(0, 0, 0, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad_tex.gradient = grad
	grad_tex.width = 32
	grad_tex.height = 32

	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.18, 0.18)
	var m_mat = StandardMaterial3D.new()
	m_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	m_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m_mat.albedo_texture = grad_tex
	m_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad_mesh.material = m_mat

	particles.process_material = p_mat
	particles.draw_pass_1 = quad_mesh
	particles.position = Vector3(0, cavern_height * 0.35, 0)
	add_child(particles)

# ----------------------------------------------------------------------
# 9. PROCEDURAL MINERAL VEINS & ORE NODES (TIER 3 & 4)
# ----------------------------------------------------------------------
func _build_mineral_veins() -> void:
	var ore_group = Node3D.new()
	ore_group.name = "MineralVeins"
	add_child(ore_group)

	# Abyssal Phosphor in the deep canyon floor
	var phosphor_coords = [
		Vector3(-5.0, 0.0, 16.0),
		Vector3(5.0, 0.0, 16.0),
		Vector3(0.0, 0.0, 21.0),
		Vector3(-12.0, 0.0, 18.0),
		Vector3(12.0, 0.0, 18.0),
		Vector3(18.0, 0.0, 15.0)
	]
	for pos in phosphor_coords:
		var ore = OreNodeClass.new()
		ore.ore_type = OreNodeClass.OreType.PHOSPHOR
		ore.max_durability = 80.0
		ore.yield_amount = 3
		var floor_y = get_floor_height(pos.x, pos.z)
		ore.position = Vector3(pos.x, floor_y + 0.05, pos.z)
		ore_group.add_child(ore)

	# Raw Iron Ore Veins in the Basin Strata
	var iron_coords = [
		Vector3(-8.0, 0.0, -8.0),
		Vector3(-3.0, 0.0, -14.0),
		Vector3(6.0, 0.0, -10.0),
		Vector3(10.0, 0.0, -2.0),
		Vector3(4.0, 0.0, 4.0),
		Vector3(-6.0, 0.0, 4.0)
	]
	for pos in iron_coords:
		var ore = OreNodeClass.new()
		ore.ore_type = OreNodeClass.OreType.IRON
		ore.max_durability = 100.0
		ore.yield_amount = 4
		var floor_y = get_floor_height(pos.x, pos.z)
		ore.position = Vector3(pos.x, floor_y + 0.05, pos.z)
		ore_group.add_child(ore)

	# Calcite Spires on Basin Slopes
	var calcite_coords = [
		Vector3(-14.0, 0.0, -20.0),
		Vector3(-4.0, 0.0, -24.0),
		Vector3(12.0, 0.0, -20.0),
		Vector3(16.0, 0.0, -12.0),
		Vector3(2.0, 0.0, -6.0)
	]
	for pos in calcite_coords:
		var ore = OreNodeClass.new()
		ore.ore_type = OreNodeClass.OreType.CALCITE
		ore.max_durability = 60.0
		ore.yield_amount = 5
		var floor_y = get_floor_height(pos.x, pos.z)
		ore.position = Vector3(pos.x, floor_y + 0.05, pos.z)
		ore_group.add_child(ore)

# ----------------------------------------------------------------------
# 10. MINABLE COBBLESTONE OUTCROPS (BASIN STRATA - ZERO FLOAT!)
# ----------------------------------------------------------------------
func _build_minable_rock_outcrops() -> void:
	var rock_group = Node3D.new()
	rock_group.name = "MinableRockOutcrops"
	add_child(rock_group)

	# Cleanly positioned exclusively on natural basin terrain
	var rock_coords = [
		Vector2(-9.0, -16.0),
		Vector2(-6.0, -10.0),
		Vector2(-4.0, -5.0),
		Vector2(-10.0, -3.0),
		Vector2(-1.0, -18.0),
		Vector2(5.0, -12.0),
		Vector2(8.0, -5.0),
		Vector2(12.0, -14.0),
		Vector2(15.0, -3.0),
		Vector2(-5.0, 3.0),
		Vector2(7.0, 3.0),
		Vector2(-2.0, -32.0),
		Vector2(6.0, -28.0),
		Vector2(14.0, 8.0)
	]

	for pos in rock_coords:
		var floor_y = get_floor_height(pos.x, pos.y)

		# Natural basalt base socket embedded into terrain
		var socket = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 1.35
		s_cyl.bottom_radius = 1.85
		s_cyl.height = 1.40
		s_cyl.radial_segments = 7
		socket.mesh = s_cyl
		socket.material_override = columnar_basalt_material
		socket.position = Vector3(pos.x, floor_y - 0.35, pos.y)
		rock_group.add_child(socket)
		socket.create_trimesh_collision()

		# Clustered Minable Cobblestone Boulders
		var boulder_offsets = [
			Vector3(-0.35, 0.45, -0.25),
			Vector3(0.40, 0.45, 0.30)
		]
		for b_idx in range(boulder_offsets.size()):
			var bo = boulder_offsets[b_idx]
			var block = MinableBlockClass.new()
			block.max_durability = 45.0
			block.drop_type = DroppedItemClass.ItemType.COBBLESTONE
			block.drop_amount = 2
			block.position = Vector3(pos.x + bo.x, floor_y + bo.y, pos.y + bo.z)

			var m_inst = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(1.05, 0.85, 1.05)
			m_inst.mesh = box
			m_inst.material_override = cobblestone_material
			block.add_child(m_inst)

			var col = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(1.05, 0.85, 1.05)
			col.shape = box_shape
			block.add_child(col)

			rock_group.add_child(block)

# ----------------------------------------------------------------------
# 11. SUBTERRANEAN BASIN FLOOR ILLUMINATION (GROUND VISIBILITY & ATMOSPHERE)
# ----------------------------------------------------------------------
func _build_basin_illumination() -> void:
	var lights_group = Node3D.new()
	lights_group.name = "BasinFloorLights"
	add_child(lights_group)

	# Atmospheric illuminated surveyor beacons placed directly across the cavern floor
	var basin_light_coords = [
		Vector3(-8.0, 0.0, -12.0),
		Vector3(-2.0, 0.0, -14.0),
		Vector3(4.0, 0.0, -10.0),
		Vector3(10.0, 0.0, -6.0),
		Vector3(-4.0, 0.0, 4.0),
		Vector3(2.0, 0.0, 4.0),
		Vector3(8.0, 0.0, 8.0)
	]

	for pos in basin_light_coords:
		var fy = get_floor_height(pos.x, pos.z)

		# Ground tripod beacon base
		var base = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.22
		b_cyl.bottom_radius = 0.35
		b_cyl.height = 0.40
		b_cyl.radial_segments = 6
		base.mesh = b_cyl
		base.material_override = industrial_steel_material
		base.position = Vector3(pos.x, fy + 0.20, pos.z)
		lights_group.add_child(base)
		base.create_trimesh_collision()

		# Warm amber survey beacon light illuminating the surrounding cobblestone terrain
		var light = OmniLight3D.new()
		light.position = Vector3(pos.x, fy + 1.2, pos.z)
		light.light_color = Color(1.0, 0.85, 0.55)
		light.light_energy = 2.6
		light.omni_range = 32.0
		light.omni_attenuation = 0.88
		light.shadow_enabled = false # Fill illumination for floor visibility
		lights_group.add_child(light)
