class_name Move
extends Node

var from: Vector2i
var to: Vector2i

var promotion_type := Piece.PieceType.QUEEN 

var is_castle := false
var is_en_passant := false
