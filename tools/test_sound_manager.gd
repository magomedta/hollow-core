extends SceneTree

func _init():
	var img = Image.load_from_file("res://textures/mobs/tex_cryo_wisp.png")
	print("Image loaded: ", img)
	var tex = ImageTexture.create_from_image(img)
	print("ImageTexture created: ", tex, " size: ", tex.get_size())
	quit(0)
