# Player.gd
class_name Player
extends CharacterBody3D

signal inventory_updated

# --- REFERENCIAS A RECURSOS Y NODOS ---
@export var player_data: PlayerData
@export var inventory: Inventory

@onready var animation_player = $Sketchfab_Scene/AnimationPlayer
@onready var head = $Head
# ¡NUEVO! Hacemos una referencia a la UI del inventario.
# Asegúrate de que esta ruta sea correcta según tu escena Main.tscn.
@onready var inventory_ui = get_node("/root/Main/InventoryUI")

# --- Variables de Estado ---
var controls_enabled: bool = true

# --- Variables de Movimiento y Combate ---
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
var max_health: float = 100.0
var max_stamina: float = 100.0
var current_movement_speed: float = 4.0
var attack_speed_multiplier: float = 1.0
var total_stats: Stats = Stats.new()

# --- Variables de Física ---
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var jump_velocity: float = 6.0

# --- Variables de la Cámara ---
@export var mouse_sensitivity: float = 0.25
const CAMERA_ANGLE_LIMIT = 80.0

# ---------------------------------------------------------------------
# INICIALIZACIÓN Y ESTADÍSTICAS
# ---------------------------------------------------------------------
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# El jugador se presenta a la UI del inventario en cuanto existe.
	if is_instance_valid(inventory_ui):
		inventory_ui.initialize(self)
		
	if not player_data or not inventory:
		print("¡ADVERTENCIA! No se ha asignado PlayerData o Inventory al nodo Player.")
		return
	recalculate_all_stats()

func recalculate_all_stats():
	if not player_data: return
	total_stats = player_data.get_total_stats(inventory.equipped_items)
	max_health = 100.0 + (total_stats.fuerza * 1.0)
	max_stamina = 100.0 + (total_stats.resistencia * 5.0)
	current_movement_speed = walk_speed * (1.0 + total_stats.destreza * 0.01)
	attack_speed_multiplier = 1.0 + (total_stats.destreza * 0.05)
	_apply_stats_to_animation_player()
	
func _apply_stats_to_animation_player():
	if animation_player:
		animation_player.speed_scale = attack_speed_multiplier

# ---------------------------------------------------------------------
# INPUT Y MOVIMIENTO
# ---------------------------------------------------------------------
func _unhandled_input(event: InputEvent):
	# ¡LÓGICA CLAVE! El jugador siempre escucha la tecla de inventario.
	if event.is_action_just_pressed("inventory"):
		toggle_inventory()

	if not controls_enabled: return

	if Input.is_action_just_pressed("mouse_controller"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_x(deg_to_rad(event.relative.y * mouse_sensitivity))
		self.rotate_y(deg_to_rad(event.relative.x * mouse_sensitivity))
		var camera_rotation = head.rotation_degrees
		camera_rotation.x = clamp(camera_rotation.x, -CAMERA_ANGLE_LIMIT, CAMERA_ANGLE_LIMIT)
		head.rotation_degrees = camera_rotation

func _physics_process(delta: float):
	if not player_data: return

	if not controls_enabled:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		animation_player.play("5Idle")
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var is_running = Input.is_action_pressed("run")
	var final_run_speed = run_speed * (1.0 + total_stats.destreza * 0.01)
	var speed = final_run_speed if is_running else current_movement_speed
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()
	update_animations(is_running)

func update_animations(is_running: bool):
	if not is_on_floor():
		animation_player.play("7Jump")
	else:
		if velocity.length() > 0.1:
			if is_running:
				animation_player.play("9Rurring")
			else:
				animation_player.play("12Walking")
		else:
			animation_player.play("5Idle")

# ---------------------------------------------------------------------
# GESTIÓN DEL INVENTARIO
# ---------------------------------------------------------------------
func toggle_inventory():
	inventory_ui.visible = not inventory_ui.visible
	if inventory_ui.visible:
		disable_controls()
	else:
		enable_controls()

func disable_controls():
	controls_enabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func enable_controls():
	controls_enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func equip_item(item_to_equip: EquipmentItem):
	if not item_to_equip or not inventory or not inventory.items.has(item_to_equip): return
	var slot = item_to_equip.slot
	if inventory.equipped_items[slot] != null:
		unequip_item(slot)
	inventory.items.erase(item_to_equip)
	inventory.equipped_items[slot] = item_to_equip
	recalculate_all_stats()
	inventory_updated.emit()

func unequip_item(slot: EquipmentItem.Slot):
	if not inventory: return
	var item_to_unequip = inventory.equipped_items.get(slot)
	if not item_to_unequip: return
	inventory.equipped_items[slot] = null
	inventory.items.append(item_to_unequip)
	recalculate_all_stats()
	inventory_updated.emit()

func delete_item(item_to_delete: EquipmentItem):
	if not inventory or not inventory.items.has(item_to_delete): return
	inventory.items.erase(item_to_delete)
	inventory_updated.emit()
