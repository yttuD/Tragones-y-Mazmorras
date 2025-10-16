# PlayerSlot.gd
extends PanelContainer

# Referencias a los nodos DENTRO de PlayerSlot.tscn
# ¡Asegúrate de que los nombres coincidan con tu escena!
@onready var player_name_label: Label = $HBoxContainer/PlayerNameLabel
@onready var player_avatar_texture: TextureRect = $HBoxContainer/PlayerAvatarTexture
@onready var ready_indicator: ColorRect = $HBoxContainer/ReadyIndicator

# Esta variable será ASIGNADA desde GameLobbyUI.gd.
# Usamos un 'setter' para que la UI se actualice automáticamente.
var player_info: Dictionary = {}:
	set(value):
		player_info = value
		if is_node_ready():
			_update_visuals()

func _ready() -> void:
	# Actualizamos la UI en caso de que la información se haya asignado antes de que el nodo estuviera listo.
	_update_visuals()

func _update_visuals() -> void:
	# Asignar nombre y avatar
	player_name_label.text = player_info.get("name", "Cargando...")
	var avatar_texture = player_info.get("avatar")
	if avatar_texture:
		player_avatar_texture.texture = avatar_texture

	# Mostrar/Ocultar el indicador de "listo"
	ready_indicator.visible = player_info.get("is_ready", false)
