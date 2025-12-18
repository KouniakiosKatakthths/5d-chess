class_name Piece
extends Node3D

# Enums for piece properties
enum PieceColor { WHITE, BLACK }
enum PieceType { PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING }

@export var color: PieceColor
@export var type: PieceType

var has_moved := false;
