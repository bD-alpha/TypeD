extends Resource
class_name QuoteSyntaxHighlighter

@export var base_color: Color
@export var punctuation_color: Color
@export var number_color: Color
@export var keyword_groups: Dictionary[StringName, PackedStringArray] = {}
@export var groups_colors: Dictionary[StringName, Color] = {}
@export var line_tags_colors: Dictionary[String, Color] = {}
@export var string_color: Color
