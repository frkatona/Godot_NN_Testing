class_name PerformanceGraph
extends Control

var history: Array[float] = []
var max_points: int = 10
var graph_height: float = 100.0
var graph_width: float = 200.0

func _ready():
	custom_minimum_size = Vector2(graph_width, graph_height)

func update_data(full_history: Array[float]):
	history = full_history
	queue_redraw()

func _draw():
	# Background
	draw_rect(Rect2(0, 0, graph_width, graph_height), Color(0, 0, 0, 0.5))
	
	if history.is_empty():
		return
		
	# Calculate stats
	var total = 0.0
	for val in history:
		total += val
	var avg = total / history.size()
	
	# Determine scale
	# Find max value in recent history + average to scale graph nicely
	var relevant_subset = history.slice(-max_points)
	var max_val = avg * 1.5 # Ensure average is visible
	for val in relevant_subset:
		max_val = max(max_val, val)
	
	if max_val <= 0.0001: max_val = 1.0 # Avoid div by zero
	
	# Draw Average Line
	var avg_y = graph_height - (avg / max_val * graph_height)
	draw_line(Vector2(0, avg_y), Vector2(graph_width, avg_y), Color(0, 1, 0, 0.7), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(5, avg_y - 2), "Avg: %.1f" % avg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 0))

	# Draw Graph
	var points = PackedVector2Array()
	var step_x = graph_width / (max_points - 1)
	
	for i in range(relevant_subset.size()):
		var val = relevant_subset[i]
		var x = i * step_x
		# If fewer points than max, align to right? Or left?
		# Let's align to right if we have full set, or just fill from left
		if relevant_subset.size() < max_points:
			x = i * (graph_width / (relevant_subset.size() - 1 if relevant_subset.size() > 1 else 1))
			
		var y = graph_height - (val / max_val * graph_height)
		points.append(Vector2(x, y))
		
		# Draw point
		draw_circle(Vector2(x, y), 3.0, Color(0, 0.5, 1.0))
	
	if points.size() > 1:
		draw_polyline(points, Color(0, 0.5, 1.0), 2.0)
