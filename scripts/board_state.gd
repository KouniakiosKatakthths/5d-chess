extends Node

enum GameResult { ONGOING, CHECKMATE, STALEMATE }

# The title size
var tile_size := 0.29
# The origin of the chessboard in the A1 tile
var pieces_origin := Vector3(-1.013, 0, -1.013)

var game_state: State = State.new()

# The board state stored in memory
var board := []

# The FEN string for a classic game
var default_game := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"

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

## Get the opposite color of the given one
## [param c]: The color that we want the opposite
## Return: The opposite color of the [param c]
func opposite(c: Piece.PieceColor) -> Piece.PieceColor:
	return Piece.PieceColor.BLACK if c == Piece.PieceColor.WHITE else Piece.PieceColor.WHITE

## Returns true if `color` has at least one legal move
## [param color]: The requested side
## Returns true if the [param color] side has valid moves, false otherwise
func has_any_legal_move(color: Piece.PieceColor) -> bool:
	for x in range(8):
		for y in range(8):
			var p: Piece = BoardState.board[x][y]
			if p == null or p.color != color:
				continue

			var from := Vector2i(x, y)
			var moves := BoardLogic.textbook_moves(p, from)

			for m in moves:
				if is_legal_after_simulation(p, m):
					return true

	return false


## Simulate a move on the board array only, and check king safety.
## [param piece]: The simulated requedted piece
## [param move]: The simulated movement
## Returns true if the move is valid, false otherwise
func is_legal_after_simulation(piece: Piece, move: Move) -> bool:
	# Save board + state
	var state_cache: State = BoardState.game_state.clone()
	var board_cache = BoardState.board.duplicate(true)
	var moved_cache := piece.has_moved

	var dir := 1 if piece.color == Piece.PieceColor.WHITE else -1

	# Apply capture (handle en passant)
	if move.is_en_passant:
		var captured_sq := Vector2i(move.to.x, move.to.y - dir)
		BoardState.board[captured_sq.x][captured_sq.y] = null
	else:
		# normal capture just gets overwritten by assignment below
		pass

	# Apply piece move on the array
	BoardState.board[move.from.x][move.from.y] = null
	BoardState.board[move.to.x][move.to.y] = piece
	piece.has_moved = true

	# Apply castling rook move on array (if needed)
	if move.is_castle:
		if move.to.x == 6:
			var rook = BoardState.board[7][move.from.y]
			BoardState.board[7][move.from.y] = null
			BoardState.board[5][move.from.y] = rook
		elif move.to.x == 2:
			var rook2 = BoardState.board[0][move.from.y]
			BoardState.board[0][move.from.y] = null
			BoardState.board[3][move.from.y] = rook2

	# Check king safety
	var king_sq = BoardLogic.find_king_square(piece.color)
	var illegal = BoardLogic.is_square_attacked(king_sq, BoardState.opposite(piece.color))

	# Restore
	BoardState.game_state = state_cache
	BoardState.board = board_cache
	piece.has_moved = moved_cache

	return not illegal

func evaluate_game_result() -> GameResult:
	var side := BoardState.game_state.side_to_move # after you flip turns
	var in_check := BoardLogic.is_in_check(side)
	var has_move = has_any_legal_move(side)

	if not has_move and in_check:
		return GameResult.CHECKMATE
	if not has_move and not in_check:
		return GameResult.STALEMATE

	return GameResult.ONGOING

func algebraic_to_square(s: String) -> Vector2i:
	if s.length() != 2:
		return Vector2i(-1, -1)

	var file := s[0].to_lower()
	var rank := s[1]

	var x := int(file.unicode_at(0) - "a".unicode_at(0))
	if x < 0 or x > 7:
		return Vector2i(-1, -1)

	if not rank.is_valid_int():
		return Vector2i(-1, -1)

	var r := int(rank)
	if r < 1 or r > 8:
		return Vector2i(-1, -1)

	var y := r - 1
	return Vector2i(x, y)


func _sync_has_moved_from_fen() -> void:
	# Default: assume moved (safe)
	for x in range(8):
		for y in range(8):
			var p: Piece = BoardState.board[x][y]
			if p:
				p.has_moved = true

	# Kings: if any castling right exists for that color, king has not moved
	var w_king := BoardState.piece_at(Vector2i(4,0))
	if w_king and w_king.type == Piece.PieceType.KING and w_king.color == Piece.PieceColor.WHITE:
		w_king.has_moved = not (BoardState.game_state.can_castle_wk or BoardState.game_state.can_castle_wq)

	var b_king := BoardState.piece_at(Vector2i(4,7))
	if b_king and b_king.type == Piece.PieceType.KING and b_king.color == Piece.PieceColor.BLACK:
		b_king.has_moved = not (BoardState.game_state.can_castle_bk or BoardState.game_state.can_castle_bq)

	# Rooks: if the matching castling right exists, that rook hasn't moved
	var w_rook_a := BoardState.piece_at(Vector2i(0,0))
	if w_rook_a and w_rook_a.type == Piece.PieceType.ROOK and w_rook_a.color == Piece.PieceColor.WHITE:
		w_rook_a.has_moved = not BoardState.game_state.can_castle_wq

	var w_rook_h := BoardState.piece_at(Vector2i(7,0))
	if w_rook_h and w_rook_h.type == Piece.PieceType.ROOK and w_rook_h.color == Piece.PieceColor.WHITE:
		w_rook_h.has_moved = not BoardState.game_state.can_castle_wk

	var b_rook_a := BoardState.piece_at(Vector2i(0,7))
	if b_rook_a and b_rook_a.type == Piece.PieceType.ROOK and b_rook_a.color == Piece.PieceColor.BLACK:
		b_rook_a.has_moved = not BoardState.game_state.can_castle_bq

	var b_rook_h := BoardState.piece_at(Vector2i(7,7))
	if b_rook_h and b_rook_h.type == Piece.PieceType.ROOK and b_rook_h.color == Piece.PieceColor.BLACK:
		b_rook_h.has_moved = not BoardState.game_state.can_castle_bk
