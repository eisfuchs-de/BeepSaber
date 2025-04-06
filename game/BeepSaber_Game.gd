# This is a stand-alone version of the demo game Beep Saber. It started (and is still included)
# in the godot oculus quest toolkit (https://github.com/NeoSpark314/godot_oculus_quest_toolkit)
# But this stand-alone version as additional features and will be developed independently
# This file contains the main game logic for the BeepSaber demo implementation
extends Node3D
class_name BeepSaber_Game

signal current_gamestate(name: String)

var version := "0.5.0"

var gamestate_bootup := GameState.new("bootup")
var gamestate_mapcomplete := GameStateMapComplete.new("mapcomplete")
var gamestate_mapselection := GameStateMapSelection.new("mapselection")
var gamestate_newhighscore := GameStateNewHighScore.new("highscore")
var gamestate_paused := GameStatePaused.new("paused")
var gamestate_playing := GameStatePlaying.new("playing")
var gamestate_settings := GameStateSettings.new("settings")
var gamestate: GameState = gamestate_bootup

@onready var xr_origin := $XROrigin3D as XROrigin3D
@onready var left_controller := $XROrigin3D/LeftController as BeepSaberController
@onready var right_controller := $XROrigin3D/RightController as BeepSaberController
@onready var left_saber := $XROrigin3D/LeftController/LeftLightSaber as LightSaber
@onready var right_saber := $XROrigin3D/RightController/RightLightSaber as LightSaber
@onready var left_ui_raycast := $XROrigin3D/LeftController/LeftLightSaber/UIRaycast as UIRaycast
@onready var right_ui_raycast := $XROrigin3D/RightController/RightLightSaber/UIRaycast as UIRaycast
@onready var goggles_shader := ($XROrigin3D/XRCamera3D/VRGoggles as MeshInstance3D).material_override as ShaderMaterial
@onready var debug_info_label := $XROrigin3D/XRCamera3D/PlayerHead/DebugInfoLabel as MeshInstance3D

@onready var main_menu := $MainMenu_OQ_UI2DCanvas as OQ_UI2DCanvas
@onready var pause_menu := $PauseMenu_canvas as OQ_UI2DCanvas
@onready var pause_countdown := $Pause_countdown as OQ_UI2DLabel
@onready var settings_canvas := $Settings_canvas as OQ_UI2DCanvas
@onready var settings_panel := settings_canvas.ui_control as SettingsPanel
@onready var highscore_canvas := $Highscores_Canvas as OQ_UI2DCanvas
@onready var highscore_panel := highscore_canvas.ui_control as HighscorePanel
@onready var name_selector_canvas := $NameSelector_Canvas as OQ_UI2DCanvas
@onready var highscore_keyboard := $Keyboard_highscore as OQ_UI2DKeyboard
@onready var endscore := $EndScore as EndScore

@onready var points_label_driver := $Points_label_driver as PointsLabelDriver
@onready var event_driver := $event_driver as EventDriver

@onready var multiplier_label := $Multiplier_Label as MeshInstance3D
@onready var point_label := $Point_Label as MeshInstance3D
@onready var percent_indicator := $Percent_Indicator as PercentIndicator

@onready var map_source_dialogs := $MapSourceDialogs as Node3D
@onready var online_search_keyboard := $Keyboard_online_search as OQ_UI2DKeyboard

@onready var cube_template := preload("res://game/BeepCube/BeepCube.tscn").instantiate() as BeepCube

@onready var track := $Track as Node3D
@onready var standing_ground := $StandingGround as Floor

@onready var song_player := $SongPlayer as AudioStreamPlayer

@onready var menu := main_menu.ui_control as MainMenu


# There's an interesting issue where the AudioStreamPlayer's playback_position
# doesn't immediately return to 0.0 after restarting the song_player. This
# causes issues with restarting a map because the process_physics routine will
# execute for a times and attempt to process the map up to the playback_position
# prior to the AudioStreamPlayer restart. This bug can presents itself as notes
# persisting between map restarts.
# To remidy this issue, this flag is set to true when the map is restarted. The
# process_physics routine won't begin processing the map until after the
# AudioStreamPlayer has reset it's playback_position to zero. This flag is set
# to false once the AudioStreamPlayer reset is detected.
var _audio_synced_after_restart := false

var _in_wall := false

# location to store the custom offsets on the filesystem
const OFFSETS_FILEPATH = "user://custom_offsets.json"

# custom origin for the currently playing map
var origin_offset : float

#prevents the song for starting from the start when pausing and unpausing
var pause_position := 0.0

# load custom origin offset from filesystem
func load_offset(song_key : String) -> float:
	var file := FileAccess.open(OFFSETS_FILEPATH, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		file.close()
		var json_res := JSON.parse_string(text) as Dictionary
		if json_res:
			if json_res.has(song_key):
				return json_res[song_key]
			return 1.0

	else:
		vr.log_warning("Failed read offsets from %s (might not exist yet)" % OFFSETS_FILEPATH)

	return 1.0

# save custom origin offset to filesystem
func save_offset(song_key : String) -> void:
	var text := "{}"
	var file := FileAccess.open(OFFSETS_FILEPATH, FileAccess.READ)
	if file:
		text = file.get_as_text()
		file.close()

	var json_res := JSON.parse_string(text) as Dictionary
	if not json_res:
		vr.log_warning("Failed to read offsets from %s" % OFFSETS_FILEPATH)

	json_res[song_key] = origin_offset

	file = FileAccess.open(OFFSETS_FILEPATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_res, "   ", true))
		file.close()
	else:
		vr.log_error("Failed to write offsets to %s" % OFFSETS_FILEPATH)

func start_map(info: MapInfo, map_difficulty: DifficultyInfo) -> void:
	var map_filename := info.filepath + map_difficulty.beatmap_filename
	var map_data := vr.load_json_file(map_filename)
	
	if (map_data == null):
		vr.log_error("Could not read map data from " + map_filename)

	var lightshow_data := {}
	if map_difficulty.lightshow_filename:
		var lightshow_filename := info.filepath + map_difficulty.lightshow_filename
		lightshow_data = vr.load_json_file(lightshow_filename)
		if lightshow_data == null:
			vr.log_error("Could not read lightshow data from " + lightshow_filename)
			# set to empty dictionary so we don't get errors later
			lightshow_data = {}

	if not Map.load_beatmap(info, map_difficulty, map_data, lightshow_data):
		return
	
	origin_offset = load_offset(Map.current_info.get_key())
	xr_origin.transform.origin.z = origin_offset

	update_saber_colors(Map.color_left, Map.color_right)
	update_env_colors()
	if Map.event_stack.is_empty():
		event_driver.set_all_on(Map.env_color_left, Map.env_color_right, Map.env_color_left_boost, Map.env_color_right_boost)
	else:
		event_driver.set_all_off()
	
	vr.log_info("loading: " + info.filepath + info.song_filename)
	song_player.stream = AudioStreamOggVorbis.load_from_file(info.filepath + info.song_filename)
	
	_audio_synced_after_restart = false
	song_player.play(0.0)
	song_player.volume_db = 0.0
	_in_wall = false
	Scoreboard.restart()
	
	_display_points()
	percent_indicator.start_map()
	
	_clear_track()
	_transition_game_state(gamestate_playing)

# This function will transitioning the game from it's current state into
# the provided 'next_state'.
func _transition_game_state(next_state: GameState) -> void:
	if gamestate == gamestate_playing:
		save_offset(Map.current_info.get_key())

	if next_state == gamestate_mapselection:
		xr_origin.transform.origin.z = 1.0
		vr.log_info("Set origin back to 1.0")

	gamestate = next_state
	gamestate._ready(self)

	current_gamestate.emit(gamestate.name)

func show_MapSourceDialogs(showing: bool = true) -> void:
	map_source_dialogs.visible = showing
	for c in map_source_dialogs.get_children():
		if c is OQ_UI2DCanvas:
			(c as OQ_UI2DCanvas)._hide()
	if showing:
		var first_dialog := map_source_dialogs.get_child(0)
		if first_dialog is OQ_UI2DCanvas:
			(first_dialog as OQ_UI2DCanvas)._show()

# call this method to submit a new highscore to the database
func _submit_highscore(player_name: String) -> void:
	if gamestate == gamestate_newhighscore:
		Highscores.add_highscore(
			Map.current_info,
			Map.current_difficulty.difficulty_rank,
			player_name,
			Scoreboard.points)
			
		_transition_game_state(gamestate_mapcomplete)

func _check_and_update_saber(controller: BeepSaberController, saber: LightSaber) -> void:
	# to allow extending/sheething the saber while not playing a song
	if ((not song_player.playing)
		and (controller.ax_just_pressed() or controller.by_just_pressed())
		and (not saber._anim.is_playing())):
		if (saber.is_extended()): saber._hide()
		else: saber._show()
	
	# check for saber rumble (only when extended and not already rumbling)
	# this check is necessary to not overwrite a rumble set from somewhere else
	# (in this case it can come from cutting cubes)
	if not controller.is_simple_rumbling(): 
		if _in_wall:
			# weak rumble on both controllers when player is inside wall
			controller.simple_rumble(0.1, 0.1)
		elif saber.get_overlapping_areas().size() > 0 or saber.get_overlapping_bodies().size() > 0:
			# strong rumble when saber is cutting into wall or other saber
			controller.simple_rumble(0.5, 0.1)
		else:
			controller.simple_rumble(0.0, 0.1)

	if song_player.playing and controller == left_controller:
		origin_offset -= controller.stick_position().y * 0.02
		xr_origin.transform.origin.z = clamp(origin_offset, 0.0, 2.0)

func _physics_process(_dt: float) -> void:
	if debug_info_label.visible:
		var dbg_text := "FPS: %d\nCube Pool: %d free of %d\nLink Pool: %d free of %d" % [
			Engine.get_frames_per_second(),
			GlobalReferences.cube_pool.free_count(), GlobalReferences.cube_pool.total_count(),
			GlobalReferences.link_pool.free_count(), GlobalReferences.link_pool.total_count()]
		(debug_info_label.mesh as TextMesh).text = dbg_text
	
	gamestate._physics_process(self)
	
	_check_and_update_saber(left_controller, left_saber)
	_check_and_update_saber(right_controller, right_saber)

func _enter_tree() -> void:
	GlobalReferences.main_game_scene = self
	
	@warning_ignore("return_value_discarded")
	Settings.changed.connect(on_settings_changed)

func _ready() -> void:
	# pre-allocate scenes in our scene pools
	GlobalReferences.cube_pool = $BeepCubePool
	GlobalReferences.link_pool = $ChainLinkPool
	GlobalReferences.cube_pool.presize(100)
	GlobalReferences.link_pool.presize(100)
	
	var xr_camera := $XROrigin3D/XRCamera3D as XRCamera3D
	vr.initialize(
		xr_origin,
		xr_camera,
		left_controller,
		right_controller
	)
	
	vr.pose_recentered.connect(recenter)

	debug_info_label.visible = Settings.show_debug_info
	set_colors_from_settings()
	($WorldEnvironment as WorldEnvironment).environment.glow_enabled = Settings.glare
	
	if not vr.inVR:
		xr_origin.add_child(preload("res://OQ_Toolkit/OQ_ARVROrigin/Feature_VRSimulator.tscn").instantiate())
	
	UI_AudioEngine.attach_children(highscore_keyboard)
	UI_AudioEngine.attach_children(online_search_keyboard)
	
	_transition_game_state(gamestate_mapselection)
	
	@warning_ignore("return_value_discarded")
	Scoreboard.score_changed.connect(_display_points)
	@warning_ignore("return_value_discarded")
	Scoreboard.points_awarded.connect(points_label_driver.show_points)
	
	#render common assets for a couple of frames to prevent performance issues when loading them mid game
	($pre_renderer as Node3D).visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	($pre_renderer as Node3D).queue_free()
	
	recenter()

func on_settings_changed(key: StringName) -> void:
	# ensures proper initialization of tree for proper first frame setting loading
	await get_tree().process_frame
	match key:
		&"color_left":
			update_saber_colors(Settings.color_left, Settings.color_right)
		&"color_right":
			update_saber_colors(Settings.color_left, Settings.color_right)
		&"events":
			disable_events(not Settings.events)
		&"show_debug_info":
			debug_info_label.visible = Settings.show_debug_info
		&"glare":
			($WorldEnvironment as WorldEnvironment).environment.glow_enabled = Settings.glare
		&"player_height_offset":
			xr_origin.transform.origin.y = Settings.player_height_offset

func set_colors_from_settings() -> void:
	update_saber_colors(Settings.color_left, Settings.color_right)

func update_saber_colors(left_color: Color, right_color: Color) -> void:
	if !left_saber:
		await get_tree().process_frame

	if !right_saber:
		await get_tree().process_frame

	left_saber.set_color(left_color)
	right_saber.set_color(right_color)

	Arc.left_material.set_shader_parameter(&"color", left_color)
	Arc.left_material_magnet.set_shader_parameter(&"color", left_color)
	Arc.right_material.set_shader_parameter(&"color", left_color)
	Arc.right_material_magnet.set_shader_parameter(&"color", left_color)

	goggles_shader.set_shader_parameter(&"left_color", left_color)
	goggles_shader.set_shader_parameter(&"right_color", right_color)

	standing_ground.update_left_color(left_color)
	standing_ground.update_right_color(right_color)

func update_env_colors() -> void:
	event_driver.update_left_colors(Map.env_color_left, Map.env_color_left_boost)
	event_driver.update_right_colors(Map.env_color_right, Map.env_color_right_boost)
	event_driver.update_white_colors(Map.env_color_white, Map.env_color_white_boost)
	
func disable_events(disabled: bool) -> void:
	event_driver.disabled = disabled
	if disabled:
		event_driver.set_all_off()
	else:
		event_driver.set_all_on(Map.env_color_left, Map.env_color_right, Map.env_color_left_boost, Map.env_color_right_boost)

func _clear_track() -> void:
	for c in track.get_children():
		if c.has_method("clear_from_track"):
			c.clear_from_track()
		else:
			track.remove_child(c)
			c.queue_free()

func _display_points() -> void:
	var hit_rate: float
	if Scoreboard.right_notes+Scoreboard.wrong_notes > 0:
		hit_rate = Scoreboard.right_notes/(Scoreboard.right_notes+Scoreboard.wrong_notes)
	else:
		hit_rate = 1.0
	
	(point_label.mesh as TextMesh).text = "Score: %6d" % Scoreboard.points
	(multiplier_label.mesh as TextMesh).text = "x %d\nCombo %d" % [Scoreboard.multiplier, Scoreboard.combo]
	percent_indicator.update_percent(hit_rate)

# accessor method for the player name selector UI element
func _name_selector() -> NameSelector:
	return name_selector_canvas.ui_control

func _on_PlayerHead_area_entered(area: Area3D) -> void:
	if area.is_in_group(&"wall"):
		song_player.volume_db = -15.0
		_in_wall = true

func _on_PlayerHead_area_exited(area: Area3D) -> void:
	if area.is_in_group(&"wall"):
		song_player.volume_db = 0.0
		_in_wall = false

# when the song ended we want to display the current score and
# the high score
func _on_song_ended() -> void:
	song_player.stop()
	PlayCount.increment_play_count(Map.current_info, Map.current_difficulty_set, Map.current_difficulty.difficulty_rank)
	
	var new_record := false
	var highscore := Highscores.get_highscore(Map.current_info,Map.current_difficulty.difficulty_rank)
	if highscore == -1:
		# no highscores exist yet
		highscore = Scoreboard.points
	elif Scoreboard.points > highscore:
		# player's score is the new highscore!
		highscore = Scoreboard.points
		new_record = true

	var current_percent := Scoreboard.right_notes/(Scoreboard.right_notes+Scoreboard.wrong_notes)
	endscore.show_score(
		Scoreboard.points,
		highscore,
		current_percent,
		"%s By %s\n%s     Map author: %s" % [
			Map.current_info.song_name,
			Map.current_info.song_author_name,
			Map.current_difficulty.custom_name,
			Map.current_info.level_author_name],
		Scoreboard.full_combo,
		new_record
	)
	
	if Highscores.is_new_highscore(Map.current_info,Map.current_difficulty.difficulty_rank,Scoreboard.points):
		_transition_game_state(gamestate_newhighscore)
	else:
		_transition_game_state(gamestate_mapcomplete)

func _restart_button() -> void:
	start_map(Map.current_info, Map.current_difficulty)
	endscore.visible = false
	pause_menu.visible = false

func _main_menu_button() -> void:
	_clear_track()
	_transition_game_state(gamestate_mapselection)

func _voted(stars: int) -> void:
	PlayCount.set_stars(Map.current_info, Map.current_difficulty_set, Map.current_difficulty.difficulty_rank, stars)

func _unpause_button() -> void:
	pause_menu.visible = false
	pause_countdown.visible = true
	track.visible = true
	pause_countdown.set_label_text("3")
	await get_tree().create_timer(0.5).timeout
	pause_countdown.set_label_text("2")
	await get_tree().create_timer(0.5).timeout
	pause_countdown.set_label_text("1")
	await get_tree().create_timer(0.5).timeout
	pause_countdown.visible = false
	
	# continue game play
	song_player.play(pause_position)
	_transition_game_state(gamestate_playing)

func _on_BeepSaberMainMenu_difficulty_changed(map_info: MapInfo, diff_rank: int) -> void:
	# menu loads playlist in _ready(), must yield until scene is loaded
	if not highscore_canvas:
		await self.ready
	
	highscore_canvas._show()
	highscore_panel.load_highscores(map_info,diff_rank)

func _settings_button() -> void:
	_transition_game_state(gamestate_settings)

func _on_settings_Panel_apply() -> void:
	set_colors_from_settings()
	_transition_game_state(gamestate_mapselection)

func _on_ScenePool_new_scene_instanced(obj: Node3D, during_presizing: bool) -> void:
	# add obj to the track. it will reside inside the track for eternity, only
	# to be reposition and made visible again when it is acquired and spawned.
	track.add_child(obj)
	
	# make obj visible and wait for a frame to be processed. this tricks
	# shaders to be loaded at startup time.
	if during_presizing:
		obj.position.z = -2.0
		await get_tree().process_frame
		
		if obj is BeepCube:
			obj.hide_cube()
		elif obj is ChainLink:
			obj.hide_cube()
		else:
			obj.visible = false

func recenter():
	var xr_camera := $XROrigin3D/XRCamera3D as XRCamera3D
	xr_origin.rotation.y -= xr_camera.global_rotation.y
	xr_origin.position -= (xr_camera.global_position * Vector3(1,0,1)) - Vector3(0,0,1)
