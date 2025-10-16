# EquipmentItem.gd
class_name EquipmentItem
extends Resource

enum Slot { CASCO, PECHERA, GUANTES, PANTALONES, BOTAS, ARMA, POTION, FOOD }

@export var nombre: String = "Nuevo Ítem"
@export var slot: Slot
@export var bonus_stats: Stats
@export var icon: Texture2D
