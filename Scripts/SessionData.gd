# SessionData.gd
extends Node

# El ID del lobby de Steam en el que estamos actualmente
var current_lobby_id: int = 0

# El SteamID del anfitrión (Host/Owner) del lobby
var owner_id: int = 0

# Este diccionario almacenará el estado de todos los jugadores en el lobby.
# Lo inicializamos con una estructura 'players' vacía.
var game_state: Dictionary = {
	"players": {},
	"selected_game": ""
}
# Variable para saber qué partida cargar al entrar a Main.tscn
var selected_game_to_load: String = ""
