class_name MobDeathEffects
extends RefCounted

## Universal Subterranean Horror Mob Death System
## Spawns explosive particle bursts, drops survival loot, and cleanly frees the body.
## Guarantees NO dead corpses or empty hulls remain cluttering the world.

static func play_death_effect(mob: Node3D, mob_type: String = "generic") -> void:
	if not is_instance_valid(mob):
		return

	# 1. Disable collision immediately so player and physics queries pass through cleanly
	if mob is CollisionObject3D:
		mob.collision_layer = 0
		mob.collision_mask = 0

	var parent = mob.get_parent()
	if parent == null:
		mob.queue_free()
		return

	var death_pos = mob.global_position + Vector3(0, 0.5, 0)

	# 2. Spawn dramatic subterranean horror particle explosion
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 32
	particles.lifetime = 0.65
	particles.explosiveness = 0.95
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 2.8
	particles.initial_velocity_max = 5.2
	particles.damping_min = 3.5
	particles.damping_max = 6.0
	particles.scale_amount_min = 0.12
	particles.scale_amount_max = 0.32

	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	particles.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	match mob_type:
		"magma", "basilisk":
			mat.albedo_color = Color(1.0, 0.45, 0.1, 0.95)
		"fungal", "strider", "spitter":
			mat.albedo_color = Color(0.1, 0.9, 0.75, 0.95)
		"geode", "golem", "crawler":
			mat.albedo_color = Color(0.8, 0.3, 1.0, 0.95)
		"cryo", "wisp":
			mat.albedo_color = Color(0.6, 0.85, 1.0, 0.95)
		_:
			# Dark subterranean soul smoke + blood cinders
			mat.albedo_color = Color(0.7, 0.15, 0.2, 0.95)
	sphere.material = mat

	parent.add_child(particles)
	particles.global_position = death_pos

	var pt = particles.create_tween()
	pt.tween_interval(0.75)
	pt.tween_callback(particles.queue_free)

	# 3. Drop thematic survival loot
	var DroppedItemClass = load("res://scripts/dropped_item.gd")
	if DroppedItemClass:
		var drop = DroppedItemClass.new()
		var loot_item = "cobblestone"
		var loot_count = 1
		match mob_type:
			"stalker", "lurker":
				loot_item = "rations"
				loot_count = 1
			"crawler":
				loot_item = "calcite"
				loot_count = 2
			"magma", "basilisk":
				loot_item = "phosphor"
				loot_count = 3
			"fungal", "strider", "spitter":
				loot_item = "mushroom"
				loot_count = 2
			"geode", "golem":
				loot_item = "calcite"
				loot_count = 3
			"cryo", "wisp":
				loot_item = "water"
				loot_count = 1
		drop.setup(loot_item, loot_count, death_pos)
		parent.add_child(drop)

	# 4. Mob model collapse & rapid dissolution (ZERO CORPSE REMAINS!)
	mob.set_physics_process(false)
	mob.set_process(false)

	var tween = mob.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mob, "scale", Vector3(0.01, 0.01, 0.01), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(mob, "position:y", mob.position.y - 0.15, 0.42)

	# Free the mob completely when animation finishes
	var end_tween = mob.create_tween()
	end_tween.tween_interval(0.44)
	end_tween.tween_callback(mob.queue_free)
