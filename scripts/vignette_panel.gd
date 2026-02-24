@tool
extends Panel

func _ready() -> void:
	_update_panel()

func _update_panel() -> void:
	var parent_panel = get_parent().get_theme_stylebox(&"panel", &"PanelContainerBase")
	var panel: StyleBoxTexture = get_theme_stylebox(&"panel")
	
	if parent_panel is StyleBoxFlat:
		(panel.texture as GradientTexture2D).gradient.colors[0] = parent_panel.bg_color
		(panel.texture as GradientTexture2D).gradient.colors[0].a = 0.0
		(panel.texture as GradientTexture2D).gradient.colors[1] = parent_panel.bg_color
		
		panel.expand_margin_bottom = parent_panel.expand_margin_bottom + 1
		panel.expand_margin_left = parent_panel.expand_margin_left + 1
		panel.expand_margin_right = parent_panel.expand_margin_right + 1
		panel.expand_margin_top = parent_panel.expand_margin_top + 1
		
		visible = true
		
	else:
		visible = false
	
