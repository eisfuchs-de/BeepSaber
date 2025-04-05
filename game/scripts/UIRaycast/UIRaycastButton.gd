@tool
extends UIRaycastTarget
class_name UIRaycastButton

signal pressed(pos: Vector3)
signal repeated(pos: Vector3)
signal released(pos: Vector3)

@export var size := Vector2(0.25, 0.0625):
	set(s):
		size = s
		var shape := ($Collision as CollisionShape3D).shape as BoxShape3D
		shape.size.x = s.x
		shape.size.y = s.y
		(($BackPanel as MeshInstance3D).mesh as QuadMesh).size = size
		# avoid null pointer error when called before ready
		# this is ugly, but since buttons aren't getting resized very often,
		# it'll be fine.
		if back_shader != null:
			back_shader.set_shader_parameter(&"size", s)
@export var text := "Button":
	set(txt):
		text = txt
		(($Text as MeshInstance3D).mesh as TextMesh).text = txt

var back_shader: ShaderMaterial
var held := false

func _ready() -> void:
	var collision := ($Collision as CollisionShape3D).shape as BoxShape3D
	collision.size.x = size.x
	collision.size.y = size.y
	
	var back_panel := $BackPanel as MeshInstance3D
	var mesh := back_panel.mesh as QuadMesh
	mesh.size.x = size.x
	mesh.size.y = size.y
	back_shader = back_panel.material_override as ShaderMaterial
	
	var text_mesh := $Text as MeshInstance3D
	(text_mesh.mesh as TextMesh).text = text

func ui_raycast_hit_event(pos: Vector3, click: bool, release: bool) -> void:
	if click:
		if not held:
			pressed.emit((pos - position) / Vector3(size.x, size.y, 1.0))
		held = true
	elif release and held:
		released.emit((pos - position) / Vector3(size.x, size.y, 1.0))
		held = false
	elif held:
		repeated.emit((pos - position) / Vector3(size.x, size.y, 1.0))
	back_shader.set_shader_parameter(&"highlight", 1.0 + float(held))

func ui_raycast_exit() -> void:
	held = false
	back_shader.set_shader_parameter(&"highlight", 0.0)
