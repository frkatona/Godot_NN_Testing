extends Node

@onready var cart = $"../Cart"
@onready var pole = $"../Pole"
@onready var label_time = $"../CanvasLayer/UI/LabelTime"
@onready var label_highscore = $"../CanvasLayer/UI/LabelHighScore"
@onready var ai_agent = $"../AIAgent"

var time_elapsed: float = 0.0
var high_score: float = 0.0
var is_game_over: bool = false
var max_angle: float = 60.0 # degrees

const GraphScript = preload("res://scripts/ui/performance_graph.gd")
var stats_graph: Control
var label_gen: Label

var wind_noise: FastNoiseLite
var wind_strength: float = 1.0
var noise_freq: float = 0.03
var wind_vis: Node2D
var sfx_wind: AudioStreamPlayer
var sfx_fail: AudioStreamPlayer
var sfx_success: AudioStreamPlayer
const WindVisualizerScript = preload("res://scripts/visuals/wind_visualizer.gd")

func _ready():
	wind_noise = FastNoiseLite.new()
	wind_noise.seed = randi()
	wind_noise.frequency = 0.5
	wind_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	wind_vis = WindVisualizerScript.new()
	add_child(wind_vis)
	
	setup_audio()
	setup_ui()
	reset_game()

func setup_audio():
	# Wind
	sfx_wind = AudioStreamPlayer.new()
	var wind_stream = preload("res://assets/sfx/wind.wav")
	wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sfx_wind.stream = wind_stream
	sfx_wind.volume_db = -80.0
	add_child(sfx_wind)
	sfx_wind.bus = "Wind"
	sfx_wind.play()
	
	# Fail
	sfx_fail = AudioStreamPlayer.new()
	sfx_fail.stream = preload("res://assets/sfx/fail.mp3")
	sfx_fail.volume_db = -10.0
	add_child(sfx_fail)
	
	# Success
	sfx_success = AudioStreamPlayer.new()
	sfx_success.stream = preload("res://assets/sfx/success.mp3")
	sfx_success.volume_db = -20.0
	add_child(sfx_success)

func setup_ui():
	var ui_root = label_time.get_parent()
	
	# Menu Button
	var btn_menu = Button.new()
	btn_menu.text = "Menu"
	btn_menu.position = Vector2(20, 80)
	ui_root.add_child(btn_menu)
	
	# Create Gen Label
	label_gen = Label.new()
	label_gen.text = "Gen: 1"
	label_gen.position = Vector2(80, 85)
	ui_root.add_child(label_gen)
	
	# Create Graph
	stats_graph = GraphScript.new()
	stats_graph.position = Vector2(20, 120)
	ui_root.add_child(stats_graph)
	
	# Settings Container
	var settings_box = VBoxContainer.new()
	settings_box.position = Vector2(20, 230)
	settings_box.custom_minimum_size = Vector2(200, 0)
	ui_root.add_child(settings_box)
	
	var create_slider = func(label_text, min_v, max_v, step_v, default_v, callback):
		var l = Label.new()
		l.text = label_text % default_v
		settings_box.add_child(l)
		
		var slider = HSlider.new()
		slider.min_value = min_v
		slider.max_value = max_v
		slider.step = step_v
		slider.value = default_v
		slider.custom_minimum_size = Vector2(200, 20)
		settings_box.add_child(slider)
		
		slider.value_changed.connect(func(v):
			callback.call(v)
			l.text = label_text % v
		)
		return slider

	# 1. Master Volume
	var master_idx = AudioServer.get_bus_index("Master")
	var vol_db = AudioServer.get_bus_volume_db(master_idx)
	var vol_linear = db_to_linear(vol_db)
	
	create_slider.call("Master Vol: %.2f", 0.0, 1.0, 0.05, vol_linear, func(v):
		var db = linear_to_db(v) if v > 0.001 else -80.0
		AudioServer.set_bus_volume_db(master_idx, db)
	)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	settings_box.add_child(spacer1)

	# 2. Mutation Rate
	create_slider.call("Mut Rate: %.2f", 0.0, 1.0, 0.01, 0.2, func(v):
		if ai_agent: ai_agent.mutation_rate = v
	)
	
	# 3. Mutation Magnitude
	create_slider.call("Mut Mag: %.1f", 0.0, 20.0, 0.1, 0.4, func(v):
		if ai_agent: ai_agent.mutation_magnitude = v
	)
	
	# 4. Chaos Mode
	var chaos_check = CheckBox.new()
	chaos_check.text = "Chaos Mode"
	settings_box.add_child(chaos_check)
	chaos_check.toggled.connect(func(t):
		if ai_agent: ai_agent.chaos_mode = t
	)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	settings_box.add_child(spacer2)
	
	# 5. Wind Strength
	create_slider.call("Wind Str: %.1f", 0.0, 1000.0, 10.0, wind_strength, func(v):
		wind_strength = v
	)
	
	# 6. Wind Freq
	create_slider.call("Wind Freq: %.3f", 0.001, 0.1, 0.001, noise_freq, func(v):
		noise_freq = v
	)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	settings_box.add_child(spacer3)
	
	# 7. Manual Fail Button
	var fail_btn = Button.new()
	fail_btn.text = "Fail"
	settings_box.add_child(fail_btn)
	fail_btn.pressed.connect(func():
		game_over()
	)
	
	# Toggle Logic
	btn_menu.pressed.connect(func():
		var is_vis = not settings_box.visible
		settings_box.visible = is_vis
		if stats_graph: stats_graph.visible = is_vis
	)

func update_stats(history: Array, gen: int, child_count: int = 0):
	if label_gen:
		label_gen.text = "Gen: %d | Child: %d" % [gen, child_count]
	if stats_graph:
		stats_graph.update_data(history)

func _physics_process(delta):
	if is_game_over:
		return
		
	# Apply Wind
	# Use time_elapsed for continuity, but maybe seed offset
	var noise_val = wind_noise.get_noise_1d(time_elapsed * noise_freq)
	var force_x = noise_val * wind_strength
	
	if wind_vis:
		wind_vis.update_wind(force_x)
		
	# Update Wind Audio
	if sfx_wind:
		# Map force magnitude to volume (max wind sound should trigger >=300)
		var wind_ratio = clamp(abs(force_x) / 300, 0.0, 1.0)
		# -40dB (quiet) to 0dB (loud). -80 is silent.
		# Let's try dynamic range: -60 minimum, up to 0 max
		var target_db = lerp(-60.0, -20.0, wind_ratio)
		if wind_ratio < 0.01:
			target_db = -80.0
		sfx_wind.volume_db = move_toward(sfx_wind.volume_db, target_db, delta * 30.0)

		# set the wind mixer bus panner to the opposite direction of wind force
		var bus_index = AudioServer.get_bus_index("Wind")
		var effect = AudioServer.get_bus_effect(bus_index, 0)
		effect.pan = sign(-force_x) * 0.75

	#) Apply to pole center of mass (effectively)
	pole.apply_force(Vector2(force_x, 0))

func _process(delta):
	if is_game_over:
		if Input.is_action_just_pressed("ui_accept"):
			reset_game()
		return

	time_elapsed += delta
	label_time.text = "Time: %.2f" % time_elapsed
	
	# Early Reset if we beat the high score by 10 minutes
	if time_elapsed > high_score + 600.0 and high_score > 0:
		game_over()
		
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
	var current_success = false
	if time_elapsed > high_score:
		high_score = time_elapsed
		label_highscore.text = "High Score: %.2f" % high_score
		current_success = true
	
	if current_success:
		if sfx_success: sfx_success.play()
	else:
		if sfx_fail: sfx_fail.play()
	
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
