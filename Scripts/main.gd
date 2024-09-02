extends Node3D

# Onready variables
@onready var camera : Camera3D = get_node("Camera3D")
@onready var UI : Control = get_node("UI")
@onready var tower = get_node("Tower")
@onready var top_floor = get_node("Tower/Floor_TOP")
var number_of_floors : int
var number_of_basement_floors : int
@onready var blank_floor : PackedScene = preload("res://Scenes/Tower/floor_blank.tscn")

# Cursors
var cursor_default = load("res://Models/Cursors/arrow_cursor_default.png")
var cursor_move = load("res://Models/Cursors/arrow_cursor.png")
var cursor_build = load("res://Models/Cursors/cursor_hammer.png")

# Player Values
var gold : int = 10000

# Constants
var tower_segment_base_height = 0.77
var tower_segment_height = 3.9

# Export variables
@export var rotate_speed : float = 1.5

#DEBUG
var timer = false

# Buildables
@onready var table : PackedScene = preload("res://Scenes/Objects/table.tscn")
@onready var furnace : PackedScene = preload("res://Scenes/Objects/furnace.tscn")
var green_overlay = load("res://Models/Tower/Tower_Objects/green.tres")
var red_overlay = load("res://Models/Tower/Tower_Objects/red.tres")
var table_cost : int = 100
var furnace_cost : int = 500

# Buildables & Shop Variables
var temp_object = null
var in_build_menu : bool = false
var building_table : Dictionary = {'value' : false}
var building_furnace : Dictionary = {'value' : false}
var moving_object : Dictionary = {'value' : false}
var moving_object_original_position : Dictionary = {'x' : 0, 'y' : 0, 'z' : 0}
var moving_object_original_rotation : Dictionary = {'x' : 0, 'y' : 0, 'z' : 0}
var selected_object = null
@onready var shop_objects : Dictionary = {'Table' : table, 'Furnace' : furnace}
@onready var building_current_item : Dictionary = {
	'Table' : building_table,
	'Furnace' : building_furnace
}
@onready var original_building_items_cost : Dictionary = {
	'Table' : table_cost,
	'Furnace' : furnace_cost
}
@onready var building_items_costs : Dictionary = {
	'Table' : {'cost' : table_cost},
	'Furnace' : {'cost' : furnace_cost}
}

func _ready() -> void:
	# Reset camera
	print("Setting camera position")
	camera.position = Vector3(8,0.5,0)
	# Change cursor
	change_mouse_cursor_image(cursor_default)


func _process(delta: float) -> void:
	# check for whether the shop panel is open
	if UI.shop_panel.visible:
		in_build_menu = true
	else:
		in_build_menu = false
	# handle the mouse controls, currently only used in the shop
	handle_mouse_controls(delta)


func change_mouse_cursor_image(cursor_image, cursor_shape = 0) -> void:
	Input.set_custom_mouse_cursor(cursor_image)
	Input.set_default_cursor_shape(cursor_shape)

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
	if building_table.value:
		var key = "Table"
		if gold >= building_items_costs[key]['cost']:
			build(shop_objects[key], key, false, building_current_item[key], ray_result, delta, +0.52, building_items_costs[key])
		else:
			print("Too Poor")
			building_table.value = false
	if building_furnace.value:
		var key = "Furnace"
		if gold >= building_items_costs[key]['cost']:
			build(shop_objects[key], key, true, building_current_item[key], ray_result, delta, -0.05, building_items_costs[key])
		else:
			print("Too Poor")
			building_furnace.value = false
	if moving_object.value:
		move(ray_result, moving_object, delta)


func build(object : PackedScene, object_name : String, basement : bool, building_object : Dictionary, ray_result: Dictionary, delta: float, offset, build_cost : Dictionary = {'cost' : 0}) -> void:
	# stop the user changing floors
	camera.is_movement_locked = true
	# Toggle the shop window to give more visibility
	if UI.shop_panel.visible:
		UI.toggle_shop()
		pass
	# DEBUG print
	#print("BUILDING")
	# Check whether the ray has collided with anything, i.e. the floor
	if ray_result.size() > 0:
		# get the current floor, used for collisions and naming
		var curr_floor
		curr_floor = get_current_floor()
		# if a ghostly version of the object doesn't exist, create it
		if temp_object == null:
			temp_object = object.instantiate()
			if basement:
				get_node("Tower/Basement_Floors/%s" % [curr_floor]).add_child(temp_object)
			elif not basement:
				get_node("Tower/%s" % [curr_floor]).add_child(temp_object)
			temp_object.visible = true
		
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
			
			#var current_floor_number = get_current_floor_num()
			# Adjust the offset because all 3d files are complicated and I don't understand them yet
			temp_object.global_position = intersection_point + Vector3(0, offset, 0)
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
				# See if there are any overlaps
				# and check it cannot be placed on the wrong floors
				# if either are wrong then make the material red
				var object_camera_difference_abs: float = absf(temp_object.global_position.y - camera.global_position.y)
				if overlaps.size() > 0 or (object_camera_difference_abs < 1) or (object_camera_difference_abs > 2):
					#print(temp_object.global_position.y, " ", camera.position.y)
					mesh_instance.set_surface_override_material(0, red_overlay)
					# Allow cancelling here
					if Input.is_action_just_pressed("cancel"):
						# make sure temp_object is null 
						# otherwise it will be deleted when the next initiatisation is meant to occur
						cancel_build(temp_object, object_name, mesh_instance, building_object)
						temp_object = null
				# If no overlaps then we are good to go
				else:
					mesh_instance.set_surface_override_material(0, green_overlay)
					if Input.is_action_just_pressed("left_click"):
						# Name the object
						temp_object.name = "%s" % [object_name]
						# slightly lower the position to compensate for the slight lift
						temp_object.position -= Vector3(0, 0.02, 0)
						# Change the collision layer back to 1
						temp_object.get_node("%s" % [object_name]).collision_layer = 1
						# Reset it back to default textures
						mesh_instance.set_surface_override_material(0, null)
						# This object now no longer exists as a variable
						#print(temp_object.get_groups())
						temp_object = null
						# Stop building the current object
						building_object.value = false
						# Unlock the camera
						camera.is_movement_locked = false
						# Reduce Gold amount by cost
						gold -= build_cost.cost
						# update the cost of the object to be back to default
						# This is for when the object was 'built' by moving and was free
						var cost_data = building_items_costs.get(object_name, {})
						cost_data['cost'] = original_building_items_cost[object_name]
						building_items_costs[object_name] = cost_data
						# Show the shop again and change the gold amount
						UI.toggle_shop()
						UI.update_gold_count()
						# Return mouse cursor to default
						change_mouse_cursor_image(cursor_default)

					# Cancel placement
					if Input.is_action_just_pressed("cancel"):
						# cancel the build
						cancel_build(temp_object, object_name, mesh_instance, building_object)
						# make sure temp_object is null 
						# otherwise it will be deleted when the next initiatisation is meant to occur
						temp_object = null

# Triggered if building/moving is cancelled
func cancel_build(temp_object, object_name, mesh_instance, building_object):
	if moving_object.value == true:
		print("Triggered")
		# Restore it to its original coordinates and rotation
		temp_object.global_position.x = moving_object_original_position.x
		temp_object.global_position.y = moving_object_original_position.y
		temp_object.global_position.z = moving_object_original_position.z
		temp_object.rotation.x = moving_object_original_rotation.x
		temp_object.rotation.y = moving_object_original_rotation.y
		temp_object.rotation.z = moving_object_original_rotation.z
		# Name the object
		temp_object.name = "%s" % [object_name]
		# Change the collision layer back to 1
		temp_object.get_node("%s" % [object_name]).collision_layer = 1
		# Reset it back to default textures
		mesh_instance.set_surface_override_material(0, null)
		# This object now no longer exists as a variable
		#print(temp_object.get_groups())
		temp_object = null
		# Stop building the current object
		building_object.value = false
		# Unlock the camera
		camera.is_movement_locked = false
		# Turn off moving object mode
		moving_object.value = false
		# re-open the shop the shop
		UI.toggle_shop()
		# Mouse cursor back to default
		change_mouse_cursor_image(cursor_default)
	else:
		# delete object
		temp_object.queue_free()
		temp_object = null
		# stop building
		building_object.value = false
		# stop locking camera
		camera.is_movement_locked = false
		# re-open the shop the shop
		UI.toggle_shop()
		# mouse cursor back to default
		change_mouse_cursor_image(cursor_default)


# Function to move objects on a floor
func move(ray_result : Dictionary, moving_object : Dictionary, delta : float) -> void:
	camera.is_movement_locked = true
	if ray_result.size() > 0:
		# get the current floor, used for collisions and naming
		var curr_floor = get_current_floor()
		# left_click to select an object
		if Input.is_action_just_pressed("left_click"):
			selected_object = select_object(ray_result)
			# Retrieve the name of the object selected
			if selected_object != null:
				var object_name = String(selected_object.name)
				# Check the objects groups to see if it should be moved
				var object_groups = selected_object.get_groups()
				for group in object_groups:
					if group == "Object_Movable":
						# Change mouse cursor to show what is happening
						change_mouse_cursor_image(cursor_move, 3)
						# Track its original coordinates
						moving_object_original_position.x = selected_object.global_position.x
						moving_object_original_position.y = selected_object.global_position.y
						moving_object_original_position.z = selected_object.global_position.z
						moving_object_original_rotation.x = selected_object.rotation.x
						moving_object_original_rotation.y = selected_object.rotation.y
						moving_object_original_rotation.z = selected_object.rotation.z
						# If it can be moved delete it
						selected_object.queue_free()
						# And rebuild it as if the build button had been pressed
						building_current_item[object_name].value = true
						# However change the cost of building the item to 0
						var cost_data = building_items_costs.get(object_name, {})
						cost_data['cost'] = 0
						# Update that cost
						building_items_costs[object_name] = cost_data
		# If tab is pressed, cancel the operation
		elif Input.is_action_just_pressed("cancel"):
			selected_object = null
			moving_object.value = false
			change_mouse_cursor_image(cursor_default)

# Selects an object and returns it
func select_object(ray_result : Dictionary):
	var collider = ray_result.get("collider")
	if collider and collider is Node3D:
		selected_object = collider
		return selected_object
	else:
		print("Object not selectable")
		return null

# Function to check whether the floor is the current floor
func is_floor(body: Node3D, current_floor) -> bool:
	#print(body.name, current_floor)
	if body.name == current_floor:
		return true
	else:
		return false

# Add a new floor when the top floor upgrade is pressed
func _on_floor_top_add_floor_pressed() -> void:
	create_new_top_floor()
	
func create_new_top_floor() -> void:
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
	camera.get_camera_clamp_values()

# get the floor count, returned as an int
func get_floor_count() -> int:
	number_of_floors = get_tree().get_first_node_in_group("Tower").get_child_count() - 1
	print(number_of_floors)
	return number_of_floors

# get the current amount of basement floors as an int
func get_basement_floor_count() -> int:
	number_of_basement_floors = get_tree().get_first_node_in_group("Tower_Basement").get_child_count()
	print(number_of_basement_floors)
	return number_of_basement_floors

# get the name of the current floor as a string
func get_current_floor() -> String:
	var current_floor_name = get_node("UI/Floor_Label").text
	return current_floor_name


# returns the current floor number as an int
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
	change_mouse_cursor_image(cursor_build)

# for when the button to buy a furnace has been pressed
func _on_floor_add_furnace_pressed() -> void:
	building_furnace.value = true
	change_mouse_cursor_image(cursor_build)


# For when the move button is pressed
func _on_move_objects_pressed() -> void:
	moving_object.value = true


func _on_floor_bottom_add_floor_pressed() -> void:
	create_new_basement_floor()


func create_new_basement_floor() -> void:
	var new_floor = blank_floor.instantiate()
	# make it a child of the Basement floor node
	var basement_tower = tower.get_node("Basement_Floors")
	basement_tower.add_child(new_floor,0, 0)
	# get a new number of floors
	number_of_basement_floors = get_basement_floor_count()
	#prints(basement_tower, number_of_basement_floors)
	# move the floor to the penultimate place in the list
	# otherwise the for loop for naming and the shop doesn't work
	basement_tower.move_child(new_floor, number_of_basement_floors - 1)
	# give the node a name
	new_floor.name = "Floor_-%d" % [number_of_basement_floors]
	#print(new_floor.name)
	# give it a position
	if basement_tower.get_child_count() == 1:
		print("Triggered child_count == 1")
		new_floor.global_position = tower.get_node("Floor_0").global_position - Vector3(0, 3.9, 0)
	elif basement_tower.get_child_count() > 1:
		print("Triggered child_count > 1")
		var basement_floors : Array = basement_tower.get_children()
		var lowest_floor = basement_floors[-2]
		prints(lowest_floor.name, lowest_floor.global_position)
		new_floor.global_position = lowest_floor.global_position - Vector3(0, 3.9, 0)
		print(new_floor.global_position)
	# update the UI
	UI.tower_basement_segments = basement_tower.get_children()
	UI.check_floor(camera.position)
	# update the camera information for clamping
	camera.get_camera_clamp_values()
