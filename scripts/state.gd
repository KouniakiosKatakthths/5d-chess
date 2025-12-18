class_name State
extends Node

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
