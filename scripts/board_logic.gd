extends Node

## Holds Lamdas that build the avalable "textbook" positions of each piece
var movement_matrix := {}

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
				slide_movement(piece, from, d, moves)
			
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
			var two := from + Vector2i(0, dir * 2)
			if (BoardState.in_bounds(two) and 
				BoardState.in_bounds(one) and 
				BoardState.is_empty(one) and 
				BoardState.is_empty(two) and 
				not piece.has_moved):
					
				var move := Move.new()
				move.from = from
				move.to = two
				
				moves.append(move)
			
			# En passant capture move
			if BoardState.en_passant != null:
				for dx in [-1, 1]:
					var ep_to := from + Vector2i(dx, dir)
					if ep_to == BoardState.en_passant:
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
## [param piece]: The desired piece
## [param from]: Starting position in grid coords
## [param dir]: The target direction
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

func is_square_attacked(target: Vector2i, by_color: Piece.PieceColor) -> bool:
	for x in range(8):
		for y in range(8):
			var p: Piece = BoardState.board[x][y]
			if p == null or p.color != by_color:
				continue
			if piece_attacks_square(p, Vector2i(x,y), target):
				return true
	return false

func piece_attacks_square(p: Piece, from: Vector2i, target: Vector2i) -> bool:
	match p.type:
		Piece.PieceType.PAWN:
			var dir := 1 if p.color == Piece.PieceColor.WHITE else -1
			return target == from + Vector2i(-1, dir) or target == from + Vector2i(1, dir)

		Piece.PieceType.KNIGHT:
			for d in [Vector2i(1,2),Vector2i(2,1),Vector2i(2,-1),Vector2i(1,-2),
					  Vector2i(-1,-2),Vector2i(-2,-1),Vector2i(-2,1),Vector2i(-1,2)]:
				if from + d == target: return true
			return false

		Piece.PieceType.KING:
			return abs(target.x - from.x) <= 1 and abs(target.y - from.y) <= 1

		Piece.PieceType.ROOK:
			return _ray_attacks(from, target, [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)])

		Piece.PieceType.BISHOP:
			return _ray_attacks(from, target, [Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)])

		Piece.PieceType.QUEEN:
			return _ray_attacks(from, target, [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
											   Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)])
	return false

func _ray_attacks(from: Vector2i, target: Vector2i, dirs: Array[Vector2i]) -> bool:
	for d in dirs:
		var sq := from + d
		while BoardState.in_bounds(sq):
			if sq == target: return true
			if not BoardState.is_empty(sq): break
			sq += d
	return false
