extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ARREMESSO_FORCA = 10.0 
const EMPURRAO_FORCA = 1.0
const INERCIA_AO_SOLTAR = 0.35

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- SISTEMA DE ESTADOS ---
var estado_atual: String = "LIVRE" # Pode ser "LIVRE" ou "PILOTANDO"
var leme_atual = null # Guarda o leme que estamos a usar

# --- SISTEMA DE SEGURAR ---
var hold_distance: float = 0.0
var hold_relative_rotation: Quaternion
var objeto_na_mao: InteractableObject = null
var ultimo_objeto_focado = null
var objeto_interacao_continua = null

@onready var camera = $CameraHolder/Camera3D
@onready var raycast = $CameraHolder/Camera3D/RayCast3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
		
	# --- SE ESTIVER LIVRE PARA ANDAR ---
	if estado_atual == "LIVRE":
		# Todo o seu código de rodar a câmera deve estar DENTRO deste bloco!
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(event.relative.x * -0.11))
			#camera.rotate_x(deg_to_rad(event.relative.y * -0.11)) # (Se a sua câmera mexe aqui)
			
		if event.is_action_pressed("mouse_left"): 
			if objeto_na_mao: soltar_objeto(0.0)
			else: tentar_pegar_objeto()
			
		if event.is_action_pressed("mouse_right"): 
			if objeto_na_mao: soltar_objeto(ARREMESSO_FORCA)
			
		if event.is_action_pressed("interact"): 
			if raycast.is_colliding():
				var corpo = raycast.get_collider()
				if corpo.has_method("interagir_abrir"):
					corpo.interagir_abrir()
					return 
			if objeto_na_mao and objeto_na_mao.has_method("interagir_abrir"): 
				objeto_na_mao.interagir_abrir()
				
	# --- SE ESTIVER PRESO NO LEME ---
	elif estado_atual == "PILOTANDO":
		# Aperta 'E' novamente para sair do leme
		if event.is_action_pressed("interact"):
			sair_do_leme()
			return

func _process(delta):
	if objeto_na_mao:
		atualizar_posicao_objeto()

func _physics_process(delta):
	# Se estiver livre, a gravidade funciona normalmente
	if estado_atual == "LIVRE":
		if not is_on_floor(): velocity.y -= gravity * delta
		if Input.is_action_pressed("ui_accept") and is_on_floor(): velocity.y = JUMP_VELOCITY 
		
		var input_dir = Input.get_vector("a", "d", "w", "s")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
		_processar_silhueta()
		_processar_interacao_continua(delta)
		
	# SE ESTIVER NO LEME:
	else:
		# Desliga o motor do player e Zera a gravidade para ele não cair!
		velocity = Vector3.ZERO
	
			
	move_and_slide()
	
	# Empurrar objetos no chão
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo = colisao.get_collider()
		if corpo is RigidBody3D and corpo != objeto_na_mao:
			corpo.apply_central_impulse(-colisao.get_normal() * EMPURRAO_FORCA)



func entrar_no_leme(leme):
	estado_atual = "PILOTANDO"
	leme_atual = leme
	if objeto_na_mao: soltar_objeto(0.0) 
	
	# MÁGICA: Liga a câmera do leme (A do Player desliga automaticamente)
	if leme.camera_leme:
		leme.camera_leme.make_current()
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 

func sair_do_leme():
	estado_atual = "LIVRE"
	leme_atual = null
	
	# MÁGICA: Devolve a visão para a câmera original do Player
	camera.make_current()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
			
			raycast.add_exception(objeto_na_mao)
			
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
		raycast.remove_exception(objeto_na_mao)
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
	
# --- SISTEMA DE SEGURAR (HOLD TO INTERACT) ---

func _processar_interacao_continua(delta):
	if Input.is_action_pressed("interact") and raycast.is_colliding():
		var corpo = raycast.get_collider()
		
		# TRAVA DE SEGURANÇA: Garante que o corpo ainda é válido e existe no mundo
		if is_instance_valid(corpo) and corpo.has_method("interagir_segurando"):
			objeto_interacao_continua = corpo
			corpo.interagir_segurando(delta, self)
			return

	if objeto_interacao_continua:
		if is_instance_valid(objeto_interacao_continua) and objeto_interacao_continua.has_method("cancelar_interacao"):
			objeto_interacao_continua.cancelar_interacao(self)
		objeto_interacao_continua = null
