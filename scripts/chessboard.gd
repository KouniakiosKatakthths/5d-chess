class_name ChessBoard
extends Node3D

# Get the root of the pieces
@onready var pieces_root: Node3D = $pieces_root

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
	
	for y in range(0, 8):
		# Get the row string
		var row := rows[y]
		
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

func try_move(piece_node: Node3D, move: Move) -> bool:
	if not BoardState.in_bounds(move.from) or not BoardState.in_bounds(move.to): return false

	var piece := piece_node as Piece
	if piece == null: return false
	if BoardState.piece_at(move.from) != piece: return false

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

	# CHeck for castling move
	check_castle(move)

	# Snap to grid
	var pos := BoardState.square_to_world_center(move.to)
	pos.y = BoardState.pieces_origin.y
	piece.global_position = pos
	
	# Check for en passant
	check_en_passant(piece, selected, dir)

	# Set the has moved flag
	piece.has_moved = true;

	return true

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
func try_capture(move: Move, dir: int):
	# Check if its en passant capture
	if move.is_en_passant:
		var captured_sq := Vector2i(move.to.x, move.to.y - dir)
		var captured_piece: Piece = BoardState.board[captured_sq.x][captured_sq.y]
		if captured_piece != null:
			captured_piece.queue_free()
			
		BoardState.board[captured_sq.x][captured_sq.y] = null
	
	# Normal capture
	var captured := BoardState.piece_at(move.to)
	if captured != null:
		captured.queue_free()

## Check if the movement creates an en passant possibility
## [param piece]: The moved piece
## [param move]: The target movement
## [param dir]: The direction of the movement
func check_en_passant(piece: Piece, move: Move, dir: int):
	# Reset en passant memory
	BoardState.en_passant = null
	# Mark the tile as en passan in case the pawn moved twice
	if piece.type == Piece.PieceType.PAWN and abs(move.to.y - move.from.y) == 2:
		BoardState.en_passant = Vector2i(move.from.x, move.from.y + dir)

func check_castle(move: Move):
	if move.is_castle:
		if move.to.x == 6: # king-side
			BoardState.move_piece(Vector2i(7, move.from.y), Vector2i(5, move.from.y))
		elif move.to.x == 2: # queen-side
			BoardState.move_piece(Vector2i(0, move.from.y), Vector2i(3, move.from.y))

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
