extends Panel
class_name SettingsPanel

signal apply()
@export var beepsaber_game : BeepSaber_Game

var saber_control: OptionButton
var glare_control: CheckButton
var saber_tail_control: CheckButton
var saber_thickness: HSlider
var cut_blocks: CheckButton
var extra_particle_effects: CheckButton
var use_gpu_particles: CheckButton
var d_background: CheckButton
var simple_shaders: CheckButton
var antialias_option: OptionButton
var left_saber_col: ColorPickerButton
var right_saber_col: ColorPickerButton
var show_debug_control: CheckButton
var mixed_reality_control: CheckButton
var explain_control: CheckButton
var show_collisions: CheckButton
var bombs_enabled_control: CheckButton
var ui_volume_slider: HSlider
var disable_map_color_control: CheckButton
var left_saber_posx_control: SpinBox
var left_saber_posy_control: SpinBox
var left_saber_posz_control: SpinBox
var left_saber_rotx_control: SpinBox
var left_saber_roty_control: SpinBox
var left_saber_rotz_control: SpinBox
var right_saber_posx_control: SpinBox
var right_saber_posy_control: SpinBox
var right_saber_posz_control: SpinBox
var right_saber_rotx_control: SpinBox
var right_saber_roty_control: SpinBox
var right_saber_rotz_control: SpinBox
var player_height_offset_control: SpinBox
var audio_master_control: HSlider
var audio_music_control: HSlider
var audio_sfx_control: HSlider
var spectator_view_control: CheckButton
var spectator_hud_control: CheckButton

var _play_ui_sound_demo := false

func _ready() -> void:
	UI_AudioEngine.attach_children(self)
	
	set_controls_from_settings()
	_play_ui_sound_demo = true
	
func set_controls_from_settings() -> void:
	saber_control = find_child("saber")
	saber_thickness = find_child("saber_thickness")
	saber_tail_control = find_child("saber_tail")
	left_saber_col = find_child("left_saber_col")
	right_saber_col = find_child("right_saber_col")

	cut_blocks = find_child("cut_blocks")
	extra_particle_effects = find_child("extra_particle_effects")
	use_gpu_particles = find_child("use_gpu_particles")
	show_collisions = find_child("show_collisions")
	glare_control = find_child("glare")
	d_background = find_child("d_background")
	simple_shaders = find_child("simple_shaders")
	antialias_option = find_child("antialias_option")
	disable_map_color_control = find_child("disable_map_color")

	mixed_reality_control = find_child("mixed_reality")
	explain_control = find_child("explain")
	show_debug_control = find_child("show_debug")
	player_height_offset_control = find_child("player_height_offset")
	bombs_enabled_control = find_child("bombs_enabled")
	spectator_view_control = find_child("spectator_view")
	spectator_hud_control = find_child("spectator_hud")

	audio_master_control = find_child("master_slider")
	ui_volume_slider = find_child("ui_volume_slider")
	audio_music_control = find_child("music_slider")
	audio_sfx_control = find_child("sfx_slider")

	var left_saber: HBoxContainer = find_child("left_saber_offset")
	left_saber_posx_control = left_saber.find_child("posx")
	left_saber_posy_control = left_saber.find_child("posy")
	left_saber_posz_control = left_saber.find_child("posz")
	left_saber_rotx_control = left_saber.find_child("rotx")
	left_saber_roty_control = left_saber.find_child("roty")
	left_saber_rotz_control = left_saber.find_child("rotz")

	var right_saber: HBoxContainer = find_child("right_saber_offset")
	right_saber_posx_control = right_saber.find_child("posx")
	right_saber_posy_control = right_saber.find_child("posy")
	right_saber_posz_control = right_saber.find_child("posz")
	right_saber_rotx_control = right_saber.find_child("rotx")
	right_saber_roty_control = right_saber.find_child("roty")
	right_saber_rotz_control = right_saber.find_child("rotz")

	saber_control.clear()
	for s in Settings.SABER_VISUALS:
		saber_control.add_item(s[0])
	
	show_collisions.button_pressed = get_tree().debug_collisions_hint
	show_collisions.visible = OS.is_debug_build()
	
	# set the selections to the loaded values
	await get_tree().process_frame

	if OS.get_name() == &"Web":
		# way too heavy for webxr
		glare_control.button_pressed = false
		Settings.glare = false
		glare_control.hide()
	else:
		glare_control.button_pressed = Settings.glare

	saber_thickness.value = Settings.thickness
	cut_blocks.button_pressed = Settings.cube_cuts_falloff
	extra_particle_effects.button_pressed = Settings.extra_particle_effects
	use_gpu_particles.disabled = !Settings.extra_particle_effects
	use_gpu_particles.button_pressed = Settings.use_gpu_particles
	left_saber_col.color = Settings.color_left
	right_saber_col.color = Settings.color_right
	saber_tail_control.button_pressed = Settings.saber_tail

	d_background.button_pressed = Settings.events
	simple_shaders.button_pressed = Settings.simple_shaders
	antialias_option.selected = Settings.antialias
	saber_control.select(Settings.saber_visual)
	show_debug_control.button_pressed = Settings.show_debug_info
	mixed_reality_control.button_pressed = Settings.mixed_reality
	explain_control.button_pressed = Settings.explain
	bombs_enabled_control.button_pressed = Settings.bombs_enabled
	ui_volume_slider.value = Settings.ui_volume
	disable_map_color_control.button_pressed = Settings.disable_map_color
	left_saber_posx_control.value = Settings.left_saber_offset_pos.x
	left_saber_posy_control.value = Settings.left_saber_offset_pos.y
	left_saber_posz_control.value = Settings.left_saber_offset_pos.z
	left_saber_rotx_control.value = Settings.left_saber_offset_rot.x
	left_saber_roty_control.value = Settings.left_saber_offset_rot.y
	left_saber_rotz_control.value = Settings.left_saber_offset_rot.z
	right_saber_posx_control.value = Settings.right_saber_offset_pos.x
	right_saber_posy_control.value = Settings.right_saber_offset_pos.y
	right_saber_posz_control.value = Settings.right_saber_offset_pos.z
	right_saber_rotx_control.value = Settings.right_saber_offset_rot.x
	right_saber_roty_control.value = Settings.right_saber_offset_rot.y
	right_saber_rotz_control.value = Settings.right_saber_offset_rot.z
	player_height_offset_control.value = Settings.player_height_offset
	audio_master_control.value = Settings.audio_master
	audio_music_control.value = Settings.audio_music
	audio_sfx_control.value = Settings.audio_sfx
	spectator_view_control.button_pressed = Settings.spectator_view
	spectator_hud_control.button_pressed = Settings.spectator_hud

	left_saber_col.get_popup().mouse_exited.connect(_on_saber_color_mouse_exited.bind(left_saber_col))
	right_saber_col.get_popup().mouse_exited.connect(_on_saber_color_mouse_exited.bind(right_saber_col))

func _restore_defaults() -> void:
	Settings.restore_defaults()
	set_controls_from_settings()

#settings down here
func _on_thickness_value_changed(value: float) -> void:
	Settings.thickness = value

func _on_cut_blocks_toggled(button_pressed: bool) -> void:
	Settings.cube_cuts_falloff = button_pressed

func _on_extra_particle_effects_toggled(button_pressed: bool) -> void:
	Settings.extra_particle_effects = button_pressed
	use_gpu_particles.disabled = !button_pressed

func _on_use_gpu_particles_toggled(button_pressed: bool) -> void:
	Settings.use_gpu_particles = button_pressed

func _on_left_saber_color_changed(color: Color) -> void:
	Settings.color_left = color

func _on_right_saber_color_changed(color: Color) -> void:
	Settings.color_right = color

func _on_saber_color_mouse_exited(color: ColorPickerButton) -> void:
	color.get_popup().hide()

func _on_saber_tail_toggled(button_pressed: bool) -> void:
	Settings.saber_tail = button_pressed

func _on_glare_toggled(button_pressed: bool) -> void:
	Settings.glare = button_pressed

func _on_d_background_toggled(button_pressed: bool) -> void:
	Settings.events = button_pressed

func _on_simple_shaders_toggled(button_pressed: bool) -> void:
	Settings.simple_shaders = button_pressed

func _on_antialias_selected(value: int) -> void:
	Settings.antialias = value

func _on_saber_item_selected(index: int) -> void:
	Settings.saber_visual = index

func _on_show_debug_toggled(button_pressed: bool) -> void:
	Settings.show_debug_info = button_pressed

func _on_mixed_reality_toggled(button_pressed: bool) -> void:
	Settings.mixed_reality = button_pressed
	MixedReality.set_mixed_reality()

func _on_explain_toggled(button_pressed: bool) -> void:
	Settings.explain = button_pressed

func _on_bombs_enabled_toggled(button_pressed: bool) -> void:
	Settings.bombs_enabled = button_pressed

func _on_ui_volume_slider_value_changed(value: float) -> void:
	UI_AudioEngine.set_volume(linear_to_db(float(value)/10.0))
	if _play_ui_sound_demo:
		UI_AudioEngine.play_click()
	
	Settings.ui_volume = value

func _on_left_saber_pos_x_changed(value: float) -> void:
	Settings.left_saber_offset_pos.x = value

func _on_left_saber_pos_y_changed(value: float) -> void:
	Settings.left_saber_offset_pos.y = value

func _on_left_saber_pos_z_changed(value: float) -> void:
	Settings.left_saber_offset_pos.z = value

func _on_left_saber_rot_x_changed(value: float) -> void:
	Settings.left_saber_offset_rot.x = value

func _on_left_saber_rot_y_changed(value: float) -> void:
	Settings.left_saber_offset_rot.y = value

func _on_left_saber_rot_z_changed(value: float) -> void:
	Settings.left_saber_offset_rot.z = value

func _on_right_saber_pos_x_changed(value: float) -> void:
	Settings.right_saber_offset_pos.x = value

func _on_right_saber_pos_y_changed(value: float) -> void:
	Settings.right_saber_offset_pos.y = value

func _on_right_saber_pos_z_changed(value: float) -> void:
	Settings.right_saber_offset_pos.z = value

func _on_right_saber_rot_x_changed(value: float) -> void:
	Settings.right_saber_offset_rot.x = value

func _on_right_saber_rot_y_changed(value: float) -> void:
	Settings.right_saber_offset_rot.y = value

func _on_right_saber_rot_z_changed(value: float) -> void:
	Settings.right_saber_offset_rot.z = value

func _on_player_height_offset_changed(value: float) -> void:
	Settings.player_height_offset = value

func _on_disable_map_color_toggled(toggled_on: bool) -> void:
	Settings.disable_map_color = toggled_on

func _force_update_show_coll_shapes(node: Node) -> void:
	# toggle enable to make engine show collision shapes
	if node is CollisionShape3D:
		var col := node as CollisionShape3D
		col.disabled = not col.disabled
		col.disabled = not col.disabled
	elif node is RayCast3D:
		var ray := node as RayCast3D
		ray.enabled = not ray.enabled
		ray.enabled = not ray.enabled
	
	for c in node.get_children():
		_force_update_show_coll_shapes(c)

func _on_show_collisions_toggled(button_pressed: bool) -> void:
	get_tree().debug_collisions_hint = button_pressed
	# must toggle 
	_force_update_show_coll_shapes(get_tree().root)

func _on_apply_pressed() -> void:
	Settings.save()
	apply.emit()
	left_saber_col.get_popup().hide()
	right_saber_col.get_popup().hide()


func _on_master_slider_value_changed(value: float) -> void:
	Settings.audio_master = value

func _on_music_slider_value_changed(value: float) -> void:
	Settings.audio_music = value

func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.audio_sfx = value

func _on_spectator_view_toggled(value: bool) -> void:
	Settings.spectator_view = value

func _on_spectator_hud_toggled(value: bool) -> void:
	Settings.spectator_hud = value


func _on_recenter_button_up() -> void:
	var recenter_button : Button = find_child("recenter")
	recenter_button.disabled = true
	recenter_button.text = "3.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "2.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "1.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "Recenter"
	recenter_button.disabled = false
	beepsaber_game.recenter()
