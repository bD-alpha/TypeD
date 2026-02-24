extends Control

signal session_finished(data: Dictionary)

# Logic Variables
var current_mode: DataManager.Mode = DataManager.Mode.WORDS
var current_display: Node
var target_text: String = ""
var typed_text: String = ""
var start_time: float = 0.0
var is_active: bool = false
var is_paused: bool = true

var total_mistakes: int = 0  
var fixed_mistakes: int = 0

# Statistics Tracking
var total_keystrokes: int = 0
var error_indices: Array[int] = []
var wpm_history: Array[float] = []  # For the graph
var last_wpm_update: float = 0.0

# UI References
@onready var timer_label = %TimeDisplay
@onready var wpm_label = %WPMDisplay
@onready var progress_bar = %ProgressBar

func _ready():
	set_process_unhandled_input(true)
	# Ensure the session starts paused
	is_active = false
	is_paused = true

# --- 1. Initialization ---

func start_session(text: String):
	target_text = text
	typed_text = ""
	total_keystrokes = 0
	error_indices.clear()
	wpm_history.clear()
	
	is_active = true
	is_paused = true # Wait for first keypress
	
	current_display = %WordsDisplay if current_mode == DataManager.Mode.WORDS else %QuoteDisplay
	(%QuoteDisplay if current_mode == DataManager.Mode.WORDS else %WordsDisplay).hide()
	current_display.show()
	
	current_display.update_view("", target_text)
	get_tree().process_frame.connect(current_display.center_tween.custom_step.bind(1.0), CONNECT_ONE_SHOT)
	
	%VignettePanel.visible = current_mode != DataManager.Mode.QUOTE
	
	_update_stats_ui(0, 0)

# --- 2. Input Handling ---

func _unhandled_input(event: InputEvent):
	if not is_active: return

	# Toggle Stats Visibility (F1)
	#if event.is_action_pressed("ui_toggle_stats") or (event is InputEventKey and event.keycode == KEY_F1):
		#stats_bar.visible = !stats_bar.visible
		#return

	# Handle Mouse Movement (Pause)
	if event is InputEventMouseMotion and not is_paused:
		_pause_session()
		return

	# Handle Typing
	if event is InputEventKey and event.pressed:
		if is_paused: 
			_resume_session()
		
		# Backspace
		if event.keycode == KEY_BACKSPACE:
			_delete_char()
			return
		
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_process_char("\n")
			return
		
		# Character Input
		if event.unicode > 31: # Ignore control keys like Shift, Ctrl, etc.
			_process_char(char(event.unicode))

func _delete_char() -> void:
	if typed_text.length() > 0:
		while typed_text.right(1) == "\t":
			typed_text = typed_text.left(-1)
		typed_text = typed_text.left(-1)
	current_display.update_view(typed_text, target_text)
	progress_bar.value = (float(typed_text.length()) / target_text.length()) * 100.0


func _process_char(c: String):
	var current_target_char = target_text[typed_text.length()]
	
	if c != current_target_char:
		total_mistakes += 1 # Increments every time a wrong key is hit
		if not typed_text.length() in error_indices:
			error_indices.append(typed_text.length())
	
	total_keystrokes += 1
	var current_target_idx = typed_text.length()
	
	# Error Detection
	if c != target_text[current_target_idx]:
		if not current_target_idx in error_indices:
			error_indices.append(current_target_idx)
	
	typed_text += c
	
	while typed_text.length() < target_text.length():
		var next_char = target_text[typed_text.length()]
		
		if next_char == "\t":
			typed_text += next_char
		else:
			break
	
	progress_bar.value = (float(typed_text.length()) / target_text.length()) * 100.0
	
	current_display.update_view(typed_text, target_text)
	
	# Check Completion
	if typed_text.length() >= target_text.length():
		_finish_session()


# --- 3. Session State ---

func _pause_session():
	is_paused = true
	# You can add a "PAUSED" label visibility here

func _resume_session():
	if start_time == 0.0 or typed_text.length() == 0:
		start_time = Time.get_unix_time_from_system()
	is_paused = false

func _process(_delta):
	if is_active and not is_paused:
		_calculate_realtime_metrics()

func _calculate_realtime_metrics():
	var elapsed = Time.get_unix_time_from_system() - start_time
	if elapsed <= 0: return
	
	# Standard WPM formula
	var minutes = elapsed / 60.0
	var current_wpm = (typed_text.length() / 5.0) / minutes
	
	_update_stats_ui(elapsed, current_wpm)
	
	# Record WPM every second for the graph
	if elapsed - last_wpm_update >= 1.0:
		wpm_history.append(current_wpm)
		last_wpm_update = elapsed

# --- 4. Visuals & UI ---

func _update_stats_ui(elapsed, wpm):
	var m = int(elapsed) / 60
	var s = int(elapsed) % 60
	timer_label.text = "%02d:%02d" % [m, s]
	wpm_label.text = str(round(wpm)) + " WPM"

# --- 5. Wrap Up ---

func _finish_session():
	is_active = false
	var final_time = Time.get_unix_time_from_system() - start_time
	var accuracy = (float(target_text.length()) / total_keystrokes) * 100.0
	var settings = get_parent().last_settings
	var elapsed = Time.get_unix_time_from_system() - start_time
	
	fixed_mistakes = total_mistakes - error_indices.size()
	
	var data = {
		"wordset": settings.wordset,
		"mode": "Words" if settings.mode == DataManager.Mode.WORDS else "Quote",
		"size": settings.size_label,
		"start_time": Time.get_time_string_from_unix_time(start_time * 1000),
		"wpm": target_text.length() / elapsed / 5.0 * 60.0,
		"accuracy": accuracy,
		"time": elapsed,
		"mistakes": total_mistakes,
		"fixed": fixed_mistakes,
		"wpm_history": wpm_history,
		"error_indices": error_indices,
		"target_length": target_text.length()
	}
	
	session_finished.emit(data)
