extends Panel

@export var chessboard: ChessBoard 
@onready var label := $Label
@onready var play_again = $Button

func _ready() -> void:
	self.visible = false
	chessboard.game_over.connect(on_game_over)
	chessboard.draw.connect(on_draw)
	
	play_again.pressed.connect(on_play_again_pressed)


func on_game_over(winner: Piece.PieceColor) -> void:
	self.visible = true

	if winner == Piece.PieceColor.WHITE:
		label.text = "WHITE WINS\nCHECKMATE"
	else:
		label.text = "BLACK WINS\nCHECKMATE"


func on_draw(reason: String) -> void:
	self.visible = true
	label.text = "DRAW\n" + reason

func on_play_again_pressed() -> void:
	self.visible = false
	chessboard.reset_game()
