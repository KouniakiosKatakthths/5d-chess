extends Node

# The title size
var tile_size := 0.29
# The origin of the chessboard in the A1 tile
var pieces_origin := Vector3(-1.013, 0, -1.013)

# Current side to play
var side_to_move := Piece.PieceColor.WHITE

# Castling rights
var can_castle_wk := true
var can_castle_wq := true
var can_castle_bk := true
var can_castle_bq := true

# En passant target square (the square a pawn could capture into), or null
var en_passant: Variant = null

# Counters
var halfmove_clock := 0
var fullmove_number := 1

# The board state stored in memory
var board := []

# The FEN string for a classic game
var default_game := "RNBQKBNR/PPPPPPPP/8/8/8/8/pppppppp/rnbqkbnr"

## Checks if the requested coords are inside the chessboard [br]
## [param sq]: The request coords [br]
## Returns true if its inside, false otherwise
func in_bounds(sq: Vector2i) -> bool:
	return sq.x >= 0 and sq.x < 8 and sq.y >= 0 and sq.y < 8

## Get the the piece at a giver location [br]
## [param sq]: The desired grid coords
func piece_at(sq: Vector2i) -> Piece:
	if not in_bounds(sq): return null
	return board[sq.x][sq.y]

## Init the board with null values everywhere 
func init_board_array() -> void:
	board.resize(8)
	for x in range(8):
		board[x] = []
		board[x].resize(8)
		for y in range(8):
			board[x][y] = null

## Checks if the piece at the target grid coord is an enemy of the giver piece [br]
## [param piece]: The piece that we want to know [br]
## [param sq]: The target grid coord [br]
## Returns true if the piece at the location is enemy, false otherwise
func is_enemy(piece: Piece, sq: Vector2i) -> bool:
	var p := piece_at(sq)
	return p != null and p.color != piece.color

## Move the piece that is located on [param from] 
## [param fron]: Old location of the piece
## [param to]: Target location for the piece
func move_piece(from: Vector2i, to: Vector2i) -> void:
	var piece: Piece = BoardState.piece_at(from)
	if piece == null: return
	BoardState.board[from.x][from.y] = null
	BoardState.board[to.x][to.y] = piece

	var pos := BoardState.square_to_world_center(to)
	pos.y = BoardState.pieces_origin.y
	piece.global_position = pos
	piece.has_moved = true

## Converts from grid coords to word coords [br]
## [param sq]: The grid coords [br]
## Returns: The global position coords
func square_to_world_center(sq: Vector2i) -> Vector3:
	return Vector3(
		pieces_origin.x + sq.x * tile_size,
		pieces_origin.y,
		pieces_origin.z + sq.y * tile_size
	)

## Check if the target square is empty [br]
## [param sq]: The grid coords [br]
## Returns: True if the position is empty, false otherwise
func is_empty(sq: Vector2i) -> bool:
	return piece_at(sq) == null

## Converts from words coords to grid coords [br]
## [param world]: The world coords to convert from [br]
## Retuns: The grid coords 
func world_to_square_center(world: Vector3) -> Vector2i:
	return Vector2i(
		round((world.x - pieces_origin.x) / tile_size - (tile_size / 2)),
		round((world.z - pieces_origin.z) / tile_size - (tile_size / 2))
	)
