extends Control

var network: NeuralNetwork
var cached_inputs: Array
var cached_outputs: Array
var canvas_rect: Rect2

func update_network(net: NeuralNetwork, inputs: Array, outputs: Array):
	network = net
	cached_inputs = inputs
	cached_outputs = outputs
	queue_redraw()

func _draw():
	if not network:
		return
		
	# Draw settings
	var layer_gap = size.x / (network.layer_sizes.size() + 1)
	var node_gap = 30.0
	var radius = 8.0
	
	var layers = network.layer_sizes
	var node_positions = [] # Array of Arrays of Vector2
	
	# Calculate positions
	for i in range(layers.size()):
		var layer_count = layers[i]
		var l_positions = []
		var x = (i + 1) * layer_gap
		var start_y = (size.y - (layer_count * node_gap)) / 2.0
		
		for j in range(layer_count):
			var pos = Vector2(x, start_y + j * node_gap)
			l_positions.append(pos)
		node_positions.append(l_positions)
	
	# Draw Connections (Weights)
	for i in range(network.weights.size()):
		var w_matrix = network.weights[i]
		var current_layer_pos = node_positions[i]
		var next_layer_pos = node_positions[i + 1]
		
		for prev in range(w_matrix.cols):
			for next in range(w_matrix.rows):
				var weight = w_matrix.get_val(next, prev)
				var start = current_layer_pos[prev]
				var end = next_layer_pos[next]
				
				var color = Color.GREEN if weight > 0 else Color.RED
				color.a = clamp(abs(weight), 0.2, 1.0)
				var width = clamp(abs(weight) * 2.0, 1.0, 5.0)
				
				draw_line(start, end, color, width)

	# Draw Nodes
	for i in range(node_positions.size()):
		var layer_pos = node_positions[i]
		for j in range(layer_pos.size()):
			var pos = layer_pos[j]
			var val = 0.0
			
			# Try to visualize activation if possible?
			# For now just draw white circles, maybe fill based on input/output for first/last
			var color = Color.WHITE
			if i == 0 and j < cached_inputs.size():
				var inp = cached_inputs[j]
				if inp > 0: color = Color(0, inp, 0)
				else: color = Color(0, 0, -inp)
			elif i == node_positions.size() - 1 and j < cached_outputs.size():
				var outp = cached_outputs[j]
				if outp > 0: color = Color(0, outp, 0)
				else: color = Color(0, 0, -outp)
			
			draw_circle(pos, radius, Color.BLACK) # Outline
			draw_circle(pos, radius * 0.8, color)
			
			# Draw Labels
			var label = ""
			var label_pos = pos + Vector2(0, -15)
			if i == 0: # Input Layer
				match j:
					0: label = "CartX"
					1: label = "CartV"
					2: label = "PoleA"
					3: label = "PoleV"
			elif i == node_positions.size() - 1: # Output Layer
				match j:
					0: label = "Move"
					
			if label != "":
				draw_string(ThemeDB.fallback_font, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
