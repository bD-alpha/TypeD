extends RichTextLabel
class_name WordsDisplay

var typed_correct_color: Color
var typed_mistake_color: Color
var current_word_typed_correct_color: Color
var current_word_typed_mistake_color: Color
var current_word_untyped_color: Color
var untyped_color: Color
var typed_space_character: String
var typed_space_correct_color: Color
var typed_space_mistake_color: Color
var cursor_color: Color

var center_tween: Tween
var prev_word_index: int = -1

var cursor_target_position: float = 0.0
var cursor_rect: Rect2

func _ready() -> void:
	cursor_rect = Rect2(-2, 0, 2, get_theme_font("normal_font").get_char_size(32, get_theme_font_size("normal_font_size")).y)
	theme_changed.connect(_update_theme)
	_update_theme()
	
func _update_theme() -> void:
	typed_correct_color = get_theme_color(&"typed_correct_color", &"WordsDisplay")
	typed_mistake_color = get_theme_color(&"typed_mistake_color", &"WordsDisplay")
	current_word_typed_correct_color = get_theme_color(&"current_word_typed_correct_color", &"WordsDisplay")
	current_word_typed_mistake_color = get_theme_color(&"current_word_typed_mistake_color", &"WordsDisplay")
	current_word_untyped_color = get_theme_color(&"current_word_untyped_color", &"WordsDisplay")
	untyped_color = get_theme_color(&"untyped_color", &"WordsDisplay")
	typed_space_correct_color = get_theme_color(&"typed_space_correct_color", &"WordsDisplay")
	typed_space_mistake_color = get_theme_color(&"typed_space_mistake_color", &"WordsDisplay")
	cursor_color = get_theme_color(&"cursor_color", &"WordsDisplay")
	typed_space_character = char(get_theme_constant(&"typed_space_character", &"WordsDisplay"))
	queue_redraw()

func update_view(typed: String, target: String):
	var words = target.split(" ")
	
	# Finding current word bounds
	var current_word_start = 0
	var current_word_end = 0
	var typed_chars_count = typed.length()
	var current_word_index = 0
	
	for word in words:
		var word_length = word.length()
		current_word_end = current_word_start + word_length
		if current_word_end >= typed_chars_count:
			break
		current_word_start += word_length + 1
		current_word_index += 1
	
	# Building text display
	var char_index = 0
	var active_color = 0b00
	
	var colors = {
		0b000: typed_correct_color,
		0b001: typed_space_correct_color,
		0b010: typed_mistake_color,
		0b011: typed_space_mistake_color,
		0b100: current_word_typed_correct_color,
		0b110: current_word_typed_mistake_color
	}
	
	clear()
	push_color(typed_correct_color)
	
	# Typed
	for typed_char in typed:
		var target_char = target[char_index]
		var color = (int(target_char == " ")) | (int(typed_char != target_char) << 1) | (int(char_index >= current_word_start) << 2)
		
		if  color != active_color:
			pop()
			push_color(colors[color])
			active_color = color
		
		if target_char == " ":
			add_text(typed_space_character)
		else:
			add_text(target_char)
		
		char_index += 1
	pop()
	
	# Untyped
	push_color(current_word_untyped_color)
	add_text(target.substr(char_index, current_word_end - char_index))
	pop()
	
	push_color(untyped_color)
	add_text(target.right(-current_word_end))
	pop()
	
	
	var font = get_theme_font(&"normal_font")
	var font_size = get_theme_font_size("normal_font_size")
	
	# Cursor
	cursor_target_position = font.get_string_size(typed, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x - 1
	# Centering
	if current_word_index != prev_word_index:
		var typed_width_start = font.get_string_size(target.left(current_word_start), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		var typed_width_end =  font.get_string_size(target.left(current_word_end), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x

		if center_tween:
			center_tween.custom_step(1.0)
			center_tween.kill()
		
		center_tween = create_tween()
		center_tween.tween_property(self, "position:x", -(typed_width_start + typed_width_end) / 2.0, 0.2).set_trans(Tween.TRANS_CUBIC)
	
	prev_word_index = current_word_index

func _process(delta: float) -> void:
	cursor_rect.position.x = lerpf(cursor_rect.position.x, cursor_target_position, 1.0 - 0.00015 ** delta)
	queue_redraw()
	
func _draw() -> void:
	draw_rect(cursor_rect, cursor_color)
