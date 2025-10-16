# MainMenu.gd
extends Control

# Hacemos una referencia a nuestro botón "Jugar".
@onready var play_button = $CenterContainer/VBoxContainer/PlayButton

func _ready():
	# Le decimos al gestor que reanude la música del menú.
	MusicManager.play_menu_music()
	# Conectamos la señal 'pressed' del botón a nuestra función.
	play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed():
	# Desactivamos el botón para evitar múltiples clics
	play_button.disabled = true
	play_button.text = "Creando sala..."
	
	# Le pedimos al NetworkManager que cree un lobby privado.
	# El tipo 2 corresponde a LOBBY_TYPE_FRIENDS_ONLY en GodotSteam.
	# Esto hace la sala invisible en el buscador público, pero accesible para amigos.
	var lobby_name = "%s's Game" % Steam.getPersonaName()
	NetworkManager.create_lobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, lobby_name)
