# PlayerData.gd
# Este recurso contiene la información persistente de un ÚNICO personaje.
class_name PlayerData
extends Resource

## -- ESTADÍSTICAS BASE --
# Las estadísticas que el jugador asigna a su personaje.
@export var base_stats: Stats

## -- MAESTRÍA DE ARMAS --
# El progreso del personaje con cada tipo de arma.
@export var weapon_mastery: Dictionary = {
	"SwordAndShield": 0,
	"Axe": 0,
	"Bow": 0,
	"Staff": 0
}
