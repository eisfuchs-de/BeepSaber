extends PooledNode3D
class_name Cuttable

var speed: float
var beat: float

# used to release the cube once both of it's cut pieces have died off
# Note: serves no purpose for bombs
var _piece_death_count := 0

# overridden by bombs and cubes
func set_collision_disabled(_value: bool) -> void:
	return

# overriden by bombs, chain links and cubes
func cut(_saber_type: int, _cut_speed: Vector3, _cut_plane: Plane, _controller: BeepSaberController, _point: Vector3) -> void:
	return

# this too
func on_miss() -> void:
	return

func _on_cut_piece_died():
	_piece_death_count += 1
	if _piece_death_count >= 2:
		release()

func _physics_process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	transform.origin.z += speed * delta
	
	# enable collisions when cuttable gets close enough to player
	if global_transform.origin.z > -3.0:
		set_collision_disabled(false)
	
	# remove children that go to far
	if global_transform.origin.z > Constants.MISS_Z:
		on_miss()
