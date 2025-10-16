# PlayerSlot.gd
extends HBoxContainer

@onready var avatar_texture = $AvatarTexture
@onready var name_label = $NameLabel

func set_player_data(_peer_id: int, info: Dictionary):
	name_label.text = info.get("name", "Cargando...")

	# ¡CAMBIO CLAVE! Obtenemos la RUTA del avatar desde la información recibida del host.
	var avatar_path = info.get("avatar_path")

	# Si la ruta existe y el archivo es válido, cargamos la imagen.
	if avatar_path and FileAccess.file_exists(avatar_path):
		avatar_texture.texture = load(avatar_path)
	else:
		# Si por alguna razón no hay ruta o no se encuentra el archivo,
		# no mostramos ninguna imagen para indicar un slot vacío o un error.
		avatar_texture.texture = null
		print("Advertencia: No se pudo cargar el avatar en la ruta: ", avatar_path)
