# character.gd

class_name Character
extends RefCounted

var name: String
var level: int

# El constructor: se usa para crear un nuevo personaje en el juego.
func _init(p_name: String, p_level: int):
	self.name = p_name
	self.level = p_level

# --- FUNCIONES PARA GUARDADO Y CARGA ---

# Convierte los datos del personaje a un Diccionario para poder guardarlo en un archivo JSON.
func to_dict() -> Dictionary:
	return {
		"name": self.name,
		"level": self.level
	}

# Crea una instancia de Personaje a partir de un Diccionario (cuando cargas desde un archivo).
static func from_dict(data: Dictionary) -> Character:
	if not data:
		return null
	return Character.new(data.get("name", "Sin Nombre"), data.get("level", 1))
