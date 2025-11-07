extends Cuttable
class_name Bomb

@export var min_speed := 0.5
@onready var collision_shape := $Area3D/CollisionShape3D as CollisionShape3D
@onready var mi := $BombAnimation/Mesh/Icosphere as MeshInstance3D

func _ready() -> void:
	var _mat := mi.material_override as StandardMaterial3D
	if Settings.simple_shaders:
		_mat.metallic = 0.0
		_mat.metallic_specular = 0.5
		_mat.roughness = 1.0
	else:
		_mat.metallic = 1.0
		_mat.metallic_specular = 1.0
		_mat.roughness = 0.21

func set_collision_disabled(value: bool) -> void:
	collision_shape.disabled = value

@warning_ignore("unused_parameter")
func cut(saber_type: int, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController, point: Vector3) -> void:
	Scoreboard.bad_cut(transform.origin, "bomb")
	queue_free()

func on_miss() -> void:
	queue_free()

func spawn(info: BombInfo, current_beat: float) -> void:
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute / 60.0 * Map.speed_factor
	beat = info.beat
	
	var distance: float = info.beat - current_beat
	
	transform.origin.x = Constants.LANE_DISTANCE * float(info.line_index) + Constants.LANE_ZERO_X
	transform.origin.y = Constants.LANE_DISTANCE * float(info.line_layer) + Constants.LAYER_ZERO_Y
	transform.origin.z = -distance * Constants.BEAT_DISTANCE
	var anim := $AnimationPlayer as AnimationPlayer
	var anim_speed := Map.current_difficulty.note_jump_movement_speed / 9.0
	anim.speed_scale = maxf(min_speed, anim_speed)
	anim.play(&"Spawn")
