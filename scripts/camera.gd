class_name CameraScript
extends CharacterBody3D

# Ref to chessboard to be passed down to the drag_drop
@export var chessboard: ChessBoard;

# Get the camera 
@onready var camera: Camera3D = $Camera3D

# The movement speed of the camera
@export var camera_speed := 6.0
#The sensitivity of the mouse
@export var mouse_sensitivity := 0.20

# The picth of the camera 
var pitch_deg := 0.0
# Max and min pitch values
@export var min_pitch := -85.0
@export var max_pitch := 85.0

# If we are in free camera state
var free_camera := false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set initial pitch
	pitch_deg = rad_to_deg(rotation.x)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If not in free csmera state dont process movement
	if not free_camera:
		return;
	
	# Handle keyboard input movements
	var move := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): 	move.z += 1
	if Input.is_action_pressed("move_backwards"):   move.z -= 1
	if Input.is_action_pressed("move_left"):    	move.x -= 1
	if Input.is_action_pressed("move_right"):   	move.x += 1
	if Input.is_action_pressed("move_down"):    	move.y -= 1
	if Input.is_action_pressed("move_up"):      	move.y += 1
	
	# No movements 
	if move == Vector3.ZERO:
		return
	
	# Get the camera basis
	var cam_basis := camera.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	
	# Normalize
	forward = forward.normalized()
	right = right.normalized()
	
	# Calculate the movement of the camera
	var world_dir := (right * move.x) + (Vector3.UP * move.y) + (forward * move.z)
	
	# Applay the movement
	self.global_position += world_dir.normalized() * camera_speed * delta
	

func _unhandled_input(event: InputEvent) -> void:
	# If the event is a mouse button event about the RMB
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		# Set the state of the free cam 
		free_camera = event.pressed
		
		# Set the cursor depenting if the button is pressed or not
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED if free_camera 
			else Input.MOUSE_MODE_VISIBLE
		)
	
	# If the freecam is enabled and the event is a movement of the mouse
	if free_camera and event is InputEventMouseMotion:
		# Rotate the camera
		self.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		# Calculate the camera pitch
		pitch_deg -= event.relative.y * mouse_sensitivity
		pitch_deg = clamp(pitch_deg, min_pitch, max_pitch)
		self.rotation_degrees.x = pitch_deg
