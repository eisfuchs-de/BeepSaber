extends Panel
class_name HighscorePanel

signal close()

@export var show_close_button := true
@export var show_song_info := true

# keep a copy of the base row for regeneration later
@onready var _base_row = $Margin/VBox/LeftRight/ScrollContainer/Margin/HighscoresList/BaseRecordRow.duplicate()
@onready var _highscore_list = $Margin/VBox/LeftRight/ScrollContainer/Margin/HighscoresList
@onready var _title = $Margin/VBox/Title
@onready var _song_info = $Margin/VBox/LeftRight/VBox/SongInfo_Label
@onready var _exit_button = $Margin/VBox/Exit_Button
@onready var _song_info_panel = $Margin/VBox/LeftRight/VBox

func _ready() -> void:
	_clear_list()
	_exit_button.visible = show_close_button
	_song_info_panel.visible = show_song_info

func load_highscores(map_info: MapInfo, diff_rank: int, highlight_rank: int = -1):
	# clear the high score list
	_clear_list()
	
	# populate title text
	set_title("Highscores (%s)" % _get_difficulty_name(map_info,diff_rank))
	
	# populate song info
	_song_info.text = """Artist: %s
		Song: %s
		Map Author: %s""" % [map_info.song_author_name, map_info.song_name, map_info.level_author_name]
		
	# TODO populate song artwork
		
	var records := Highscores.get_records(map_info,diff_rank)
	var idx = 1
	for record in records:
		# build a new row and populate fields from record
		var percent_str := "-"
		if record.has("percent"):
			percent_str = "%d%%" % [ int(record.percent * 100.0) ]

		var date_time := Time.get_datetime_dict_from_unix_time(record.epoch_time)
		var date_time_str := "  %04d-%02d-%02d %02d:%02d" % [
			date_time["year"],
			date_time["month"],
			date_time["day"],
			date_time["hour"],
			date_time["minute"],
		]

		var new_row = _base_row.duplicate()
		new_row.get_child(0).text = "%d." % idx
		new_row.get_child(1).text = record.player_name
		new_row.get_child(2).text = str(int(record.score))
		new_row.get_child(3).text = percent_str
		new_row.get_child(4).text = date_time_str
	
		_highscore_list.add_child(new_row)

		if highlight_rank + 1 == idx:
			var label: Label = new_row.get_child(1)
			label.add_theme_color_override("font_color", Color(1, 0.5, 0))

		idx += 1
		
func set_title(title_text):
	_title.text = title_text
	
# clears all rows from the highscore table
func _clear_list():
	for c in _highscore_list.get_children():
		c.queue_free()
	
func _get_difficulty_name(map_info: MapInfo, diff_rank: int) -> String:
	for difficulty_set_name in map_info.difficulty_beatmaps:
		var beatmap : Dictionary = map_info.difficulty_beatmaps[difficulty_set_name]
		for difficulty_name in beatmap:
			if beatmap[difficulty_name].difficulty_rank == diff_rank:
				return beatmap[difficulty_name].difficulty
	return 'Rank %s' % diff_rank

func _on_Exit_Button_pressed() -> void:
	close.emit()
