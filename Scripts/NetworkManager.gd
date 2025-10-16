# NetworkManager.gd (Rediseño Completo)
extends Node

## SEÑALES (Para comunicarse con la UI)
signal lobbies_updated(lobbies: Array)
signal game_state_updated(game_state: Dictionary)

## CONSTANTES Y RUTAS DE ESCENA
const GAME_LOBBY_SCENE_PATH := "res://UI/GameLobbyUI.tscn"
const MAIN_GAME_SCENE_PATH := "res://Main.tscn"
const CHARACTER_CREATION_SCENE_PATH := "res://UI/CharacterCreationUI.tscn"

const MAX_PLAYERS := 4
const PORT := 7777

## VARIABLES DE ESTADO
var _lobby_created_data_pending = null
var _lobby_joined_data_pending = null
var _pending_lobby_name: String = ""
var local_player_name = ""

# --- INICIALIZACIÓN Y BUCLE ---
func _ready() -> void:
	# Asegurarse de que Steam se inicializa correctamente. Usa el AppID de Spacewar (480) para pruebas.
	if not Steam.steamInit(480):
		print("Error: Falló la inicialización de Steam.")
		get_tree().quit()
		return
	
	local_player_name = Steam.getPersonaName()
	
	# Conectar señales de Steam para procesar sus respuestas
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)
	Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
	Steam.lobby_chat_update.connect(_on_steam_lobby_update)
	print("NetworkManager: Todas las señales de Steam conectadas.")

	# Conectar señales del sistema multijugador de Godot
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func _process(delta: float) -> void:
	Steam.run_callbacks()
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
	# Aunque ya no usamos la selección de lobbies, esta función es útil para el futuro.
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func join_lobby(lobby_id: int) -> void:
	Steam.joinLobby(lobby_id)

func leave_lobby():
	if SessionData.current_lobby_id != 0:
		Steam.leaveLobby(SessionData.current_lobby_id)
		SessionData.current_lobby_id = 0
		SessionData.game_state = {"players": {}}
		
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")

# --- MANEJADORES DE CALLBACKS DE STEAM ---
func _on_steam_lobby_created(result: int, lobby_id: int):
	_lobby_created_data_pending = {'result': result, 'lobby_id': lobby_id}

func _on_steam_lobby_joined(lobby_id: int, _p: int, _l: bool, response: int):
	_lobby_joined_data_pending = {'lobby_id': lobby_id, 'response': response}

func _on_steam_lobby_match_list(lobbies: Array):
	var lobby_array = []
	if not lobbies.is_empty():
		for lobby_id in lobbies:
			var lobby_name = Steam.getLobbyData(lobby_id, "name")
			if lobby_name.is_empty(): 
				lobby_name = "Sala de %s" % Steam.getFriendPersonaName(Steam.getLobbyOwner(lobby_id))
			lobby_array.append({"id": lobby_id, "name": lobby_name})
	emit_signal("lobbies_updated", lobby_array)

func _on_steam_lobby_update(_lobby_id, user_id, _changer_id, state):
	# Estados: 1=Entered, 2=Left, 4=Disconnected, 8=Kicked, 16=Banned
	if is_host() and (state == 2 or state == 4 or state == 8 or state == 16):
		if SessionData.game_state.players.has(user_id):
			SessionData.game_state.players.erase(user_id)
			rpc("update_game_state", SessionData.game_state)

# --- LÓGICA DE CONEXIÓN Y CAMBIO DE ESCENA ---
func _handle_lobby_created(_delta: float):
	if not _lobby_created_data_pending: return
	var data = _lobby_created_data_pending
	_lobby_created_data_pending = null
	
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
		# Aquí podrías volver a habilitar el botón del menú principal.

func _handle_lobby_joined(_delta: float):
	if not _lobby_joined_data_pending: return
	var data = _lobby_joined_data_pending
	_lobby_joined_data_pending = null

	if data['response'] == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var lobby_id = data['lobby_id']
		var _host_id = Steam.getLobbyOwner(lobby_id)
		
		# En un juego real, la IP se obtendría a través de la API de Steam.
		# Para pruebas locales, 127.0.0.1 es suficiente si el host está en la misma máquina.
		# Para pruebas en red, el host debería compartir su IP. GodotSteam proporciona
		# P2P para esto, pero ENet requiere la IP.
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
func server_register_player(steam_id: int, player_name: String):
	# Lo ve el host: un cliente ha respondido con su info.
	if not SessionData.game_state.players.has(steam_id):
		SessionData.game_state.players[steam_id] = {
			"name": player_name,
			"is_ready": false, 
			"peer_id": get_multiplayer().get_remote_sender_id()
		}
		rpc("update_game_state", SessionData.game_state)

@rpc("authority")
func server_set_ready_status(sender_steam_id: int, is_ready: bool):
	var sender_peer_id = get_multiplayer().get_remote_sender_id()
	
	# Verificamos que el jugador que envía la petición es quien dice ser
	var player_info = SessionData.game_state.players.get(sender_steam_id)
	if player_info and player_info.peer_id == sender_peer_id:
		SessionData.game_state.players[sender_steam_id].is_ready = is_ready
		rpc("update_game_state", SessionData.game_state)

@rpc("authority")
func server_select_game(game_name: String):
	# Solo el host puede ejecutar esto.
	# Actualiza el estado del juego y lo distribuye a todos.
	SessionData.game_state.selected_game = game_name
	rpc("update_game_state", SessionData.game_state)

@rpc("any_peer", "call_local")
func update_game_state(new_state: Dictionary):
	# Todos (host y clientes) actualizan su copia local del estado del juego
	SessionData.game_state = new_state
	emit_signal("game_state_updated", new_state)

@rpc("any_peer", "call_local")
func start_game():
	# Todos los jugadores (host y clientes) ejecutarán esta lógica localmente.
	
	# Cargamos el perfil del jugador para ver si tiene personajes.
	ProfileManager.load_profile()
	
	var scene_to_load = ""
	if ProfileManager.current_profile and not ProfileManager.current_profile.characters.is_empty():
		# El jugador ya tiene al menos un personaje, va directo al juego.
		print("NetworkManager: Perfil encontrado. Cargando juego principal.")
		scene_to_load = MAIN_GAME_SCENE_PATH
	else:
		# Es un jugador nuevo o sin personajes, debe crear uno.
		print("NetworkManager: No se encontró personaje. Cargando creación de personaje.")
		scene_to_load = CHARACTER_CREATION_SCENE_PATH
	
	get_tree().change_scene_to_file(scene_to_load)
