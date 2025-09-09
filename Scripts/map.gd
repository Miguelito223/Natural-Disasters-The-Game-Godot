extends Node3D

var player_scene = preload("res://Scenes/player.tscn")

var current_weather_and_disaster = "Sun"
var current_weather_and_disaster_int = 0

var linghting_scene = preload("res://Scenes/thunder.tscn")
var meteor_scene = preload("res://Scenes/meteors.tscn")
var tornado_scene = preload("res://Scenes/tornado.tscn")
var tsunami_scene = preload("res://Scenes/tsunami.tscn")
var volcano_scene = preload("res://Scenes/Volcano.tscn")
var earthquake_scene = preload("res://Scenes/earthquake.tscn")

var snow_texture = preload("res://Textures/snow.png")
var sand_texture = preload("res://Textures/sand.png")


var GlobalsData: DataResource = DataResource.load_file()

@onready var timer = $Timer
@onready var terrain = $HTerrain
@onready var worldenvironment = $WorldEnvironment

var started = false

func _enter_tree() -> void:
	Globals.map = self

func _exit_tree():
	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.bradiation_target = Globals.bradiation_original
	Globals.oxygen_target = Globals.oxygen_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original
	$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
	$WorldEnvironment.environment.volumetric_fog_enabled = false
	$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 1, 1)
	
	if Globals.is_networking:
		multiplayer.peer_connected.disconnect(player_join)
		multiplayer.peer_disconnected.disconnect(player_disconect)
		multiplayer.server_disconnected.disconnect(Globals.server_disconect)
		multiplayer.connected_to_server.disconnect(Globals.server_connected)
		multiplayer.connection_failed.disconnect(Globals.server_fail)

func _ready():
	Globals.map = self
	is_sun()

	if not Globals.is_networking:
		player_join(1)
		started = true
		Globals.sync_timer(GlobalsData.timer_disasters)
	else:
		multiplayer.peer_connected.connect(player_join)
		multiplayer.peer_disconnected.connect(player_disconect)

		if multiplayer.is_server():
			if not OS.has_feature("dedicated_server") :
				player_join(1)	
				
func player_join(peer_id):

	if Globals.is_networking:
		print("Joined player id: " + str(peer_id))
		var player = player_scene.instantiate()
		player.id = peer_id
		player.name = str(peer_id)

		if multiplayer.is_server():
			print("syncring timer, map, player_list and weather/disasters in server")
			var player_host = get_node(str(multiplayer.get_unique_id()))
			if player_host != null and player_host != player:
				Globals.add_player_to_list.rpc_id(peer_id, multiplayer.get_unique_id(), player_host)

			Globals.add_player_to_list.rpc(peer_id, player)

			if Globals.players_conected_int >= 2 and started == false:
				Globals.sync_timer.rpc(GlobalsData.timer_disasters)
				set_started.rpc(true)
			elif Globals.players_conected_int < 2 and started == true:
				Globals.sync_timer.rpc(60)
				set_started.rpc(false)
			elif Globals.players_conected_int >= 2 and started == true:
				Globals.sync_timer.rpc(GlobalsData.timer_disasters)
				set_started.rpc(true)
			else:
				Globals.sync_timer.rpc(60)
				set_started.rpc(false)


			set_weather_and_disaster.rpc_id(peer_id, current_weather_and_disaster_int)
			
			print("finish :D")

		add_child(player, true)
		
		player._reset_player()
	else:
		print("Joined player id: " + str(peer_id))
		var player = player_scene.instantiate()
		player.id = peer_id
		player.name = str(peer_id)
		add_child(player, true)

		player._reset_player()

	
	


		

func player_disconect(peer_id):
	if Globals.is_networking:
		var player = get_node(str(peer_id))
		if is_instance_valid(player):
			print("Disconected player id: " + str(peer_id))
			if multiplayer.is_server():
				print("syncring timer, map, player_list and weather/disasters in server")
				Globals.remove_player_to_list.rpc(peer_id, player)
				if Globals.players_conected_int >= 2 and started == false:
					Globals.sync_timer.rpc(GlobalsData.timer_disasters)
					set_started.rpc(true)
				elif Globals.players_conected_int < 2 and started == true:
					Globals.sync_timer.rpc(60)
					set_started.rpc(false)
				elif Globals.players_conected_int >= 2 and started == true:
					Globals.sync_timer.rpc(GlobalsData.timer_disasters)
					set_started.rpc(true)
				else:
					Globals.sync_timer.rpc(60)
					set_started.rpc(false)
				print("finish :D")

			player.queue_free()
	else:
		var player = get_node(str(peer_id))
		if is_instance_valid(player):	
			await get_tree().create_timer(5).timeout
			print("Disconected player id: " + str(peer_id))
			player.queue_free()
			
@rpc("any_peer","call_local")
func set_started(started_bool):
	started = started_bool

# Llama a la función wind para cada objeto en la escena
func _physics_process(_delta):
	for object in get_children():
		Globals.wind(object)

	
func _process(_delta):
	terrain.ambient_wind = Globals.Wind_speed * _delta

func _on_timer_timeout():
	if started:
		if Globals.is_networking:
			if multiplayer.is_server():
				Globals.sync_timer.rpc(GlobalsData.timer_disasters)
		else:
			Globals.sync_timer(GlobalsData.timer_disasters)
	
		sync_weather_and_disaster()
	else:
		if Globals.is_networking:
			multiplayer.multiplayer_peer.close()


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
			is_sun()
		1:
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
			is_cloud()
		2:
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
			is_raining()
		3:
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
			is_storm()
		4:
			current_weather_and_disaster = "Linghting storm"
			current_weather_and_disaster_int = 4
			is_linghting_storm()

		5:
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
			is_tsunami()

		6:
			current_weather_and_disaster = "Meteor shower"
			current_weather_and_disaster_int = 6
			is_meteor_shower()
		7:
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
			is_volcano()
		8:
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
			is_tornado()
		9:
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
			is_acid_rain()
		10:
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10
			is_earthquake()

		11:
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
			is_sandstorm()
		12:
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
			is_blizzard()

		"Sun":
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = 0
			is_sun()	

		"Cloud":
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
			is_cloud()	
		"Raining":
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
			is_raining()
		"Storm":
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
			is_storm()
		"Linghting storm":
			current_weather_and_disaster = "Linghting storm"
			current_weather_and_disaster_int = 4
			is_linghting_storm()		
		"Tsunami":
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
			is_tsunami()
		"Meteor shower":
			current_weather_and_disaster = "Meteor shower"
			current_weather_and_disaster_int = 6
		"Volcano":
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
			is_volcano()
		"Tornado":
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
			is_tornado()
		"Acid rain":
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
			is_acid_rain()
		"Earthquake":
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10
			is_earthquake()

		"Sand Storm":
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
			is_sandstorm()
		"blizzard":
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
			is_blizzard()

func is_tsunami():
	var tsunami = tsunami_scene.instantiate()
	tsunami.position = Vector3(0,0,0)
	add_child(tsunami, true)

	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	while current_weather_and_disaster == "Tsunami":
		var player = Globals.local_player
		
		if is_instance_valid(player):
			player.rain_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			player.snow_node.emitting = false
			$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 1)
			$WorldEnvironment.environment.volumetric_fog_enabled = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	


		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Tsunami":
		if is_instance_valid(tsunami):
			tsunami.queue_free()
		
		Globals.points += 1
		
		break




func is_linghting_storm():

	Globals.Temperature_target = randf_range(5,15)
	Globals.Humidity_target = randf_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 30)



	while current_weather_and_disaster == "Linghting storm":
		var player = Globals.local_player

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority() or true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				

		var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		var space_state = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
		var result = space_state.intersect_ray(ray)				
		if randi_range(1,25) == 25:
			var lighting = linghting_scene.instantiate()
			if result.has("position"):
				lighting.position = result.position
			else:
				lighting.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))

			add_child(lighting, true)

		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Linghting storm":

		Globals.points += 1
		
		break



func is_meteor_shower():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.pressure_target = randf_range(10000,10020)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)
	
	while current_weather_and_disaster == "Meteor shower":
		var player = Globals.local_player

		if is_instance_valid(player):
			player.rain_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			player.snow_node.emitting = false
			$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 1)
			$WorldEnvironment.environment.volumetric_fog_enabled = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	


		var meteor = meteor_scene.instantiate()
		meteor.position = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		add_child(meteor, true)

		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Meteor shower":

		Globals.points += 1
		
		break

func is_blizzard():
	Globals.Temperature_target =  randf_range(-20,-35)
	Globals.Humidity_target = randf_range(20,30)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(40, 50)


	while current_weather_and_disaster == "blizzard":
		
		var player = Globals.local_player
		
		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
				
		var Snow_Decal = Decal.new()
		Snow_Decal.texture_albedo = snow_texture
		var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		var space_state = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
		var result = space_state.intersect_ray(ray)	
		if result.has("position"):
			Snow_Decal.position = result.position
		else:
			Snow_Decal.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))
		var randon_num = randi_range(1,256)
		Snow_Decal.size = Vector3(randon_num,1,randon_num)
		add_child(Snow_Decal, true)	


		await get_tree().create_timer(0.5).timeout	
	
	while current_weather_and_disaster != "blizzard":

		Globals.points += 1
		
		break


func is_sandstorm():
	Globals.Temperature_target =  randf_range(30,35)
	Globals.Humidity_target = randf_range(0,5)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(30, 50)

	while current_weather_and_disaster == "Sand Storm":
		var player = Globals.local_player
		
		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = player.is_multiplayer_authority() or true
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 0.647059, 0)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)		

		var Sand_Decal = Decal.new()
		Sand_Decal.texture_albedo = sand_texture
		var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		var space_state = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
		var result = space_state.intersect_ray(ray)	
		if result.has("position"):
			Sand_Decal.position = result.position
		else:
			Sand_Decal.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))
		var randon_num = randi_range(1,256)
		Sand_Decal.size = Vector3(randon_num,1,randon_num)
		add_child(Sand_Decal, true)		
			
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Sand Storm":

		Globals.points += 1
		
		break

func is_volcano():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)

	var volcano = volcano_scene.instantiate()
	if result.has("position"):
		volcano.position = result.position
	else:
		volcano.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))

	add_child(volcano, true)

	while current_weather_and_disaster == "Volcano" and not volcano.IsVolcanoAsh:
		var player = Globals.local_player

		if is_instance_valid(player):
			player.rain_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			player.snow_node.emitting = false
			$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 1)
			$WorldEnvironment.environment.volumetric_fog_enabled = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			
		await get_tree().create_timer(0.5).timeout
	
	

	while current_weather_and_disaster != "Volcano":
		if is_instance_valid(volcano):
			volcano.IsVolcanoAsh = false
			volcano.queue_free()

		Globals.points += 1
		
		break

	


func is_tornado():

	var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)	

		
	var tornado = tornado_scene.instantiate()
	if result.has("position"):
		tornado.position = result.position
	else:
		tornado.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))
	add_child(tornado, true)

	Globals.Temperature_target =  randf_range(5,15)
	Globals.Humidity_target = randf_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 30)

	while current_weather_and_disaster == "Tornado":
		var player = Globals.local_player

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority() or true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				



		rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		space_state = get_world_3d().direct_space_state
		ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
		result = space_state.intersect_ray(ray)			
		
		if randi_range(1,25) == 25:
			var lighting = linghting_scene.instantiate()
			if result.has("position"):
				lighting.position = result.position
			else:
				lighting.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))

			add_child(lighting, true)

		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Tornado":
		if is_instance_valid(tornado):
			tornado.queue_free()

		Globals.points += 1

		break
	



func is_acid_rain():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 100
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	while current_weather_and_disaster == "Acid rain":
		var player = Globals.local_player

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority() or true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0,1,0)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0,1,0)						

		await get_tree().create_timer(0.5).timeout
	
	while current_weather_and_disaster != "Acid rain":

		Globals.points += 1
		
		break

func is_earthquake():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	var earquake = earthquake_scene.instantiate()
	add_child(earquake,true)

	while current_weather_and_disaster == "Earthquake":
		var player = Globals.local_player

		if is_instance_valid(player):
			player.rain_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			player.snow_node.emitting = false
			$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 1)
			$WorldEnvironment.environment.volumetric_fog_enabled = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Earthquake":
		if is_instance_valid(earquake):
			earquake.queue_free()
		
		Globals.points += 1
		
		break





func is_sun():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	while current_weather_and_disaster == "Sun":
		var player = Globals.local_player

		if is_instance_valid(player):
			player.rain_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			player.snow_node.emitting = false
			$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 1)
			$WorldEnvironment.environment.volumetric_fog_enabled = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			
		await get_tree().create_timer(0.5).timeout


func is_cloud():
	Globals.Temperature_target =  randf_range(20,25)
	Globals.Humidity_target = randf_range(10,30)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(9000,10000)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target =  randf_range(0, 10)


	while current_weather_and_disaster == "Cloud":
		var player = Globals.local_player

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)			
		
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Cloud":

		Globals.points += 1
		
		break



func is_raining():

	Globals.Temperature_target =   randf_range(10,20)
	Globals.Humidity_target =  randf_range(20,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(9000,9020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 20)
	
	while current_weather_and_disaster == "Raining":
		var player = Globals.local_player
		
		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority() or true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				

		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Raining":

		Globals.points += 1
		
		break

func is_storm():
	Globals.Temperature_target =  randf_range(5,15)
	Globals.Humidity_target = randf_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(30, 60)

	while current_weather_and_disaster == "Storm":
		var player = Globals.local_player

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority()
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
	
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Storm":

		Globals.points += 1
		
		break

