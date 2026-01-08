extends RigidBody2D

@export var speed: float = 2000.0
@export var ai_controlled: bool = false
@export var ai_input: float = 0.0 # -1 to 1

var sfx_left: AudioStreamPlayer
var sfx_right: AudioStreamPlayer

# Input state for visualization
var pressing_left = false
var pressing_right = false
var last_pressing_left = false
var last_pressing_right = false

func _ready():
	sfx_left = AudioStreamPlayer.new()
	sfx_left.stream = preload("res://assets/sfx/left.mp3")
	sfx_left.volume_db = -30.0
	add_child(sfx_left)
	
	sfx_right = AudioStreamPlayer.new()
	sfx_right.stream = preload("res://assets/sfx/right.mp3")
	sfx_right.volume_db = -30.0
	add_child(sfx_right)

func _physics_process(delta):
	last_pressing_left = pressing_left
	last_pressing_right = pressing_right
	
	pressing_left = false
	pressing_right = false
	
	var force = Vector2.ZERO
	if ai_controlled:
		if ai_input < -0.3:
			force.x = - speed
			pressing_left = true
		elif ai_input > 0.3:
			force.x = speed
			pressing_right = true
	else:
		if Input.is_action_pressed("ui_left"):
			force.x = - speed
			pressing_left = true
		if Input.is_action_pressed("ui_right"):
			force.x = speed
			pressing_right = true
	
	# Audio Triggers (Rising Edge)
	if pressing_left and not last_pressing_left:
		sfx_left.play()
	if pressing_right and not last_pressing_right:
		sfx_right.play()
	
	apply_force(force)

func reset_state():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	position.x = 0 # Center (assuming parent coordinates)
	rotation = 0.0
	
	pressing_left = false
	pressing_right = false
	last_pressing_left = false
	last_pressing_right = false
