extends Node
class_name GameManager

signal turn_changed(side: int)
signal piece_captured(piece_code: int, side: int)
signal check_detected()
signal game_over(result: int)

@onready var engine = get_node("/root/ChessEngine")
@onready var board = $"../GameScene/ChessBoard"
@onready var game_scene = $"../GameScene"
@onready var main_menu = $"../MainMenu"
@onready var game_hud = $"../GameHUD"

var move_history: Array[Dictionary] = []
var play_mode: int = 0 # 0=PvP, 1=Easy, 3=Medium, 5=Hard
var bot_color: int = 0 # 0=Black
var player_color: int = 1 # 1=White

func _ready():
	engine.move_made.connect(_on_move_made)
	engine.game_reset.connect(_on_game_reset)
	engine.new_game() # Populate pieces for the background
	game_scene.visible = true
	game_hud.visible = false
	main_menu.visible = true

func request_game_start(mode: int):
	main_menu.visible = false
	game_scene.visible = true
	game_hud.visible = true
	
	if game_hud.has_method("show_color_selection"):
		game_hud.show_color_selection(mode)
	else:
		start_new_game(mode, 1)

func start_new_game(mode: int = 0, p_color: int = 1):
	play_mode = mode
	player_color = p_color
	bot_color = 1 - player_color # Bot plays the opposite color
	
	main_menu.visible = false
	game_scene.visible = true
	game_hud.visible = true
	if game_hud.has_method("animate_in"):
		game_hud.animate_in()
		
	var input_handler = $"../GameScene/InputHandler"
	if input_handler and input_handler.has_method("reset_camera"):
		input_handler.reset_camera(player_color == 1)
	
	engine.new_game()

func quit_game():
	get_tree().quit()

func _on_game_reset():
	move_history.clear()
	if board:
		board.refresh_board()
	_handle_turn(engine.get_side_to_move())

func _on_move_made(src: String, dst: String, result: int):
	# The input handler animates the piece, but we record history
	move_history.append({
		"src": src,
		"dst": dst,
		"result": result,
		"notation": src + dst
	})
	
	# Show last move highlight on the board
	if board and board.has_method("show_last_move"):
		board.show_last_move(src, dst)
	
	if result == 1: # CHECK
		check_detected.emit()
	elif result == 8: # CHECKMATE
		game_over.emit(result)
		return
		
	_handle_turn(engine.get_side_to_move())

func _handle_turn(side: int):
	turn_changed.emit(side)
	
	if play_mode > 0 and side == bot_color:
		# It's the bot's turn! Wait a short moment then play
		await get_tree().create_timer(0.5).timeout
		var bot_move = engine.play_bot_move(play_mode)
		if bot_move.has("src") and bot_move.has("dst"):
			var result = bot_move["result"]
			if board:
				board.move_piece_animated(bot_move["src"], bot_move["dst"])

