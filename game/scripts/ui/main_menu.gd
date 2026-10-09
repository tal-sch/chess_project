extends Control
class_name MainMenu

@onready var game_manager = $"../GameManager"

func _ready():
	# Darken the 3D background slightly
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.4)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg_rect = bg

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center_container = center

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 480)
	
	# Premium glass-like panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.85)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.35, 0.4, 0.5)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "♔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.85, 0.75, 0.5))
	vbox.add_child(title)
	
	var game_title = Label.new()
	game_title.text = "GRANDMASTER"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_size_override("font_size", 42)
	game_title.add_theme_color_override("font_color", Color(0.92, 0.9, 0.88))
	vbox.add_child(game_title)
	
	var subtitle = Label.new()
	subtitle.text = "C++ GDExtension Chess Engine"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	vbox.add_child(subtitle)
	
	# Thin separator line
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	vbox.add_child(sep)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)
	
	main_buttons_vbox = VBoxContainer.new()
	main_buttons_vbox.add_theme_constant_override("separation", 16)
	vbox.add_child(main_buttons_vbox)
	
	difficulty_vbox = VBoxContainer.new()
	difficulty_vbox.add_theme_constant_override("separation", 16)
	difficulty_vbox.visible = false
	vbox.add_child(difficulty_vbox)
	
	_add_menu_button(main_buttons_vbox, "PLAYER VS PLAYER", func(): _on_start_pressed(0))
	_add_menu_button(main_buttons_vbox, "PLAYER VS BOT", func(): _show_difficulty())
	
	_add_menu_button(difficulty_vbox, "EASY", func(): _on_start_pressed(1))
	_add_menu_button(difficulty_vbox, "MEDIUM", func(): _on_start_pressed(3))
	_add_menu_button(difficulty_vbox, "HARD", func(): _on_start_pressed(5))
	
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(240, 40)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_hide_difficulty)
	var back_margin = MarginContainer.new()
	back_margin.add_theme_constant_override("margin_left", 48)
	back_margin.add_theme_constant_override("margin_right", 48)
	back_margin.add_child(back_btn)
	difficulty_vbox.add_child(back_margin)
	
	var options_margin = MarginContainer.new()
	options_margin.add_theme_constant_override("margin_left", 48)
	options_margin.add_theme_constant_override("margin_right", 48)
	var reduce_motion_btn = CheckButton.new()
	reduce_motion_btn.text = "REDUCE MOTION"
	reduce_motion_btn.add_theme_font_size_override("font_size", 12)
	reduce_motion_btn.button_pressed = UIFX.reduce_motion
	reduce_motion_btn.toggled.connect(func(toggled: bool): UIFX.reduce_motion = toggled)
	options_margin.add_child(reduce_motion_btn)
	main_buttons_vbox.add_child(options_margin)
	
	var quit_btn = Button.new()
	quit_btn.text = "EXIT"
	quit_btn.custom_minimum_size = Vector2(240, 40)
	quit_btn.add_theme_font_size_override("font_size", 16)
	quit_btn.pressed.connect(_on_quit_pressed)
	var quit_margin = MarginContainer.new()
	quit_margin.add_theme_constant_override("margin_left", 48)
	quit_margin.add_theme_constant_override("margin_right", 48)
	quit_margin.add_child(quit_btn)
	main_buttons_vbox.add_child(quit_margin)
	
	animate_in()

var pending_mode: int = 0
var difficulty_vbox: VBoxContainer
var main_buttons_vbox: VBoxContainer
var bg_rect: ColorRect
var center_container: CenterContainer

func animate_in():
	if not is_inside_tree(): return
	
	if bg_rect:
		bg_rect.modulate.a = 0.0
		var bg_t = create_tween()
		bg_t.tween_property(bg_rect, "modulate:a", 1.0, 0.4)
	
	if center_container:
		center_container.visible = false
		UIFX.pop_in(center_container)
	
	if main_buttons_vbox:
		var delay = 0.15
		for btn_margin in main_buttons_vbox.get_children():
			btn_margin.visible = false
			UIFX.fade_slide_in(btn_margin, Vector2(0, 30), delay)
			delay += 0.06

func _show_difficulty():
	main_buttons_vbox.visible = false
	difficulty_vbox.visible = true
	var delay = 0.0
	for child in difficulty_vbox.get_children():
		child.visible = false
		UIFX.fade_slide_in(child, Vector2(30, 0), delay)
		delay += 0.05

func _hide_difficulty():
	difficulty_vbox.visible = false
	main_buttons_vbox.visible = true
	var delay = 0.0
	for child in main_buttons_vbox.get_children():
		child.visible = false
		UIFX.fade_slide_in(child, Vector2(-30, 0), delay)
		delay += 0.05

func _add_menu_button(parent, text, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 40)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(callback)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_child(btn)
	parent.add_child(margin)

func _on_start_pressed(mode: int):
	game_manager.request_game_start(mode)

func _on_quit_pressed():
	game_manager.quit_game()
