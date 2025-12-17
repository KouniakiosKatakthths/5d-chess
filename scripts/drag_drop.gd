extends Camera3D

# The collition layers been used
const LAYER_BOARD := 1
const LAYER_PIECE := 2

# The piece been dragged
var dragging: Node3D = null

# Starting position of the piece
var start_pos := Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	# If RMB freelook is held, don't drag pieces
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): return
	
	# Try to pickup a piece if LMB is pressed
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pick_piece(event.position)
		else:	# Drop a piece if LMB is released
			drop_piece(event.position)
	#
	## Try to drag a piece if mouse is down
	if event is InputEventMouseMotion and dragging:
		drag_move(event.position)


func pick_piece(mouse_pos: Vector2) -> void:
	# Create raycast with target the piece layer
	var hit := raycast(mouse_pos, LAYER_PIECE)
	
	# Nothing hit
	if hit.is_empty(): return
	
	# Get the piece root
	var piece_root: Node3D = hit.collider.get_parent()
	if piece_root == null: return
	
	start_pos = piece_root.global_position
	# Set the draggin piece
	dragging = piece_root
	
	# Apply once for the hover effect
	drag_move(mouse_pos)


func drag_move(mouse_pos: Vector2) -> void:
	# No dragging target
	if dragging == null: return
	
	# Get the board point that the mouse is hovering
	var bp = board_point(mouse_pos)
	if bp == null:
		revert() 
		return

	var target = bp
	target.y = BoardUtilities.pieces_origin.y + 0.1
	dragging.global_position = target

func drop_piece(mouse_pos: Vector2) -> void:
	# No dragging target
	if dragging == null: return

	# Get the board point
	var bp = board_point(mouse_pos)
	if bp == null: return
	
	# Get the tile from board point
	var to_sq := BoardUtilities.world_to_square_center(bp)
	# Out of board? revert
	if to_sq.x < 0 or to_sq.x > 7 or to_sq.y < 0 or to_sq.y > 7: 
		revert()
		return
	
	# Conevrt back to global that are centered around a tile
	var grid_coord := BoardUtilities.square_to_world_center(to_sq)
	grid_coord.y = BoardUtilities.pieces_origin.y		# Set original elevation
	dragging.global_position = grid_coord
	
	# No dragging object
	dragging = null

func board_point(mouse_pos: Vector2) -> Variant:
	var hit := raycast(mouse_pos, LAYER_BOARD)
	if hit.is_empty(): return null
		
	return hit.position

func raycast(mouse_pos: Vector2, mask: int) -> Dictionary:
	# Project a ray from the mouse to detect an pieces
	var ray_length = 1000
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * ray_length
	var space_state = get_world_3d().direct_space_state

	# Params for intersect_ray
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collision_mask = mask
	params.collide_with_areas = true  # Set to true to include Area nodes
	
	# Raycast result
	var result = space_state.intersect_ray(params)
	
	return result

# Revert piece back to original position
func revert() -> void:
	dragging.global_position = start_pos
	dragging = null
