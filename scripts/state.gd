class_name State
extends Resource

func clone() -> State:
	var s := State.new()
	s.side_to_move = side_to_move
	s.can_castle_wk = can_castle_wk
	s.can_castle_wq = can_castle_wq
	s.can_castle_bk = can_castle_bk
	s.can_castle_bq = can_castle_bq
	s.en_passant = en_passant # Vector2i is value-type, ok
	s.halfmove_clock = halfmove_clock
	s.fullmove_number = fullmove_number
	s.game_finished = game_finished
	return s

# Current side to play
var side_to_move := Piece.PieceColor.WHITE

# Castling rights
var can_castle_wk := true
var can_castle_wq := true
var can_castle_bk := true
var can_castle_bq := true

var game_finished := false

# En passant target square (the square a pawn could capture into), or null
var en_passant: Variant = null

# Counters
var halfmove_clock := 0
var fullmove_number := 1
