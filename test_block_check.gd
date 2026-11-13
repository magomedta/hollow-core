extends SceneTree

func _init():
    call_deferred('_run')

func _run():
    var am = ArrayMesh.new()
    var vertices = PackedVector3Array([
        Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)
    ])
    var normals = PackedVector3Array([
        Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0)
    ])
    var uvs = PackedVector2Array([
        Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)
    ])
    var indices = PackedInt32Array([0, 2, 1, 0, 3, 2])
    
    var arr = []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = vertices
    arr[Mesh.ARRAY_NORMAL] = normals
    arr[Mesh.ARRAY_TEX_UV] = uvs
    arr[Mesh.ARRAY_INDEX] = indices
    am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

    var root_node = Node3D.new()
    root.add_child(root_node)
    var mi = MeshInstance3D.new()
    mi.mesh = am
    var mat = StandardMaterial3D.new()
    mat.cull_mode = BaseMaterial3D.CULL_BACK
    mat.albedo_color = Color(1, 0, 0, 1) # bright red
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mi.material_override = mat
    root_node.add_child(mi)

    var cam = Camera3D.new()
    root_node.add_child(cam)
    cam.position = Vector3(0.5, 3.0, 0.5)
    cam.look_at_from_position(Vector3(0.5, 3.0, 0.5), Vector3(0.5, 1.0, 0.5), Vector3(0, 0, -1))
    cam.current = true

    for i in range(5):
        await process_frame

    var img = root.get_texture().get_image()
    if img:
        img.save_png('res://test_cube_face.png')
        var col = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
        print('Center pixel color:', col)
    quit(0)
