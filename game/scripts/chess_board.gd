extends Node3D
class_name ChessBoard

const SQUARE_SIZE = 1.0
const BOARD_OFFSET = Vector3(-3.5, 0, -3.5)
const PIECE_SCALES = {
	0: Vector3(0.636, 0.636, 0.636), # Pawn
	1: Vector3(0.808, 0.808, 0.808), # Knight
	2: Vector3(0.609, 0.609, 0.609), # Rook
	3: Vector3(0.933, 0.933, 0.933), # Bishop
	4: Vector3(0.894, 0.894, 0.894), # Queen
	5: Vector3(1.0, 1.0, 1.0)        # King
}
const GLOBAL_PIECE_SCALE = 1.3

@export var highlight_material: StandardMaterial3D
var white_piece_mat: StandardMaterial3D
var black_piece_mat: StandardMaterial3D

var piece_scenes = {
	0: {}, # Black
	1: {}  # White
}

var spawned_pieces: Dictionary = {}
var active_highlights: Array[Node3D] = []
var last_move_highlights: Array[Node3D] = []
var selected_highlight: MeshInstance3D

@onready var engine = get_node("/root/ChessEngine")

var hover_highlight: MeshInstance3D

func _ready():
	if not highlight_material:
		highlight_material = load("res://assets/materials/square_highlight.tres")
		if not highlight_material:
			highlight_material = StandardMaterial3D.new()
			highlight_material.albedo_color = Color(0.05, 0.4, 0.1, 1.0)
			highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			
	# Init piece materials
	white_piece_mat = StandardMaterial3D.new()
	white_piece_mat.albedo_color = Color(0.82, 0.80, 0.76) # Slightly muted ivory to prevent blowout
	white_piece_mat.roughness = 0.15 # Polished ivory/stone
	white_piece_mat.metallic = 0.05
	white_piece_mat.clearcoat_enabled = true
	white_piece_mat.clearcoat = 0.5

	black_piece_mat = StandardMaterial3D.new()
	black_piece_mat.albedo_color = Color(0.12, 0.1, 0.1)
	black_piece_mat.roughness = 0.2 # Matte polished obsidian
	black_piece_mat.metallic = 0.15
	black_piece_mat.clearcoat_enabled = true
	black_piece_mat.clearcoat = 0.5
	
	_load_piece_scenes()
	_generate_procedural_board()
	_generate_board_labels()
	
	# Create hover highlight
	hover_highlight = MeshInstance3D.new()
	var h_ring = TorusMesh.new()
	h_ring.inner_radius = SQUARE_SIZE * 0.40
	h_ring.outer_radius = SQUARE_SIZE * 0.45
	h_ring.rings = 32
	h_ring.ring_segments = 32
	hover_highlight.mesh = h_ring
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.3)
	h_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	h_mat.emission_enabled = true
	h_mat.emission = Color(1, 1, 1, 1)
	h_mat.emission_energy_multiplier = 0.5
	hover_highlight.material_override = h_mat
	add_child(hover_highlight)
	hover_highlight.visible = false
	
	# Create selected-piece highlight (amber ring)
	selected_highlight = MeshInstance3D.new()
	var s_ring = TorusMesh.new()
	s_ring.inner_radius = SQUARE_SIZE * 0.38
	s_ring.outer_radius = SQUARE_SIZE * 0.44
	s_ring.rings = 32
	s_ring.ring_segments = 32
	selected_highlight.mesh = s_ring
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.9, 0.7, 0.2, 1.0)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.9, 0.7, 0.2, 1)
	s_mat.emission_energy_multiplier = 0.6
	selected_highlight.material_override = s_mat
	add_child(selected_highlight)
	selected_highlight.visible = false

func _generate_board_labels():
	var label_color = Color(0.7, 0.65, 0.6)
	# File labels (a-h) along the front edge
	for i in range(8):
		var label = Label3D.new()
		label.text = String.chr("a".unicode_at(0) + i)
		label.font_size = 48
		label.modulate = label_color
		label.position = Vector3(i * SQUARE_SIZE + BOARD_OFFSET.x, 0.01, BOARD_OFFSET.z - 0.6)
		label.rotation_degrees = Vector3(-90, 0, 0)
		add_child(label)
	# Rank labels (1-8) along the left edge
	for i in range(8):
		var label = Label3D.new()
		label.text = str(i + 1)
		label.font_size = 48
		label.modulate = label_color
		label.position = Vector3(BOARD_OFFSET.x - 0.6, 0.01, i * SQUARE_SIZE + BOARD_OFFSET.z)
		label.rotation_degrees = Vector3(-90, 0, 0)
		add_child(label)


func update_hover(square: String):
	if square == "":
		hover_highlight.visible = false
	else:
		hover_highlight.visible = true
		var pos = square_to_world(square)
		pos.y = 0.04
		hover_highlight.position = pos

var currently_lifted_sq: String = ""

func show_selected_square(square: String):
	selected_highlight.visible = true
	var pos = square_to_world(square)
	pos.y = 0.04
	selected_highlight.position = pos
	
	selected_highlight.scale = Vector3(0.1, 0.1, 0.1)
	var t = create_tween()
	t.tween_property(selected_highlight, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
	if currently_lifted_sq != "":
		put_down_piece(currently_lifted_sq)
	pickup_piece(square)

func pickup_piece(square: String):
	if not spawned_pieces.has(square): return
	var piece = spawned_pieces[square]
	var base_scale = piece.get_meta("base_scale") if piece.has_meta("base_scale") else piece.scale
	
	var t = UIFX._get_tween(piece, "ui_tween_pickup")
	if not t: return
	t.set_parallel(true)
	t.tween_property(piece, "position:y", 0.4, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(piece, "scale", base_scale * 1.15, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	currently_lifted_sq = square

func put_down_piece(square: String):
	if currently_lifted_sq == square:
		currently_lifted_sq = ""
	if not spawned_pieces.has(square): return
	var piece = spawned_pieces[square]
	var base_scale = piece.get_meta("base_scale") if piece.has_meta("base_scale") else piece.scale
	var base_y = (PIECE_SCALES[engine.get_piece_at(square)/2].y * GLOBAL_PIECE_SCALE) / 2.0
	
	var t = UIFX._get_tween(piece, "ui_tween_pickup")
	if not t: return
	t.set_parallel(true)
	t.tween_property(piece, "position:y", base_y, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(piece, "scale", base_scale, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func clear_selected():
	selected_highlight.visible = false
	if currently_lifted_sq != "":
		put_down_piece(currently_lifted_sq)

func _load_piece_scenes():
	var base_path = "res://assets/models/3D_Chess_Pieces_Pack/models/"
	# White (1)
	piece_scenes[1][0] = load(base_path + "11_pawn_light.glb")
	piece_scenes[1][1] = load(base_path + "07_knight_light.glb")
	piece_scenes[1][2] = load(base_path + "09_rook_light.glb")
	piece_scenes[1][3] = load(base_path + "05_bishop_light.glb")
	piece_scenes[1][4] = load(base_path + "03_queen_light.glb")
	piece_scenes[1][5] = load(base_path + "01_king_light.glb")
	
	# Black (0)
	piece_scenes[0][0] = load(base_path + "12_pawn_dark.glb")
	piece_scenes[0][1] = load(base_path + "08_knight_dark.glb")
	piece_scenes[0][2] = load(base_path + "10_rook_dark.glb")
	piece_scenes[0][3] = load(base_path + "06_bishop_dark.glb")
	piece_scenes[0][4] = load(base_path + "04_queen_dark.glb")
	piece_scenes[0][5] = load(base_path + "02_king_dark.glb")

func _generate_procedural_board():
	var board_parent = Node3D.new()
	board_parent.name = "BoardMesh"
	add_child(board_parent)
	
	# Light Wood (Darkened) Square Material
	var light_mat = StandardMaterial3D.new()
	var light_noise = FastNoiseLite.new()
	light_noise.noise_type = FastNoiseLite.TYPE_VALUE
	light_noise.frequency = 0.08
	var light_tex = NoiseTexture2D.new()
	light_tex.noise = light_noise
	light_tex.seamless = true
	var light_grad = Gradient.new()
	light_grad.add_point(0.0, Color(0.35, 0.22, 0.15)) # Darker warm brown
	light_grad.add_point(1.0, Color(0.50, 0.35, 0.22))
	light_tex.color_ramp = light_grad
	light_mat.albedo_texture = light_tex
	light_mat.uv1_scale = Vector3(0.2, 1.0, 1.5)
	light_mat.roughness = 0.15
	light_mat.metallic = 0.05
	light_mat.clearcoat_enabled = true
	light_mat.clearcoat = 1.0
	light_mat.clearcoat_roughness = 0.05

	# Dark Wood (Espresso) Square Material
	var dark_mat = StandardMaterial3D.new()
	var dark_noise = FastNoiseLite.new()
	dark_noise.noise_type = FastNoiseLite.TYPE_VALUE
	dark_noise.frequency = 0.08
	var dark_tex = NoiseTexture2D.new()
	dark_tex.noise = dark_noise
	dark_tex.seamless = true
	var dark_grad = Gradient.new()
	dark_grad.add_point(0.0, Color(0.08, 0.04, 0.02)) # Almost black espresso
	dark_grad.add_point(1.0, Color(0.15, 0.08, 0.05))
	dark_tex.color_ramp = dark_grad
	dark_mat.albedo_texture = dark_tex
	dark_mat.uv1_scale = Vector3(0.2, 1.0, 1.5)
	dark_mat.roughness = 0.15
	dark_mat.metallic = 0.05
	dark_mat.clearcoat_enabled = true
	dark_mat.clearcoat = 1.0
	dark_mat.clearcoat_roughness = 0.05
	
	# Solid dark base under the tiles to act as an outline/grout
	var base_mesh = MeshInstance3D.new()
	var base_box = BoxMesh.new()
	base_box.size = Vector3(SQUARE_SIZE * 8.0, 0.18, SQUARE_SIZE * 8.0)
	base_mesh.mesh = base_box
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.02, 0.01, 0.01) # Pure dark
	base_mesh.material_override = base_mat
	base_mesh.position = Vector3(BOARD_OFFSET.x + 3.5 * SQUARE_SIZE, -0.11, BOARD_OFFSET.z + 3.5 * SQUARE_SIZE)
	board_parent.add_child(base_mesh)
	
	for file in range(8):
		for rank in range(8):
			var sq_mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			# Shrink tile slightly to reveal the dark base underneath as an outline
			box.size = Vector3(SQUARE_SIZE * 0.95, 0.2, SQUARE_SIZE * 0.95)
			sq_mesh.mesh = box
			
			var is_light = (file + rank) % 2 != 0
			sq_mesh.material_override = light_mat if is_light else dark_mat
			
			# Stagger UVs so they don't look perfectly tiled
			if is_light:
				sq_mesh.material_override.uv1_offset = Vector3(file * 0.1, rank * 0.1, 0)
			else:
				sq_mesh.material_override.uv1_offset = Vector3(file * 0.1, rank * 0.1, 0)
			
			sq_mesh.position = Vector3(file * SQUARE_SIZE, -0.1, rank * SQUARE_SIZE) + BOARD_OFFSET
			board_parent.add_child(sq_mesh)
	
	# Rich Mahogany Wooden Border
	var border_mesh = MeshInstance3D.new()
	var border_box = BoxMesh.new()
	border_box.size = Vector3(SQUARE_SIZE * 8.4, 0.15, SQUARE_SIZE * 8.4)
	border_mesh.mesh = border_box
	var border_mat = StandardMaterial3D.new()
	
	var wood_noise = FastNoiseLite.new()
	wood_noise.noise_type = FastNoiseLite.TYPE_VALUE
	wood_noise.frequency = 0.1
	var wood_tex = NoiseTexture2D.new()
	wood_tex.noise = wood_noise
	var wood_grad = Gradient.new()
	wood_grad.add_point(0.0, Color(0.15, 0.08, 0.03))
	wood_grad.add_point(1.0, Color(0.25, 0.12, 0.05))
	wood_tex.color_ramp = wood_grad
	
	border_mat.albedo_texture = wood_tex
	border_mat.uv1_scale = Vector3(0.1, 2.0, 0.1) # Stretch to look like grain
	border_mat.roughness = 0.3
	border_mat.clearcoat_enabled = true
	border_mesh.material_override = border_mat
	border_mesh.position = Vector3(BOARD_OFFSET.x + 3.5 * SQUARE_SIZE, -0.15, BOARD_OFFSET.z + 3.5 * SQUARE_SIZE)
	board_parent.add_child(border_mesh)

func square_to_world(square: String) -> Vector3:
	var file = square.unicode_at(0) - "a".unicode_at(0)
	var rank = int(square.substr(1, 1)) - 1
	# Pieces rest on y=0
	return Vector3(file * SQUARE_SIZE, 0.0, rank * SQUARE_SIZE) + BOARD_OFFSET

func world_to_square(pos: Vector3) -> String:
	var local_pos = pos - BOARD_OFFSET
	var file_idx = roundi(local_pos.x / SQUARE_SIZE)
	var rank_idx = roundi(local_pos.z / SQUARE_SIZE)
	
	if file_idx < 0 or file_idx > 7 or rank_idx < 0 or rank_idx > 7:
		return ""
		
	var file_char = String.chr("a".unicode_at(0) + file_idx)
	var rank_char = str(rank_idx + 1)
	return file_char + rank_char

func clear_board():
	for p in spawned_pieces.values():
		p.queue_free()
	spawned_pieces.clear()
	clear_highlights()
	clear_last_move()

func refresh_board():
	clear_board()
	spawn_all_pieces()

func spawn_all_pieces():
	for file in range(8):
		for rank in range(8):
			var file_char = String.chr("a".unicode_at(0) + file)
			var square = file_char + str(rank + 1)
			
			var piece_code = engine.get_piece_at(square)
			if piece_code != -1:
				_spawn_piece(square, piece_code)

func _spawn_piece(square: String, piece_code: int):
	var type = piece_code / 2
	var color = piece_code % 2
	
	if piece_scenes.has(color) and piece_scenes[color].has(type):
		var scene = piece_scenes[color][type]
		if not scene: return
		var piece_instance = scene.instantiate()
		add_child(piece_instance)
		var base_pos = square_to_world(square)
		base_pos.y += (PIECE_SCALES[type].y * GLOBAL_PIECE_SCALE) / 2.0
		piece_instance.position = base_pos
		piece_instance.scale = PIECE_SCALES[type] * GLOBAL_PIECE_SCALE
		piece_instance.set_meta("base_scale", piece_instance.scale)
		piece_instance.set_meta("piece_code", piece_code)
		
		# Rotate black pieces to face white
		if color == 0:
			piece_instance.rotation_degrees.y = 180
		
		# Apply premium materials
		var mat = white_piece_mat if color == 1 else black_piece_mat
		_apply_material_to_meshes(piece_instance, mat)
			
		spawned_pieces[square] = piece_instance

func _apply_material_to_meshes(node: Node, mat: Material):
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_to_meshes(child, mat)

func _animate_piece_arc(piece: Node3D, target_pos: Vector3, on_complete: Callable = Callable(), capture_target: Node3D = null):
	var type = 0
	if piece.has_meta("piece_code"):
		type = piece.get_meta("piece_code") / 2
	target_pos.y = (PIECE_SCALES[type].y * GLOBAL_PIECE_SCALE) / 2.0
	
	var mid_pos = (piece.position + target_pos) / 2.0
	mid_pos.y += 0.8 # lift height
	
	var base_scale = piece.get_meta("base_scale") if piece.has_meta("base_scale") else piece.scale
	
	var t = UIFX._get_tween(piece, "ui_tween_pos")
	if not t: return
	
	t.tween_property(piece, "position", mid_pos, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(piece, "position", target_pos, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Squash on landing
	if not UIFX.reduce_motion:
		var squash_scale = base_scale * Vector3(1.1, 0.85, 1.1)
		t.tween_property(piece, "scale", squash_scale, 0.05 * UIFX.anim_speed).set_trans(Tween.TRANS_SINE)
		t.tween_property(piece, "scale", base_scale, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
		if capture_target:
			# Small bounce on capture
			t.parallel().tween_property(piece, "position:y", target_pos.y + 0.3, 0.1 * UIFX.anim_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.chain().tween_property(piece, "position:y", target_pos.y, 0.15 * UIFX.anim_speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	if on_complete.is_valid():
		t.tween_callback(on_complete)

func move_piece_animated(from_sq: String, to_sq: String):
	if not spawned_pieces.has(from_sq):
		return
		
	var piece = spawned_pieces[from_sq]

	# Special Case 1: Castling (King moves to corner rook square)
	var is_castling = false
	var king_dst = ""
	var rook_dst = ""
	
	if from_sq == "e1":
		if to_sq == "a1" and engine.get_piece_at("a1") == -1 and (engine.get_piece_at("c1") / 2) == 5:
			is_castling = true; king_dst = "c1"; rook_dst = "d1"
		elif to_sq == "h1" and engine.get_piece_at("h1") == -1 and (engine.get_piece_at("g1") / 2) == 5:
			is_castling = true; king_dst = "g1"; rook_dst = "f1"
	elif from_sq == "e8":
		if to_sq == "a8" and engine.get_piece_at("a8") == -1 and (engine.get_piece_at("c8") / 2) == 5:
			is_castling = true; king_dst = "c8"; rook_dst = "d8"
		elif to_sq == "h8" and engine.get_piece_at("h8") == -1 and (engine.get_piece_at("g8") / 2) == 5:
			is_castling = true; king_dst = "g8"; rook_dst = "f8"

	if is_castling and spawned_pieces.has(to_sq):
		var king = piece
		var rook = spawned_pieces[to_sq]

		spawned_pieces.erase(from_sq)
		spawned_pieces.erase(to_sq)
		spawned_pieces[king_dst] = king
		spawned_pieces[rook_dst] = rook

		_animate_piece_arc(king, square_to_world(king_dst))
		_animate_piece_arc(rook, square_to_world(rook_dst))
		return

	# Special Case 2: En Passant (Pawn moves diagonally to empty square)
	var is_diagonal = from_sq[0] != to_sq[0]
	var dest_empty = not spawned_pieces.has(to_sq)
	var moving_piece_type = engine.get_piece_at(to_sq) / 2
	if is_diagonal and dest_empty and moving_piece_type == 0:
		var cap_sq = to_sq[0] + from_sq[1]
		if spawned_pieces.has(cap_sq):
			var captured_pawn = spawned_pieces[cap_sq]
			
			if captured_pawn.has_meta("piece_code"):
				var code = captured_pawn.get_meta("piece_code")
				get_node("/root/Main/GameManager").piece_captured.emit(code, code % 2)
				
			spawned_pieces.erase(cap_sq)
			var cap_tween = create_tween().set_parallel(true)
			cap_tween.tween_property(captured_pawn, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			cap_tween.tween_property(captured_pawn, "position:y", -0.5, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			cap_tween.chain().tween_callback(captured_pawn.queue_free)

	spawned_pieces.erase(from_sq)
	
	var is_capture = spawned_pieces.has(to_sq)
	var captured = null
	if is_capture:
		captured = spawned_pieces[to_sq]
		
		if captured.has_meta("piece_code"):
			var code = captured.get_meta("piece_code")
			get_node("/root/Main/GameManager").piece_captured.emit(code, code % 2)
		
		# Shake the captured piece before it shrinks
		UIFX.shake(captured)
		
		var cap_tween = create_tween().set_parallel(true)
		cap_tween.tween_property(captured, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		cap_tween.tween_property(captured, "position:y", -0.5, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		cap_tween.chain().tween_callback(captured.queue_free)
		
	spawned_pieces[to_sq] = piece
	
	# Check for Promotion on arrival (piece is now Queen in engine)
	var is_promo = (to_sq[1] == "8" or to_sq[1] == "1") and engine.get_piece_at(to_sq) / 2 == 4
	if is_promo:
		_animate_piece_arc(piece, square_to_world(to_sq), func():
			if is_instance_valid(piece):
				piece.queue_free()
				spawned_pieces.erase(to_sq)
				_spawn_piece(to_sq, engine.get_piece_at(to_sq))
		, captured)
	else:
		_animate_piece_arc(piece, square_to_world(to_sq), Callable(), captured)

func highlight_squares(squares: PackedStringArray):
	clear_highlights()
	for sq in squares:
		var highlight = MeshInstance3D.new()
		# Premium 3D ring instead of flat square
		var ring_mesh = TorusMesh.new()
		ring_mesh.inner_radius = (SQUARE_SIZE * 0.35)
		ring_mesh.outer_radius = (SQUARE_SIZE * 0.42)
		ring_mesh.rings = 32
		ring_mesh.ring_segments = 32
		highlight.mesh = ring_mesh
		highlight.material_override = highlight_material
		
		var pos = square_to_world(sq)
		pos.y = 0.04 # Slightly above the board surface
		highlight.position = pos
		highlight.scale = Vector3.ONE
		add_child(highlight)
		active_highlights.append(highlight)
		
		var pulse_t = create_tween().set_loops()
		pulse_t.tween_property(highlight, "scale", Vector3(1.05, 1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_t.tween_property(highlight, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func clear_highlights():
	for h in active_highlights:
		if is_instance_valid(h):
			h.queue_free()
	active_highlights.clear()
	clear_selected()

func show_last_move(from_sq: String, to_sq: String):
	clear_last_move()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.15, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.5, 0.15, 1)
	mat.emission_energy_multiplier = 0.3
	for sq in [from_sq, to_sq]:
		var highlight = MeshInstance3D.new()
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(SQUARE_SIZE * 0.92, SQUARE_SIZE * 0.92)
		highlight.mesh = plane_mesh
		highlight.material_override = mat
		var pos = square_to_world(sq)
		pos.y = 0.02
		highlight.position = pos
		add_child(highlight)
		last_move_highlights.append(highlight)

func clear_last_move():
	for h in last_move_highlights:
		if is_instance_valid(h):
			h.queue_free()
	last_move_highlights.clear()

var check_highlight: MeshInstance3D

func show_check(side: int):
	# Shake board
	UIFX.shake(self)
	
	# Find king
	var king_code = 11 if side == 1 else 10 # 5 * 2 + side
	var king_sq = ""
	for sq in spawned_pieces:
		if engine.get_piece_at(sq) == king_code:
			king_sq = sq
			break
			
	if king_sq == "": return
	
	if not check_highlight or not is_instance_valid(check_highlight):
		check_highlight = MeshInstance3D.new()
		var p = PlaneMesh.new()
		p.size = Vector2(SQUARE_SIZE, SQUARE_SIZE)
		check_highlight.mesh = p
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.1, 0.1, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(1, 0.1, 0.1, 1)
		check_highlight.material_override = mat
		add_child(check_highlight)
	
	check_highlight.position = square_to_world(king_sq)
	check_highlight.position.y = 0.03
	check_highlight.visible = true
	
	# Pulse it red
	check_highlight.scale = Vector3(1.2, 1.2, 1.2)
	check_highlight.transparency = 0.0
	var t = create_tween()
	t.tween_property(check_highlight, "scale", Vector3(1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
func clear_check():
	if check_highlight and is_instance_valid(check_highlight):
		check_highlight.visible = false
