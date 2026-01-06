extends Node2D

var a: Vector3 = Vector3(1, 2, 3)
var b: Vector3 = Vector3(4, 5, 6)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("a: ", a)
	print("b: ", b)
	print("a + b: ", a + b)
	print("a dot b: ", a.dot(b))
	print("a cross b: ", a.cross(b))
	print("a length: ", a.length())
	print("b length: ", b.length())
	print("a normalized: ", a.normalized())
	print("b normalized: ", b.normalized())
