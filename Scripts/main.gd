extends Node3D

@onready var camera : Camera3D = get_node("Camera3D")
@onready var UI : Control = get_node("UI")
@onready var floor : PackedScene = preload("res://Scenes/floor_zero.tscn")
@onready var tower = get_node("Tower")
@onready var top_floor = get_node("Tower/Floor_TOP")
@onready var number_of_floors : int
@onready var blank_floor : PackedScene = preload("res://Scenes/floor_blank.tscn")
var in_build_menu : bool = false

# Make it such that only Floor 0 and Floor Top exist at first

func _ready() -> void:
	camera.position = Vector3(8,1,0)
	get_floor_count()


func _process(delta: float) -> void:
	if UI.shop_panel.visible:
		in_build_menu = true
	else:
		in_build_menu = false
	print(in_build_menu)
	handle_mouse_controls()
	
	
	
func handle_mouse_controls() -> void:
	var space_state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	
	var origin : Vector3 = camera.project_ray_origin(mouse_pos)
	var end : Vector3 = origin + camera.project_ray_normal(mouse_pos)*100
	var ray : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	ray.collide_with_bodies = true
	
	var ray_result : Dictionary = space_state.intersect_ray(ray)
	# Make a ray cast for adding items to shops

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


func _on_floor_one_table_pressed() -> void:
	pass # Replace with function body.
