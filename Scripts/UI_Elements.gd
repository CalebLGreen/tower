extends Control

@onready var camera : Camera3D = get_node("../Camera3D")
@onready var tower_segments : Array = get_node("../Tower").get_children()
@onready var label : Label = get_node("Label")
@onready var shop_panel : Panel = get_node("ShopPanel")

var camera_is_moving_up : bool = false
var camera_is_moving_down : bool = false


func _ready():
	shop_panel.hide()
	check_floor(camera.position)


func _process(delta: float) -> void:
	var camera_pos : Vector3 = camera.position
	
	if Input.is_action_just_pressed("pan_up"):
		camera_is_moving_up = true
	if Input.is_action_just_pressed("pan_down"):
		camera_is_moving_down = true
	
	if camera_is_moving_up:
		if camera.is_moving_up == false:
			check_floor(camera_pos)
			camera_is_moving_up = false
	
	if camera_is_moving_down:
		if camera.is_moving_down == false:
			check_floor(camera_pos)
			camera_is_moving_down = false
			
	if Input.is_action_just_pressed("open_shop"):
		if shop_panel.visible:
			shop_panel.hide()
			#print("HIDE")
		else:
			shop_panel.show()
			#print("SHOW")


func check_floor(camera_pos : Vector3):
	var y_pos : float = camera_pos.y
	for i in tower_segments:
		if i is StaticBody3D:
			#print(i)
			if y_pos >= i.position.y:
				label.set_text(i.name) 
				update_shop(i)


func update_shop(floor):
	#print("Updating Shop")
	for i in get_node("ShopPanel/VBoxContainer").get_children():
		i.hide()
	if floor.name == "Floor_1":
		$ShopPanel/VBoxContainer/Floor_One_Table.show()
	elif floor.name == "Floor_2":
		$ShopPanel/VBoxContainer/Floor_Two_Table.show()
	elif floor.name == "Floor_TOP":
		$ShopPanel/VBoxContainer/Floor_Top_Add_Floor.show()
