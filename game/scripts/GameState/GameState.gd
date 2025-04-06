extends Object
class_name GameState

var name := ""

func _init(state_name: String = ""):
	name = state_name

@warning_ignore("unused_parameter")
func _ready(game: BeepSaber_Game) -> void:
	return

@warning_ignore("unused_parameter")
func _physics_process(game: BeepSaber_Game) -> void:
	return
