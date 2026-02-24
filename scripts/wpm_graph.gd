extends Control

var wpm_points: Array = []
var errors: Array = []

const MARGIN = 40.0
const LINE_COLOR = Color("#ebcb8b") # Yellow
const ERROR_COLOR = Color("#bf616a") # Red
const GRID_COLOR = Color("#3b4252")  # Dark Gray

func draw_session_graph(history: Array, error_list: Array):
	wpm_points = history
	errors = error_list
	queue_redraw()

func _draw():
	if wpm_points.size() < 2: return

	var w = size.x - (MARGIN * 2)
	var h = size.y - (MARGIN * 2)
	var max_wpm = wpm_points.max() + 20 # Add padding to top
	
	# 1. Draw Grid Lines (Horizontal)
	for i in range(5):
		var y_pos = size.y - MARGIN - (i * (h / 4.0))
		draw_line(Vector2(MARGIN, y_pos), Vector2(size.x - MARGIN, y_pos), GRID_COLOR, 1.0)

	# 2. Map WPM Line
	var points = PackedVector2Array()
	var x_step = w / (wpm_points.size() - 1)
	
	for i in range(wpm_points.size()):
		var x = MARGIN + (i * x_step)
		var y = size.y - MARGIN - ((wpm_points[i] / max_wpm) * h)
		points.append(Vector2(x, y))
	
	# Draw smooth polyline
	draw_polyline(points, LINE_COLOR, 1.0, true)

	# 3. Draw Error Markers (Small dots at the bottom)
	for err_idx in errors:
		var progress = float(err_idx) / errors.size()
		var x = MARGIN + (progress * w)
		draw_circle(Vector2(x, size.y - MARGIN + 10), 3.0, ERROR_COLOR)
