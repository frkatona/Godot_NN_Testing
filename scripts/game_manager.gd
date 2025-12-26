extends Node

@onready var cart = $"../Cart"
@onready var pole = $"../Pole"
@onready var label_time = $"../CanvasLayer/UI/LabelTime"
@onready var label_highscore = $"../CanvasLayer/UI/LabelHighScore"
# @onready var ai_agent = $"../AIAgent" # Will be added later

var time_elapsed: float = 0.0
var high_score: float = 0.0
var is_game_over: bool = false
var max_angle: float = 60.0 # degrees

var wind_noise: FastNoiseLite
var wind_strength: float = 300.0

func _ready():
	wind_noise = FastNoiseLite.new()
	wind_noise.seed = randi()
	wind_noise.frequency = 0.5
	wind_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	reset_game()

func _physics_process(delta):
	if is_game_over:
		return
		
	# Apply Wind
	# Use time_elapsed for continuity, but maybe seed offset
	var noise_val = wind_noise.get_noise_1d(time_elapsed * 10.0)
	var force_x = noise_val * wind_strength
	
	# Apply to pole center of mass (effectively)
	pole.apply_force(Vector2(force_x, 0))

func _process(delta):
	if is_game_over:
		if Input.is_action_just_pressed("ui_accept"):
			reset_game()
		return

	time_elapsed += delta
	label_time.text = "Time: %.2f" % time_elapsed
	
	check_game_over()

func check_game_over():
	if time_elapsed < 0.2:
		return
		
	# Check pole angle
	var angle_deg = abs(rad_to_deg(pole.rotation))
	# Check cart bounds (simple checks)
	var cart_x = cart.position.x
	
	if angle_deg > max_angle or abs(cart_x) > 600: # Assuming 1280 screen width, 0 is center
		game_over()

func game_over():
	is_game_over = true
	if time_elapsed > high_score:
		high_score = time_elapsed
		label_highscore.text = "High Score: %.2f" % high_score
	
	# For AI training, we will need to hook here to auto-restart
	
func reset_game():
	is_game_over = false
	time_elapsed = 0.0
	
	# Reset Cart (Force Transform)
	force_reset_body(cart, Vector2(0, 0), 0.0)
	
	# Reset Pole (Force Transform)
	# Position relative to cart (0, -60)
	var tilt = randf_range(-0.05, 0.05)
	force_reset_body(pole, Vector2(0, -60), tilt)
	
	# Reseed wind slightly or just offset time? 
	# Time resets to 0, so we should change seed or offset to avoid identical wind patterns
	if wind_noise:
		wind_noise.seed = randi()

func force_reset_body(body: RigidBody2D, pos: Vector2, rot: float):
	PhysicsServer2D.body_set_state(
		body.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D(rot, pos)
	)
	PhysicsServer2D.body_set_state(
		body.get_rid(),
		PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY,
		Vector2.ZERO
	)
	PhysicsServer2D.body_set_state(
		body.get_rid(),
		PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY,
		0.0
	)
