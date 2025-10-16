# GameLobbyUI.gd
extends Control

const PlayerSlotScene = preload("res://UI/PlayerSlot.tscn")
@export var random_avatars: Array[Texture2D] = [
	preload("res://Avatars/Hunter_Avatar.png"), preload("res://Avatars/Rogue_Avatar.png"),
	preload("res://Avatars/Warrior_Avatar.png"), preload("res://Avatars/Witch_Avatar.png")
]

# --- NODOS REQUERIDOS EN LA ESCENA ---
# Nodos existentes
@onready var player_slots_vbox: VBoxContainer = $MarginContainer/ContentVBox/MainHBox/LeftPanel/PlayerSlotsVBox
@onready var start_button: Button = $MarginContainer/ContentVBox/BottomPanel/StartButton
@onready var ready_button: Button = $MarginContainer/ContentVBox/BottomPanel/ReadyButton
@onready var leave_button: Button = $MarginContainer/ContentVBox/BottomPanel/LeaveButton
@onready var invite_button: Button = $MarginContainer/ContentVBox/BottomPanel/InviteButton

# --- NODOS NUEVOS PARA LA SELECCIÓN DE PARTIDA ---
# ¡Deberás añadir estos nodos a tu escena!
@onready var game_list: ItemList = $MarginContainer/ContentVBox/MainHBox/RightPanel/VBoxContainer/GameList
@onready var new_game_button: Button = $MarginContainer/ContentVBox/MainHBox/RightPanel/VBoxContainer/NewGameButton
@onready var selected_game_label: Label = $MarginContainer/ContentVBox/MainHBox/RightPanel/VBoxContainer/SelectedGameLabel

var selected_game_name: String = ""

func _ready() -> void:
	# !! CORRECCIÓN CLAVE !!
	# Esperamos un fotograma para asegurar que el MultiplayerPeer esté completamente configurado.
	await get_tree().process_frame
	
	# Conectar señales de los botones
	ready_button.pressed.connect(_on_ready_button_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)
	invite_button.pressed.connect(_on_invite_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	game_list.item_selected.connect(_on_game_list_item_selected)

	# Conectar señal del NetworkManager
	NetworkManager.game_state_updated.connect(_on_game_state_updated)

	# Lógica de inicialización para el Host
	if NetworkManager.is_host():
		var steam_id = Steam.getSteamID()
		SessionData.game_state.players[steam_id] = {
			"name": Steam.getPersonaName(), "is_ready": false, "peer_id": 1
		}
		# El host puebla la lista de partidas guardadas
		_populate_game_list()
		# Forzamos una actualización RPC para que todos tengan el estado inicial
		NetworkManager.update_game_state(SessionData.game_state)
	else:
		# Los clientes simplemente actualizan su UI con el estado que reciban
		_on_game_state_updated(SessionData.game_state)

func _on_game_state_updated(new_state: Dictionary) -> void:
	# Actualizar la lista de jugadores
	for child in player_slots_vbox.get_children():
		child.queue_free()

	if new_state.has("players"):
		for player_id in new_state.players:
			var player_data: Dictionary = new_state.players[player_id]
			var slot = PlayerSlotScene.instantiate()
			slot.player_info = {
				"name": player_data.get("name", "Desconocido"),
				"avatar": random_avatars.pick_random(),
				"is_ready": player_data.get("is_ready", false)
			}
			player_slots_vbox.add_child(slot)
	
	# Actualizar la información de la partida seleccionada
	selected_game_name = new_state.get("selected_game", "")
	if selected_game_name.is_empty():
		selected_game_label.text = "Elige o crea una partida"
	else:
		selected_game_label.text = "Partida: %s" % selected_game_name
		
	# Actualizar estado de botones
	update_button_states(new_state)

func update_button_states(current_state: Dictionary) -> void:
	var is_owner = NetworkManager.is_host()

	start_button.visible = is_owner
	ready_button.visible = not is_owner
	invite_button.visible = is_owner
	
	# El panel de selección de partida solo es visible e interactivo para el host
	var game_selection_panel = $MarginContainer/ContentVBox/MainHBox/RightPanel
	game_selection_panel.visible = is_owner

	if is_owner:
		var all_clients_ready = true
		for player_id in current_state.players:
			if player_id != Steam.getSteamID() and not current_state.players[player_id].is_ready:
				all_clients_ready = false
				break
		
		# El botón de empezar solo se activa si hay una partida seleccionada Y todos están listos
		var game_is_selected = not selected_game_name.is_empty()
		start_button.disabled = not (all_clients_ready and game_is_selected)
	else:
		var my_id = Steam.getSteamID()
		if current_state.players.has(my_id):
			ready_button.text = "¡Preparado!" if current_state.players[my_id].is_ready else "Marcar como Listo"

# --- LÓGICA DE SELECCIÓN DE PARTIDA (Solo Host) ---
func _populate_game_list() -> void:
	game_list.clear()
	var saves = SaveManager.get_saved_games()
	if saves.is_empty():
		game_list.add_item("No hay partidas guardadas", null, false) # Deshabilitado
	else:
		for save_name in saves:
			game_list.add_item(save_name)

func _on_game_list_item_selected(index: int) -> void:
	var game_name = game_list.get_item_text(index)
	NetworkManager.server_select_game(game_name)

func _on_new_game_button_pressed() -> void:
	# Por ahora, creamos un nombre de partida aleatorio.
	# En el futuro, aquí podrías abrir un diálogo para pedir un nombre.
	var new_game_name = "Partida %s" % Time.get_unix_time_from_system()
	SaveManager.create_new_game(new_game_name)
	_populate_game_list()
	# Seleccionar automáticamente la nueva partida
	for i in range(game_list.item_count):
		if game_list.get_item_text(i) == new_game_name:
			game_list.select(i)
			_on_game_list_item_selected(i)
			break

# --- MANEJO DE BOTONES ---
func _on_ready_button_pressed():
	var my_id = Steam.getSteamID()
	if not SessionData.game_state.players.has(my_id): return
	var current_status = SessionData.game_state.players[my_id].is_ready
	NetworkManager.server_set_ready_status(my_id, not current_status)

func _on_leave_button_pressed():
	NetworkManager.leave_lobby()

func _on_invite_button_pressed():
	Steam.activateGameOverlayInviteDialog(SessionData.current_lobby_id)

func _on_start_button_pressed():
	# Guardamos la partida seleccionada para usarla después
	SessionData.selected_game_to_load = selected_game_name
	NetworkManager.start_game()
