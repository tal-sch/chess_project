extends CanvasLayer
class_name GameHUD

@onready var game_manager = $"../GameManager"

var turn_label: Label
var history_list: ItemList
var banner: Label
var captured_label: Label
var captured_pieces: Array[int] = []

# Unicode chess piece symbols for display
const PIECE_SYMBOLS = {
	0: "♟", 1: "♙",  # Pawn (black, white)
	2: "♞", 3: "♘",  # Knight
	4: "♜", 5: "♖",  # Rook
	6: "♝", 7: "♗",  # Bishop
	8: "♛", 9: "♕",  # Queen
	10: "♚", 11: "♔"  # King
}

const PIECE_NAMES = {
	0: "", 1: "",      # Pawn
	2: "N", 3: "N",    # Knight
	4: "R", 5: "R",    # Rook
	6: "B", 7: "B",    # Bishop
	8: "Q", 9: "Q",    # Queen
	10: "K", 11: "K"   # King
}

func _ready():
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hbox.theme = load("res://assets/theme/chess_theme.tres")
	add_child(main_hbox)
	
	# Left/Top area (Turn info)
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 0.8
	left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hbox.add_child(left_vbox)
	
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_top", 32)
	top_margin.add_theme_constant_override("margin_left", 32)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_vbox.add_child(top_margin)
	
	var turn_panel = PanelContainer.new()
	var turn_style = StyleBoxFlat.new()
	turn_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	turn_style.corner_radius_top_left = 24
	turn_style.corner_radius_top_right = 24
	turn_style.corner_radius_bottom_left = 24
	turn_style.corner_radius_bottom_right = 24
	turn_style.content_margin_left = 24
	turn_style.content_margin_right = 24
	turn_style.content_margin_top = 10
	turn_style.content_margin_bottom = 10
	turn_style.border_width_left = 1
	turn_style.border_width_top = 1
	turn_style.border_width_right = 1
	turn_style.border_width_bottom = 1
	turn_style.border_color = Color(0.3, 0.35, 0.4, 0.5)
	turn_style.shadow_color = Color(0, 0, 0, 0.3)
	turn_style.shadow_size = 10
	turn_panel.add_theme_stylebox_override("panel", turn_style)
	top_margin.add_child(turn_panel)
	
	turn_label = Label.new()
	turn_label.text = "White to move"
	turn_label.add_theme_font_size_override("font_size", 22)
	turn_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	turn_panel.add_child(turn_label)
	
	banner = Label.new()
	banner.text = ""
	banner.add_theme_font_size_override("font_size", 56)
	banner.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(banner)
	
	# Right area (History & buttons)
	var right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(160, 0)
	
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
	right_style.border_width_left = 1
	right_style.border_color = Color(0.3, 0.3, 0.35, 0.4)
	right_style.shadow_color = Color(0, 0, 0, 0.5)
	right_style.shadow_size = 20
	right_panel.add_theme_stylebox_override("panel", right_style)
	main_hbox.add_child(right_panel)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 16)
	right_margin.add_theme_constant_override("margin_right", 16)
	right_margin.add_theme_constant_override("margin_top", 24)
	right_margin.add_theme_constant_override("margin_bottom", 24)
	right_panel.add_child(right_margin)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 16)
	right_margin.add_child(right_vbox)
	
	var hist_label = Label.new()
	hist_label.text = "MOVE HISTORY"
	hist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hist_label.add_theme_font_size_override("font_size", 14)
	hist_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	right_vbox.add_child(hist_label)
	
	history_list = ItemList.new()
	history_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Style the list to blend in
	var list_style = StyleBoxEmpty.new()
	history_list.add_theme_stylebox_override("panel", list_style)
	history_list.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	history_list.add_theme_font_size_override("font_size", 13)
	right_vbox.add_child(history_list)
	
	# Captured pieces area
	var cap_label = Label.new()
	cap_label.text = "CAPTURED"
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_label.add_theme_font_size_override("font_size", 12)
	cap_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	right_vbox.add_child(cap_label)
	
	captured_label = Label.new()
	captured_label.text = ""
	captured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	captured_label.add_theme_font_size_override("font_size", 14)
	captured_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	captured_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(captured_label)
	
	# Buttons
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 8)
	right_vbox.add_child(btn_vbox)
	
	var newgame_btn = Button.new()
	newgame_btn.text = "NEW GAME"
	newgame_btn.custom_minimum_size = Vector2(0, 36)
	newgame_btn.pressed.connect(_on_newgame_pressed)
	btn_vbox.add_child(newgame_btn)
	var main_menu_btn = Button.new()
	main_menu_btn.text = "MAIN MENU"
	main_menu_btn.custom_minimum_size = Vector2(0, 36)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	btn_vbox.add_child(main_menu_btn)

	_setup_game_over_panel()
	_setup_color_selection_panel()

	if game_manager:
		game_manager.turn_changed.connect(_on_turn_changed)
		game_manager.check_detected.connect(_on_check_detected)
		game_manager.game_over.connect(_on_game_over)
		
	var engine = get_node_or_null("/root/ChessEngine")
	if engine:
		engine.move_made.connect(_on_move_made)

var game_over_overlay: ColorRect
var game_over_title: Label
var game_over_subtitle: Label

var color_selection_overlay: ColorRect
var pending_game_mode: int = 0

func _setup_color_selection_panel():
	color_selection_overlay = ColorRect.new()
	color_selection_overlay.color = Color(0, 0, 0, 0.7)
	color_selection_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_selection_overlay.visible = false
	add_child(color_selection_overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_selection_overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "Choose Your Side"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(title)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 32)
	vbox.add_child(btn_hbox)
	
	var white_btn = Button.new()
	white_btn.text = "♔ White Side"
	white_btn.custom_minimum_size = Vector2(220, 80)
	white_btn.add_theme_font_size_override("font_size", 24)
	var white_style = StyleBoxFlat.new()
	white_style.bg_color = Color(0.8, 0.8, 0.8)
	white_style.border_width_bottom = 4
	white_style.border_color = Color(0.5, 0.5, 0.5)
	white_style.corner_radius_top_left = 8
	white_style.corner_radius_top_right = 8
	white_style.corner_radius_bottom_left = 8
	white_style.corner_radius_bottom_right = 8
	white_btn.add_theme_stylebox_override("normal", white_style)
	white_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	white_btn.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	white_btn.pressed.connect(func(): _start_with_color(1))
	btn_hbox.add_child(white_btn)
	
	var black_btn = Button.new()
	black_btn.text = "♚ Black Side"
	black_btn.custom_minimum_size = Vector2(220, 80)
	black_btn.add_theme_font_size_override("font_size", 24)
	var black_style = StyleBoxFlat.new()
	black_style.bg_color = Color(0.15, 0.15, 0.15)
	black_style.border_width_bottom = 4
	black_style.border_color = Color(0.05, 0.05, 0.05)
	black_style.corner_radius_top_left = 8
	black_style.corner_radius_top_right = 8
	black_style.corner_radius_bottom_left = 8
	black_style.corner_radius_bottom_right = 8
	black_btn.add_theme_stylebox_override("normal", black_style)
	black_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	black_btn.pressed.connect(func(): _start_with_color(0))
	btn_hbox.add_child(black_btn)

func show_color_selection(mode: int):
	pending_game_mode = mode
	color_selection_overlay.visible = false
	UIFX.pop_in(color_selection_overlay)
	
	# Hide normal HUD momentarily
	var main_hbox = get_node_or_null("MainHBox")
	if main_hbox: main_hbox.visible = false

func _start_with_color(color: int):
	color_selection_overlay.visible = false
	var main_hbox = get_node_or_null("MainHBox")
	if main_hbox: main_hbox.visible = true
	
	game_manager.start_new_game(pending_game_mode, color)

func _setup_game_over_panel():
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0, 0, 0, 0.6)
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.visible = false
	add_child(game_over_overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 320)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.35, 0.4, 0.6)
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
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	var icon = Label.new()
	icon.text = "♚"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 56)
	icon.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	vbox.add_child(icon)
	
	game_over_title = Label.new()
	game_over_title.text = "CHECKMATE"
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title.add_theme_font_size_override("font_size", 36)
	game_over_title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	vbox.add_child(game_over_title)
	
	game_over_subtitle = Label.new()
	game_over_subtitle.text = "White wins by Checkmate"
	game_over_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_subtitle.add_theme_font_size_override("font_size", 16)
	game_over_subtitle.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(game_over_subtitle)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)
	
	var restart_btn = Button.new()
	restart_btn.text = "REMATCH"
	restart_btn.custom_minimum_size = Vector2(140, 44)
	restart_btn.add_theme_font_size_override("font_size", 14)
	restart_btn.pressed.connect(_on_newgame_pressed)
	btn_hbox.add_child(restart_btn)
	
	var main_menu_btn = Button.new()
	main_menu_btn.text = "MAIN MENU"
	main_menu_btn.custom_minimum_size = Vector2(140, 44)
	main_menu_btn.add_theme_font_size_override("font_size", 14)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	btn_hbox.add_child(main_menu_btn)

func animate_in():
	var right_panel = get_node_or_null("MainHBox/RightPanel")
	if right_panel:
		right_panel.position.x = get_viewport().get_visible_rect().size.x + 300
		var tween = create_tween()
		tween.tween_property(right_panel, "position:x", get_viewport().get_visible_rect().size.x - right_panel.size.x, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var main_hbox = get_node_or_null("MainHBox")
	if main_hbox:
		main_hbox.modulate.a = 0.0
		var alpha_tween = create_tween()
		alpha_tween.tween_property(main_hbox, "modulate:a", 1.0, 0.3)

func _on_turn_changed(side: int):
	var new_text = "White to move" if side == 1 else "Black to move"
	if turn_label.text != new_text:
		var tween = create_tween()
		tween.tween_property(turn_label, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): turn_label.text = new_text)
		tween.tween_property(turn_label, "modulate:a", 1.0, 0.15)
	else:
		turn_label.text = new_text
		
	banner.text = "" # Clear banners on new turn

func _on_move_made(src: String, dst: String, result: int):
	var move_num = (history_list.item_count) + 1
	var prefix = str(ceili(move_num / 2.0)) + ". " if move_num % 2 == 1 else str(ceili(move_num / 2.0)) + "... "
	history_list.add_item(prefix + src + " -> " + dst)
	history_list.ensure_current_is_visible()

func _on_check_detected():
	banner.text = "CHECK!"
	# Animate the banner
	banner.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.2)

func _on_game_over(result: int):
	var engine = get_node_or_null("/root/ChessEngine")
	var side = engine.get_side_to_move() if engine else 1
	var winner = "Black" if side == 1 else "White" # If white is in checkmate, black wins
	
	if result == 8:
		game_over_title.text = "CHECKMATE"
		game_over_subtitle.text = winner + " wins by Checkmate"
	elif result == 12:
		game_over_title.text = "STALEMATE"
		game_over_subtitle.text = "Draw by Stalemate"
	elif result == 13:
		game_over_title.text = "DRAW"
		game_over_subtitle.text = "Draw by Insufficient Material"
	elif result == 14:
		game_over_title.text = "DRAW"
		game_over_subtitle.text = "Draw by Fifty-Move Rule"
	elif result == 15:
		game_over_title.text = "DRAW"
		game_over_subtitle.text = "Draw by Threefold Repetition"
	else:
		game_over_title.text = "GAME OVER"
		game_over_subtitle.text = "Game concluded"
	
	game_over_overlay.visible = false
	UIFX.pop_in(game_over_overlay)

func _on_newgame_pressed():
	if game_over_overlay:
		game_over_overlay.visible = false
	captured_pieces.clear()
	captured_label.text = ""
	game_manager.start_new_game(game_manager.play_mode, game_manager.player_color)
	history_list.clear()

func _on_main_menu_pressed():
	if game_over_overlay:
		game_over_overlay.visible = false
	captured_pieces.clear()
	captured_label.text = ""
	history_list.clear()
	
	# Transition back to main menu
	var right_panel = get_node_or_null("MainHBox/RightPanel")
	if right_panel:
		var tween = create_tween()
		tween.tween_property(right_panel, "position:x", get_viewport().get_visible_rect().size.x + 300, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	var main_hbox = get_node_or_null("MainHBox")
	if main_hbox:
		var alpha_tween = create_tween()
		alpha_tween.tween_property(main_hbox, "modulate:a", 0.0, 0.2)
		
	# Full screen fade
	if game_manager.fade_rect:
		var ft = create_tween()
		ft.tween_property(game_manager.fade_rect, "modulate:a", 1.0, 0.3)
		await ft.finished
		
		self.visible = false
		game_manager.play_mode = 0
		game_manager.main_menu.visible = true
		
		# Reset HUD
		if main_hbox: main_hbox.modulate.a = 1.0
		
		# Start main menu pop in
		game_manager.main_menu.animate_in()
		
		game_manager.engine.new_game()
		game_manager.board.refresh_board()
		
		var out_t = create_tween()
		out_t.tween_property(game_manager.fade_rect, "modulate:a", 0.0, 0.3)

func add_captured_piece(piece_code: int):
	captured_pieces.append(piece_code)
	_update_captured_display()

func _update_captured_display():
	var white_caps = ""
	var black_caps = ""
	for pc in captured_pieces:
		var symbol = PIECE_SYMBOLS.get(pc, "?")
		if pc % 2 == 1:  # White piece was captured
			black_caps += symbol
		else:  # Black piece was captured
			white_caps += symbol
	captured_label.text = white_caps + "\n" + black_caps
