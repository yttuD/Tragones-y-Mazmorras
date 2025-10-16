# GameManager.gd
extends Node

# Información de la sesión actual
var current_lobby_id: int = 0
var current_game_save_name: String = ""
var is_host: bool = false

# Lista de partidas guardadas
var saved_games: Array[String] = []
const GAME_SAVES_DIR = "user://saves/"

func _ready():
	DirAccess.make_dir_absolute(GAME_SAVES_DIR)
	load_saved_games_list()

func load_saved_games_list():
	saved_games.clear()
	var dir = DirAccess.open(GAME_SAVES_DIR)
	if not dir: return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".save"):
			saved_games.append(file_name.trim_suffix(".save"))
		file_name = dir.get_next()

func create_new_game_save(game_name: String, host_character: Character):
	var file_path = GAME_SAVES_DIR + game_name + ".save"
	if FileAccess.file_exists(file_path):
		return false # La partida ya existe

	var initial_data = {
		"game_name": game_name,
		"host_character_name": host_character.name,
		"world_state": { "level": 1, "last_checkpoint": "start" },
		# ...otros datos del mundo
	}
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(initial_data))
	file.close()
	load_saved_games_list() # Actualizamos la lista
	return true
