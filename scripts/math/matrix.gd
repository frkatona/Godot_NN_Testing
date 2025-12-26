class_name Matrix
extends RefCounted

var rows: int
var cols: int
var data: Array[float]

func _init(p_rows: int, p_cols: int, fill: float = 0.0):
	rows = p_rows
	cols = p_cols
	data = []
	data.resize(rows * cols)
	data.fill(fill)

func set_val(r: int, c: int, val: float):
	data[r * cols + c] = val

func get_val(r: int, c: int) -> float:
	return data[r * cols + c]

static func random(p_rows: int, p_cols: int) -> Matrix:
	var m = Matrix.new(p_rows, p_cols)
	for i in range(m.data.size()):
		m.data[i] = randf_range(-1.0, 1.0)
	return m

static func dot(a: Matrix, b: Matrix) -> Matrix:
	if a.cols != b.rows:
		push_error("Matrix dimension mismatch for dot product")
		return null
	var result = Matrix.new(a.rows, b.cols)
	for r in range(a.rows):
		for c in range(b.cols):
			var sum = 0.0
			for k in range(a.cols):
				sum += a.get_val(r, k) * b.get_val(k, c)
			result.set_val(r, c, sum)
	return result

func add(other: Matrix) -> Matrix:
	if rows != other.rows or cols != other.cols:
		push_error("Matrix dimension mismatch for add")
		return null
	var result = Matrix.new(rows, cols)
	for i in range(data.size()):
		result.data[i] = data[i] + other.data[i]
	return result

func map(func_ref: Callable) -> Matrix:
	var result = Matrix.new(rows, cols)
	for i in range(data.size()):
		result.data[i] = func_ref.call(data[i])
	return result

func transpose() -> Matrix:
	var result = Matrix.new(cols, rows)
	for r in range(rows):
		for c in range(cols):
			result.set_val(c, r, get_val(r, c))
	return result

# Activation functions
static func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))

static func d_sigmoid(x: float) -> float:
	var s = sigmoid(x)
	return s * (1.0 - s)

static func relu(x: float) -> float:
	return max(0.0, x)

static func d_relu(x: float) -> float:
	return 1.0 if x > 0.0 else 0.0

static func tanh_custom(x: float) -> float:
	return tanh(x)

static func to_array(m: Matrix) -> Array:
	return m.data.duplicate()

static func from_array(p_rows: int, p_cols: int, arr: Array) -> Matrix:
	var m = Matrix.new(p_rows, p_cols)
	for i in range(min(m.data.size(), arr.size())):
		m.data[i] = float(arr[i])
	return m
