extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ARREMESSO_FORCA = 10.0 
const EMPURRAO_FORCA = 1.0
const INERCIA_AO_SOLTAR = 0.35

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- SISTEMA DE SEGURAR (ESTÁTICO) ---
# Removemos Joints e HandBody. Agora é pura matemática.
var hold_distance: float = 0.0
var hold_relative_rotation: Quaternion

@onready var camera = $CameraHolder/Camera3D
@onready var raycast = $CameraHolder/Camera3D/RayCast3D

var objeto_na_mao: InteractableObject = null
var ultimo_objeto_focado = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Não precisamos mais criar HandBody nem Joint aqui

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.11))
		# Opcional: Rotacionar a câmera verticalmente (se ainda não tiver no CameraHolder)
		# camera.rotate_x(deg_to_rad(event.relative.y * -0.11))
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
	if event.is_action_pressed("mouse_left"): 
		if objeto_na_mao: soltar_objeto(0.0)
		else: tentar_pegar_objeto()
		
	if event.is_action_pressed("mouse_right"): 
		if objeto_na_mao: soltar_objeto(ARREMESSO_FORCA)
		
	if event.is_action_pressed("interact"): 
		if objeto_na_mao: 
			if objeto_na_mao.has_method("interagir_abrsir"): objeto_na_mao.interagir_abrir()
		elif raycast.is_colliding():
			var corpo = raycast.get_collider()
			if corpo.has_method("interagir_abrir"): corpo.interagir_abrir()
			

func _physics_process(delta):
	# --- MOVIMENTO DO PLAYER ---
	if not is_on_floor(): velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
	# Empurrar objetos no chão (Mantido)
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo = colisao.get_collider()
		if corpo is RigidBody3D and corpo != objeto_na_mao:
			corpo.apply_central_impulse(-colisao.get_normal() * EMPURRAO_FORCA)

	# --- ATUALIZAR POSIÇÃO DO OBJETO NA MÃO ---
	if objeto_na_mao:
		atualizar_posicao_objeto()

	# Silhueta
	_processar_silhueta()

func atualizar_posicao_objeto():
	# 1. Calcula onde o objeto "quer" estar (Baseado na distância original)
	var target_global_pos = camera.global_position - (camera.global_transform.basis.z * hold_distance)
	
	# 2. SISTEMA ANTI-CLIPPING (Evita atravessar paredes)
	# Fazemos um raio da câmera até o ponto de destino.
	# Se tiver parede no meio, puxamos o objeto para antes da parede.
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, target_global_pos)
	
	# O raio deve ignorar o próprio player e o objeto na mão
	query.exclude = [self, objeto_na_mao]
	query.collision_mask = 1 # Considera apenas o mundo (Layer 1)
	
	var result = space_state.intersect_ray(query)
	if result:
		# Se bateu na parede, coloca o objeto um pouco antes do ponto de impacto
		objeto_na_mao.global_position = result.position + (result.normal * 0.1) # 0.1 de margem
	else:
		# Se livre, vai para o alvo
		objeto_na_mao.global_position = target_global_pos
	
	# 3. Rotação: Mantém a rotação relativa à câmera (para virar junto com você)
	objeto_na_mao.global_transform.basis = camera.global_transform.basis * Basis(hold_relative_rotation)

func tentar_pegar_objeto():
	if raycast.is_colliding():
		var corpo = raycast.get_collider()
		if corpo is InteractableObject:
			objeto_na_mao = corpo
			
			add_collision_exception_with(objeto_na_mao)
			
			# Calcula a distância e rotação atuais para manter relativo
			hold_distance = camera.global_position.distance_to(objeto_na_mao.global_position)
			# Limita a distância máxima para não pegar coisas muito longe e elas ficarem longe
			hold_distance = clamp(hold_distance, 1.0, 3.0) 
			
			# Guarda a rotação relativa
			hold_relative_rotation = (camera.global_transform.basis.inverse() * objeto_na_mao.global_transform.basis).get_rotation_quaternion()
			
			# Manda o objeto congelar
			objeto_na_mao.ao_ser_pego()

func soltar_objeto(forca: float):
	if objeto_na_mao:
		# Primeiro descongela o objeto (volta a ter física)
		objeto_na_mao.ao_ser_solto()
		
		remove_collision_exception_with(objeto_na_mao)
		
		# CASO 1: ARREMESSO FORTE (Botão Direito)
		if forca > 0:
			var direcao = -camera.global_transform.basis.z
			objeto_na_mao.apply_central_impulse(direcao * forca)
			objeto_na_mao.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 2.0)
		
		# CASO 2: SOLTAR SUAVE (Botão Esquerdo)
		else:
			# AQUI ESTÁ A MÁGICA:
			# Pegamos a velocidade que o Godot calculou e reduzimos drasticamente
			objeto_na_mao.linear_velocity *= INERCIA_AO_SOLTAR
			objeto_na_mao.angular_velocity *= INERCIA_AO_SOLTAR
		
		objeto_na_mao = null

func _processar_silhueta():
	var objeto_atual = null
	
	if raycast.is_colliding():
		var colisor = raycast.get_collider()
		
		# TRAVA 1: Verifica se o objeto ainda existe no mundo ANTES de perguntar se tem o método!
		if is_instance_valid(colisor) and colisor.has_method("set_focado"):
			objeto_atual = colisor
			
	if ultimo_objeto_focado and ultimo_objeto_focado != objeto_atual:
		
		# TRAVA 2: Só tenta desligar o brilho se o objeto anterior não tiver sido destruído pela prensa
		if is_instance_valid(ultimo_objeto_focado):
			ultimo_objeto_focado.set_focado(false)
			
	if objeto_atual and objeto_atual != ultimo_objeto_focado:
		objeto_atual.set_focado(true)
		
	ultimo_objeto_focado = objeto_atual
	
	
