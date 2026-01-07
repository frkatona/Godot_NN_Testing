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
var mutation_power: float = 0.4

signal history_updated(history: Array[float], gen: int)
var fitness_history: Array[float] = []

func _ready():
	# Network Topology: 
	# Inputs: 4
	# [CartX, CartVelX, PoleAngle, PoleAngVel]
	# Hidden: 6
	# Output: 1 (Tanh: -1 Left, 1 Right)
	var topology: Array[int] = [4, 6, 1]
	
	# Try load
	var loaded = NeuralNetwork.load_network(save_path)
	if loaded:
		best_network = loaded
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

	# Check if game reset happened effectively
	if game_manager.is_game_over:
		# Training Step
		evaluate_fitness(game_manager.time_elapsed)
		game_manager.reset_game()

func evaluate_fitness(fitness: float):
	fitness_history.append(fitness)
	history_updated.emit(fitness_history, generation)
	game_manager.update_stats(fitness_history, generation)
	
	print("Gen ", generation, " Fitness: ", fitness, " Best: ", best_fitness)
	
	if fitness > best_fitness:
		best_fitness = fitness
		best_network = current_network.copy()
		best_network.save(save_path)
		print("New Best! Saved.")
	
	# Prepare next agent: (1+1) ES strategy
	# Always mutate from BEST
	current_network = best_network.copy()
	current_network.mutate(0.2, mutation_power) # Rate, Magnitude
	
	generation += 1

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
