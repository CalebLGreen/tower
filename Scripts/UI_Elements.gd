extends Control

# other nodes for use
@onready var camera : Camera3D = get_node("../Camera3D")
@onready var tower_segments : Array = get_node("../Tower").get_children()
@onready var floor_label : Label = get_node("Floor_Label")
@onready var gold_label : Label = get_node("Gold_Label")
@onready var shop_panel : Panel = get_node("ShopPanel")
@onready var Main : Node3D = get_parent()

# detect camera motion booleans for the shop to update
var camera_is_moving_up : bool = false
var camera_is_moving_down : bool = false


# hide the shop at the start and check the floor for the label in the top left
func _ready():
	shop_panel.hide()
	check_floor(camera.position)
	update_gold_count()


func _process(_delta: float) -> void:
	# define the camera position for easier use
	var camera_pos : Vector3 = camera.position

	# is the camera now panning up or down? set the bool to true or false
	if Input.is_action_just_pressed("pan_up") and not camera.is_movement_locked:
		camera_is_moving_up = true
	if Input.is_action_just_pressed("pan_down") and not camera.is_movement_locked:
		camera_is_moving_down = true
	
	# if the camera has been defined as moving? then update after its finished
	if camera_is_moving_up:
		if camera.is_moving_up == false:
			check_floor(camera_pos)
			camera_is_moving_up = false
	
	if camera_is_moving_down:
		if camera.is_moving_down == false:
			check_floor(camera_pos)
			camera_is_moving_down = false
	
	# Open the shop on command
	if Input.is_action_just_pressed("open_shop"):
		toggle_shop()
	
# Update Gold
func update_gold_count() -> void:
	gold_label.set_text("Gold: %d" % [Main.gold])

func toggle_shop():
	if shop_panel.visible:
		shop_panel.hide()
		#print("HIDE")
	else:
		shop_panel.show()
		#print("SHOW")


# changes the label to match the current floor and refreshes the shop
func check_floor(camera_pos : Vector3):
	var y_pos : float = camera_pos.y
	for i in tower_segments:
		if i is Node3D:
			#print(i)
			if y_pos >= i.position.y:
				floor_label.set_text(i.name) 
				update_shop(i)


# update the shop after checking the floor
# this is where the shop menu is controlled from
func update_shop(curr_floor):
	#print("Updating Shop")
	for i in get_node("ShopPanel/VBoxContainer").get_children():
		i.hide()
	if curr_floor.name == "Floor_3":
		$ShopPanel/VBoxContainer/Floor_Add_Furnace.show()
	elif curr_floor.name == "Floor_1":
		$ShopPanel/VBoxContainer/Floor_Add_Table.show()
	elif curr_floor.name == "Floor_2":
		$ShopPanel/VBoxContainer/Floor_Add_Table.show()
	elif curr_floor.name == "Floor_TOP":
		$ShopPanel/VBoxContainer/Floor_Top_Add_Floor.show()
