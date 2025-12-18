class_name ChessBoard
extends Node3D

# Get the root of the pieces
@onready var pieces_root: Node3D = $pieces_root

# When the sides change
signal turn_changed(side_to_move: Piece.PieceColor)

# The white pieces prefabs
@export_group("White Pieces")
@export var white_pawn: PackedScene
@export var white_rook: PackedScene
@export var white_knight: PackedScene
@export var white_bishop: PackedScene
@export var white_queen: PackedScene
@export var white_king: PackedScene

# The black pieces prefabs
@export_group("Black Pieces")
@export var black_pawn: PackedScene
@export var black_rook: PackedScene
@export var black_knight: PackedScene
@export var black_bishop: PackedScene
@export var black_queen: PackedScene
@export var black_king: PackedScene

@export_group("Highlights")
@export var tile_highlight: PackedScene
@export var tile_capture: PackedScene

# An array that holds all of the highlights
var highlights: Array

# Temp variable for holding gamestate
var state_cache: State;
var board_cache: Array;
var piece_moved_cache: bool

func _ready() -> void:
	game_from_fen(BoardState.default_game)

# Parses a FEN string to create a game
func game_from_fen(fen: String) -> void:
	clear_pieces()
	BoardState.init_board_array()

	# Get only the piece locations from the FEN string
	var pieces_positions := fen.strip_edges().split(" ")[0]
	# Get the rows of the FEN string
	var rows := pieces_positions.split("/")
	# Must have 8 rows
	if rows.size() != 8:
		push_error("Invalid FEN: expected 8 ranks")
		return
	
	for fen_row in range(8):
		var y := 7 - fen_row
		
		# Get the row string
		var row := rows[fen_row]
		
		var x := 0;
		# For every character in the row
		for c in row:
			# An int is present
			if c.is_valid_int():
				var num := int(c);
				
				# The number is not correct 
				if num < 1 or num > 8:
					push_error("Invalid FEN: Expected number betwing 1 and 8, on row: ", y)
					return
					
				# Empty tiles so go forward
				x += num;
				continue;
			
			# Try to get the piece that corrisponds to the character
			var piece := fen_char_to_scene(c)
			if piece == null:
				push_error("Invalid FEN: Invalid piece character: \"", c ,"\" on row: ", y)
			
			spawn(piece, Vector2i(x, y))
			x += 1

# Spawn a piece to the word
func spawn(scene: PackedScene, sq: Vector2i) -> void:
	var piece: Node3D = scene.instantiate()
	pieces_root.add_child(piece)

	var pos = BoardState.square_to_world_center(sq)
	piece.global_position = pos

	BoardState.board[sq.x][sq.y] = piece

func clear_highlights() -> void:
	for h in highlights:
		if is_instance_valid(h):
			h.queue_free()
	highlights.clear()

func try_move(piece_node: Node3D, move: Move) -> bool:
	if not BoardState.in_bounds(move.from) or not BoardState.in_bounds(move.to): return false

	var piece := piece_node as Piece
	if piece == null: return false
	if BoardState.piece_at(move.from) != piece: return false
	#if BoardState.game_state.side_to_move != piece.color: return false

	# Save the current state
	state_cache = BoardState.game_state.clone()
	board_cache = BoardState.board.duplicate(true)

	# Find the direction of the piece
	var dir := 1 if piece.color == Piece.PieceColor.WHITE else -1

	# Get the textbook moves
	var selected = get_movement(piece, move)
	if selected == null: return false
	
	# Try to capture pawn at the target
	try_capture(selected, dir)
	
	# Update board
	BoardState.board[move.from.x][move.from.y] = null
	BoardState.board[move.to.x][move.to.y] = piece

	# Check for castling move
	var did_capture = check_castle(selected)
	var is_pawn := piece.type == Piece.PieceType.PAWN
	
	# Incrise the halfmove counter or reset
	if did_capture or is_pawn:
		BoardState.game_state.halfmove_clock = 0
	else:
		BoardState.game_state.halfmove_clock += 1

	# Snap to grid
	var pos := BoardState.square_to_world_center(move.to)
	pos.y = BoardState.pieces_origin.y
	piece.global_position = pos
	
	# Check for en passant
	check_en_passant(piece, selected, dir)

	# Set the has moved flag
	piece_moved_cache = piece.has_moved
	piece.has_moved = true;
	
	# Update the castling rights
	update_castling_rights(piece, move.from)

	var king_sq := BoardLogic.find_king_square(piece.color)
		
	if BoardLogic.is_square_attacked(king_sq, BoardState.opposite(piece.color)):
		BoardState.game_state = state_cache
		BoardState.board = board_cache
		piece.has_moved = piece_moved_cache;
		return false
		
	# Promotion
	if piece.type == Piece.PieceType.PAWN:
		var last_rank := 7 if piece.color == Piece.PieceColor.WHITE else 0
		if move.to.y == last_rank:
			promote_pawn(piece, move.to, selected.promotion_type)	
	
	var was_black := BoardState.game_state.side_to_move == Piece.PieceColor.BLACK
	# Flip the board
	BoardState.game_state.side_to_move = BoardState.opposite(BoardState.game_state.side_to_move)
	
	# Incrise the fullmove counter when the previus player was black
	if was_black: BoardState.game_state.fullmove_number += 1
	
	emit_signal("turn_changed", BoardState.game_state.side_to_move)
	
	# Find the game result
	var result := BoardState.evaluate_game_result()
	match result:
		BoardState.GameResult.CHECKMATE:
			print("Checkmate! Winner:", BoardState.opposite(BoardState.game_state.side_to_move))
		BoardState.GameResult.STALEMATE:
			print("Stalemate! Draw.")
		_: pass
	
	return true

func show_legal_move_highlights(piece: Piece, from: Vector2i) -> void:
	clear_highlights()

	# 1) get textbook moves
	var moves := BoardLogic.textbook_moves(piece, from)

	# 2) filter to only LEGAL moves (don’t leave king in check)
	for m in moves:
		if BoardState.is_legal_after_simulation(piece, m):
			var is_capture := (not BoardState.is_empty(m.to)) or m.is_en_passant
			spawn_highlight(m.to, is_capture)

func spawn_highlight(sq: Vector2i, is_capture: bool) -> void:
	var scene := tile_capture if (is_capture and tile_capture) else tile_highlight
	if scene == null:
		return

	var h: Node3D = scene.instantiate()
	add_child(h)

	var pos := BoardState.square_to_world_center(sq)
	pos.y = BoardState.pieces_origin.y + 0.01
	h.global_position = pos

	highlights.append(h)

## Check is the requested movement is valid
## [param piece]: The target piece
## [param move]: The requested move
## Returns: The movement that satisfy the request in success or null in fail
func get_movement(piece: Piece, move: Move) -> Variant:
	# Get all avaliable moves from the starting pos
	var moves := BoardLogic.textbook_moves(piece, move.from)
	
	# Get the move that satisfy the request
	var selected: Move = null
	for m in moves:
		if m.to == move.to:
			selected = m
			break

	return selected

## Try to capture a piece
## [param move]: The move that is selected by the user
## [param dir]: The movement direction (Matters for pawns)
## Returns true if a piece was captured or false otherwise
func try_capture(move: Move, dir: int) -> bool:
	# Check if its en passant capture
	if move.is_en_passant:
		var captured_sq := Vector2i(move.to.x, move.to.y - dir)
		var captured_piece: Piece = BoardState.board[captured_sq.x][captured_sq.y]
		if captured_piece != null:
			captured_piece.queue_free()
			
		BoardState.board[captured_sq.x][captured_sq.y] = null
		return true
	
	# Normal capture
	var captured := BoardState.piece_at(move.to)
	if captured != null:
		captured.queue_free()
		return true
	
	return false

## Check if the movement creates an en passant possibility
## [param piece]: The moved piece
## [param move]: The target movement
## [param dir]: The direction of the movement
func check_en_passant(piece: Piece, move: Move, dir: int):
	# Reset en passant memory
	BoardState.game_state.en_passant = null
	# Mark the tile as en passan in case the pawn moved twice
	if piece.type == Piece.PieceType.PAWN and abs(move.to.y - move.from.y) == 2:
		BoardState.game_state.en_passant = Vector2i(move.from.x, move.from.y + dir)

func check_castle(move: Move):
	if move.is_castle:
		if move.to.x == 6: # king-side
			BoardState.move_piece(Vector2i(7, move.from.y), Vector2i(5, move.from.y))
		elif move.to.x == 2: # queen-side
			BoardState.move_piece(Vector2i(0, move.from.y), Vector2i(3, move.from.y))

## If the king or the rook was moved remove the castling rights
## [param piece]: The king or rook piece
## [param from]: Rook old location
func update_castling_rights(piece: Piece, from: Vector2i) -> void:
	if piece.type == Piece.PieceType.KING:
		if piece.color == Piece.PieceColor.WHITE:
			BoardState.game_state.can_castle_wk = false
			BoardState.game_state.can_castle_wq = false
		else:
			BoardState.game_state.can_castle_bk = false
			BoardState.game_state.can_castle_bq = false

	if piece.type == Piece.PieceType.ROOK:
		if piece.color == Piece.PieceColor.WHITE:
			if from == Vector2i(0,0): BoardState.game_state.can_castle_wq = false
			if from == Vector2i(7,0): BoardState.game_state.can_castle_wk = false
		else:
			if from == Vector2i(0,7): BoardState.game_state.can_castle_bq = false
			if from == Vector2i(7,7): BoardState.game_state.can_castle_bk = false

# Clears the board
func clear_pieces() -> void:
	for child in pieces_root.get_children():
		child.queue_free()

# Maps charaters to piece prefabs
func fen_char_to_scene(ch: String) -> PackedScene:
	match ch:
		"p": return black_pawn
		"r": return black_rook
		"n": return black_knight
		"b": return black_bishop
		"q": return black_queen
		"k": return black_king

		"P": return white_pawn
		"R": return white_rook
		"N": return white_knight
		"B": return white_bishop
		"Q": return white_queen
		"K": return white_king
		_:   return null

## Get scene for a piece for the promotion
## [param color]: The piece color
## [parap t]: The requested type
## Return: The screen of the new piece
func scene_for_piece(color: Piece.PieceColor, t: Piece.PieceType) -> PackedScene:
	if color == Piece.PieceColor.WHITE:
		match t:
			Piece.PieceType.QUEEN:  return white_queen
			Piece.PieceType.ROOK:   return white_rook
			Piece.PieceType.BISHOP: return white_bishop
			Piece.PieceType.KNIGHT: return white_knight
	else:
		match t:
			Piece.PieceType.QUEEN:  return black_queen
			Piece.PieceType.ROOK:   return black_rook
			Piece.PieceType.BISHOP: return black_bishop
			Piece.PieceType.KNIGHT: return black_knight

	return null

## Promote a pawn to an other piece
func promote_pawn(pawn: Piece, to_sq: Vector2i, promotion_type: Piece.PieceType) -> void:
	# Only allow real promotion pieces
	if promotion_type not in [
		Piece.PieceType.QUEEN,
		Piece.PieceType.ROOK,
		Piece.PieceType.BISHOP,
		Piece.PieceType.KNIGHT
	]:
		promotion_type = Piece.PieceType.QUEEN

	var scene := scene_for_piece(pawn.color, promotion_type)
	if scene == null:
		promotion_type = Piece.PieceType.QUEEN
		scene = scene_for_piece(pawn.color, promotion_type)

	# Remove pawn node
	pawn.queue_free()

	# Spawn promoted piece node
	var new_piece: Piece = scene.instantiate() as Piece
	pieces_root.add_child(new_piece)

	var pos := BoardState.square_to_world_center(to_sq)
	pos.y = BoardState.pieces_origin.y
	new_piece.global_position = pos

	new_piece.has_moved = true

	# Update board reference
	BoardState.board[to_sq.x][to_sq.y] = new_piece
