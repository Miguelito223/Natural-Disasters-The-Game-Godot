extends CharacterBody3D

@onready var tsunami = $tsunami
var speed = 100
var tsunami_strength = 100
var direction = Vector3(0, 0, 1)
var distance_traveled = 0.0
var total_distance = 4097.0  # Adjust this value based on your scene

func _physics_process(delta):
	var distance_this_frame = speed * delta
	distance_traveled += distance_this_frame
	var displacement = direction * distance_this_frame

	position += displacement

	for body in $Area3D.get_overlapping_bodies():
		if body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
			var body_direction = direction
			var relative_direction = global_transform.origin - body.global_transform.origin
			var projected_direction = body_direction.project(relative_direction)
			var force = projected_direction.normalized() * tsunami_strength
			body.apply_central_impulse(force)
			body.freeze = false
		elif body.is_in_group("player"):
			if not body.is_on_floor():
				body.velocity = self.velocity

	move_and_slide()

func _on_area_3d_body_entered(body: Node3D):
	if body.is_in_group("player"):
		body.IsInWater = true
		if body.camera_node:
			body.IsUnderWater = true

func _on_area_3d_body_exited(body: Node3D):
	if body.is_in_group("player"):
		body.IsInWater = false
		if body.camera_node:
			body.IsUnderWater = false

