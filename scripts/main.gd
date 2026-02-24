extends Node

@onready var settings_panel = %SettingsPanel
@onready var typing_session = %TypingSession
@onready var results_panel = %ResultsPanel

var last_text: String
var last_settings: Dictionary

func _ready():
	settings_panel.session_requested.connect(_on_session_requested)
	typing_session.session_finished.connect(_on_session_finished)
	results_panel.menu_requested.connect(_on_back_to_menu_requested)
	results_panel.restart_requested.connect(_on_restart_requested)

func _on_session_requested(text: String, settings: Dictionary):
	last_text = text
	last_settings = settings
	
	# 1. Fade animation
	typing_session.show()
	typing_session.modulate.a = 0.0
	
	var tween = create_tween().set_parallel()
	tween.tween_property(typing_session, "modulate:a", 1.0, 0.25)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(results_panel, "modulate:a", 0.0, 0.25)
	tween.chain()
	tween.tween_callback(settings_panel.hide)
	tween.tween_callback(results_panel.hide)
	
	# 2. Setup and show the typing session
	typing_session.current_mode = settings.mode # Pass the mode for rendering logic
	typing_session.start_session(text)
	
	# 3. Ensure the typing session starts receiving input
	typing_session.grab_focus()

func _on_session_finished(data: Dictionary):
	results_panel.show()
	results_panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel()
	tween.tween_property(typing_session, "modulate:a", 0.0, 0.25)
	tween.tween_property(results_panel, "modulate:a", 1.0, 0.25)
	tween.chain()
	tween.tween_callback(typing_session.hide)
	
	
	results_panel.display_results(data)
	
	# Save to persistent history
	DataManager.save_to_history(data)

func _on_back_to_menu_requested():	
	settings_panel.show()
	settings_panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel()
	tween.tween_property(results_panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.25)
	tween.chain()
	tween.tween_callback(results_panel.hide)

func _on_restart_requested():
	# Reuse the last session parameters to start again
	_on_session_requested(last_text, last_settings)
