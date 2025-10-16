# NetworkManager.gd (Rediseño Completo)
extends Node

## SEÑALES (Para comunicarse con la UI)
signal lobbies_updated(lobbies: Array)
signal game_state_updated(game_state: Dictionary)

## CONSTANTES Y RUTAS DE ESCENA
const LOBBY_SELECTION_SCENE_PATH := "res://Scenes/UI/LobbySelectionUI.tscn"
const GAME_LOBBY_SCENE_PATH := "res://Scenes/UI/GameLobbyUI.tscn"
const MAIN_GAME_SCENE_PATH := "res://Scenes/Main.tscn"

const MAX_PLAYERS := 4
const PORT := 7777

## VARIABLES DE ESTADO
var _lobby_created_data_pending = null
var _lobby_joined_data_pending = null
var _pending_lobby_name: String = ""
var local_player_name = ""
# --- INICIALIZACIÓN Y BUCLE ---
func _ready() -> void:
	if not Steam.steamInit(480): # <-- CAMBIO APLICADO AQUÍ
		print("Error: Falló la inicialización de Steam.")
		return
	local_player_name = Steam.getPersonaName()
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)
	Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
	print("NetworkManager: Todas las señales de Steam conectadas.")
	# Conectar señales de Steam para procesar sus respuestas
	if not Steam.steamInit():
		Steam.steamInit(480)
	if Steam.isSteamRunning():
		Steam.lobby_created.connect(_on_steam_lobby_created)
		Steam.lobby_joined.connect(_on_steam_lobby_joined)
		Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
		Steam.lobby_chat_update.connect(_on_steam_lobby_update)
	else:
		print("ERROR: NetworkManager no pudo inicializar Steam.")

	# Conectar señales del sistema multijugador de Godot
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func _process(delta: float) -> void:
	# Usamos el _process para manejar los callbacks de Steam de forma segura
	if _lobby_created_data_pending:
		_handle_lobby_created(delta)
	if _lobby_joined_data_pending:
		_handle_lobby_joined(delta)

# --- API PÚBLICA (Funciones que la UI puede llamar) ---
func is_host() -> bool:
	return multiplayer.is_server()

func create_lobby(lobby_type: int, lobby_name: String) -> void:
	_pending_lobby_name = lobby_name
	Steam.createLobby(lobby_type, MAX_PLAYERS)

func refresh_lobbies() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func join_lobby(lobby_id: int) -> void:
	Steam.joinLobby(lobby_id)

func leave_lobby():
	if SessionData.current_lobby_id != 0:
		Steam.leaveLobby(SessionData.current_lobby_id)
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(LOBBY_SELECTION_SCENE_PATH)

# --- MANEJADORES DE CALLBACKS DE STEAM ---
func _on_steam_lobby_created(result: int, lobby_id: int):
	_lobby_created_data_pending = {'result': result, 'lobby_id': lobby_id}

func _on_steam_lobby_joined(lobby_id: int, _p: int, _l: bool, response: int):
	_lobby_joined_data_pending = {'lobby_id': lobby_id, 'response': response}

# ¡CORRECCIÓN CLAVE! Esta función ahora procesa los lobbies
func _on_steam_lobby_match_list(lobbies: Array):
	var lobby_array = []
	if not lobbies.is_empty():
		for lobby_id in lobbies:
			var lobby_name = Steam.getLobbyData(lobby_id, "name")
			if lobby_name.is_empty(): lobby_name = "Sala de %s" % Steam.getFriendPersonaName(Steam.getLobbyOwner(lobby_id))
			lobby_array.append({"id": lobby_id, "name": lobby_name})
	emit_signal("lobbies_updated", lobby_array)

func _on_steam_lobby_update(_lobby_id, user_id, _changer_id, state):
	if is_host() and (state == 2 or state == 4): # 2=Left, 4=Disconnected
		if SessionData.game_state.players.has(user_id):
			SessionData.game_state.players.erase(user_id)
			rpc("update_game_state", SessionData.game_state)

# --- LÓGICA DE CONEXIÓN Y CAMBIO DE ESCENA ---
func _handle_lobby_created(_delta: float):
	if not _lobby_created_data_pending: return
	var data = _lobby_created_data_pending; _lobby_created_data_pending = null
	
	if data['result'] == Steam.RESULT_OK:
		var lobby_id = data['lobby_id']
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(PORT)
		multiplayer.multiplayer_peer = peer
		
		SessionData.current_lobby_id = lobby_id
		Steam.setLobbyData(lobby_id, "name", _pending_lobby_name)
		
		get_tree().change_scene_to_file(GAME_LOBBY_SCENE_PATH)
	else:
		print("Error al crear lobby de Steam. Código: %s" % data['result'])

func _handle_lobby_joined(_delta: float):
	if not _lobby_joined_data_pending: return
	var data = _lobby_joined_data_pending; _lobby_joined_data_pending = null

	if data['response'] == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var lobby_id = data['lobby_id']
		# NOTA: Para un juego real, necesitarás la IP del host. Para pruebas locales, 127.0.0.1 es suficiente.
		var host_ip = "127.0.0.1" 
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(host_ip, PORT)
		multiplayer.multiplayer_peer = peer
		
		SessionData.current_lobby_id = lobby_id
		get_tree().change_scene_to_file(GAME_LOBBY_SCENE_PATH)
	else:
		print("Error al unirse al lobby de Steam. Código: %s" % data['response'])

# --- SINCRONIZACIÓN DE ESTADO DEL LOBBY (RPCS) ---
func _on_player_connected(peer_id: int):
	# Lo ve el host: un nuevo cliente se ha conectado. Le pedimos su SteamID.
	rpc_id(peer_id, "client_send_your_info")

func _on_player_disconnected(peer_id: int):
	# Lo ve el host: un cliente se ha desconectado.
	var steam_id_to_remove = 0
	for id in SessionData.game_state.players:
		if SessionData.game_state.players[id].get("peer_id") == peer_id:
			steam_id_to_remove = id
			break
	if steam_id_to_remove != 0:
		SessionData.game_state.players.erase(steam_id_to_remove)
		rpc("update_game_state", SessionData.game_state)

@rpc("any_peer")
func client_send_your_info():
	# Lo ve el cliente: el host nos pide nuestra info. Respondemos.
	rpc_id(1, "server_register_player", Steam.getSteamID(), Steam.getPersonaName())

@rpc("authority") # Solo el host puede ejecutar esta función
func server_register_player(steam_id: int, player_name: String): # <-- 'name' ahora es 'player_name'
	# Lo ve el host: un cliente ha respondido con su info.
	if not SessionData.game_state.players.has(steam_id):
		SessionData.game_state.players[steam_id] = {
			"name": player_name, # <-- Usamos la nueva variable
			"character_slot": -1, 
			"is_ready": false, 
			"peer_id": get_multiplayer().get_remote_sender_id()
		}
		rpc("update_game_state", SessionData.game_state)

@rpc("authority")
func server_claim_character_slot(sender_id: int, slot_index: int):
	SessionData.game_state.players[sender_id].character_slot = slot_index
	rpc("update_game_state", SessionData.game_state)

@rpc("authority")
func server_select_game_slot(slot_index: int):
	SessionData.game_state.selected_game_slot = slot_index
	rpc("update_game_state", SessionData.game_state)
	
@rpc("authority")
func server_set_ready_status(sender_id: int, is_ready: bool):
	SessionData.game_state.players[sender_id].is_ready = is_ready
	rpc("update_game_state", SessionData.game_state)

@rpc("any_peer", "call_local")
func update_game_state(new_state: Dictionary):
	# Todos (host y clientes) actualizan su copia local del estado del juego
	SessionData.game_state = new_state
	emit_signal("game_state_updated", new_state)

@rpc("any_peer", "call_local")
func start_game():
	# Todos cambian a la escena principal del juego
	get_tree().change_scene_to_file(MAIN_GAME_SCENE_PATH)
