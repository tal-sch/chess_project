extends Node
class_name ChessEngineWrapper

signal move_made(src, dst, result)
signal game_reset()

var native_engine = null
var is_native = false

# Mock state
var _board_state: Dictionary = {}
var _side_to_move: int = 1 # 1=white, 0=black

# Piece codes
enum Piece {
	PAWN = 0,
	KNIGHT = 1,
	ROOK = 2,
	BISHOP = 3,
	QUEEN = 4,
	KING = 5
}

enum PieceColor {
	BLACK = 0,
	WHITE = 1
}

enum MoveResult {
	VALID = 0,
	CHECK = 1,
	INVALID_SOURCE = 2,
	INVALID_DEST = 3,
	INVALID_MOVE = 4,
	CHECKMATE = 8
}

func _ready():
	if ClassDB.class_exists("ChessEngine"):
		# Using a generic instantiate for unknown classes
		native_engine = ClassDB.instantiate("ChessEngine")
		if native_engine:
			is_native = true
			print("Native ChessEngine loaded successfully.")
	
	if not is_native:
		print("Falling back to GDScript mock engine.")
		new_game()

func new_game():
	if is_native:
		native_engine.new_game()
	else:
		_side_to_move = 1
		_board_state.clear()
		_setup_mock_board()
	game_reset.emit()

func get_piece_at(square: String) -> int:
	if is_native:
		return native_engine.get_piece_at(square)
	else:
		return _board_state.get(square, -1)

func get_legal_moves(square: String) -> PackedStringArray:
	if is_native:
		return native_engine.get_legal_moves(square)
	else:
		return _get_mock_legal_moves(square)

func play_move(src: String, dst: String) -> int:
	if is_native:
		var result = native_engine.play_move(src, dst)
		move_made.emit(src, dst, result)
		return result
	else:
		return _play_mock_move(src, dst)

func play_bot_move(difficulty: int) -> Dictionary:
	if is_native:
		var result = native_engine.play_bot_move(difficulty)
		if result.has("src") and result.has("dst"):
			move_made.emit(result["src"], result["dst"], result["result"])
		return result
	else:
		return {}

func get_side_to_move() -> int:
	if is_native:
		return native_engine.get_side_to_move()
	else:
		return _side_to_move

# --- MOCK IMPLEMENTATION BELOW ---

func _setup_mock_board():
	# White pieces
	_board_state["a1"] = Piece.ROOK * 2 + PieceColor.WHITE
	_board_state["b1"] = Piece.KNIGHT * 2 + PieceColor.WHITE
	_board_state["c1"] = Piece.BISHOP * 2 + PieceColor.WHITE
	_board_state["d1"] = Piece.QUEEN * 2 + PieceColor.WHITE
	_board_state["e1"] = Piece.KING * 2 + PieceColor.WHITE
	_board_state["f1"] = Piece.BISHOP * 2 + PieceColor.WHITE
	_board_state["g1"] = Piece.KNIGHT * 2 + PieceColor.WHITE
	_board_state["h1"] = Piece.ROOK * 2 + PieceColor.WHITE
	
	for i in range(8):
		var file = String.chr("a".unicode_at(0) + i)
		_board_state[file + "2"] = Piece.PAWN * 2 + PieceColor.WHITE
		_board_state[file + "7"] = Piece.PAWN * 2 + PieceColor.BLACK
	
	# Black pieces
	_board_state["a8"] = Piece.ROOK * 2 + PieceColor.BLACK
	_board_state["b8"] = Piece.KNIGHT * 2 + PieceColor.BLACK
	_board_state["c8"] = Piece.BISHOP * 2 + PieceColor.BLACK
	_board_state["d8"] = Piece.QUEEN * 2 + PieceColor.BLACK
	_board_state["e8"] = Piece.KING * 2 + PieceColor.BLACK
	_board_state["f8"] = Piece.BISHOP * 2 + PieceColor.BLACK
	_board_state["g8"] = Piece.KNIGHT * 2 + PieceColor.BLACK
	_board_state["h8"] = Piece.ROOK * 2 + PieceColor.BLACK

func _get_mock_legal_moves(square: String) -> PackedStringArray:
	var moves = PackedStringArray()
	if not _board_state.has(square):
		return moves
	
	var piece_code = _board_state[square]
	var color = piece_code % 2
	
	if color != _side_to_move:
		return moves
	
	# Basic mock logic: allow moving anywhere on the board that doesn't contain a piece of the same color
	for r in range(1, 9):
		for f in range(8):
			var file = String.chr("a".unicode_at(0) + f)
			var target = file + str(r)
			if target != square:
				var target_piece = _board_state.get(target, -1)
				if target_piece == -1 or target_piece % 2 != color:
					moves.append(target)
	
	return moves

func _play_mock_move(src: String, dst: String) -> int:
	if not _board_state.has(src):
		return MoveResult.INVALID_SOURCE
	
	var piece_code = _board_state[src]
	if piece_code % 2 != _side_to_move:
		return MoveResult.INVALID_SOURCE
		
	var legal = _get_mock_legal_moves(src)
	if not dst in legal:
		return MoveResult.INVALID_DEST
		
	# Execute move
	_board_state[dst] = piece_code
	_board_state.erase(src)
	
	# Swap side
	_side_to_move = 1 - _side_to_move
	
	var result = MoveResult.VALID
	move_made.emit(src, dst, result)
	return result
