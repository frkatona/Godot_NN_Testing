class_name WindVisualizer
extends Node2D

var wind_force: float = 0.0
var particles: CPUParticles2D

func _ready():
	# Setup Particles
	particles = CPUParticles2D.new()
	add_child(particles)
	particles.amount = 50
	particles.lifetime = 3.0
	particles.preprocess = 5.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(10, 400) # Vertical line source covering height
	particles.spread = 5.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.7, 0.9, 1.0, 0.4)
	
	# Start
	particles.emitting = true

func update_wind(force: float):
	wind_force = force
	queue_redraw()
	
	# Update Particles
	# Force typically ranges 0-300+
	var speed = abs(force)
	var dir = 1 if force >= 0 else -1
	
	# Update direction and speed
	particles.direction = Vector2(dir, 0)
	particles.initial_velocity_min = speed * 8.0
	particles.initial_velocity_max = speed * 12.0
	
	# Position emitter
	# Assuming 0,0 is center of screen. Wind from left spawns at left edge.
	if dir > 0:
		particles.position = Vector2(-700, 0)
	else:
		particles.position = Vector2(700, 0)

func _draw():
	# Draw Arrow near top center to indicate wind
	var start_pos = Vector2(0, -300)
	var length = wind_force * 5.0 # Scale down for visuals
	var end_pos = start_pos + Vector2(length, 0)
	var color = Color(0.4, 0.8, 1.0, 0.8)
	
	draw_line(start_pos, end_pos, color, 4.0)
	
	# Draw Arrow Head
	if abs(length) > 10:
		var dir = Vector2(sign(length), 0)
		var arrow_size = 15.0
		var p1 = end_pos - dir * arrow_size + dir.rotated(PI / 2) * (arrow_size * 0.5)
		var p2 = end_pos - dir * arrow_size + dir.rotated(-PI / 2) * (arrow_size * 0.5)
		var points = PackedVector2Array([end_pos, p1, p2])
		draw_colored_polygon(points, color)
