# SaveManager.gd
extends Node

const SAVE_DIR = "user://GameSaves/"

func _ready() -> void:
	# Asegurarse de que el directorio de guardado exista
	DirAccess.make_dir_absolute(SAVE_DIR)

# Devuelve una lista con los nombres de todas las partidas guardadas
func get_saved_games() -> Array[String]:
	var saved_games: Array[String] = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".sav"):
				# Quitamos la extensión .sav para mostrar un nombre limpio
				saved_games.append(file_name.trim_suffix(".sav"))
			file_name = dir.get_next()
	else:
		print("SaveManager: No se pudo abrir el directorio de guardado.")
	
	return saved_games

# Crea un nuevo archivo de partida (vacío por ahora)
func create_new_game(game_name: String) -> void:
	# Aquí guardaremos la información inicial de la partida.
	# Por ahora, solo creamos un diccionario vacío.
	var game_data = {
		"creation_date": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),
		# ...más datos como dificultad, nivel, etc.
	}
	
	var file = FileAccess.open(SAVE_DIR.path_join(game_name + ".sav"), FileAccess.WRITE)
	if file:
		# Guardamos los datos en formato JSON
		file.store_string(JSON.stringify(game_data))
		print("SaveManager: Nueva partida '%s' creada." % game_name)
	else:
		print("SaveManager: Error al crear la partida '%s'." % game_name)

# (En el futuro, aquí tendrás una función 'load_game_data(game_name)')
