extends Node
class_name InputHandler

signal square_clicked(square: String)

@onready var camera: Camera3D = $"../Camera3D"
@onready var board: ChessBoard = $"../ChessBoard"
@onready var engine = get_node("/root/ChessEngine")

enum State { IDLE, PIECE_SELECTED }
var state = State.IDLE
var selected_square: String = ""
var legal_moves: PackedStringArray = []

@onready var main_menu = $"../../MainMenu"

var is_dragging_camera: bool = false
var cam_distance: float = 9.9
var cam_yaw: float = 180.0
var cam_pitch: float = 45.0

# Target variables for smooth interpolation
var target_cam_distance: float = 9.9
var target_cam_yaw: float = 180.0
var target_cam_pitch: float = 45.0

const PITCH_MIN = 5.0
const PITCH_MAX = 85.0

func reset_camera(is_white: bool):
	target_cam_yaw = 180.0 if is_white else 0.0
	target_cam_pitch = 45.0
	target_cam_distance = 9.9

func _ready():
	if camera:
		_update_camera()

func _process(delta):
	if not camera: return
	
	# Smoothly interpolate current camera values toward target values
	cam_distance = lerp(cam_distance, target_cam_distance, 12.0 * delta)
	cam_yaw = lerp(cam_yaw, target_cam_yaw, 12.0 * delta)
	cam_pitch = lerp(cam_pitch, target_cam_pitch, 12.0 * delta)
	
	_update_camera()

func _input(event):
	if main_menu and main_menu.visible: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked_square = _raycast_square(event.position)
			if clicked_square != "":
				_handle_square_click(clicked_square)
		
		# Camera controls update the TARGET variables now
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging_camera = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_cam_distance = max(4.0, target_cam_distance - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_cam_distance = min(20.0, target_cam_distance + 0.5)
			
	elif event is InputEventMouseMotion:
		if is_dragging_camera:
			target_cam_yaw -= event.relative.x * 0.4
			target_cam_pitch -= event.relative.y * 0.4
			target_cam_pitch = clamp(target_cam_pitch, PITCH_MIN, PITCH_MAX)
		else:
			var hovered = _raycast_square(event.position)
			board.update_hover(hovered)

func _update_camera():
	if not camera: return
	var pitch_rad = deg_to_rad(cam_pitch)
	var yaw_rad = deg_to_rad(cam_yaw)
	
	var pos = Vector3()
	pos.y = sin(pitch_rad) * cam_distance
	var h_dist = cos(pitch_rad) * cam_distance
	pos.x = sin(yaw_rad) * h_dist
	pos.z = cos(yaw_rad) * h_dist
	
	camera.position = pos
	camera.look_at(Vector3.ZERO)

func _raycast_square(mouse_pos: Vector2) -> String:
	if not camera or not board:
		return ""
		
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	# Ray-plane intersection where plane is y=0
	if ray_dir.y == 0: return ""
	
	var t = -ray_origin.y / ray_dir.y
	if t < 0: return ""
	
	var hit_pos = ray_origin + ray_dir * t
	var sq = board.world_to_square(hit_pos)
	return sq

func _handle_square_click(square: String):
	# Block input if playing vs bot and it's the bot's turn
	var gm = get_node("/root/Main/GameManager")
	if gm and gm.play_mode > 0 and engine.get_side_to_move() == gm.bot_color:
		return
		
	square_clicked.emit(square)
	
	if state == State.IDLE:
		var piece = engine.get_piece_at(square)
		if piece != -1:
			var color = piece % 2
			if color == engine.get_side_to_move():
				selected_square = square
				legal_moves = engine.get_legal_moves(square)
				if legal_moves.size() > 0:
					board.highlight_squares(legal_moves)
					board.show_selected_square(square)
					state = State.PIECE_SELECTED
	
	elif state == State.PIECE_SELECTED:
		if square in legal_moves:
			var result = engine.play_move(selected_square, square)
			if result == 0 or result == 1 or result >= 8:
				board.move_piece_animated(selected_square, square)
			
			board.clear_highlights()
			state = State.IDLE
			selected_square = ""
			legal_moves = []
		else:
			# If clicked on another own piece, select it instead. Else deselect.
			var piece = engine.get_piece_at(square)
			if piece != -1 and piece % 2 == engine.get_side_to_move():
				selected_square = square
				legal_moves = engine.get_legal_moves(square)
				board.highlight_squares(legal_moves)
				board.show_selected_square(square)
			else:
				board.clear_highlights()
				state = State.IDLE
				selected_square = ""
				legal_moves = []
