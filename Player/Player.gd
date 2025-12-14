extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ARREMESSO_FORCA = 10.0 # Força do arremesso

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Referências aos nós que criamos no Passo 1
@onready var raycast = $CameraHolder/Camera3D/RayCast3D
@onready var hold_pos = $CameraHolder/Camera3D/HoldPosition

# Variável para guardar o objeto que estamos segurando
var objeto_na_mao: InteractableObject = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.11))
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
	# --- SISTEMA DE INTERAÇÃO ---
	
	# Botão Esquerdo: PEGAR / SOLTAR SUAVE
	if event.is_action_pressed("mouse_left"): # Configure "mouse_left" no Input Map
		if objeto_na_mao:
			soltar_objeto(0.0)
		else:
			tentar_pegar_objeto()
			
	# Botão Direito: ARREMESSAR
	if event.is_action_pressed("mouse_right"): # Configure "mouse_right" no Input Map
		if objeto_na_mao:
			soltar_objeto(ARREMESSO_FORCA)

	# Tecla E: ABRIR
	if event.is_action_pressed("interact"): # Configure "interact" (tecla E)
		if raycast.is_colliding():
			var corpo = raycast.get_collider()
			# Verifica se o objeto tem a função de abrir
			if corpo.has_method("interagir_abrir"):
				corpo.interagir_abrir()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# --- ATUALIZAR POSIÇÃO DO OBJETO SEGURADO ---
	if objeto_na_mao:
		# Mover o objeto para a posição do HoldPosition
		# Usamos lerp (interpolação) para ficar suave e ter um "peso"
		var destino = hold_pos.global_position
		objeto_na_mao.global_position = objeto_na_mao.global_position.lerp(destino, 20 * delta)
		# Opcional: Rotacionar igual a câmera
		objeto_na_mao.rotation = hold_pos.global_rotation

# FUNÇÕES AUXILIARES

func tentar_pegar_objeto():
	if raycast.is_colliding():
		var corpo = raycast.get_collider()
		# Verifica se o objeto é do tipo InteractableObject
		if corpo is InteractableObject:
			objeto_na_mao = corpo
			objeto_na_mao.interagir_pegar(hold_pos)

func soltar_objeto(forca_frente: float):
	if objeto_na_mao:
		# Calcula a direção para frente da câmera
		var direcao_arremesso = -get_viewport().get_camera_3d().global_transform.basis.z
		objeto_na_mao.interagir_soltar(direcao_arremesso * forca_frente)
		objeto_na_mao = null
