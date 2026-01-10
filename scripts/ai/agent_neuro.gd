extends Node

@onready var cart = $"../Cart"
@onready var pole = $"../Pole"
@onready var game_manager = $"../GameManager"
@onready var visualizer = $"../CanvasLayer/UI/NetworkVisualizer"

var best_network: NeuralNetwork
var current_network: NeuralNetwork

var best_fitness: float = 0.0
var generation: int = 1
var save_path = "user://best_ai_v2.json"
var enabled: bool = true
var mutation_magnitude: float = 0.4
var mutation_rate: float = 0.2
var chaos_mode: bool = false
var generation_child_count: int = 0


signal history_updated(history: Array[float], gen: int, child: int)
var fitness_history: Array[float] = []

func _ready():
	# Network Topology: 
	# Inputs: 4
	# [CartX, CartVelX, PoleAngle, PoleAngVel]
	# Hidden: 6
	# Output: 1 (Tanh: -1 Left, 1 Right)
	var topology: Array[int] = [4, 6, 1]
	
	var loaded = NeuralNetwork.load_network(save_path)
	if loaded:
		best_network = loaded
		generation = best_network.generation_number
		generation_child_count = best_network.child_number
		best_fitness = best_network.best_time
		
		# Sync to GameManager
		if game_manager:
			game_manager.high_score = best_fitness
			game_manager.update_stats(fitness_history, generation, generation_child_count)
			# Force label update for high score since it's only updated on game over usually
			game_manager.label_highscore.text = "High Score: %.2f" % best_fitness
			
		print("Loaded existing network")
	else:
		best_network = NeuralNetwork.new(topology)
		bias_network(best_network)
		
	current_network = best_network.copy()
	
	# Hook into game over
	get_tree().process_frame.connect(_on_process_frame)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		enabled = !enabled
		cart.ai_controlled = enabled
		print("AI Enabled: ", enabled)

func _on_process_frame():
	if not enabled:
		return
		
	if game_manager.is_game_over:
		return
		
	# Get Inputs
	# Normalize somewhat for better training
	var inputs = [
		clamp(cart.position.x / 600.0, -1.0, 1.0),
		clamp(cart.linear_velocity.x / 1000.0, -1.0, 1.0),
		clamp(pole.rotation / 1.0, -1.0, 1.0), # ~60 deg is 1.0
		clamp(pole.angular_velocity / 5.0, -1.0, 1.0)
	]
	
	# Forward
	var all_activations = current_network.forward_all(inputs)
	var output = all_activations.back() # Last layer is output
	var action_val = output[0] # -1 to 1
	
	# Apply to Cart
	cart.ai_controlled = true
	cart.ai_input = action_val
	
	# Update Vis
	if visualizer:
		visualizer.update_network(current_network, all_activations)

func _process(delta):
	if not enabled:
		return

	# janky network save when fitness exceeds best (each delta for 1 sec) just to prevent perfect solution from escaping save without forcing a reset
	if game_manager.time_elapsed > best_fitness + 10 and game_manager.time_elapsed < best_fitness + 11:
		best_fitness = game_manager.time_elapsed
		current_network.save(save_path)
		print("New Best! Saved.")
		
	# Check if game reset happened effectively
	if game_manager.is_game_over:
		# Training Step
		evaluate_fitness(game_manager.time_elapsed)
		game_manager.reset_game()

func evaluate_fitness(fitness: float):
	fitness_history.append(fitness)
	
	if fitness > best_fitness:
		best_fitness = fitness
		best_network = current_network.copy()
		
		# Metadata
		best_network.generation_number = generation
		best_network.child_number = generation_child_count
		best_network.best_time = best_fitness
		
		best_network.save(save_path)
		print("New Best! Saved.")
		generation += 1
		generation_child_count = 0
	else:
		generation_child_count += 1
		
	history_updated.emit(fitness_history, generation, generation_child_count)
	game_manager.update_stats(fitness_history, generation, generation_child_count)
	
	print("Gen ", generation, " Child ", generation_child_count, " Fitness: ", fitness, " Best: ", best_fitness)
	
	# Prepare next agent: (1+1) ES strategy
	# Always mutate from BEST
	current_network = best_network.copy()
	
	var rate = mutation_rate
	var mag = mutation_magnitude
	
	if chaos_mode:
		rate = 0.8
		mag = 10.0
		
	current_network.mutate(rate, mag) # Rate, Magnitude

func bias_network(nn: NeuralNetwork):
	# Manually set strong weights for Angle -> Move relation
	# Input 2 (PoleAngle) -> Hidden 0 -> Output 0
	# Input->Hidden
	# Row 0 (Hidden node 0), Col 2 (Input node 2)
	nn.weights[0].set_val(0, 2, 5.0)
	nn.biases[0].set_val(0, 0, 0.0)
	
	# Hidden->Output
	# Row 0 (Output node 0), Col 0 (Hidden node 0)
	nn.weights[1].set_val(0, 0, 5.0)
	nn.biases[1].set_val(0, 0, 0.0)
	
	print("Network biased for initial association.")
