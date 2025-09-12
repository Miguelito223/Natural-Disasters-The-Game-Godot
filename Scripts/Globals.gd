extends Node

#Network
@export var ip = "localhost"
@export var port = 9999
@export var points = 0
@export var username = ""
@export var players_conected: Array[Node]
@export var is_networking = false
var enetMultiplayerpeer: ENetMultiplayerPeer


#Globals Weather
@export var Temperature: float = 23
@export var pressure: float = 10000
@export var oxygen: float  = 100
@export var bradiation: float = 0
@export var Humidity: float = 25
@export var Wind_Direction: Vector3 = Vector3(1,0,0)
@export var Wind_speed: float = 0
@export var is_raining: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#Globals Time
@export var time: float = 0.0
@export var time_left: float = 0.0
@export var Day: int = 0
@export var Hour: int = 0
@export var Minute: int = 00

#Globals Weather target
@export var Temperature_target: float = 23
@export var pressure_target: float = 10000
@export var oxygen_target: float = 100
@export var bradiation_target: float = 0
@export var Humidity_target: float = 25
@export var Wind_Direction_target: Vector3 = Vector3(1,0,0)
@export var Wind_speed_target: float = 0

#Globals Weather original
@export var Temperature_original: float = 23
@export var pressure_original: float = 10000
@export var oxygen_original: float = 100
@export var bradiation_original: float = 0
@export var Humidity_original: float = 25
@export var Wind_Direction_original: Vector3 = Vector3(1,0,0)
@export var Wind_speed_original: float = 0

@export var seconds = Time.get_unix_time_from_system()

@export var main: Node3D
@export var main_menu: Control
@export var map: Node3D
@export var local_player: CharacterBody3D

@export var bounding_radius_areas = {}



@export var started = false
@export var GlobalsData: DataResource = DataResource.load_file()

@export var current_weather_and_disaster = "Sun"
@export var current_weather_and_disaster_int = 0

var player_scene = preload("res://Scenes/player.tscn")
var linghting_scene = preload("res://Scenes/thunder.tscn")
var meteor_scene = preload("res://Scenes/meteors.tscn")
var tornado_scene = preload("res://Scenes/tornado.tscn")
var tsunami_scene = preload("res://Scenes/tsunami.tscn")
var volcano_scene = preload("res://Scenes/Volcano.tscn")
var earthquake_scene = preload("res://Scenes/earthquake.tscn")

@onready var timer = $Timer

func convert_MetoSU(metres):
	return (metres * 39.37) / 0.75

func convert_KMPHtoMe(kmph):
	return (kmph*1000)/3600

func convert_VectorToAngle(vector):
	var x = vector.x
	var y = vector.z
	
	return int(360 + rad_to_deg(atan2(y,x))) % 360

func perform_trace_collision(ply, direction):
	var start_pos = ply.global_position
	var end_pos = start_pos + direction * 1000
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [ply.get_rid()]
	var result = space_state.intersect_ray(ray)

	if result:
		return true
	else:
		return false

func perform_trace_wind(ply, direction):
	var start_pos = ply.global_position
	var end_pos = start_pos + direction * 60000
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [ply.get_rid()]
	var result = space_state.intersect_ray(ray)

	if result:
		return result.position
	else:
		return end_pos

func get_node_by_id_recursive(node: Node, node_id: int) -> Node:
	if node.get_instance_id() == node_id:
		return node

	for child in node.get_children():
		var result := get_node_by_id_recursive(child, node_id)
		if result != null:
			return result

	return null

func is_below_sky(ply):
	var start_pos = ply.global_position
	var end_pos = start_pos + Vector3(0, 48000, 0)
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [ply.get_rid()]
	var result = space_state.intersect_ray(ray)
	
	return !result


func is_outdoor(ply):
	var hit_left = perform_trace_collision(ply, Vector3(1, 0, 0))
	var hit_right = perform_trace_collision(ply, Vector3(-1, 0, 0))
	var hit_forward = perform_trace_collision(ply, Vector3(0, 0, 1))
	var hit_behind = perform_trace_collision(ply, Vector3(0, 0, -1))
	var in_tunnel = (hit_left and hit_right) and not (hit_forward and hit_behind) or ((not hit_left and not hit_right) and (hit_forward or hit_behind))
	var hit_sky = is_below_sky(ply)

	if ply.is_in_group("player"):
		if hit_sky:
			ply.Outdoor = true
		else:
			ply.Outdoor = false
		
		return hit_sky
	else:
		return hit_sky

func is_inwater(ply):
	if ply.is_in_group("player"):
		return ply.IsInWater

func is_underwater(ply):
	if ply.is_in_group("player"):
		return ply.IsUnderWater
	
func is_inlava(ply):
	if ply.is_in_group("player"):
		return ply.IsInLava

func is_underlava(ply):
	if ply.is_in_group("player"):
		return ply.IsUnderLava


func vec2_to_vec3(vector):
	return Vector3(vector.x, 0, vector.y)

func is_something_blocking_wind(entity):
	var start_pos = entity.global_position
	var end_pos = start_pos + (Wind_Direction * 300)
	var space_state = entity.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [entity.get_rid()]
	var result = space_state.intersect_ray(ray)

	if result:
		return true
	else:
		return false

func calcule_bounding_radius(entity):
	var max_radius = 0.0
	
	for child in entity.get_children():
		if child.get_child_count() > 0:
			return calcule_bounding_radius(child)

		if child.is_class("MeshInstance3D") and child != null:
			var mesh = child.mesh
			var aabb = mesh.get_aabb()
			
			# Obtener los 8 vértices de la AABB original
			var vertices = [
				aabb.position,
				aabb.position + Vector3(aabb.size.x, 0, 0),
				aabb.position + Vector3(0, aabb.size.y, 0),
				aabb.position + Vector3(0, 0, aabb.size.z),
				aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
				aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
				aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
				aabb.position + aabb.size
			]
			
			# Transformar los vértices con la matriz de transformación del MeshInstance3D
			var transformed_vertices = []
			for vertex in vertices:
				transformed_vertices.append(child.transform * vertex )
			
			# Calcular el nuevo AABB a partir de los vértices transformados
			# Calcular el radio de contorno a partir de los vértices transformados
			for vertex in transformed_vertices:
				var distance = vertex.length()
				max_radius = max(max_radius, distance)


	return max_radius



func search_in_node(node, origin: Vector3, radius: float, result: Array):
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if child.is_class("Spatial"): # Solo considerar nodos Spatial (puedes ajustar esto según tus necesidades)
			var distance = origin.distance_to(child.global_position)
			if distance <= radius:
				result.append(child)
		# Recursión si el nodo tiene hijos
		if child.get_child_count() > 0:
			search_in_node(child, origin, radius, result)

	return result

func find_in_sphere(origin: Vector3, radius: float) -> Array:
	var result = []
	var scene_root = get_tree().get_root()
	
	result = search_in_node(scene_root, origin, radius, result)

	return result

func wind(object):
	# Verificar si el objeto es un jugador
	if object.is_in_group("player"):
		var is_outdoor = is_outdoor(object)
		var is_something_blocking_wind = is_something_blocking_wind(object)
		var hit_left = perform_trace_wind(object, Vector3(1, 0, 0))
		var hit_right = perform_trace_wind(object, Vector3(-1, 0, 0))
		var hit_forward = perform_trace_wind(object, Vector3(0, 0, 1))
		var hit_behind = perform_trace_wind(object, Vector3(0, 0,-1))
		
		var distance_left_right = hit_left.distance_to(hit_right)
		var distance_forward_behind = hit_forward.distance_to(hit_behind)
		
		var area = distance_left_right * distance_forward_behind / 2
		var area_percentage = clamp(area / 100, 0, 1)
		
		# Calcular la velocidad del viento local
		var local_wind = area_percentage * Wind_speed
		if not is_outdoor or is_something_blocking_wind:
			local_wind = 0

		object.body_wind = local_wind
		
		# Calcular la velocidad del viento y la fricción
		var wind_vel = convert_MetoSU(convert_KMPHtoMe((clamp(((clamp(local_wind / 256, 0, 1) * 5) ** 2) * local_wind, 0, local_wind) / 2.9225))) * Wind_Direction
		var frictional_scalar = clamp(wind_vel.length(), -400, 400)
		var frictional_velocity = frictional_scalar * -wind_vel.normalized()
		var wind_vel_new = (wind_vel + frictional_velocity) * 0.5

		# Verificar si está al aire libre y no hay obstáculos que bloqueen el viento
		if is_outdoor and not is_something_blocking_wind:
			var delta_velocity = (object.get_velocity() - wind_vel_new) - object.get_velocity()
			
			if delta_velocity.length() != 0:
				object.set_velocity(delta_velocity * 0.3)
	elif object.is_in_group("movable_objects") and object.is_class("RigidBody3D"):
		var is_outdoor = is_outdoor(object)
		var is_something_blocking_wind = is_something_blocking_wind(object)
		if is_outdoor and not is_something_blocking_wind:
			var area = Area(object)
			var mass = object.mass

			var force_mul_area = clamp((area / 680827), 0, 1) # bigger the area >> higher the f multiplier is
			var friction_mul = clamp((mass / 50000), 0, 1) # lower the mass  >> lower frictional force 
			var avrg_mul = (force_mul_area + friction_mul) / 2 
			
			var wind_vel = convert_MetoSU(convert_KMPHtoMe(Wind_speed / 2.9225)) * Wind_Direction
			var frictional_scalar = clamp(wind_vel.length(), 0, mass)
			var frictional_velocity = frictional_scalar * -wind_vel.normalized()
			var wind_vel_new = (wind_vel + frictional_velocity) * -1
			
			var windvel_cap = wind_vel_new.length() - object.get_linear_velocity().length()

			if windvel_cap > 0:
				object.add_constant_central_force(wind_vel_new * avrg_mul) 

func Area(entity):
	if not "bounding_radius_area" in entity or entity.bounding_radius_area == null:
		var bounding_radius = calcule_bounding_radius(entity)
		var bounding_radius_area = (2 * PI) * (bounding_radius * bounding_radius)
		bounding_radius_areas[entity] = bounding_radius_area
		
		return bounding_radius_area
	else:
		return entity.bounding_radius_area

func get_frame_multiplier() -> float:
	var frame_time: float = Engine.get_frames_per_second()
	if frame_time == 0:
		return 0
	else:
		return 60 / frame_time

func get_physics_multiplier() -> float:
	var physics_interval: float = get_physics_process_delta_time()
	return (200.0 / 3.0) / physics_interval

func hit_chance(chance: int) -> bool:
	if is_networking:
		if multiplayer.is_server():
			# En el servidor
			return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
		else:
			# En el cliente
			return randf() < (clamp(chance * get_frame_multiplier(), 0, 100) / 100)
	else:
		return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
	
@rpc("any_peer", "call_local")
func sync_player_list():
	players_conected.clear()

	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			players_conected.append(p)


func print_role(msg: String):
	if is_networking:
		var is_server = get_tree().get_multiplayer().is_server()
		
		if is_server:
			# Azul
			print_rich("[color=blue][Servidor] " + msg + "[/color]")
		else:
			# Amarillo
			print_rich("[color=yellow][Cliente] " + msg + "[/color]")
	else:
		print(msg)



func hostwithport(port_int):
	enetMultiplayerpeer = ENetMultiplayerPeer.new()
	var error = enetMultiplayerpeer.create_server(port_int)
	if error == OK:
		multiplayer.multiplayer_peer = enetMultiplayerpeer
		multiplayer.allow_object_decoding = true
		if multiplayer.is_server():
			is_networking = true
			if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
				print_role("Servidor dedicado iniciado.")

				await get_tree().create_timer(2).timeout

				UPNP_setup()
				LoadScene.load_scene(main_menu, "map")
			else:
				UPNP_setup()
				LoadScene.load_scene(main_menu, "map")
	else:
		print_role("Fatal Error in server")


func joinwithip(ip_str, port_int):
	enetMultiplayerpeer = ENetMultiplayerPeer.new()
	var error = enetMultiplayerpeer.create_client(ip_str, port_int)
	if error == OK:
		multiplayer.multiplayer_peer = enetMultiplayerpeer
		multiplayer.allow_object_decoding = true
		if not multiplayer.is_server():
			is_networking = true
			UnloadScene.unload_scene(main_menu)
	else:
		print_role("Fatal Error in client")

func server_fail():
	print_role("client disconected: failed to load")
	is_networking = false
	sync_player_list()
	LoadScene.load_scene(map, "res://Scenes/main_menu.tscn")
	
func server_disconect():
	print_role("client disconected")
	is_networking = false
	sync_player_list()
	LoadScene.load_scene(map, "res://Scenes/main_menu.tscn")


func server_connected():
	print_role("connected to server :)")
	is_networking = true

func UPNP_setup():
	var upnp = UPNP.new()

	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:  
		print_role("UPNP discover Failed")
		return
	
	if upnp.get_gateway() and !upnp.get_gateway().is_valid_gateway():
		print_role("UPNP invalid gateway")
		return 

	var map_result_udp = upnp.add_port_mapping(port, port, "", "UDP")
	if map_result_udp != UPNP.UPNP_RESULT_SUCCESS:
		print_role("UPNP port UDP mapping failed")
		return

	var map_result_tcp = upnp.add_port_mapping(port, port, "", "TCP")
	if map_result_tcp != UPNP.UPNP_RESULT_SUCCESS:
		print_role("UPNP port TCP mapping failed")
		return



func _exit_tree() -> void:
	multiplayer.peer_connected.disconnect(player_join)
	multiplayer.peer_disconnected.disconnect(player_disconect)
	multiplayer.server_disconnected.disconnect(server_disconect)
	multiplayer.connected_to_server.disconnect(server_connected)
	multiplayer.connection_failed.disconnect(server_fail)

	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original

func _process(_delta):
	if is_networking:
		if not multiplayer.is_server(): 
			return

	time_left = timer.time_left
	Temperature = clamp(Temperature, -275.5, 275.5)
	Humidity = clamp(Humidity, 0, 100)
	bradiation = clamp(bradiation, 0, 100)
	pressure = clamp(pressure , 0, 100000)
	oxygen = clamp(oxygen, 0, 100)

	Temperature = lerp(Temperature, Temperature_target, 0.005)
	Humidity = lerp(Humidity, Humidity_target, 0.005)
	bradiation = lerp(bradiation, bradiation_target, 0.005)
	pressure = lerp(pressure, pressure_target, 0.005)
	oxygen = lerp(oxygen, oxygen_target, 0.005)
	Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005)
	Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005)

func _ready():
	multiplayer.peer_connected.connect(player_join)
	multiplayer.peer_disconnected.connect(player_disconect)
	multiplayer.server_disconnected.connect(server_disconect)
	multiplayer.connected_to_server.connect(server_connected)
	multiplayer.connection_failed.connect(server_fail)

	print("ready is running")

	if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
		var args = OS.get_cmdline_user_args()
		for arg in args:
			var key_value = arg.rsplit("=")
			match key_value[0]:
				"port":
					Globals.port = key_value[1].to_int()

		Globals.print_role("port:" + Globals.port)
		Globals.print_role("ip:" + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4))
		
		await get_tree().create_timer(2).timeout

		Globals.hostwithport(Globals.port)
	else: 
		Globals.print_role("No se puede jugar en modo de servidor")
	

func player_join(peer_id):
	if is_networking:
		if not multiplayer.is_server():
			return 
			
	var player = player_scene.instantiate()
	if map and is_instance_valid(map):
		print_role("Joined player id: " + str(peer_id))
		player.id = peer_id
		player.name = str(peer_id)
		map.add_child(player, true)

		sync_player_list.rpc()

		set_weather_and_disaster.rpc_id(peer_id, current_weather_and_disaster_int)

		print_role("finish :D")




func player_join_singleplayer():
	var player = player_scene.instantiate()
	player.id = 1
	player.name = str(1)
	map.add_child(player, true)


func player_disconect(peer_id):
	if is_networking:
		if not multiplayer.is_server():
			return 

	var player = map.get_node(str(peer_id))
	if is_instance_valid(player):
		print_role("Disconected player id: " + str(peer_id))
		sync_player_list.rpc()
		player.queue_free()
		print_role("finish :D")



func sync_weather_and_disaster():
	if Globals.is_networking:
		if multiplayer.is_server():
			var random_weather_and_disaster = randi_range(0,12)
			set_weather_and_disaster.rpc(random_weather_and_disaster)
	else:
		var random_weather_and_disaster = randi_range(0,12)
		set_weather_and_disaster(random_weather_and_disaster)		

@rpc("any_peer", "call_local")
func set_weather_and_disaster(weather_and_disaster_index):
	match weather_and_disaster_index:
		0:
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = 0
			if is_instance_valid(map):
				map.is_sun()
		1:
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
			if is_instance_valid(map):
				map.is_cloud()
		2:
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
			if is_instance_valid(map):
				map.is_raining()
		3:
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
			if is_instance_valid(map):
				map.is_storm()
		4:
			current_weather_and_disaster = "Linghting storm"
			current_weather_and_disaster_int = 4
			if is_instance_valid(map):
				map.is_linghting_storm()

		5:
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
			if is_instance_valid(map):
				map.is_tsunami()

		6:
			current_weather_and_disaster = "Meteor shower"
			current_weather_and_disaster_int = 6
			if is_instance_valid(map):
				map.is_meteor_shower()
		7:
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
			if is_instance_valid(map):
				map.is_volcano()
		8:
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
			if is_instance_valid(map):
				map.is_tornado()
		9:
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
			map.is_acid_rain()
		10:
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10
			if is_instance_valid(map):
				map.is_earthquake()

		11:
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
			if is_instance_valid(map):
				map.is_sandstorm()
		12:
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
			if is_instance_valid(map):
				map.is_blizzard()

		"Sun":
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = 0
			if is_instance_valid(map):
				map.is_sun()

		"Cloud":
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
			if is_instance_valid(map):
				map.is_cloud()
		"Raining":
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
			if is_instance_valid(map):
				map.is_raining()
		"Storm":
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
			if is_instance_valid(map):
				map.is_storm()
		"Linghting storm":
			current_weather_and_disaster = "Linghting storm"
			current_weather_and_disaster_int = 4
			if is_instance_valid(map):
				map.is_linghting_storm()
		"Tsunami":
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
			if is_instance_valid(map):
				map.is_tsunami()
		"Meteor shower":
			current_weather_and_disaster = "Meteor shower"
			current_weather_and_disaster_int = 6
		"Volcano":
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
			if is_instance_valid(map):
				map.is_volcano()
		"Tornado":
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
			if is_instance_valid(map):
				map.is_tornado()
		"Acid rain":
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
			if is_instance_valid(map):
				map.is_acid_rain()
		"Earthquake":
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10
			if is_instance_valid(map):
				map.is_earthquake()

		"Sand Storm":
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
			if is_instance_valid(map):
				map.is_sandstorm()
		"blizzard":
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
			if is_instance_valid(map):
				map.is_blizzard()


func teleport_position(pos):
	for player in self.get_children():
		if player.is_multiplayer_authority() and player.is_in_group("player"):
			player.position = pos

func teleport_player(player_name):
	for player in self.get_children():
		if player.is_multiplayer_authority() and player.is_in_group("player"):
			for player2 in self.get_children():
				if player2.is_in_group("player") and player2.username == player_name  :
					player.position = player2.position


func kill_player(player_name):
	for player2 in self.get_children():
		if player2.is_in_group("player") and player2.username == player_name  :
			player2.damage(100)

func god_mode_player(player_name):
	for player2 in self.get_children():
		if player2.is_in_group("player") and player2.username == player_name  :
			player2.god_mode = true

func kick_player(player_name):
	for player2 in self.get_children():
		if player2.is_in_group("player") and player2.username == player_name  :
			multiplayer.multiplayer_peer.disconnect_peer(player2.id, true)

func damage_player(player_name, damage):
	for player2 in self.get_children():
		player2.damage(damage)



func _on_timer_timeout():
	if started:
		sync_weather_and_disaster()
	else:
		if Globals.is_networking:
			multiplayer.multiplayer_peer.close()
