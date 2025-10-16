# GameLobbyUI.gd
extends Control

const PlayerSlotScene = preload("res://UI/PlayerSlot.tscn")
@export var random_avatars: Array[Texture2D] = [
	preload("res://Avatars/Hunter_Avatar.png"), preload("res://Avatars/Rogue_Avatar.png"),
	preload("res://Avatars/Warrior_Avatar.png"), preload("res://Avatars/Witch_Avatar.png")
]

# Arrays para gestionar los slots fácilmente
var character_slots: Array[Control] = []
var game_slots: Array[Control] = []

@onready var player_slots_vbox = $MarginContainer/ContentVBox/MainHBox/LeftPanel/PlayerSlotsVBox
@onready var start_button = $MarginContainer/ContentVBox/BottomPanel/StartButton
@onready var ready_button = $MarginContainer/ContentVBox/BottomPanel/ReadyButton
@onready var leave_button = $MarginContainer/ContentVBox/BottomPanel/LeaveButton
@onready var invite_button = $MarginContainer/ContentVBox/BottomPanel/InviteButton

var my_character_slot_index = -1
var my_ready_status = false

func _ready():
	# Llenar los arrays de slots
	for i in range(1, 6):
		character_slots.append(get_node("Path/To/CharacterSlot" + str(i))) # Corrige esta ruta
		game_slots.append(get_node("Path/To/GameSlot" + str(i))) # Corrige esta ruta

	# Conectar señales
	# (Haz esto en el editor para cada slot)
	# character_slots[0].gui_input.connect(func(event): _on_character_slot_gui_input(event, 0))
	
	# Configuración inicial de la UI
	setup_initial_view()

	# Conectar a señales del NetworkManager
	NetworkManager.player_states_updated.connect(_on_player_states_updated)

	# El primer jugador se auto-asigna como Owner
	if NetworkManager.is_host():
		SessionData.owner_id = Steam.getSteamID()
	
	update_player_slots() # Poblar la lista de jugadores de la izquierda

# --- CONFIGURACIÓN DE LA UI ---
func setup_initial_view():
	var is_owner = (Steam.getSteamID() == SessionData.owner_id)
	
	# El Owner ve el botón de Start y los slots de partida
	start_button.visible = is_owner
	for slot in game_slots:
		slot.visible = is_owner
		
	# Los clientes ven el botón de Ready
	ready_button.visible = not is_owner
	
	update_button_states()

func update_button_states():
	var is_owner = (Steam.getSteamID() == SessionData.owner_id)

	if is_owner:
		# Lógica para habilitar el botón "Start"
		var all_clients_ready = true
		var game_slot_selected = false # Necesitas una variable para rastrear esto
		
		# (Aquí iría la lógica para revisar el estado de los demás jugadores)
		
		start_button.disabled = not (all_clients_ready and game_slot_selected)
	else:
		# Los clientes necesitan seleccionar un personaje para estar listos
		ready_button.disabled = (my_character_slot_index == -1)

# --- MANEJO DE SLOTS ---
func _on_character_slot_gui_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Jugador %s intenta seleccionar slot de personaje %d" % [Steam.getPersonaName(), slot_index])
		my_character_slot_index = slot_index
		# Enviar RPC al Owner para reclamar el slot
		NetworkManager.rpc_id(SessionData.owner_id, "server_update_player_state", Steam.getSteamID(), {"character_slot": slot_index})
		update_button_states()

func _on_game_slot_gui_input(event: InputEvent, slot_index: int):
	if Steam.getSteamID() != SessionData.owner_id: return # Solo el Owner puede interactuar
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Owner seleccionó slot de partida %d" % slot_index)
		# Enviar RPC a todos para informar de la selección
		NetworkManager.rpc("client_update_game_state", {"game_slot": slot_index})
		update_button_states()


# --- MANEJO DE BOTONES ---

func _on_ready_button_pressed():
	my_ready_status = not my_ready_status
	ready_button.text = "Listo" if my_ready_status else "No Listo"
	NetworkManager.rpc_id(SessionData.owner_id, "server_update_player_state", Steam.getSteamID(), {"ready": my_ready_status})

func _on_leave_button_pressed():
	NetworkManager.leave_lobby()
	get_tree().change_scene_to_file("res://Scenes/UI/LobbySelectionUI.tscn")

func _on_invite_button_pressed():
	Steam.activateGameOverlayInviteDialog(SessionData.current_lobby_id)

# --- ACTUALIZACIÓN DE ESTADO (RPCs) ---

# Se ejecuta en todos los clientes cuando el Owner actualiza el estado

@rpc("any_peer")
func client_update_ui(_new_player_states: Dictionary): # Se añade "_"
	# Redibujar todos los slots de personaje y partida según el diccionario
	if Steam.getSteamID() == SessionData.owner_id:
		update_button_states()

# --- Lista de Jugadores (Izquierda) ---
func update_player_slots():
	for child in player_slots_vbox.get_children():
		child.queue_free()
	
	var lobby_id = SessionData.current_lobby_id
	if lobby_id == 0: return
	
	# --- CORRECCIÓN CLAVE ---
	# 1. Obtener el NÚMERO de miembros en el lobby.
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	
	# 2. Iterar ese número de veces para obtener cada miembro por su índice.
	for i in range(member_count):
		var member_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		var slot = PlayerSlotScene.instantiate()
		var steam_name = Steam.getFriendPersonaName(member_id)
		slot.player_info = {"name": steam_name, "avatar": random_avatars.pick_random()}
		player_slots_vbox.add_child(slot)


func _on_create_character_button_pressed() -> void:
	pass # Replace with function body.


func _on_create_game_button_pressed() -> void:
	pass # Replace with function body.


func _on_character_list_item_selected(_index: int): # Se añade "_"
	update_button_states()


func _on_name_dialog_confirmed() -> void:
	pass # Replace with function body.


func _on_start_button_pressed() -> void:
	pass # Replace with function body.


func _on_game_list_item_selected(_index: int): # Se añade "_"
	update_button_states()
	
func _on_player_states_updated(_states: Dictionary):
	# Esta función se ejecutará cuando el NetworkManager envíe una actualización
	# sobre el estado de los jugadores (ej: quién está listo).
	# Por ahora, la dejamos vacía.
	pass
