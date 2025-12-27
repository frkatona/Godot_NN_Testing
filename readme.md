# Godot Neural Networking Playground

pole and cart simple feed-forward genetic network test

![pole demo](pole-demo.gif)

## Overview

### define matrices and their behavior (+ activation functions) in `scripts/math/matrix.gd`

```gdscript
func _init(p_rows: int, p_cols: int, fill: float = 0.0):
	rows = p_rows
	cols = p_cols
	data = []
	data.resize(rows * cols)
	data.fill(fill)

func random(p_rows: int, p_cols: int) -> Matrix

func dot(a: Matrix, b: Matrix) -> Matrix

func add(other: Matrix) -> Matrix

func map(func_ref: Callable) -> Matrix

func transpose() -> Matrix

func tanh_custom(x: float) -> float
```

### define network properties `scripts/ai/neural_network.gd`

```gdscript
func _init(sizes: Array[int]):
	layer_sizes = sizes
	weights = []
	biases = []

func forward(input_array: Array) -> Array

func mutate(rate: float, magnitude: float)

func copy() -> NeuralNetwork

func save(path: String)

func load_network(path: String) -> NeuralNetwork
```

### train agent `scripts/ai/agent_neuro.gd`

 - topology: 
  - 4 x inputs (cart position, cart velocity, pole angle, pole velocity)
  - 6 x hidden
  - 1 x output (tanh: -1 left, 1 right)
- algorithm: 1+1 Evolution Strategy
    - mutation rate: 0.2
    - mutation magnitude: 0.1

```gdscript
func _ready():
	var topology: Array[int] = [4, 6, 1]
    best_network = NeuralNetwork.load_network(save_path)
    current_network = best_network.copy()

var inputs_normalized = [
    clamp(cart.position.x / 600.0, -1.0, 1.0),
    clamp(cart.linear_velocity.x / 1000.0, -1.0, 1.0),
    clamp(pole.rotation / 1.0, -1.0, 1.0), # ~60 deg is 1.0
    clamp(pole.angular_velocity / 5.0, -1.0, 1.0)
]
	
var output = current_network.forward(inputs_normalized)
cart.ai_input = output[0] # -1 to 1

func evaluate_fitness(fitness: float):
	if fitness > best_fitness:
		best_fitness = fitness
		best_network = current_network.copy()
		best_network.save(save_path)
		print("New Best! Saved.")
	
	current_network = best_network.copy()
	current_network.mutate(0.2, 0.1) # Rate, Magnitude
	generation += 1

func _process(delta):
	if game_manager.is_game_over:
		evaluate_fitness(game_manager.time_elapsed)
		game_manager.reset_game()

```

### Cart Controller with `scripts/cart_controller.gd`

```gdscript
extends RigidBody2D

@export var speed: float = 2000.0

func _physics_process(delta):
    if ai_input < -0.3:
        force.x = -speed
    apply_force(force)
```

### Misc

#### `game_manager.gd`
 - Manage other scripts (update UI, handle game over, etc.)
 - Add noise to pole tilt force
    - very light, slow background noise to prevent the model from perfectly balancing the pole
    - used FastNoiseLite for coherence and randi() to seed it to prevent training from accomodating the noise
    - also uses `visuals/wind_visualizer.gd` to make a little particle effect and arrow to illustrate the effect of the noise

#### Network Topology Visualizer with `scripts/ai/network_visualizer.gd`
    - inputs and outputs are labeled
    - activation of each node is represented with color: black (0), green (+), and red (-)
    - weight magnitudes are represented with thickness and their sign is represented with color: green (+), red (-)
    - biases are excluded for simplicity (I'm sure there's a nice way people represent them somehow)

#### Arrows with `scripts/ui.gd`
 - the agent's input options (move left, move right) light up when the corresponding choice is selected

#### `scripts/ai/history_graph.gd`
 - graph shows the last 10 generations of fitness

## resources

 - [1+1 ES description](https://algorithmafternoon.com/strategies/one_plus_one_evolution_strategy/) on AlgorithmAfternoon
 - Unity official [ML-Agents repo](https://github.com/Unity-Technologies/ml-agents)

## don't worry about this section (gh md syntax playground)

I ain't making a dedicated repo for this this morning

### fun little syntax playground

```stl
solid cube_corner
  facet normal 0.0 -1.0 0.0
    outer loop
      vertex 0.0 0.0 0.0
      vertex 1.0 0.0 0.0
      vertex 0.0 0.0 1.0
    endloop
  endfacet
  facet normal 0.0 0.0 -1.0
    outer loop
      vertex 0.0 0.0 0.0
      vertex 0.0 1.0 0.0
      vertex 1.0 0.0 0.0
    endloop
  endfacet
  facet normal -1.0 0.0 0.0
    outer loop
      vertex 0.0 0.0 0.0
      vertex 0.0 0.0 1.0
      vertex 0.0 1.0 0.0
    endloop
  endfacet
  facet normal 0.577 0.577 0.577
    outer loop
      vertex 1.0 0.0 0.0
      vertex 0.0 1.0 0.0
      vertex 0.0 0.0 1.0
    endloop
  endfacet
endsolid
```

```mermaid
graph TD;
    A-->B;
    A-->C;
    B-->D;
    C-->D;
```

```geojson
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "properties": {
        "ID": 0
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
              [-90,35],
              [-90,30],
              [-85,30],
              [-85,35],
              [-90,35]
          ]
        ]
      }
    }
  ]
}
```