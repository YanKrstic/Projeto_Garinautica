extends Node3D

@export_group("Configuração do Spawn")
@export var lista_de_lixos: Array[PackedScene] 
@export var intervalo_entre_spawns: float = 0.2

@export_group("Física do Arremesso")
@export var forca_expulsao: float = 8.0 
@export var espalhamento: float = 0.2 
@export var mira_raycast: RayCast3D 

@export_group("Referências do Tubo")
@export var ponto_spawn: Marker3D
@export var luz_alerta: OmniLight3D

var lixos_armazenados: int = 0

func _ready():
	add_to_group("tubos_de_coleta")
	_atualizar_visual()

func receber_lixo(quantidade: int = 1):
	lixos_armazenados += quantidade
	_atualizar_visual()
	print("Tubo: Recebi ", quantidade, " lixos do radar! Total: ", lixos_armazenados)

func acionar_tubo():
	if lixos_armazenados > 0:
		var qtd_para_ejetar = lixos_armazenados
		lixos_armazenados = 0 # Esvazia o tubo instantaneamente
		_atualizar_visual() # Apaga a luz na hora
		
		print("Tubo: Ejetando ", qtd_para_ejetar, " lixo(s) com física!")
		
		# Cospe tudo o que estava guardado, um por um!
		for i in range(qtd_para_ejetar):
			_criar_um_lixo()
			if i < qtd_para_ejetar - 1:
				await get_tree().create_timer(intervalo_entre_spawns).timeout
	else:
		print("Tubo: Vazio. Vá pilotar e buscar mais!")

func _atualizar_visual():
	if luz_alerta:
		luz_alerta.light_energy = 2.0 if lixos_armazenados > 0 else 0.0

# --- A SUA LÓGICA DE FÍSICA INTACTA ---
func _criar_um_lixo():
	if lista_de_lixos.is_empty():
		print("ERRO: A lista de lixos está vazia no Inspector!")
		return
		
	var cena_lixo = lista_de_lixos.pick_random()
	var novo_lixo = cena_lixo.instantiate()
	
	get_tree().current_scene.add_child(novo_lixo)
	
	if ponto_spawn:
		novo_lixo.global_position = ponto_spawn.global_position
		
	novo_lixo.rotation_degrees = Vector3(randf()*360, randf()*360, randf()*360)
	
	if novo_lixo is RigidBody3D:
		var direcao_final = Vector3.DOWN # Padrão caso não haja Raycast
		
		if mira_raycast:
			var ponta_do_raycast = mira_raycast.to_global(mira_raycast.target_position)
			var origem_do_raycast = mira_raycast.global_position
			direcao_final = (ponta_do_raycast - origem_do_raycast).normalized()
		else:
			direcao_final = -global_transform.basis.z
		
		direcao_final.x += randf_range(-espalhamento, espalhamento)
		direcao_final.y += randf_range(-espalhamento, espalhamento)
		direcao_final.z += randf_range(-espalhamento, espalhamento)
		
		novo_lixo.apply_central_impulse(direcao_final.normalized() * forca_expulsao)
