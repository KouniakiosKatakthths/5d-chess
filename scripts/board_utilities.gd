extends Node

# The title size
var tile_size := 0.29
# The origin of the chessboard in the A1 tile
var pieces_origin := Vector3(-1.013, 0, -1.013)

# Converts from grid coords to word coords
func square_to_world_center(sq: Vector2i) -> Vector3:
	return Vector3(
		pieces_origin.x + sq.x * tile_size,
		pieces_origin.y,
		pieces_origin.z + sq.y * tile_size
	)

# Converts from words coords to grid coords
func world_to_square_center(world: Vector3) -> Vector2i:
	return Vector2i(
		round((world.x - pieces_origin.x) / tile_size - (tile_size / 2)),
		round((world.z - pieces_origin.z) / tile_size - (tile_size / 2))
	)
