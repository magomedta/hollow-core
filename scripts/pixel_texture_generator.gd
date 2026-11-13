# scripts/pixel_texture_generator.gd
class_name PixelTextureGenerator
extends RefCounted

# Static cache of 64x64 retro pixel art textures
static var _cache: Dictionary = {}

static func _load_or_create(key: String, path: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]

	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			_cache[key] = res
			return res

	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img != null and not img.is_empty():
			var tex = ImageTexture.create_from_image(img)
			_cache[key] = tex
			return tex

	# Fallback placeholder if file somehow missing
	var fallback_img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	fallback_img.fill(Color(0.2, 0.2, 0.25, 1.0))
	var tex = ImageTexture.create_from_image(fallback_img)
	_cache[key] = tex
	return tex

# 1. Cavern Strata Textures (64x64)
static func get_stone_texture() -> Texture2D:
	return get_deep_basalt_texture()

static func get_deep_basalt_texture() -> Texture2D:
	return _load_or_create("deep_basalt", "res://textures/deep_basalt.png")

static func get_cobblestone_texture() -> Texture2D:
	return _load_or_create("cobblestone_shale", "res://textures/cobblestone_shale.png")

static func get_mossy_stone_texture() -> Texture2D:
	return _load_or_create("mossy_stone", "res://textures/mossy_stone.png")

static func get_slate_brick_texture() -> Texture2D:
	return _load_or_create("slate_brick", "res://textures/slate_brick.png")

static func get_cavern_gravel_texture() -> Texture2D:
	return _load_or_create("cavern_gravel", "res://textures/cavern_gravel.png")

static func get_column_texture() -> Texture2D:
	return get_deep_basalt_texture()

# 2. Wood & Camp Textures (64x64)
static func get_wood_plank_texture() -> Texture2D:
	return _load_or_create("wood_planks", "res://textures/wood_planks.png")

static func get_hewn_timber_texture() -> Texture2D:
	return _load_or_create("hewn_timber", "res://textures/hewn_timber.png")

static func get_crate_texture() -> Texture2D:
	return _load_or_create("cargo_crate", "res://textures/cargo_crate.png")

static func get_surveyor_desk_texture() -> Texture2D:
	return _load_or_create("wood_planks", "res://textures/wood_planks.png")

# 3. Mineral & Ore Textures (64x64)
static func get_phosphor_texture() -> Texture2D:
	return _load_or_create("phosphor_ore", "res://textures/phosphor_ore.png")

static func get_iron_ore_texture() -> Texture2D:
	return _load_or_create("iron_ore", "res://textures/iron_ore.png")

static func get_calcite_texture() -> Texture2D:
	return _load_or_create("calcite_crystal", "res://textures/calcite_crystal.png")

# 4. Metallurgy & Industrial Textures (64x64)
static func get_industrial_steel_texture() -> Texture2D:
	return _load_or_create("industrial_steel", "res://textures/industrial_steel.png")

static func get_hazard_steel_texture() -> Texture2D:
	return _load_or_create("hazard_steel", "res://textures/hazard_steel.png")

static func get_lantern_brass_texture() -> Texture2D:
	return _load_or_create("antique_brass", "res://textures/antique_brass.png")

static func get_lantern_glass_texture() -> Texture2D:
	if not _cache.has("lantern_glass"):
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var c_clear = Color(0.85, 0.92, 1.0, 0.15)
		var c_frame = Color(0.20, 0.20, 0.24, 0.90)
		for y in range(64):
			for x in range(64):
				var is_frame = (x < 3 or x >= 61 or y < 3 or y >= 61)
				img.set_pixel(x, y, c_frame if is_frame else c_clear)
		_cache["lantern_glass"] = ImageTexture.create_from_image(img)
	return _cache["lantern_glass"]

# 5. Character First-Person Textures (64x64)
static func get_sleeve_texture() -> Texture2D:
	return _load_or_create("canvas_sleeve", "res://textures/canvas_sleeve.png")

static func get_cuff_texture() -> Texture2D:
	return _load_or_create("work_glove", "res://textures/work_glove.png")

static func get_glove_texture() -> Texture2D:
	return _load_or_create("work_glove", "res://textures/work_glove.png")

# 6. Digging & Destruction Fracture Decals (64x64)
static func get_dig_crack_texture(stage: int) -> Texture2D:
	var s = clamp(stage, 1, 5)
	var key = "dig_crack_%d" % s
	return _load_or_create(key, "res://textures/dig_crack_%d.png" % s)

# 7. Diverse Subterranean Strata & Geological Formations (64x64)
static func get_natural_stone_texture() -> Texture2D:
	return _load_or_create("stone_rock", "res://textures/stone_rock.png")

static func get_deepslate_texture() -> Texture2D:
	return _load_or_create("deepslate_rock", "res://textures/deepslate_rock.png")

static func get_granite_texture() -> Texture2D:
	return _load_or_create("granite_rock", "res://textures/granite_rock.png")

static func get_diorite_texture() -> Texture2D:
	return _load_or_create("diorite_rock", "res://textures/diorite_rock.png")

static func get_andesite_texture() -> Texture2D:
	return _load_or_create("andesite_rock", "res://textures/andesite_rock.png")

static func get_coal_ore_texture() -> Texture2D:
	return _load_or_create("coal_ore", "res://textures/coal_ore.png")

static func get_copper_ore_texture() -> Texture2D:
	return _load_or_create("copper_ore", "res://textures/copper_ore.png")

static func get_gold_ore_texture() -> Texture2D:
	return _load_or_create("gold_ore", "res://textures/gold_ore.png")

static func get_permafrost_ice_texture() -> Texture2D:
	return _load_or_create("permafrost_ice", "res://textures/permafrost_ice.png")

static func get_magma_rock_texture() -> Texture2D:
	return _load_or_create("magma_rock", "res://textures/magma_rock.png")

static func get_bedrock_texture() -> Texture2D:
	return _load_or_create("bedrock", "res://textures/bedrock.png")

static func get_stalker_chitin_texture() -> Texture2D:
	return _load_or_create("stalker_chitin", "res://textures/stalker_chitin.png")

static func get_water_spring_texture() -> Texture2D:
	return _load_or_create("water_spring", "res://textures/water_spring.png")

static func get_biolum_mushroom_texture() -> Texture2D:
	return _load_or_create("biolum_mushroom", "res://textures/biolum_mushroom.png")

static func get_sulfur_block_texture() -> Texture2D:
	return _load_or_create("sulfur_block", "res://textures/sulfur_block.png")

static func get_crystal_amethyst_texture() -> Texture2D:
	return _load_or_create("crystal_amethyst", "res://textures/crystal_amethyst.png")

static func get_precursor_conduit_texture() -> Texture2D:
	return _load_or_create("precursor_conduit", "res://textures/precursor_conduit.png")

static func get_lichen_root_texture() -> Texture2D:
	return _load_or_create("lichen_root", "res://textures/lichen_root.png")

# 8. Unified 512x512 Voxel Texture Atlas
static func get_texture_atlas() -> Texture2D:
	return _load_or_create("texture_atlas", "res://textures/texture_atlas.png")

# 9. Handcrafted 32x32 Visual Item Icons for UI & Inventory
static func get_item_icon(item_id: String) -> Texture2D:
	var path = "res://textures/icon_%s.png" % item_id
	if FileAccess.file_exists(path):
		return _load_or_create("icon_" + item_id, path)
	# Fallback icon
	return _load_or_create("icon_cobblestone", "res://textures/icon_cobblestone.png")

static func preload_all() -> void:
	get_texture_atlas()
	var items = [
		"pickaxe", "lantern", "torch", "timber", "planks", "cobblestone",
		"canteen", "rations", "calcite", "phosphor", "iron", "gold",
		"journal", "mushroom", "water", "lichen", "copper", "coal"
	]
	for it in items:
		get_item_icon(it)



