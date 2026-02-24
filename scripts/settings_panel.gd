extends Control

signal session_requested(text, settings)

# Using Unique Names as requested
@onready var wordset_selector = %WordsetSelector
@onready var mode_selector = %ModeSelector
@onready var count_selector = %CountSelector
@onready var size_selector = %SizeSelector
@onready var start_button = %StartButton

func _ready():
	_setup_ui()
	
	# Connect signals
	mode_selector.item_selected.connect(_on_mode_changed)
	start_button.pressed.connect(_on_start_pressed)

func _setup_ui():
	# 1. Fill Wordsets
	wordset_selector.clear()
	for set_name in DataManager.get_list_of_sets():
		wordset_selector.add_item(set_name)
	
	# 3. Initial Visibility
	_on_mode_changed(0) 

func _on_mode_changed(index: int):
	# Show/Hide selectors based on mode
	var is_words = (index == 0)
	count_selector.get_parent().visible = is_words
	size_selector.get_parent().visible = !is_words
	
	# Optional: If you have labels next to them, 
	# wrap them in a HBox/VBox and hide the parent.

func _on_start_pressed():
	var selected_set = wordset_selector.get_item_text(wordset_selector.selected)
	var mode = mode_selector.selected as DataManager.Mode
	
	# Use count_selector index if Words, size_selector index if Quote
	var size_index = count_selector.selected if mode == DataManager.Mode.WORDS else size_selector.selected
	
	# Get the text from our DataManager
	var text_to_type = DataManager.generate_text(mode, selected_set, size_index)
	
	var settings = {"wordset": selected_set,
					"mode": mode,
					"size": size_index, 
					"size_label": str((DataManager.WORD_COUNTS if mode == DataManager.Mode.WORDS else DataManager.QUOTE_KEYS)[size_index]).capitalize()}
	
	# Shout to the Main scene that we are ready!
	session_requested.emit(text_to_type, settings)
