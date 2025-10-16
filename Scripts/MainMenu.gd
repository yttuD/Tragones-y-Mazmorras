# MainMenu.gd
extends Control

# Hacemos una referencia a nuestro botón "Jugar".
@onready var play_button = $CenterContainer/VBoxContainer/PlayButton

# La ruta a la escena del lobby que ya creamos.
# ¡Asegúrate de que esta ruta sea correcta!
const LOBBY_SCENE_PATH = "res://Scripts/LobbySelectionUI.gd"

func _ready():
	#Le decimos al gestor que reanude la música del menú.
	MusicManager.play_menu_music()
	# Conectamos la señal 'pressed' del botón a nuestra función.
	play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed():
	# Cuando se presiona el botón, simplemente cambiamos a la escena del lobby.
	get_tree().change_scene_to_file(LOBBY_SCENE_PATH)
