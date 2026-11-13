extends SceneTree

func _init():
    var mobs = ['abyssal_glider', 'cave_wyrm', 'chasm_stalker', 'cryo_wisp', 'fungal_strider', 'geode_golem', 'lithic_crawler', 'magma_basilisk', 'pale_lurker', 'spore_spitter', 'wall_mimic']
    for m in mobs:
        var p = 'res://models/' + m + '.glb'
        var res = load(p)
        if res:
            var inst = res.instantiate()
            var meshes = []
            _find_meshes(inst, meshes)
            var info = []
            for mi in meshes:
                var mat = mi.material_override
                if mat == null and mi.mesh:
                    mat = mi.mesh.surface_get_material(0)
                var mat_name = mat.resource_name if mat else 'NONE'
                var has_tex = false
                if mat is StandardMaterial3D:
                    has_tex = (mat.albedo_texture != null)
                info.append(mi.name + ' (mat=' + mat_name + ', has_albedo=' + str(has_tex) + ')')
            print(m, ' -> ', info)
        else:
            print(m, ' -> FAILED TO LOAD')
    quit(0)

func _find_meshes(node: Node, out: Array):
    if node is MeshInstance3D:
        out.append(node)
    for c in node.get_children():
        _find_meshes(c, out)
