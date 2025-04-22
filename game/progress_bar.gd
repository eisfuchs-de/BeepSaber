extends Node3D
class_name ProgressBarIndicator

enum DisplayMode {
	Percent,
	MinutesSeconds,
	Value,
}

var how_full := 0.0
var max_full := 1.0

var label: TextMesh
var shader: ShaderMaterial

var mode: DisplayMode = DisplayMode.Value

func _ready() -> void:
	var bar_instance = $Bar as MeshInstance3D
	shader = bar_instance.material_override as ShaderMaterial

	var label_instance = $Label as MeshInstance3D
	label = label_instance.mesh as TextMesh

func set_value(value: float) -> void:
	how_full = value
	shader.set_shader_parameter(&"how_full", how_full / max_full)

	match mode:
		DisplayMode.Percent:
			label.text = "%d%%" % [how_full / max_full * 100.0]
		DisplayMode.MinutesSeconds:
			label.text = "%d:%02d / %d:%02d" % [how_full / 60, int(how_full) % 60, max_full / 60, int(max_full) % 60]
		DisplayMode.Value:
			label.text = "%d / %d" % [how_full, max_full]

func set_mode(new_mode: DisplayMode) -> void:
	mode = new_mode
	set_value(how_full)

func set_max_value(max_value: float) -> void:
	max_full = max_value
	if max_full == 0.0:
		max_full = 0.0000001
	set_value(how_full)
