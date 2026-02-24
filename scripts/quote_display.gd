extends RichTextLabel
class_name QuoteDisplay

var typed_mistake_color: Color
var cursor_color: Color
var untyped_color: Color

var typed_space_character: String
var typed_enter_character: String
var typed_tab_character: String
var typed_space_correct_color: Color
var typed_space_mistake_color: Color

var cursor_target_position: Vector2 = Vector2.ZERO
var target_line: int = -1
var cursor_rect: Rect2
var center_tween: Tween

func _ready() -> void:
	cursor_rect = Rect2(-2, 0, 2, get_theme_font("normal_font").get_char_size(32, get_theme_font_size("normal_font_size")).y)
	theme_changed.connect(_update_theme)
	_update_theme()

func _update_theme() -> void:
	typed_mistake_color = get_theme_color(&"typed_mistake_color", &"QuoteDisplay")
	cursor_color = get_theme_color(&"cursor_color", &"QuoteDisplay")
	untyped_color = get_theme_color(&"untyped_color", &"QuoteDisplay")
	typed_space_correct_color = get_theme_color(&"typed_space_correct_color", &"QuoteDisplay")
	typed_space_mistake_color = get_theme_color(&"typed_space_mistake_color", &"QuoteDisplay")
	typed_space_character = char(get_theme_constant(&"typed_space_character", &"QuoteDisplay"))
	typed_enter_character = char(get_theme_constant(&"typed_enter_character", &"QuoteDisplay"))
	typed_tab_character = char(get_theme_constant(&"typed_tab_character", &"QuoteDisplay"))
	
func update_view(typed: String, target: String):
	clear()
	
	if not typed:
		push_color(untyped_color)
		add_text(target)
	
	push_color(Color.WHITE)
	
	var char_index = 0
	var active_color = 0b00
	var highlight_changed = false
	
	var colors = {
		0b00: Color.WHITE,
		0b01: typed_mistake_color,
		0b10: typed_space_correct_color,
		0b11: typed_space_mistake_color
	}
	
	var whitespaces = {
		" " : typed_space_character,
		"\n": " " + typed_enter_character + "\n",
		"\t": typed_tab_character + " ".repeat(tab_size - 1)
	}

	for target_char in target:
		if char_index >= typed.length(): break
		
		if char_index in DataManager.syntax_map:
			colors[0b00] = DataManager.syntax_map[char_index]
			highlight_changed = true
		
		var typed_char = typed[char_index]
		var color = int(target_char in whitespaces) << 1 | int(typed_char != target_char)
		
		if color != active_color or (highlight_changed and color == 0b00):
			pop()
			push_color(colors[color])
			active_color = color
			highlight_changed = false
		
		if target_char in whitespaces:
			add_text(whitespaces[target_char])
		else:
			add_text(target_char)
			
		char_index += 1
			
	pop()
	
	push_color(untyped_color)
	add_text(target.right(-char_index))
	pop()
	
	var new_target_line = target.left(typed.length()).count("\n")
	var font = get_theme_font(&"normal_font")
	var font_size = get_theme_font_size("normal_font_size")
	
	custom_minimum_size = font.get_multiline_string_size(target.replace("\n", "__\n").replace("\t", "____"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	if target_line != new_target_line:
		var height = font.get_char_size(32, font_size).y
		target_line = new_target_line
		
		if center_tween:
			center_tween.custom_step(1.0)
			center_tween.kill()
		
		center_tween = create_tween()
		center_tween.tween_property(self, "position:y", -height * (target_line + 0.5), 0.1)
	
	var last_line_start_index = target.left(typed.length()).rfind("\n") + 1
	cursor_target_position.x = font.get_string_size(target.substr(last_line_start_index, typed.length() - last_line_start_index).replace("\t", "    "), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	cursor_target_position.y = font.get_multiline_string_size(target.left(last_line_start_index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).y
	
func _process(delta: float) -> void:
	cursor_rect.position = lerp(cursor_rect.position, cursor_target_position, 1.0 - 0.00015 ** delta)
	queue_redraw()
	
func _draw() -> void:
	draw_rect(cursor_rect, cursor_color)
