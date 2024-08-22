extends Camera3D

@onready var camera : Camera3D = self
var camera_pan_incr : float = 3.9
@export var is_moving_up : bool = false
@export var is_moving_down : bool = false
var camera_zoom_speed : int = 25
var camera_max_height : float = 16.1
var camera_min_height : float
var camera_max_distance : float = 10
var camera_min_distance : float = 6
var target_y : float = 0.0

func _ready():
	get_floor_count()
	


func _process(delta: float) -> void:
	# Pan Up
	if Input.is_action_just_pressed("pan_up"):
		target_y = clamp(camera.position.y + (camera_pan_incr), camera_min_height, camera_max_height)
		is_moving_up = true
		#print("Moving Camera Up")
	
	# Pan Down
	elif Input.is_action_just_pressed("pan_down"):
		target_y = clamp(camera.position.y - (camera_pan_incr), camera_min_height, camera_max_height)
		is_moving_down = true
		#print("Moving Camera Down")
	
	# Smooth Pan Up
	if is_moving_up:
		camera.position.y = lerp(camera.position.y, target_y, 0.2)
		if abs(camera.position.y - target_y) < 0.01:  # Stop moving when close to the target
			camera.position.y = target_y
			is_moving_up = false
	
	# Smooth Pan Down
	if is_moving_down:
		camera.position.y = lerp(camera.position.y, target_y, 0.2)
		if abs(camera.position.y - target_y) < 0.01:  # Stop moving when close to the target
			camera.position.y = target_y
			is_moving_down = false
	
	# Zoom in
	if Input.is_action_just_pressed("pan_in"):
		camera.position.x = clamp(camera.position.x - (camera_zoom_speed * delta), camera_min_distance, camera_max_distance)
		
	# Zoom out
	if Input.is_action_just_pressed("pan_away"):
		camera.position.x = clamp(camera.position.x + (camera_zoom_speed * delta), camera_min_distance, camera_max_distance)

	# print("Camera Position: " camera.position)


func get_floor_count():
	var number_of_floors = get_tree().get_first_node_in_group("Tower").get_child_count()
	camera_min_height = 0.5
	camera_max_height = 0.5 + (3.9 * (number_of_floors - 1))
	#print("Min Height: ", (camera_min_height), ", Max Height: ", (camera_max_height))
