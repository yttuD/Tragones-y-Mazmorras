# MusicManager.gd
extends Node

@onready var audio_player := $AudioStreamPlayer

@export var menu_music: Array[AudioStream]
@export var game_music: Array[AudioStream]

enum Playlist { NONE, MENU, GAME }
var current_playlist = Playlist.NONE

func _ready():
	audio_player.finished.connect(_on_track_finished)

func play_menu_music():
	if current_playlist == Playlist.MENU and audio_player.playing:
		return
	current_playlist = Playlist.MENU
	_play_random_track_from_current_playlist()

func play_game_music():
	if current_playlist == Playlist.GAME and audio_player.playing:
		return
	current_playlist = Playlist.GAME
	_play_random_track_from_current_playlist()

# ¡SOLUCIÓN! Hacemos que la función de detener sea más robusta.
func stop_music():
	print("MusicManager: Música detenida.")
	current_playlist = Playlist.NONE
	audio_player.stop()
	audio_player.stream = null # Vaciamos el reproductor para asegurar el silencio.

func _play_random_track_from_current_playlist():
	var active_list = []
	match current_playlist:
		Playlist.MENU:
			active_list = menu_music
		Playlist.GAME:
			active_list = game_music
	if active_list.is_empty():
		stop_music()
		return
	active_list.shuffle()
	audio_player.stream = active_list[0]
	audio_player.play()

func _on_track_finished():
	_play_random_track_from_current_playlist()
