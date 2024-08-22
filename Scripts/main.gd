extends Node3D

@onready var camera : Camera3D = get_node("Camera3D")
@onready var UI : Control = get_node("UI")
@onready var floor : PackedScene = preload("res://Scenes/floor_zero.tscn")
@onready var tower = get_node("Tower")
@onready var top_floor = get_node("Tower/Floor_TOP")
@onready var number_of_floors : int
@onready var blank_floor : PackedScene = preload("res://Scenes/floor_blank.tscn")
@onready var table : PackedScene = preload("res://Scenes/table.tscn")


var ghost_table = null


# Shop variables
var in_build_menu : bool = false
var building_table : bool = false

# Make it such that only Floor 0 and Floor Top exist at first

func _ready() -> void:
	camera.position = Vector3(8,1,0)
	get_floor_count()


func _process(delta: float) -> void:
	if UI.shop_panel.visible:
		in_build_menu = true
	else:
		in_build_menu = false
	#print(in_build_menu)
	handle_mouse_controls()
	#print(get_current_floor())
	
	
func handle_mouse_controls() -> void:
	var space_state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	
	var origin : Vector3 = camera.project_ray_origin(mouse_pos)
	var end : Vector3 = origin + camera.project_ray_normal(mouse_pos)*100
	var ray : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	ray.collide_with_bodies = true
	
	var ray_result : Dictionary = space_state.intersect_ray(ray)
	# Make a ray cast for adding items to shops
	if in_build_menu and building_table:
		#print("BUILDING")
		if ray_result.size() > 0:
			var curr_floor = get_current_floor()
			if ghost_table == null:
				ghost_table = table.instantiate()
				get_node("Tower/%s" % [curr_floor]).add_child(ghost_table)
				ghost_table.visible
			if ghost_table:
				var mesh_instance = ghost_table.get_node("Table/Table_Mesh")
				var intersection_point : Vector3 = ray_result.get("position")
				ghost_table.position = intersection_point + Vector3(0, -3.38, 0)
				
				# Get the area3d
				var area = ghost_table.get_node("Table/Table_Area")
				if area and area is Area3D:
					area.global_transform.origin = ghost_table.global_transform.origin
					
					# Check for overlaps
					var overlaps = area.get_overlapping_bodies()
					#print(overlaps)
					var valid_overlaps = []
					for body in overlaps:
						if not is_floor(body, curr_floor):
							valid_overlaps.append(body)
				
					if overlaps.size() > 1:
						#print("Cannot place table: overlap detected.")
						mesh_instance.set_surface_override_material(0, load("res://Models/red.tres"))
					else:
						mesh_instance.set_surface_override_material(0, load("res://Models/green.tres"))
						if Input.is_action_just_pressed("left_click"):
							ghost_table.visible
							ghost_table.position -= Vector3(0, 0.02, 0)
							mesh_instance.set_surface_override_material(0, null)
							ghost_table = null
							building_table = false


func is_floor(body: Node3D, current_floor) -> bool:
	if body.name == current_floor:
		return true
	else:
		return false


func _on_floor_top_add_floor_pressed() -> void:
	var new_floor = blank_floor.instantiate()
	tower.add_child(new_floor,0, 0)
	number_of_floors = get_floor_count()
	tower.move_child(new_floor, number_of_floors - 2)
	new_floor.name = "Floor_%d" % [number_of_floors-2]
	new_floor.position = top_floor.position
	top_floor.position.y += 3.9
	UI.tower_segments = tower.get_children()
	camera.get_floor_count()
	UI.check_floor(camera.position)

func get_floor_count() -> int:
	number_of_floors = get_tree().get_first_node_in_group("Tower").get_child_count()
	return number_of_floors


func get_current_floor() -> String:
	var current_floor_name = get_node("UI/Label").text
	return current_floor_name


func _on_floor_add_table_pressed() -> void:
	building_table = true
