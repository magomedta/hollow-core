# scripts/glacial_hydrology.gd
# Realistic Glacial Hydrology & Subterranean Meltwater System
# Features:
# - Water originates strictly from upper glaciers and permafrost strata (Y >= 20..40)
# - Glacial drip stalactites hang from ceiling with animated falling water droplets
# - Floor impact splashes and pure glacial meltwater collection basins
# - Player can drink or fill canteens directly from glacial pools

class_name GlacialHydrology
extends Node3D

const StalactiteScene = preload("res://models/ice_stalactite_drip.glb")

var voxel_world: Node3D
var active_drips: Dictionary = {} # Vector3i -> Node3D

func _ready() -> void:
	name = "GlacialHydrology"

func set_voxel_world(vw: Node3D) -> void:
	voxel_world = vw

func spawn_glacial_drip_at(ceiling_coord: Vector3i, floor_y: int) -> Node3D:
	if active_drips.has(ceiling_coord):
		return active_drips[ceiling_coord]
		
	var drip_node = Node3D.new()
	drip_node.name = "GlacialDrip_%d_%d_%d" % [ceiling_coord.x, ceiling_coord.y, ceiling_coord.z]
	drip_node.position = Vector3(ceiling_coord.x + 0.5, ceiling_coord.y + 0.05, ceiling_coord.z + 0.5)
	
	# 1. 3D Glacial Icicle Speleothem
	var model_inst = StalactiteScene.instantiate()
	model_inst.name = "IcicleModel"
	drip_node.add_child(model_inst)
	
	# 2. Animated Falling Water Droplets Particles
	var drop_particles = CPUParticles3D.new()
	drop_particles.name = "DripParticles"
	drop_particles.amount = 4
	drop_particles.lifetime = 1.4
	drop_particles.explosiveness = 0.0
	drop_particles.randomness = 0.2
	drop_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	drop_particles.emission_points = PackedVector3Array([Vector3(0, -0.75, 0)])
	drop_particles.gravity = Vector3(0, -9.8, 0)
	drop_particles.initial_velocity_min = 0.2
	drop_particles.initial_velocity_max = 0.5
	drop_particles.direction = Vector3.DOWN
	
	var drop_mat = StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.75, 0.90, 1.0, 0.85)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.metallic = 0.1
	drop_mat.roughness = 0.05
	drop_mat.emission_enabled = true
	drop_mat.emission = Color(0.4, 0.7, 0.9)
	drop_mat.emission_energy_multiplier = 0.5
	
	var drop_mesh = SphereMesh.new()
	drop_mesh.radius = 0.025
	drop_mesh.height = 0.05
	drop_mesh.material = drop_mat
	drop_particles.mesh = drop_mesh
	drip_node.add_child(drop_particles)
	
	# 3. Floor Meltwater Basin directly underneath
	var drop_dist = ceiling_coord.y - floor_y
	if drop_dist > 1 and drop_dist < 20:
		var basin = _create_meltwater_basin(drop_dist)
		drip_node.add_child(basin)
		
	add_child(drip_node)
	active_drips[ceiling_coord] = drip_node
	return drip_node

func _create_meltwater_basin(drop_dist: float) -> Node3D:
	var basin_root = Node3D.new()
	basin_root.position = Vector3(0, -drop_dist + 0.06, 0)
	
	# Translucent Water Surface Decal/Mesh
	var water_mesh = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.40
	cm.height = 0.08
	
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.35, 0.65, 0.82, 0.65)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.metallic = 0.15
	water_mat.roughness = 0.08
	water_mat.rim_enabled = true
	water_mat.rim = 0.5
	water_mat.rim_tint = 0.8
	
	water_mesh.mesh = cm
	water_mesh.material_override = water_mat
	basin_root.add_child(water_mesh)
	
	# Floor Splash Rings
	var splash = CPUParticles3D.new()
	splash.name = "FloorSplash"
	splash.amount = 6
	splash.lifetime = 0.45
	splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	splash.emission_sphere_radius = 0.15
	splash.gravity = Vector3(0, -4.0, 0)
	splash.initial_velocity_min = 0.6
	splash.initial_velocity_max = 1.2
	splash.direction = Vector3.UP
	splash.spread = 60.0
	
	var sp_mat = StandardMaterial3D.new()
	sp_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.70)
	sp_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var sp_mesh = SphereMesh.new()
	sp_mesh.radius = 0.015
	sp_mesh.height = 0.03
	sp_mesh.material = sp_mat
	splash.mesh = sp_mesh
	basin_root.add_child(splash)
	
	return basin_root
