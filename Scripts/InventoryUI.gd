# InventoryUI.gd
extends Control

const InventorySlotScene = preload("res://UI/InventorySlot.tscn")

# --- Referencias a los Contenedores de Slots ---
@onready var inventory_grid = $MainHBox/InventoryGrid
@onready var equipment_panel = $MainHBox/EquipmentPanel
@onready var consumables_box = $MainHBox/CharacterPanel/ConsumablesBox

# --- Referencia al Modelo 3D ---
@onready var model_animation_player = $MainHBox/CharacterPanel/ViewportContainer/CharacterViewport/Player/Sketchfab_Scene/AnimationPlayer

var context_menu: PopupMenu
var player: Player
var current_item_clicked: EquipmentItem

func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	
	context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	
	# Generamos los 63 slots vacíos del inventario.
	for i in Inventory.MAX_SLOTS:
		var new_slot = InventorySlotScene.instantiate()
		inventory_grid.add_child(new_slot)
		new_slot.right_clicked.connect(_on_inventory_slot_right_clicked)
		new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

	# Conectamos la señal 'pressed' para cada slot de equipo.
	equipment_panel.get_node("HelmetSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.CASCO))
	equipment_panel.get_node("ChestSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.PECHERA))
	equipment_panel.get_node("GlovesSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.GUANTES))
	equipment_panel.get_node("PantsSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.PANTALONES))
	equipment_panel.get_node("BootsSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.BOTAS))
	equipment_panel.get_node("WeaponSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.ARMA))
	consumables_box.get_node("PotionSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.POTION))
	consumables_box.get_node("FoodSlot").pressed.connect(_on_equipped_slot_pressed.bind(EquipmentItem.Slot.FOOD))

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("inventory"):
		if visible:
			hide_inventory()
		elif is_instance_valid(player):
			show_inventory()

func show_inventory():
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	model_animation_player.play("5Idle")
	update_display()

func hide_inventory():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func initialize(p_player: Player):
	player = p_player
	if not player.inventory_updated.is_connected(update_display):
		player.inventory_updated.connect(update_display)
	update_display()

func update_display():
	if not is_instance_valid(player) or not player.inventory: return
	
	# 1. Actualizar el inventario (mochila).
	var slots = inventory_grid.get_children()
	for i in range(slots.size()):
		if i < player.inventory.items.size():
			slots[i].display_item(player.inventory.items[i])
		else:
			slots[i].display_item(null)
			
	# 2. Actualizar los slots de equipo.
	_update_equipped_slot(equipment_panel.get_node("HelmetSlot"), player.inventory.equipped_items[EquipmentItem.Slot.CASCO])
	_update_equipped_slot(equipment_panel.get_node("ChestSlot"), player.inventory.equipped_items[EquipmentItem.Slot.PECHERA])
	_update_equipped_slot(equipment_panel.get_node("GlovesSlot"), player.inventory.equipped_items[EquipmentItem.Slot.GUANTES])
	_update_equipped_slot(equipment_panel.get_node("PantsSlot"), player.inventory.equipped_items[EquipmentItem.Slot.PANTALONES])
	_update_equipped_slot(equipment_panel.get_node("BootsSlot"), player.inventory.equipped_items[EquipmentItem.Slot.BOTAS])
	_update_equipped_slot(equipment_panel.get_node("WeaponSlot"), player.inventory.equipped_items[EquipmentItem.Slot.ARMA])
	_update_equipped_slot(consumables_box.get_node("PotionSlot"), player.inventory.equipped_items.get(EquipmentItem.Slot.POTION))
	_update_equipped_slot(consumables_box.get_node("FoodSlot"), player.inventory.equipped_items.get(EquipmentItem.Slot.FOOD))

func _update_equipped_slot(slot_button: TextureButton, item: EquipmentItem):
	if item and item.icon:
		slot_button.texture_normal = item.icon
	else:
		slot_button.texture_normal = null

# --- FUNCIONES DE INTERACCIÓN ---

# ¡NUEVA FUNCIÓN! Se llama al hacer clic izquierdo en un slot del inventario.
func _on_inventory_slot_pressed(slot_node: Node):
	if is_instance_valid(player) and is_instance_valid(slot_node.item):
		player.equip_item(slot_node.item)

# ¡NUEVA FUNCIÓN! Se llama al hacer clic izquierdo en un slot de equipo.
func _on_equipped_slot_pressed(slot_type: EquipmentItem.Slot):
	if is_instance_valid(player):
		player.unequip_item(slot_type)

func _on_inventory_slot_right_clicked(item: EquipmentItem, mouse_position: Vector2):
	if not item: return
	current_item_clicked = item
	
	context_menu.clear()
	context_menu.add_item("Equipar", 0)
	context_menu.add_item("Eliminar", 1)
	
	context_menu.position = mouse_position
	context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	if not current_item_clicked: return
	
	match id:
		0: # Equipar
			player.equip_item(current_item_clicked)
		1: # Eliminar
			player.delete_item(current_item_clicked)
