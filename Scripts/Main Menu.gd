extends Control

var resolution: Dictionary = {
	"2400x1080 ": Vector2i(2400, 1080 ),
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1440x1080": Vector2i(14400, 1080),
	"1440x900": Vector2i(1440, 900),
	"1366x768": Vector2i(1366, 768),
	"1360x768": Vector2i(1360, 768),
	"1280x1024": Vector2i(1280, 1024),
	"1280x962": Vector2i(1280, 962),
	"1280x960": Vector2i(1280, 960),
	"1280x800": Vector2i(1280, 800),
	"1280x768": Vector2i(1280, 768),
	"1280x720": Vector2i(1280, 720),
	"1176x664": Vector2i(1176, 664),
	"1152x648": Vector2i(1152, 648),
	"1024x768": Vector2i(1024, 768),
	"800x600": Vector2i(800, 600),
	"720x480": Vector2i(720, 480),
}

func addresolutions():
	var current_resolution = Globals.GlobalsData.resolution
	var index = 0
	
	for r in resolution:
		$Settings/resolutions.add_item(r,index)
		
		if resolution[r] == current_resolution:
			$Settings/resolutions._select_int(index)
		index += 1


# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.main_menu = self


	
	$Menu.show()
	$Title.show()
	$Multiplayer.hide()
	$Settings.hide()

   
	$Multiplayer/username.text = Globals.username
	$Multiplayer/ip.text = Globals.ip
	$Multiplayer/port.text = str(Globals.port)
	
	addresolutions()
	DisplayServer.window_set_size(Globals.GlobalsData.resolution)
	get_viewport().set_size(Globals.GlobalsData.resolution)

	$Settings/Fullscreen.button_pressed = Globals.GlobalsData.fullscreen
	$Settings/fps.button_pressed = Globals.GlobalsData.FPS
	$Settings/vsync.button_pressed = Globals.GlobalsData.vsync
	$Settings/antialiasing.button_pressed = Globals.GlobalsData.antialiasing
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(Globals.GlobalsData.volumen))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Globals.GlobalsData.volumen_music))
	$Settings/Volumen.value = Globals.GlobalsData.volumen
	$"Settings/Volumen Music".value = Globals.GlobalsData.volumen_music
	$Settings/Time.value = Globals.GlobalsData.timer_disasters
	$Settings/quality.selected = Globals.GlobalsData.quality



func _process(_delta):
	if self.visible:
		await $Music.finished
		$Music.play()
	else:
		$Music.stop()


func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)


func _on_join_pressed():
	if Globals.username.length() < 10 and Globals.username.length() >= 1:
		Globals.joinwithip(Globals.ip, Globals.port)
	else:
		$Multiplayer/Label.visible = true
		await get_tree().create_timer(2).timeout
		$Multiplayer/Label.visible = false


func _on_host_pressed():
	if Globals.username.length() < 10 and Globals.username.length() >= 1:
		Globals.hostwithport(Globals.port)
	else:
		$Multiplayer/Label.visible = true
		await get_tree().create_timer(2).timeout
		$Multiplayer/Label.visible = false


func _on_play_pressed():
	$Menu.hide()
	$Multiplayer.show()
	$Title.hide()
	$Settings.hide()


func _on_settings_pressed():
	$Menu.hide()
	$Multiplayer.hide()
	$Title.hide()
	$Settings.show()


func _on_exit_pressed():
	get_tree().quit()



func _on_fps_toggled(toggled_on:bool):
	Globals.GlobalsData.FPS = toggled_on
	Globals.GlobalsData.save_file()


func _on_vsycn_toggled(toggled_on:bool):
	Globals.GlobalsData.vsync = toggled_on
	ProjectSettings.set_setting("display/window/vsync/vsync_mode", toggled_on)
	Globals.GlobalsData.save_file()


func _on_antialiasing_toggled(toggled_on:bool):
	Globals.GlobalsData.antialiasing = toggled_on
	ProjectSettings.set_setting("rendering/anti_aliasing/screen_space_roughness_limiter/enabled", toggled_on)
	Globals.GlobalsData.save_file()


func _on_back_pressed():
	$Menu.show()
	$Title.show()
	$Multiplayer.hide()
	$Settings.hide()


func _on_username_text_changed(new_text:String):
	Globals.username = new_text
	Globals.GlobalsData.save_file()


func _on_h_slider_2_value_changed(value):
	Globals.GlobalsData.timer_disasters = value
	Globals.GlobalsData.save_file()


func _on_volumen_value_changed(value:float):
	Globals.GlobalsData.volumen = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	Globals.GlobalsData.save_file()

func _on_resolutions_item_selected(index:int):
	var size = resolution.get($Settings/resolutions.get_item_text(index))
	DisplayServer.window_set_size(size)
	get_viewport().set_size(size)
	Globals.GlobalsData.resolution = size
	Globals.GlobalsData.save_file()


func _on_fullscreen_toggled(toggled_on:bool):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Globals.GlobalsData.fullscreen = toggled_on
	Globals.GlobalsData.save_file()


func _on_singleplayer_pressed():
	LoadScene.load_scene(self, "map")


func _on_volumen_music_value_changed(value):
	Globals.GlobalsData.volumen_music = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	Globals.GlobalsData.save_file()


func _on_option_button_item_selected(index: int):
	Globals.GlobalsData.quality = index
	Globals.GlobalsData.save_file()
