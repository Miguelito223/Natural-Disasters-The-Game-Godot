extends CanvasLayer

@onready var container = $Panel/GridContainer
@export var spawnlist: Array[Node]
@export var buttonlist: Array[Button]
@export var spawnedobject: Array[Node]
var spawnmenu_state = false
@onready var camera = get_parent().get_node("head/Camera3D")

var entity_scene = preload("res://Scenes/entity.tscn")

const RAY_LENGTH = 10000

func _ready():

	self.visible = false
	load_spawnlist_entities()
	load_buttons()


func load_spawnlist_entities():
	var directory = DirAccess.open("res://Scenes/")
	if directory:
		var files = directory.get_files()
		for f in files:
			if f.ends_with(".tscn"):
				var node = load(directory.get_current_dir() + "/" + f).instantiate()
				if node is Node3D:
					var icon_path = "res://icons/" + node.name + "_icon.png"
					if ResourceLoader.exists(icon_path):
						spawnlist.append(node)


func load_buttons():
	for i in spawnlist:
		var icon_path = "res://icons/" + i.name + "_icon.png"
		if ResourceLoader.exists(icon_path): # 🔑 comprueba que el archivo exista
			var entity = entity_scene.instantiate()
			var label = entity.get_node("Label")
			label.text = i.name
			label.add_theme_font_size_override("FontSize", 20)
			label.custom_minimum_size = Vector2(150, 150) # cada celda fija
			var icon = entity.get_node("Icon")
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_normal = load(icon_path)	
			icon.custom_minimum_size = Vector2(64, 64) # icono fijo
			container.add_child(entity)

			icon.pressed.connect(func(): on_press(i))
		else:
			Globals.print_role("No icon for " + i.name)


func on_press(i: Node):
	if Globals.is_networking:
		if not multiplayer.is_server():
			Globals.print_role("You not a host")
			return

	var player = get_parent()
	var raycast = player.interactor
	
	if raycast.is_colliding():
		var new_i = i.duplicate()
		new_i.transform.origin = raycast.get_collision_point()
		spawnedobject.append(new_i)
		Globals.map.add_child(new_i)

	



func spawnmenu():
	self.visible = spawnmenu_state
	
	if spawnmenu_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if not Globals.is_networking:
			get_tree().paused = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if not Globals.is_networking:
			get_tree().paused = false

	spawnmenu_state = !spawnmenu_state

func remove():
	if spawnedobject.size() > 0:
		var last = spawnedobject.pop_back()
		if is_instance_valid(last):
			last.queue_free()



func _process(_delta):
	if Input.is_action_just_pressed("Spawnmenu"):
		spawnmenu()

	if Input.is_action_just_pressed("Remove"):
		remove()
