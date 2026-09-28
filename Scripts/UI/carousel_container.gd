extends CenterContainer

#How fast the user has to swipe to make the change happen
@export var swipe_sens : float = 200

#The current enabled child
var curr_index = 0

#Only allow one swipe per finger press
var is_finger_pressed : bool = false
var has_already_swiped:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Turn off all the children except for the first one
	for child in get_children():
		child.visible = false
	
	get_child(curr_index).visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	#Check if the input event was the screen being touched
	if(event is InputEventScreenTouch):
		if event.is_pressed():
			print("Pressed screen")
			is_finger_pressed = true
		else:
			print("Lifted finger")
			is_finger_pressed = false
			has_already_swiped = false

#Swiping logic
	if(event is InputEventScreenDrag and is_finger_pressed and !has_already_swiped):
		print(event.velocity)
		#Make sure the swipe was fast enough (prevent unintended swipes)
		if(event.screen_velocity.x < -swipe_sens): #Swiping left
			
			get_children()[curr_index].visible = false
			if(curr_index>0):
				curr_index-=1
			else:#Loop around if we've gotten to the left bound
				curr_index = get_child_count()-1
			get_child(curr_index).visible = true
			has_already_swiped = true
			
		elif(event.screen_velocity.x >swipe_sens): #Swipe Right
			get_children()[curr_index].visible = false
			if(curr_index<get_child_count()-1):
				curr_index+=1
			else:
				curr_index = 0
			get_child(curr_index).visible = true
			has_already_swiped = true
	pass
