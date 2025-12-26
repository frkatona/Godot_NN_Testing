extends Control

@onready var label_left = $Controls/LeftKey
@onready var label_right = $Controls/RightKey
@onready var cart = $"../../Cart"

func _process(delta):
	# Reset colors
	label_left.modulate = Color(1, 1, 1, 0.3)
	label_right.modulate = Color(1, 1, 1, 0.3)
	
	if cart.pressing_left:
		label_left.modulate = Color(1, 1, 0, 1) # Yellow
	
	if cart.pressing_right:
		label_right.modulate = Color(1, 1, 0, 1) # Yellow
