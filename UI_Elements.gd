extends Control

@onready var camera : Camera3D = get_node("../Camera3D")
@onready var tower_segments : Array = get_node("../Tower").get_children()
@onready var label : Label = get_node("Label")
@onready var shop_panel : Panel = get_node("ShopPanel")


func _ready():
	shop_panel.hide()
	check_floor(camera.position)


func _process(delta: float) -> void:
	var camera_pos : Vector3 = camera.position
	
	if Input.is_action_just_pressed("pan_up") or Input.is_action_just_pressed("pan_down"):
		check_floor(camera_pos)
			
	if Input.is_action_just_pressed("open_shop"):
		if shop_panel.visible:
			shop_panel.hide()
			print("HIDE")
		else:
			shop_panel.show()
			print("SHOW")


func _on_table_button_pressed() -> void:
	pass # Replace with function body.


func check_floor(camera_pos : Vector3):
	var y_pos : float = camera_pos.y
	for i in tower_segments:
		print(i)
		if y_pos >= i.position.y:
			label.set_text(i.name) 
			update_shop(i)


func update_shop(floor):
	print("Updating Shop")
	for i in get_node("ShopPanel/VBoxContainer").get_children():
		i.hide()
	if floor.name == "Floor_ONE":
		$ShopPanel/VBoxContainer/Floor_One_Table.show()
	elif floor.name == "Floor_TWO":
		$ShopPanel/VBoxContainer/Floor_Two_Table.show()
