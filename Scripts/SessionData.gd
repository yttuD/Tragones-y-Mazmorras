# SessionData.gd

extends Node

# El personaje seleccionado para la partida actual
var selected_character: Character 

# El ID del lobby de Steam al que estamos conectados
var current_lobby_id: int = 0

# El nombre del archivo de guardado que el host ha cargado
var current_game_save_name: String = ""

# ¿Somos nosotros los que hemos creado el lobby?
var is_host: bool = false
