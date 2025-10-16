# ProfileManager.gd
extends Node

const SAVE_DIRECTORY = "user://Saves"
const PROFILE_SAVE_FILE = "PlayerProfile.tres"

# La variable clave que faltaba o estaba mal declarada
var current_profile: PlayerProfile

func _ready():
	_ensure_save_directory_exists()
	load_profile()
	
	# Configurar el auto-guardado
	var auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 900 # 15 minutos
	auto_save_timer.autostart = true
	auto_save_timer.connect("timeout",Callable(self,"save_profile"))
	add_child(auto_save_timer)

func _notification(what):
	# Verificamos si la notificación es la de 'cerrar ventana'
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_profile()
		get_tree().quit() # Cierra el juego de forma segura

func _ensure_save_directory_exists():
	DirAccess.make_dir_absolute(SAVE_DIRECTORY)

func load_profile():
	var save_path = SAVE_DIRECTORY.path_join(PROFILE_SAVE_FILE)
	if FileAccess.file_exists(save_path):
		current_profile = ResourceLoader.load(save_path)
		print("ProfileManager: Perfil de jugador cargado.")
	else:
		current_profile = PlayerProfile.new()
		print("ProfileManager: No se encontró perfil. Creando uno nuevo.")
		save_profile()

func save_profile():
	if not current_profile: return
	var save_path = SAVE_DIRECTORY.path_join(PROFILE_SAVE_FILE)
	ResourceSaver.save(current_profile, save_path)
	print("ProfileManager: Perfil de jugador guardado.")

func create_new_character(character_name: String):
	if not current_profile.characters.has(character_name):
		var new_player_data = PlayerData.new()
		var default_stats = Stats.new()
		
		default_stats.character_name = character_name
		default_stats.fuerza = 5
		default_stats.destreza = 5
		default_stats.inteligencia = 5
		default_stats.resistencia = 10
		
		new_player_data.base_stats = default_stats
		
		current_profile.characters[character_name] = new_player_data
		print("ProfileManager: Personaje '", character_name, "' creado.")
		save_profile()
	else:
		print("ProfileManager: El personaje '", character_name, "' ya existe.")

func create_new_character_with_stats(character_name: String, stats: Dictionary):
	if not current_profile.characters.has(character_name):
		var new_player_data = PlayerData.new()
		var new_stats = Stats.new()
		
		new_stats.character_name = character_name
		new_stats.fuerza = stats.get("fuerza", 1)
		new_stats.destreza = stats.get("destreza", 1)
		new_stats.inteligencia = stats.get("inteligencia", 1)
		new_stats.resistencia = stats.get("resistencia", 1)
		
		new_player_data.base_stats = new_stats
		
		current_profile.characters[character_name] = new_player_data
		print("ProfileManager: Personaje '", character_name, "' creado con estadísticas personalizadas.")
		save_profile()
	else:
		print("ProfileManager: El personaje '", character_name, "' ya existe.")
