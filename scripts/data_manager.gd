extends Node

const WORDSETS_DIR = "res://wordsets/"
const WORD_COUNTS = [25, 50, 100]
const QUOTE_KEYS = ["short", "medium", "long"]

enum Mode { WORDS, QUOTE }

# This will hold all data in memory
# Structure: { "English": { "words": [...], "short": [...], "medium": [...], "large": [...] } }
var wordsets_data = {}

var syntax_highlight = {}
var syntax_map: Dictionary[int, Color]

func _ready():
	load_all_data()

func load_all_data():
	wordsets_data.clear()
	var dir = DirAccess.open(WORDSETS_DIR)
	
	if not dir:
		printerr("Could not open wordsets directory!")
		return

	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			wordsets_data[folder_name] = _load_single_set(folder_name)
		folder_name = dir.get_next()
	
	print("Data Manager: Loaded ", wordsets_data.size(), " wordsets.")

func _load_single_set(set_name: String) -> Dictionary:
	var set_dict = {
		"short": [],
		"medium": [],
		"long": []
	}
	
	# 1. Load words.txt
	var words_path = WORDSETS_DIR + set_name + "/words.txt"
	if FileAccess.file_exists(words_path):
		var file = FileAccess.open(words_path, FileAccess.READ)
		set_dict["words"] = Array(file.get_as_text().split("\n", false))
	
	# 2. Load syntax highlight (if present)
	var syntax_path = WORDSETS_DIR + set_name + "/syntax.tres"
	if FileAccess.file_exists(syntax_path):
		syntax_highlight[set_name] = load(syntax_path)
	
	# 3. Load quotes from subfolders
	for key in QUOTE_KEYS:
		var path = WORDSETS_DIR + set_name + "/" + key + "/"
		var q_dir = DirAccess.open(path)
		if q_dir:
			q_dir.list_dir_begin()
			var f_name = q_dir.get_next()
			while f_name != "":
				if not q_dir.current_is_dir() and f_name.ends_with(".txt"):
					var f = FileAccess.open(path + f_name, FileAccess.READ)
					set_dict[key].append(f.get_as_text().strip_edges())
				f_name = q_dir.get_next()
				
	return set_dict

# --- Public API for the UI ---

func get_list_of_sets() -> Array:
	return wordsets_data.keys()

func generate_text(mode: Mode, set_name: String, size_index: int) -> String:
	if not wordsets_data.has(set_name):
		return "Error: Set not found"
	
	var data = wordsets_data[set_name]
	
	if mode == Mode.WORDS:
		var count = WORD_COUNTS[clampi(size_index, 0, 2)]
		var pool = data["words"]
		if pool.is_empty(): return "Error: No words available"
		
		var result = []
		for i in range(count):
			result.append(pool.pick_random())
		return " ".join(result)
	else:
		var key = QUOTE_KEYS[clampi(size_index, 0, 2)]
		var pool = data[key]
		if pool.is_empty(): return "Error: No quotes available"
		var text = pool.pick_random()
		syntax_map = _generate_syntax_map(set_name, text)
		return text
	

func _generate_syntax_map(set_name: String, text: String) -> Dictionary[int, Color]:
	if set_name not in syntax_highlight: return {0: Color.WHITE}
	
	var syntax = syntax_highlight[set_name]
	var map: Dictionary[int, Color] = {}
	
	# Applying punctuation color
	_apply_regex(text, map, "[.:\\-!,/\\\\[\\]%#@^&*();{}<>=]+", syntax.base_color, syntax.punctuation_color)
	
	# Applying number color
	_apply_regex(text, map, "(\\b0[bBxX][\\da-fA-F]+\\b)|(\\b-?\\d+(\\.\\d+)?[fF]?\\b)", syntax.base_color, syntax.number_color)
	
	# Applying keyword highlighting
	for keyword_group in syntax.keyword_groups:
		for keyword in syntax.keyword_groups[keyword_group]:
			_apply_regex(text, map, "\\b" + keyword + "\\b", syntax.base_color, syntax.groups_colors[keyword_group])
	
	# Applying line tags highlighting
	for line_tag in syntax.line_tags_colors:
		_apply_regex(text, map, "%s.*\n" % [line_tag], syntax.base_color, syntax.line_tags_colors[line_tag])
	
	# Applying string formatting
	_apply_regex(text, map, "(?:\"(?:[^\"\\\\]|\\.)*\"|'(?:[^'\\\\]|\\.)*')", syntax.base_color, syntax.string_color)
	
	return map

func _apply_regex(text: String, map: Dictionary[int, Color], pattern: String, base_color: Color, color: Color) -> void:
	var regex = RegEx.new()
	regex.compile(pattern)
	for m in regex.search_all(text):
		map[m.get_start()] = color
		for i in range(m.get_start() + 1, m.get_end()):
			map.erase(i)
		if m.get_end() not in map:
			map[m.get_end()] = base_color

func save_to_history(data: Dictionary) -> void:
	pass
