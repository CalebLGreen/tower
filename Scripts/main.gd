extends Node3D

# Onready variables
@onready var camera : Camera3D = get_node("Camera3D")
@onready var UI : Control = get_node("UI")
@onready var tower = get_node("Tower")
@onready var top_floor = get_node("Tower/Floor_TOP")
@onready var number_of_floors : int
@onready var blank_floor : PackedScene = preload("res://Scenes/floor_blank.tscn")
@onready var table : PackedScene = preload("res://Scenes/table.tscn")

# Constants
var tower_segment_base_height = 0.77
var tower_segment_height = 3.9

# Export variables
@export var rotate_speed : float = 1.5

#DEBUG
var timer = false

# Buildables
var temp_object = null

# Shop variables
var in_build_menu : bool = false
var building_table : Dictionary = {'value' : false}
var moving_object : Dictionary = {'value' : false}
var selected_object = null

func _ready() -> void:
	# Reset camera
	camera.position = Vector3(8,1,0)
	# get the floor count, important for other functions
	get_floor_count()


func _process(delta: float) -> void:
	# check for whether the shop panel is open
	if UI.shop_panel.visible:
		in_build_menu = true
	else:
		in_build_menu = false
	# handle the mouse controls, currently only used in the shop
	handle_mouse_controls(delta)
	
	
func handle_mouse_controls(delta) -> void:
	# Create a ray cast on the mouse
	var space_state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	
	var origin : Vector3 = camera.project_ray_origin(mouse_pos)
	var end : Vector3 = origin + camera.project_ray_normal(mouse_pos)*20
	var ray : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)

	# Ensure the ray collides with the correct layer and bodies
	ray.collide_with_bodies = true
	ray.collision_mask = 1
	# DEBUG print
	#print(ray.collision_mask)
	# Store values from collision
	var ray_result : Dictionary = space_state.intersect_ray(ray)
	# DEBUG 1 per second timer print
	#if timer:
		#pass
	#elif not timer:
		#timer = get_tree().create_timer(1.0)
		#await timer.timeout
		#print(origin, ", ", end, " ", ray_result)
		#timer = false
	# Now if building
	if in_build_menu:
		# Check if the table is being built
		if building_table.value:
			build(table, "Table", building_table, ray_result, delta)
		#if moving_object.value:
			#move(ray_result, moving_object, delta)


func build(object : PackedScene, object_name : String, building_object : Dictionary, ray_result: Dictionary, delta: float) -> void:
	# stop the user changing floors
	camera.is_movement_locked = true
	
	# DEBUG print
	#print("BUILDING")
	# Check whether the ray has collided with anything, i.e. the floor
	if ray_result.size() > 0:
		# get the current floor, used for collisions and naming
		var curr_floor = get_current_floor()
		# if a ghostly version of the object doesn't exist, create it
		if temp_object == null:

			temp_object = object.instantiate()
			get_node("Tower/%s" % [curr_floor]).add_child(temp_object)
			temp_object.visible = true
			# Add the object to the correct groups
			
		# Cancel placement
		if Input.is_action_just_pressed("cancel"):
			temp_object.queue_free()
			building_object.value = false
			camera.is_movement_locked = false
			UI.toggle_shop()
		
		# If the ghostly object does already exist continue
		if temp_object:
			# Change the collision layer of the object
			# The mask layer is still one so it'll collide with walls and floors
			# This ensures the object doesn't collide with the ray cast
			# Important that the string name in the scene is correct
			temp_object.get_node("%s" % [object_name]).collision_layer = 2
			
			# Get the mesh instance node from the object, used to switch it between being green, red or complete
			# Be consistent with the nomenclature of child nodes in the scenes to following the same format
			var mesh_instance = temp_object.get_node("%s/%s_Mesh" % [object_name, object_name])
			# Get the interesction of the ray and where it collides
			# Set the the object position to hover slightly below this point, due to my silly blender skills
			var intersection_point : Vector3 = ray_result.get("position")
			
			var current_floor_number = get_current_floor_num()
			var offset = -0.48 - (tower_segment_height * get_current_floor_num() - 1)
			temp_object.position = intersection_point + Vector3(0, offset, 0)
			#prints(current_floor_number, offset, intersection_point)
			# Allow for rotations - simple enough
			if Input.is_action_pressed("rotate_left"):
				temp_object.rotation.y += delta * rotate_speed
			elif Input.is_action_pressed("rotate_right"):
				temp_object.rotation.y -= delta * rotate_speed
			
			# Get the Area3D for collisions with self
			var area = temp_object.get_node("%s/%s_Area" % [object_name, object_name])
			if area and area is Area3D:
				area.global_transform.origin = temp_object.global_transform.origin
				
				# Check for overlaps, currently can be placed on the wrong floor, must fix
				var overlaps = area.get_overlapping_bodies()
				#print(overlaps)
				var valid_overlaps = []
				for body in overlaps:
					if not is_floor(body, curr_floor):
						valid_overlaps.append(body)
				# See if there are any overlaps, in which case make the material red
				# and it cannot be placed
				if overlaps.size() > 0 or temp_object.global_position.y < (camera.position.y - 1.5) or temp_object.global_position.y > (camera.position.y-1):
					#print(temp_object.global_position.y, " ", camera.position.y)
					mesh_instance.set_surface_override_material(0, load("res://Models/red.tres"))
				# If no overlaps then we are good to go
				else:
					mesh_instance.set_surface_override_material(0, load("res://Models/green.tres"))
					if Input.is_action_just_pressed("left_click"):
						# slightly lower the position to compensate for the slight lift
						temp_object.position -= Vector3(0, 0.02, 0)
						# Change the collision layer back to 1
						temp_object.get_node("%s" % [object_name]).collision_layer = 1
						# Reset it back to default textures
						mesh_instance.set_surface_override_material(0, null)
						# This object now no longer exists as a variable
						#print(temp_object.get_groups())
						temp_object = null
						building_object.value = false
						camera.is_movement_locked = false

## Function to move objects on a floor
#func move(ray_result : Dictionary, moving_object : Dictionary, delta : float) -> void:
	#camera.is_movement_locked = true
	#if ray_result.size() > 0:
		## get the current floor, used for collisions and naming
		#var curr_floor = get_current_floor()
		## if a ghostly version of the object doesn't exist, create it
		#if Input.is_action_just_pressed("left_click"):
			#if selected_object:
				#move_object(ray_result, moving_object, delta)
			#else:
				#select_object(ray_result)
		#elif Input.is_action_just_pressed("cancel"):
			#selected_object = null
			#moving_object.value = false
#
#func select_object(ray_result : Dictionary) -> void:
	#var collider = ray_result.get("collider")
	#if collider and collider is Node3D:
		#selected_object = collider
	#else:
		#print("Object not selectable")


func move_object(ray_result : Dictionary, moving_object : Dictionary, delta : float) -> void:
	if selected_object:
		var interesection_point : Vector3 = ray_result.get("position")
		selected_object.position = interesection_point + Vector3(0, -3.38, 0)
		
		# Allow for rotations
		if Input.is_action_pressed("rotate_left"):
			selected_object.rotation.y += delta * rotate_speed
		elif Input.is_action_pressed("rotate_right"):
			selected_object.rotation.y -= delta * rotate_speed

		# Finalize the move on left click
		if Input.is_action_just_pressed("left_click"):
			print("Object moved to: ", selected_object.position)
			selected_object = null  # Deselect after moving
			moving_object.value = false

# Function to check whether the floor is the current floor
func is_floor(body: Node3D, current_floor) -> bool:
	#print(body.name, current_floor)
	if body.name == current_floor:
		return true
	else:
		return false

# Add a new floor when the top floor upgrade is pressed
func _on_floor_top_add_floor_pressed() -> void:
	# create a new floor
	var new_floor = blank_floor.instantiate()
	# make it a child of the Tower Node
	tower.add_child(new_floor,0, 0)
	# get a new number of floors
	number_of_floors = get_floor_count()
	# move the floor to the penultimate place in the list
	# otherwise the for loop for naming and the shop doesn't work
	tower.move_child(new_floor, number_of_floors - 2)
	# give the node a name
	new_floor.name = "Floor_%d" % [number_of_floors-2]
	# give it a position
	new_floor.position = top_floor.position
	# then move the top floor up by the height of one floor
	top_floor.position.y += 3.9
	# update the UI
	UI.tower_segments = tower.get_children()
	UI.check_floor(camera.position)
	# update the camera information for clamping
	camera.get_floor_count()

# get the floor count
func get_floor_count() -> int:
	number_of_floors = get_tree().get_first_node_in_group("Tower").get_child_count()
	return number_of_floors

# get the name of the current floor as a string
func get_current_floor() -> String:
	var current_floor_name = get_node("UI/Label").text
	return current_floor_name

func get_current_floor_num() -> int:
	var current_floor_number
	var current_floor_name = get_current_floor()
	var prefix = "Floor_"
	var index = current_floor_name.rfind(prefix)
	if index != -1:
		var suffix_start = index + prefix.length()
		current_floor_number = current_floor_name.substr(suffix_start, current_floor_name.length() - suffix_start)
		
		if current_floor_number.is_valid_int():
			return int(current_floor_number)
		else:
			return -1
		
	else:
		return -1

# for when the button to buy a table has been pressed
func _on_floor_add_table_pressed() -> void:
	building_table.value = true


func _on_move_objects_pressed() -> void:
	#moving_object.value = true
	pass
