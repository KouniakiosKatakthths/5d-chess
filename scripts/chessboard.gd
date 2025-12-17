extends Node3D

# Get the root of the pieces
@onready var pieces_root: Node3D = $pieces_root

# The title size
@export var title_size := 0.29

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

# The board state stored in memory
var board := []

# The FEN string for a classic game
var default_game := "RNBQKBNR/PPPPPPPP/8/8/8/8/pppppppp/rnbqkbnr"

func _ready() -> void:
	game_from_fen(default_game)

# Init the board with null values everywhere 
func init_board_array() -> void:
	board.resize(8)
	for x in range(8):
		board[x] = []
		board[x].resize(8)
		for y in range(8):
			board[x][y] = null

# Parses a FEN string to create a game
func game_from_fen(fen: String) -> void:
	clear_pieces()
	init_board_array()

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
			
			_spawn(piece, Vector2i(x, y))
			x += 1

# Spawn a piece to the word
func _spawn(scene: PackedScene, sq: Vector2i) -> void:
	var piece: Node3D = scene.instantiate()
	pieces_root.add_child(piece)

	var pos = square_to_world_center(sq)
	piece.global_position = pos

	board[sq.x][sq.y] = piece

# Clears the board
func clear_pieces() -> void:
	for child in pieces_root.get_children():
		child.queue_free()

# Converts from grid coords to word coords
func square_to_world_center(sq: Vector2i) -> Vector3:
	return Vector3(
		pieces_root.position.x + sq.x * title_size,
		pieces_root.position.y,
		pieces_root.position.z + sq.y * title_size
	)

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
