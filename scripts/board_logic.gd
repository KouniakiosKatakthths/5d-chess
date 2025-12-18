extends Node

## Holds Lamdas that build the avalable "textbook" positions of each piece
var movement_matrix := {}
## Holds lamdas that calculate if a tile can be attached from a piece
var attacking_matrix := {}

func _ready() -> void:
	movement_matrix = {
		# Rook moves Up, Down, Left, Right
		Piece.PieceType.ROOK: func (piece: Piece, from: Vector2i) -> Array[Move]:
			var moves: Array[Move] = [];
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				slide_movement(piece, from, d, moves)
			
			return moves,
		
		# Knight can move 2 Up, Down, Left, Right and 1 Up, Down, Left, Right
		Piece.PieceType.KNIGHT: func (piece: Piece, from: Vector2i) -> Array[Move]:
			var moves: Array[Move] = [];
			for d in [Vector2i(1,2),Vector2i(2,1),Vector2i(2,-1),Vector2i(1,-2),
					  Vector2i(-1,-2),Vector2i(-2,-1),Vector2i(-2,1),Vector2i(-1,2)]:
				var sq = from + d
				if not BoardState.in_bounds(sq):
					continue
					
				if BoardState.is_empty(sq) or BoardState.is_enemy(piece, sq):
					var m := Move.new()
					m.from = from
					m.to = sq
					moves.append(m)
			
			return moves,
		
		# Bishop moves diagnally 
		Piece.PieceType.BISHOP: func (piece: Piece, from: Vector2i) -> Array[Move]:
			var moves: Array[Move] = [];
			for d in [Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
				slide_movement(piece, from, d, moves)
			
			return moves,
		
		# Queen can move everywhere expect 
		Piece.PieceType.QUEEN: func (piece: Piece, from: Vector2i) -> Array[Move]:
			var moves: Array[Move] = [];
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
					  Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
				slide_movement(piece, from, d, moves)
			
			return moves,
		
		# King can move around himself
		Piece.PieceType.KING: func (piece: Piece, from: Vector2i) -> Array[Move]:
			var moves: Array[Move] = [];
			# For left/right
			for dx in [-1,0,1]:
				# For up/down
				for dy in [-1,0,1]:
					# No movement
					if dx == 0 and dy == 0: continue
					
					# Offset
					var sq := from + Vector2i(dx,dy)
					if not BoardState.in_bounds(sq): continue
					
					if BoardState.is_empty(sq) or BoardState.is_enemy(piece, sq):
						var move := Move.new()
						move.from = from
						move.to = sq
						
						moves.append(move)
			
			# Castling check
			var y := from.y
			var enemy := BoardState.opposite(piece.color)
			
			# King cannot castle out of a check
			if not is_square_attacked(from, enemy):
				# Check if the king can perfrom a king-side slide
				var can_k := (piece.color == Piece.PieceColor.WHITE and BoardState.game_state.can_castle_wk) \
			 			or (piece.color == Piece.PieceColor.BLACK and BoardState.game_state.can_castle_bk)
				if can_k:
					# Squares between must be empty
					if BoardState.is_empty(Vector2i(5,y)) and BoardState.is_empty(Vector2i(6,y)):
						# Squares king crosses must not be attacked
						if not is_square_attacked(Vector2i(5,y), enemy) and not is_square_attacked(Vector2i(6,y), enemy):
							var m := Move.new()
							m.from = from
							m.to = Vector2i(6,y)
							m.is_castle = true
							moves.append(m)
				
				# Check if the king can perfrom a queen-side slide
				var can_q := (piece.color == Piece.PieceColor.WHITE and BoardState.game_state.can_castle_wq) \
			 				or (piece.color == Piece.PieceColor.BLACK and BoardState.game_state.can_castle_bq)
				if can_q:
					# Squares between must be empty
					if BoardState.is_empty(Vector2i(1,y)) and BoardState.is_empty(Vector2i(2,y)) and BoardState.is_empty(Vector2i(3,y)):
						# Squares king crosses must not be attacked
						if not is_square_attacked(Vector2i(3,y), enemy) and not is_square_attacked(Vector2i(2,y), enemy):
							var m2 := Move.new()
							m2.from = from
							m2.to = Vector2i(2,y)
							m2.is_castle = true
							moves.append(m2)
			
			return moves,
		
		# Pawn moves one up or captures up left/right
		Piece.PieceType.PAWN: func (piece: Piece, from: Vector2i) -> Array[Move]:
			var moves: Array[Move] = [];
			
			# Find the direction of the pawn
			var dir := 1 if piece.color == Piece.PieceColor.WHITE else -1
			
			# One step move
			var one := from + Vector2i(0, dir)
			if BoardState.in_bounds(one) and BoardState.is_empty(one):
				var move := Move.new()
				move.from = from
				move.to = one
				
				moves.append(move)
			
			# Calculate the double movement in the first time
			var start_rank := 1 if piece.color == Piece.PieceColor.WHITE else 6
			var two := from + Vector2i(0, dir * 2)
			if (BoardState.in_bounds(two) and 
				BoardState.in_bounds(one) and 
				BoardState.is_empty(one) and 
				BoardState.is_empty(two) and 
				from.y == start_rank):
					
				var move := Move.new()
				move.from = from
				move.to = two
				
				moves.append(move)
			
			# En passant capture move
			if BoardState.game_state.en_passant != null:
				for dx in [-1, 1]:
					var ep_to := from + Vector2i(dx, dir)
					if ep_to == BoardState.game_state.en_passant:
						var move := Move.new()
						move.from = from
						move.to = ep_to
						move.is_en_passant = true
						
						moves.append(move)
			
			# Captures
			for dx in [-1, 1]:
				var cap := from + Vector2i(dx, dir)
				if BoardState.in_bounds(cap) and BoardState.is_enemy(piece, cap):
					var move := Move.new()
					move.from = from
					move.to = cap
					
					moves.append(move)
					
			return moves,
	}
	attacking_matrix = {
		# Pawn can attack forward and left/right
		Piece.PieceType.PAWN: func(piece: Piece, from: Vector2i, to: Vector2i) -> bool:
			var dir := 1 if piece.color == Piece.PieceColor.WHITE else -1
			return to == from + Vector2i(-1, dir) or to == from + Vector2i(1, dir),
		
		# Knight can attack 2 forward, backward, left, right and 1 forward, backward, left, right
		Piece.PieceType.KNIGHT: func(_piece: Piece, from: Vector2i, to: Vector2i) -> bool:
			for d in [Vector2i(1,2),Vector2i(2,1),Vector2i(2,-1),Vector2i(1,-2),
					  Vector2i(-1,-2),Vector2i(-2,-1),Vector2i(-2,1),Vector2i(-1,2)]:
				if from + d == to: return true
			return false,
		
		# King can attack in an area around him
		Piece.PieceType.KING: func(_piece: Piece, from: Vector2i, to: Vector2i) -> bool:
			return abs(to.x - from.x) <= 1 and abs(to.y - from.y) <= 1,
		
		# Rook can attack forwards, backwords, left, right
		Piece.PieceType.ROOK: func(_piece: Piece, from: Vector2i, to: Vector2i) -> bool:
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				if slide_attacks(from, to, d):
					return true
				
			return false,
		
		# Bishop can attack sideways
		Piece.PieceType.BISHOP: func(_piece: Piece, from: Vector2i, to: Vector2i) -> bool:
			for d in [Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
				if slide_attacks(from, to, d):
					return true
				
			return false,
		
		# Queen can attack forwards, backwards, left, right and sideways
		Piece.PieceType.QUEEN: func(_piece: Piece, from: Vector2i, to: Vector2i) -> bool:
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
				   Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
				if slide_attacks(from, to, d):
					return true
				
			return false,
	}

## Gets a piece and its position on the chessboard and calculates all the textbook valid positons [br]
## [param piece]: The desired piece [br]
## [param from]: The piece current location [br]
## Retuns: An array with all the possible movements
func textbook_moves(piece: Piece, from: Vector2i) -> Array[Move]:
	# Invalid piece provited
	if piece == null: return []
	
	# Get the calculation lamda
	var fn = movement_matrix.get(piece.type, null)
	if fn == null: return []
	
	# Build the avaliable moves
	return fn.call(piece, from)

## Calculate all the avaliable movements for "slide" that can slide accross the chessboard [br]
## [param piece]: The desired piece [br]
## [param from]: Starting position in grid coords [br]
## [param dir]: The target direction [br]
## [param out]: Array of the valid locations 
func slide_movement(piece: Piece, from: Vector2i, dir: Vector2i, out: Array[Move]):
	# First step
	var sq := from + dir
	
	# While the coords are valid
	while BoardState.in_bounds(sq):
		var move = Move.new()
		move.from = from
		move.to = sq
		
		# If the target tile is empty appent it
		if BoardState.is_empty(sq):
			out.append(move)
		else:
			# Capture enemy if possible
			if BoardState.is_enemy(piece, sq):
				out.append(move)
			
			break # blocked
		
		# Step the movement
		sq += dir

## Gets the square the for selected color [br]
## [param color]: The color of the tagret pieces [br]
## Returns: The position of the king if its found
func find_king_square(color: Piece.PieceColor) -> Vector2i:
	for x in range(8):
		for y in range(8):
			var p: Piece = BoardState.board[x][y]
			if p and p.type == Piece.PieceType.KING and p.color == color:
				return Vector2i(x,y)
	return Vector2i(-1,-1)

## Checks if a tile can be attacked by a certen piece [br]
## [param target]: The target tile [br]
## [param by_color]: Spesify color [br]
## Return: True if the tile can be attacked, false otherwise
func is_square_attacked(target: Vector2i, by_color: Piece.PieceColor) -> bool:
	for x in range(8):
		for y in range(8):
			# Get the piece at the position
			var p: Piece = BoardState.board[x][y]
			if p == null or p.color != by_color: continue
			
			# if its enemy piece get its attack function
			var attack_fn = attacking_matrix.get(p.type, null)
			if attack_fn == null: continue;
			
			# If the selected piece can attack return true
			if attack_fn.call(p, Vector2i(x, y), target): return true;
			
	return false

## Calculate if a piece can attack a tile for a direction [br]
## [param from]: The starting tile [br]
## [param target]: The target tile [br]
## [param dir]: The direction of the piece
func slide_attacks(from: Vector2i, target: Vector2i, dir: Vector2i) -> bool:
	var sq := from + dir
	while BoardState.in_bounds(sq):
		if sq == target: return true
		if not BoardState.is_empty(sq): break
		sq += dir
	return false

## Checks if the king is in check
## [param color]: The target color king
func is_in_check(color: Piece.PieceColor) -> bool:
	var king_sq := find_king_square(color)
	if king_sq.x == -1:
		return false # or push_error
	return is_square_attacked(king_sq, BoardState.opposite(color))
