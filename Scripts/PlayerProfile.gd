# PlayerProfile.gd
# Este recurso representa la cuenta completa de un jugador,
# incluyendo todos sus personajes.
class_name PlayerProfile
extends Resource

# Un diccionario que mapea el nombre de un personaje (ej: "Martita")
# a su recurso PlayerData correspondiente.
@export var characters: Dictionary = {}

# Aquí podríamos añadir otros datos de la cuenta, como logros,
# cosméticos desbloqueados, etc.
