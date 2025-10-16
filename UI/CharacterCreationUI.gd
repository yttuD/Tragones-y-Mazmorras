# CharacterCreationUI.gd
extends Control

const TOTAL_STAT_POINTS = 20

# Referencias a los nodos de la UI
@onready var points_label: Label = $PointsLabel
@onready var name_edit: LineEdit = $NameEdit
@onready var strength_spinbox: SpinBox = $StatsContainer/StrengthSpinBox
@onready var dexterity_spinbox: SpinBox = $StatsContainer/DexteritySpinBox
@onready var intelligence_spinbox: SpinBox = $StatsContainer/IntelligenceSpinBox
@onready var endurance_spinbox: SpinBox = $StatsContainer/EnduranceSpinBox
@onready var confirm_button: Button = $ConfirmButton

# Guardamos los SpinBox en un array para iterar fácilmente
var stat_spinboxes: Array[SpinBox]

func _ready() -> void:
	stat_spinboxes = [strength_spinbox, dexterity_spinbox, intelligence_spinbox, endurance_spinbox]
	
	# Conectamos las señales de cambio de valor de los SpinBox
	for spinbox in stat_spinboxes:
		spinbox.value_changed.connect(_on_stat_changed)
	
	name_edit.text_changed.connect(_on_name_changed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# Estado inicial
	update_points_label()
	update_confirm_button_state()

func _on_stat_changed(_new_value: float) -> void:
	update_points_label()
	update_confirm_button_state()

func _on_name_changed(_new_text: String) -> void:
	update_confirm_button_state()

func get_points_spent() -> int:
	var spent_points = 0
	for spinbox in stat_spinboxes:
		# Restamos el valor base de cada estadística (asumamos que es 1)
		spent_points += spinbox.value - 1
	return spent_points

func update_points_label() -> void:
	var points_left = TOTAL_STAT_POINTS - get_points_spent()
	points_label.text = "Puntos restantes: %d" % points_left
	
	# Evitar que los SpinBox permitan gastar más puntos de los disponibles
	for spinbox in stat_spinboxes:
		var current_value = spinbox.value
		spinbox.max_value = current_value + points_left

func update_confirm_button_state() -> void:
	var points_spent = get_points_spent()
	var name_is_valid = not name_edit.text.is_empty()
	
	# El botón solo se activa si se han gastado todos los puntos y hay un nombre
	confirm_button.disabled = not (points_spent == TOTAL_STAT_POINTS and name_is_valid)

func _on_confirm_button_pressed() -> void:
	confirm_button.disabled = true
	confirm_button.text = "Creando..."

	var character_name = name_edit.text
	
	# Creamos el diccionario de estadísticas
	var stats_dict = {
		"fuerza": strength_spinbox.value,
		"destreza": dexterity_spinbox.value,
		"inteligencia": intelligence_spinbox.value,
		"resistencia": endurance_spinbox.value
	}
	
	# Llamamos a ProfileManager para crear y guardar el personaje
	ProfileManager.create_new_character_with_stats(character_name, stats_dict)
	
	# Finalmente, vamos a la escena principal del juego
	get_tree().change_scene_to_file(NetworkManager.MAIN_GAME_SCENE_PATH)
