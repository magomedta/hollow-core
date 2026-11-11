
extends SceneTree

func _init():
    var main_packed = load('res://scenes/main.tscn')
    var main = main_packed.instantiate()
    root.add_child(main)
    print('Dumping nodes...')
    var f = FileAccess.open('res://nodes_dump.txt', FileAccess.WRITE)
    _dump(main, f, 0)
    f.close()
    print('Dump finished!')
    quit(0)

func _dump(node: Node, f: FileAccess, depth: int):
    var indent = ''
    for i in range(depth): indent += '  '
    var line = indent + node.name + ' (' + node.get_class() + ')'
    if node is Node3D:
        line += ' gpos=' + str(node.global_position) + ' rot=' + str(node.global_rotation_degrees)
        if node is MeshInstance3D and node.mesh:
            line += ' mesh=' + node.mesh.get_class()
            if node.mesh is BoxMesh:
                line += ' size=' + str(node.mesh.size)
            elif node.mesh is CylinderMesh:
                line += ' h=' + str(node.mesh.height) + ' r=' + str(node.mesh.top_radius)
            if node.material_override:
                line += ' mat=' + node.material_override.resource_name
    f.store_line(line)
    for c in node.get_children():
        _dump(c, f, depth + 1)
