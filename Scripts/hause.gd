extends StaticBody3D

@onready var door = $hause/Room/Pivot
@onready var door_collision_shape = $DoorCollision
@onready var door_frame_collision_shape = $DoorFrameCollision
@export var door_open_sound: AudioStreamPlayer3D
@export var door_close_sound: AudioStreamPlayer3D

var door_open = false

@rpc("any_peer", "call_local")
func open_door():
	print("Open the door!!")
	door.rotation.y = deg_to_rad(145)
	door_collision_shape.disabled = true
	door_frame_collision_shape.disabled = true
	if not door_open_sound.playing:
		door_open_sound.play()
	door_open = true

@rpc("any_peer", "call_local")
func close_door():
	print("Close the door!!")
	door.rotation.y = deg_to_rad(0)
	door_collision_shape.disabled = false
	door_frame_collision_shape.disabled = false
	if not door_close_sound.playing:
		door_close_sound.play()
	door_open = false


func Interact():
	if Globals.is_networking:
		if not door_open:
			open_door.rpc()
		else:
			close_door.rpc()
	else:
		if not door_open:
			open_door()
		else:
			close_door()	
