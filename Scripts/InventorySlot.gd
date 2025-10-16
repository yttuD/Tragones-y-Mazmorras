# InventorySlot.gd
extends TextureButton

# Señal que emitiremos al hacer clic derecho. Enviará el ítem y la posición global del mouse.
signal right_clicked(item: EquipmentItem, position: Vector2)

@onready var icon = $Icon
var item: EquipmentItem # Variable para guardar el objeto que este slot representa.

# Esta función actualiza la apariencia del slot.
func display_item(p_item: EquipmentItem):
	item = p_item
	if item:
		icon.texture = item.icon
		icon.visible = true
	else:
		icon.visible = false

# Detectamos el input del mouse sobre este slot.
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		# Si se hace clic derecho, emitimos nuestra señal personalizada.
		right_clicked.emit(item, get_global_mouse_position())
