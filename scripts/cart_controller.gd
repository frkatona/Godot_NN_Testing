extends RigidBody2D

@export var speed: float = 2000.0
@export var ai_controlled: bool = false
@export var ai_input: float = 0.0 # -1 to 1

# Input state for visualization
var pressing_left = false
var pressing_right = false

func _physics_process(delta):
	pressing_left = false
	pressing_right = false
	
	var force = Vector2.ZERO
	if ai_controlled:
		if ai_input < -0.3:
			force.x = -speed
			pressing_left = true
		elif ai_input > 0.3:
			force.x = speed
			pressing_right = true
	else:
		if Input.is_action_pressed("ui_left"):
			force.x = -speed
			pressing_left = true
		if Input.is_action_pressed("ui_right"):
			force.x = speed
			pressing_right = true
	
	apply_force(force)

func reset_state():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	position.x = 0 # Center (assuming parent coordinates)
	rotation = 0.0
