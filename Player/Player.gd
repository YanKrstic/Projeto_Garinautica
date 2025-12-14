extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ARREMESSO_FORCA = 8.0 
const EMPURRAO_FORCA = 2.0 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- SISTEMA DE FÍSICA (JOINT) ---
var joint: Generic6DOFJoint3D
var hand_body: StaticBody3D 

# MUDANÇA: Em vez de guardar só a distância, guardamos a posição/rotação RELATIVA
# Isso memoriza "como" o objeto estava em relação à câmera quando você o pegou.
var hold_relative_transform: Transform3D 

@onready var camera = $CameraHolder/Camera3D
@onready var raycast = $CameraHolder/Camera3D/RayCast3D

var objeto_na_mao: InteractableObject = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Criar a "Mão Física" invisível
	hand_body = StaticBody3D.new()
	hand_body.top_level = true 
	
	# SEGURANÇA: A mão em si não deve colidir com nada no mundo
	hand_body.collision_layer = 0
	hand_body.collision_mask = 0
	
	add_child(hand_body)
	
	# Criar o Joint
	joint = Generic6DOFJoint3D.new()
	add_child(joint)
	
	# Configuração dos limites do Joint (Travado)
	_configurar_joint_travado()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.11))
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
	if event.is_action_pressed("mouse_left"): 
		if objeto_na_mao:
			soltar_objeto(0.0)
		else:
			tentar_pegar_objeto()
			
	if event.is_action_pressed("mouse_right"): 
		if objeto_na_mao:
			soltar_objeto(ARREMESSO_FORCA)

	if event.is_action_pressed("interact"): 
		if objeto_na_mao:
			if objeto_na_mao.has_method("interagir_abrir"):
				objeto_na_mao.interagir_abrir()
		elif raycast.is_colliding():
			var corpo = raycast.get_collider()
			if corpo.has_method("interagir_abrir"):
				corpo.interagir_abrir()

func _physics_process(delta):
	# Gravidade e Movimento Padrão
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
	
	# --- 1. EMPURRAR OBJETOS (CORRIGIDO) ---
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo = colisao.get_collider()
		
		# SEGURANÇA: Só empurra se for um RigidBody E se NÃO for o objeto que estamos segurando
		if corpo is RigidBody3D and corpo != objeto_na_mao:
			corpo.apply_central_impulse(-colisao.get_normal() * EMPURRAO_FORCA)

	# --- 2. ATUALIZAR MÃO (MÁGICA DO "THE LONG DRIVE") ---
	if objeto_na_mao:
		# Pegamos a posição atual da câmera e multiplicamos pela posição relativa memorizada.
		# Isso faz a mão ir para onde o objeto deveria estar relativo ao seu rosto agora.
		hand_body.global_transform = camera.global_transform * hold_relative_transform

func tentar_pegar_objeto():
	if raycast.is_colliding():
		var corpo = raycast.get_collider()
		if corpo is InteractableObject:
			objeto_na_mao = corpo
			add_collision_exception_with(objeto_na_mao)
			# CÁLCULO MÁGICO:
			# "Qual é a posição deste objeto RELATIVA à minha câmera agora?"
			# Guardamos essa diferença (offset).
			hold_relative_transform = camera.global_transform.affine_inverse() * objeto_na_mao.global_transform
			
			# Movemos a mão imediatamente para lá para evitar "pulos" visuais no primeiro frame
			hand_body.global_transform = objeto_na_mao.global_transform
			
			# Conecta
			joint.node_a = hand_body.get_path()
			joint.node_b = objeto_na_mao.get_path()
			
			objeto_na_mao.ao_ser_pego()

func soltar_objeto(forca: float):
	if objeto_na_mao:
		remove_collision_exception_with(objeto_na_mao)
		joint.node_a = NodePath("")
		joint.node_b = NodePath("")
		
		objeto_na_mao.ao_ser_solto()
		
		if forca > 0:
			var direcao = -camera.global_transform.basis.z
			objeto_na_mao.apply_central_impulse(direcao * forca)
		
		objeto_na_mao = null

func _configurar_joint_travado():
	# Eixo X
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	
	# Eixo Y
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	
	# Eixo Z
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	
	# Angular
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)

	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
