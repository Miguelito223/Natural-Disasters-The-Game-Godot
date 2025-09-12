extends Node3D
var snow_texture = preload("res://Textures/snow.png")
var sand_texture = preload("res://Textures/sand.png")

@onready var terrain = $HTerrain
@onready var worldenvironment = $WorldEnvironment

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

func _ready():
	Globals.map = self
	is_sun()

	if not Globals.is_networking:
		Globals.player_join_singleplayer()
		Globals.started = true
		Globals.timer.wait_time = Globals.GlobalsData.timer_disasters
		Globals.timer.start()
	else:
		if multiplayer.is_server():
			if not OS.has_feature("dedicated_server") :
				Globals.player_join(1)	

			for i in multiplayer.get_peers():
				Globals.player_join(i)

			
			Globals.timer.wait_time = Globals.GlobalsData.timer_disasters
			Globals.timer.start()


# Llama a la función wind para cada objeto en la escena
func _physics_process(_delta):
	for object in get_children():
		Globals.wind(object)

	
func _process(_delta):
	terrain.ambient_wind = Globals.Wind_speed * _delta

	if Globals.is_networking:
		if Globals.players_conected.size() > 1:
			Globals.started = true
		else:
			Globals.started = false



func is_tsunami():
	var tsunami = Globals.tsunami_scene.instantiate()
	tsunami.position = Vector3(0,0,0)
	add_child(tsunami, true)

	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	while Globals.current_weather_and_disaster == "Tsunami":
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

	while Globals.current_weather_and_disaster != "Tsunami":
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



	while Globals.current_weather_and_disaster == "Linghting storm":
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
			var lighting = Globals.linghting_scene.instantiate()
			if result.has("position"):
				lighting.position = result.position
			else:
				lighting.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))

			add_child(lighting, true)

		await get_tree().create_timer(0.5).timeout

	while Globals.current_weather_and_disaster != "Linghting storm":

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
	
	while Globals.current_weather_and_disaster == "Meteor shower":
		var player = Globals.local_player

		if is_instance_valid(player):
			player.rain_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			player.snow_node.emitting = false
			$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 1)
			$WorldEnvironment.environment.volumetric_fog_enabled = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	


		var meteor = Globals.meteor_scene.instantiate()
		meteor.position = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		add_child(meteor, true)

		await get_tree().create_timer(0.5).timeout

	while Globals.current_weather_and_disaster != "Meteor shower":

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


	while Globals.current_weather_and_disaster == "blizzard":
		
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
	
	while Globals.current_weather_and_disaster != "blizzard":

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

	while Globals.current_weather_and_disaster == "Sand Storm":
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

	while Globals.current_weather_and_disaster != "Sand Storm":

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

	var volcano = Globals.volcano_scene.instantiate()
	if result.has("position"):
		volcano.position = result.position
	else:
		volcano.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))

	add_child(volcano, true)

	while Globals.current_weather_and_disaster == "Volcano" and not volcano.IsVolcanoAsh:
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
	
	

	while Globals.current_weather_and_disaster != "Volcano":
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

		
	var tornado = Globals.tornado_scene.instantiate()
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

	while Globals.current_weather_and_disaster == "Tornado":
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
			var lighting = Globals.linghting_scene.instantiate()
			if result.has("position"):
				lighting.position = result.position
			else:
				lighting.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))

			add_child(lighting, true)

		await get_tree().create_timer(0.5).timeout

	while Globals.current_weather_and_disaster != "Tornado":
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

	while Globals.current_weather_and_disaster == "Acid rain":
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
	
	while Globals.current_weather_and_disaster != "Acid rain":

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

	var earquake = Globals.earthquake_scene.instantiate()
	add_child(earquake,true)

	while Globals.current_weather_and_disaster == "Earthquake":
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

	while Globals.current_weather_and_disaster != "Earthquake":
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

	while Globals.current_weather_and_disaster == "Sun":
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


	while Globals.current_weather_and_disaster == "Cloud":
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

	while Globals.current_weather_and_disaster != "Cloud":

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
	
	while Globals.current_weather_and_disaster == "Raining":
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

	while Globals.current_weather_and_disaster != "Raining":

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

	while Globals.current_weather_and_disaster == "Storm":
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

	while Globals.current_weather_and_disaster != "Storm":

		Globals.points += 1
		
		break

