# Inventory.gd
class_name Inventory
extends Resource

# Maximo de inventario en la mochila
const MAX_SLOTS = 63
# Los objetos que el jugador tiene en su "mochila".
@export var items: Array[EquipmentItem]

# Los objetos que el jugador tiene puestos. Usamos un diccionario
# para acceder fácilmente al objeto de un slot específico.
@export var equipped_items: Dictionary = {
	EquipmentItem.Slot.CASCO: null,
	EquipmentItem.Slot.PECHERA: null,
	EquipmentItem.Slot.GUANTES: null,
	EquipmentItem.Slot.PANTALONES: null,
	EquipmentItem.Slot.BOTAS: null,
	EquipmentItem.Slot.ARMA: null
}
