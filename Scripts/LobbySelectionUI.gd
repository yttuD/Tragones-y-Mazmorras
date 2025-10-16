# LobbySelectionUI.gd
extends Control

@onready var lobby_list: ItemList = $MainVBox/LobbyList
@onready var host_button: Button = $MainVBox/ButtonBox/HostButton
@onready var join_button: Button = $MainVBox/ButtonBox/JoinButton
@onready var lobby_type_option: OptionButton = $MainVBox/HostOptionsBox/LobbyTypeOption
@onready var refresh_timer: Timer = $RefreshTimer

func _ready() -> void:
	# Conectar señales del NetworkManager.
	# Estas señales deben existir en tu NetworkManager.gd
	NetworkManager.lobbies_updated.connect(_on_lobbies_updated)
	
	# Configurar el temporizador para refrescar la lista cada 30 segundos
	refresh_timer.wait_time = 30.0
	refresh_timer.start()

	# Refrescar la lista por primera vez
	_on_refresh_timer_timeout()

# --- FUNCIONES CONECTADAS A NODOS DE LA UI ---

func _on_host_button_pressed() -> void:
	var lobby_type = lobby_type_option.get_item_id(lobby_type_option.selected)
	var lobby_name = "%s's Game" % Steam.getPersonaName()
	
	print("UI: Intentando crear lobby. Tipo: ", lobby_type)
	NetworkManager.create_lobby(lobby_type, lobby_name)

func _on_join_button_pressed() -> void:
	var selected_items = lobby_list.get_selected_items()
	if selected_items.is_empty():
		return
	
	var lobby_id = lobby_list.get_item_metadata(selected_items[0])
	print("UI: Intentando unirse al lobby ID: ", lobby_id)
	NetworkManager.join_lobby(lobby_id)

func _on_refresh_timer_timeout() -> void:
	print("UI: Refrescando lista de lobbies automáticamente...")
	lobby_list.clear()
	lobby_list.add_item("Buscando partidas...")
	NetworkManager.refresh_lobbies()

# --- FUNCIONES QUE RESPONDEN AL NETWORKMANAGER ---

func _on_lobbies_updated(lobbies: Array) -> void:
	lobby_list.clear()
	if lobbies.is_empty():
		lobby_list.add_item("No se encontraron partidas públicas.")
		join_button.disabled = true
		return
		
	for lobby_data in lobbies:
		var item_index = lobby_list.add_item(lobby_data["name"])
		lobby_list.set_item_metadata(item_index, lobby_data["id"])
	
	join_button.disabled = true # Se activa al seleccionar un item
