extends Camera3D

# Get the board class from the root
@onready var board := $"." as Board

const LAYER_BOARD := 1 << 1
const LAYER_PIECE := 1 << 2

# The piece been dragged
var dragging: Node3D = null

func _unhandled_input(event: InputEvent) -> void:
	# If RMB freelook is held, don't drag pieces
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return
	
	# Try to pickup a piece if LMB is pressed
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#_pick_piece(event.position)
		#else:	# Drop a piece if LMB is released
			#_drop_piece()
	#
	## Try to drag a piece if mouse is down
	#if event is InputEventMouseMotion and dragging:
		#_drag_move(event.position)


func _pick_piece(mouse_pos: Vector2) -> void:
	# Create raycast with target the piece layer
	var hit := _raycast(mouse_pos, LAYER_PIECE)
	# Nothing hit
	if hit.is_empty():
		return

	#var collider = hit["collider"]
	#var piece_root: Node3D = null
#
	## If collider is an Area3D, assume its parent is the piece root
	#if collider is Area3D:
		#piece_root = collider.get_parent() as Node3D
	#elif collider is Node3D:
		#piece_root = collider as Node3D
#
	#if piece_root == null:
		#return
#
	## Optional: ask BoardManager if this piece can be picked (turn, etc.)
	## if not board_manager.can_pick(piece_root): return
#
	#dragging = piece_root
	#start_pos = dragging.global_position
	#start_square = board_manager.world_to_square(start_pos)
#
	#var board_point = _board_point(mouse_pos)
	#if board_point == null:
		#dragging = null
		#return
#
	#grabbed_offset = dragging.global_position - board_point

func _raycast(mouse_pos: Vector2, mask: int) -> Dictionary:
	# Project a ray from the mouse to detect an pieces
	var from = self.project_ray_origin(mouse_pos)
	var dir = self.project_ray_normal(mouse_pos)
	# Target location of ray
	var to = from + dir * 2000.0
	
	# Project the ray
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	
	# Find intersections
	params.collision_mask = mask
	return space.intersect_ray(params)
