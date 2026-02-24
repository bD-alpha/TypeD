extends PanelContainer

signal restart_requested
signal menu_requested

func _ready() -> void:
	%RestartButton.pressed.connect(_on_restart_button_pressed)
	%MenuButton.pressed.connect(_on_menu_button_pressed)

func display_results(data: Dictionary):
	# Panel 1: Settings
	%WordsetLabel.text = data.wordset
	%ModeLabel.text = data.mode
	%SizeLabel.text = data.size
	%StartTimeLabel.text = data.start_time

	# Panel 2: Stats
	%WPMLabel.text = str(snapped(data.wpm, 0.1))
	%AccuracyLabel.text = str(snapped(data.accuracy, 0.01)) + "%"
	%TimeLabel.text = str(snapped(data.time, 0.01)) + "s"
	%MistakesLabel.text = "%d / %d" % [data.mistakes, data.fixed]

	# Panel 3: Graph
	%WPMGraph.draw_session_graph(data.wpm_history, data.error_indices)
	
	show()

func _on_restart_button_pressed():
	restart_requested.emit()

func _on_menu_button_pressed():
	menu_requested.emit()
