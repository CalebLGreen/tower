extends Camera3D

@onready var camera : Camera3D = self
var camera_pan_incr : float = 3.9
var camera_zoom_speed : int = 25
var camera_max_height : float = 16.1
var camera_min_height : float = 0.5
var camera_max_distance : float = 10
var camera_min_distance : float = 6

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pan_up"):
		camera.position.y = clamp(camera.position.y + (camera_pan_incr), camera_min_height, camera_max_height)
	elif Input.is_action_just_pressed("pan_down"):
		camera.position.y = clamp(camera.position.y - (camera_pan_incr), camera_min_height, camera_max_height)
	if Input.is_action_just_pressed("pan_in"):
		camera.position.x = clamp(camera.position.x - (camera_zoom_speed * delta), camera_min_distance, camera_max_distance)
	if Input.is_action_just_pressed("pan_away"):
		camera.position.x = clamp(camera.position.x + (camera_zoom_speed * delta), camera_min_distance, camera_max_distance)

	# print("Camera Position: " camera.position)
