class_name NeuralNetwork
extends RefCounted

var layer_sizes: Array[int]
var weights: Array[Matrix]
var biases: Array[Matrix]

func _init(sizes: Array[int]):
	layer_sizes = sizes
	weights = []
	biases = []
	
	# initialize weight and bias arrays for each layer
	for layer in range(sizes.size() - 1):
		# Weights: rows = next_layer, cols = prev_layer
		var w = Matrix.random(sizes[layer + 1], sizes[layer])
		weights.append(w)
		
		# Biases: rows = next_layer, cols = 1
		var b = Matrix.random(sizes[layer + 1], 1)
		biases.append(b)

func forward_all(input_array: Array) -> Array:
	var activations = []
	
	# Input Layer
	var current = Matrix.from_array(input_array.size(), 1, input_array)
	activations.append(Matrix.to_array(current))
	
	for i in range(weights.size()):
		var w = weights[i]
		var b = biases[i]
		
		# Z = W * X + B
		var z = Matrix.multiply(w, current)
		z = z.bias(b)
		
		# Activate
		if i == weights.size() - 1:
			current = z.map(tanh)
		else:
			current = z.map(Matrix.sigmoid)
			
		activations.append(Matrix.to_array(current))
			
	return activations

# Metadata
var generation_number: int = 1
var child_number: int = 0
var best_time: float = 0.0

# Mutate function for Neuroevolution/Genetic Algorithm
func mutate(rate: float, magnitude: float):
	for w in weights:
		for i in range(w.data.size()):
			if randf() < rate:
				w.data[i] += randf_range(-magnitude, magnitude)
	for b in biases:
		for i in range(b.data.size()):
			if randf() < rate:
				b.data[i] += randf_range(-magnitude, magnitude)

func copy() -> NeuralNetwork:
	var nn = NeuralNetwork.new(layer_sizes)
	nn.generation_number = generation_number
	nn.child_number = child_number
	nn.best_time = best_time
	
	for i in range(weights.size()):
		nn.weights[i] = Matrix.from_array(
			weights[i].rows,
			weights[i].cols,
			weights[i].data.duplicate()
		)
		nn.biases[i] = Matrix.from_array(
			biases[i].rows,
			biases[i].cols,
			biases[i].data.duplicate()
		)
	return nn

func save(path: String):
	var data = {
		"sizes": layer_sizes,
		"weights": [],
		"biases": [],
		"generation_number": generation_number,
		"child_number": child_number,
		"best_time": best_time
	}
	for w in weights:
		data["weights"].append(w.data)
	for b in biases:
		data["biases"].append(b.data)
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

static func load_network(path: String) -> NeuralNetwork:
	if not FileAccess.file_exists(path):
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) != OK:
		return null
		
	var data = json.data
	# Safely cast instructions for arrays of ints? Godot JSON parses to floats often
	var sizes: Array[int] = []
	for s in data["sizes"]:
		sizes.append(int(s))
		
	var nn = NeuralNetwork.new(sizes)
	
	if "generation_number" in data:
		nn.generation_number = int(data["generation_number"])
	if "child_number" in data:
		nn.child_number = int(data["child_number"])
	if "best_time" in data:
		nn.best_time = float(data["best_time"])
	
	for i in range(nn.weights.size()):
		var w_data = data["weights"][i]
		for j in range(min(nn.weights[i].data.size(), w_data.size())):
			nn.weights[i].data[j] = float(w_data[j])
			
	for i in range(nn.biases.size()):
		var b_data = data["biases"][i]
		for j in range(min(nn.biases[i].data.size(), b_data.size())):
			nn.biases[i].data[j] = float(b_data[j])
		
	return nn
