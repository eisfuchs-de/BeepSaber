extends Node
class_name PlayCountTable

# location to store the play counts on filesystem
const PLAY_COUNT_FILEPATH = "user://play_count.json"

# internal copy of the play count table
# restored from user file in load_table()
# {
#    "<song_hash>" : { # play counts for a given song
#       "Standard": {
#          "1": {
#             "count": 10, # play count at difficulty rank 1 in set "Standard"
#             "stars": 5   # star rating for this song at difficulty rank 1 in set "Standard"
#          },
#          "3": {
#             "count": 10, # play count at difficulty rank 3 in set "Standard"
#             "stars": 5   # star rating for this song at difficulty rank 3 in set "Standard"
#          }
#       },
#		"90Degrees": {
#          ...
#       }
#    }
# }

var _pc_table: Dictionary = {}

func _ready() -> void:
	# this happens now in BeepSaberMainMenu.gd on discover all songs
	# load_table()
	pass

# clears the whole play count table
func clear_table() -> void:
	_pc_table = {}
	
# removes a given map from the table, effectively resetting that map's counters
func remove_map(map_info: MapInfo) -> void:
	var song_key := map_info.get_key()
	@warning_ignore("return_value_discarded")
	_pc_table.erase(song_key)

	var song_hash := map_info.get_hash()
	@warning_ignore("return_value_discarded")
	_pc_table.erase(song_hash)

	save_table()

# increments the maps play count by 1.
#
# map_info : data structure as read for map's info.dat file
# difficulty_set : Characteristic ("Standard", "90Degrees", etc.) that the map was played on
# difficulty_rank : rank (1, 3, etc.) that the map was played on
#
# return : None
func increment_play_count(map_info: MapInfo, difficulty_set: String, difficulty_rank: int) -> void:
	var song_hash := map_info.get_hash()

	if not _pc_table.has(song_hash):
		_pc_table[song_hash] = {}

	var play_count_dict := Utils.get_dict(_pc_table, song_hash, {})

	if not play_count_dict.has(difficulty_set):
		play_count_dict[difficulty_set] = {}

	var diff_str := str(difficulty_rank)
	if not play_count_dict[difficulty_set].has(diff_str):
		play_count_dict[difficulty_set][diff_str] = {
			&"count": 1,
			&"stars": -1,
		}
	else:
		play_count_dict[difficulty_set][diff_str][&"count"] += 1
	
	save_table()

# return : the map's play count and stars for the given difficulty
func get_play_count(map_info: MapInfo, difficulty_set: String, difficulty_rank: int) -> Dictionary:
	var song_hash := map_info.get_hash()

	# return this dictionary if something goes wrong or was not found
	var default_return := {
		&"count": 0,
		&"stars": -1,
	}

	var play_count_dict := Utils.get_dict(_pc_table, song_hash, {})

	if not play_count_dict.has(difficulty_set):
		return default_return

	var diff_str := str(difficulty_rank)
	if play_count_dict[difficulty_set].has(diff_str):
		return {
			&"count": int(play_count_dict[difficulty_set][diff_str].get(&"count", 0)),
			&"stars": int(play_count_dict[difficulty_set][diff_str].get(&"stars", -1)),
		}

	return default_return

# return : the map's total play count accros all difficulties + average stars voted for it
func get_total_play_count(map_info: MapInfo) -> Dictionary:
	var song_hash := map_info.get_hash()
	var play_count_dict := Utils.get_dict(_pc_table, song_hash, {})

	var total := 0
	var avg_stars := 0.0

	if not play_count_dict.is_empty():
		var star_votes := 0
		for difficulty_set in play_count_dict.keys():
			for difficulty in play_count_dict[difficulty_set].keys():
				total += int(play_count_dict[difficulty_set][difficulty].get(&"count", 0))
				var stars := float(play_count_dict[difficulty_set][difficulty].get(&"stars", -1))
				if stars >= 0.0:
					avg_stars += stars
					star_votes += 1

		if star_votes:
			avg_stars /= float(star_votes)

	return {
		&"total": total,
		&"avg_stars": avg_stars,
	}

func set_stars(map_info: MapInfo, difficulty_set: String, difficulty_rank: int, stars: int) -> void:
	var song_hash := map_info.get_hash()

	var play_count_dict := Utils.get_dict(_pc_table, song_hash, {})

	if not play_count_dict.has(difficulty_set):
		return

	var diff_str := str(difficulty_rank)
	if play_count_dict[difficulty_set].has(diff_str):
		play_count_dict[difficulty_set][diff_str][&"stars"] = stars
		save_table()

# restores play count table from filesystem, converts old format
func load_table(keys_to_hashes: Dictionary) -> void:
	var file := FileAccess.open(PLAY_COUNT_FILEPATH,FileAccess.READ)
	if not file:
		print("WARN: Failed to open %s (might not exist yet)" % PLAY_COUNT_FILEPATH)
		return

	var text := file.get_as_text()
	file.close()

	var json_res := JSON.parse_string(text) as Dictionary
	if not json_res:
		return

	_pc_table = {}
	for song_hash_or_key in json_res.keys():
		var song_dict := {}
		var song_data : Dictionary = json_res[song_hash_or_key]
		for difficulty_set : Variant in song_data.keys():
			if song_data[difficulty_set] is Dictionary:
				song_dict[difficulty_set] = song_data[difficulty_set]
			else:
				# convert old format
				if song_dict.is_empty():
					song_dict["Standard"] = {}

				song_dict["Standard"][difficulty_set] = {
					&"count": song_data[difficulty_set],
					&"stars": "-1",
				}

		# convert old format keys to song hashes
		if keys_to_hashes.has(song_hash_or_key):
			song_hash_or_key = keys_to_hashes[song_hash_or_key]

		_pc_table[song_hash_or_key] = song_dict

# saves play count table to filesystem
func save_table() -> void:
	var file := FileAccess.open(PLAY_COUNT_FILEPATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_pc_table,"   ",true))
		file.close()
	else:
		print("ERROR: Failed to open %s" % PLAY_COUNT_FILEPATH)
