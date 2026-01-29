extends Node3D

# --- CONFIGURAÇÕES ---
@export_group("Configuração do Spawn")
@export var lista_de_lixos: Array[PackedScene] 
@export var quantidade_minima: int = 3
@export var quantidade_maxima: int = 6
@export var intervalo_entre_spawns: float = 0.2

@export_group("Física do Arremesso")
@export var forca_expulsao: float = 8.0 
@export var espalhamento: float = 0.2 

# --- NOVO: A MIRA LASER ---
# Em vez de digitar números, usamos o Raycast para apontar
@export var mira_raycast: RayCast3D 

@onready var ponto_saida = self 

func spawnar_lote():
	if lista_de_lixos.is_empty():
		print("ERRO: Lista de lixos vazia!")
		return
	
	var qtd = randi_range(quantidade_minima, quantidade_maxima)
	
	for i in range(qtd):
		_criar_um_lixo()
		if i < qtd - 1:
			await get_tree().create_timer(intervalo_entre_spawns).timeout

func _criar_um_lixo():
	var cena_lixo = lista_de_lixos.pick_random()
	var novo_lixo = cena_lixo.instantiate()
	
	get_tree().current_scene.add_child(novo_lixo)
	novo_lixo.global_position = ponto_saida.global_position
	novo_lixo.rotation_degrees = Vector3(randf()*360, randf()*360, randf()*360)
	
	if novo_lixo is RigidBody3D:
		# --- CÁLCULO DA DIREÇÃO PELO RAYCAST ---
		var direcao_final = Vector3.DOWN # Padrão caso esqueça o Raycast
		
		if mira_raycast:
			# A mágica acontece aqui:
			# Pegamos a ponta da linha do Raycast (Target Position) no mundo global
			# e subtraímos da origem dele. Isso cria um vetor que aponta
			# EXATAMENTE para onde a linha do Raycast está desenhada no editor.
			var ponta_do_raycast = mira_raycast.to_global(mira_raycast.target_position)
			var origem_do_raycast = mira_raycast.global_position
			
			direcao_final = (ponta_do_raycast - origem_do_raycast).normalized()
		else:
			# Se você não colocar o Raycast, ele joga pra frente do Spawner como fallback
			direcao_final = -global_transform.basis.z
		
		# Adiciona o espalhamento (Spread)
		direcao_final.x += randf_range(-espalhamento, espalhamento)
		direcao_final.y += randf_range(-espalhamento, espalhamento)
		direcao_final.z += randf_range(-espalhamento, espalhamento)
		
		# Chuta!
		novo_lixo.apply_central_impulse(direcao_final.normalized() * forca_expulsao)
