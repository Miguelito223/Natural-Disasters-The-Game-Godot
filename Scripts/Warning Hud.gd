extends CanvasLayer

func _enter_tree():
	if Globals.is_networking:
		set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:
	if Globals.is_networking:
		if not is_multiplayer_authority():
			self.visible = is_multiplayer_authority()
			return

	self.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Globals.started:
		$Label.text = "Current Disasters/Weather is: \n"  + Globals.current_weather_and_disaster + "\nTime Left for the next disasters: \n" + str(int(Globals.timer.time_left)) + "\nTime:\n" + str(Globals.Hour) + ":" + str(Globals.Minute)
	else:
		$Label.text = "Waiting for players... Time remain: \n" + str(int(Globals.timer.time_left))
