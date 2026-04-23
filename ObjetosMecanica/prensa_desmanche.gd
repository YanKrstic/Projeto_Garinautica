extends StaticBody3D

@export var area_esmagamento: Area3D
@export var ponto_de_saida: Marker3D

func spawnar_lote():
	if not area_esmagamento or not ponto_de_saida:
		print("ERRO: Faltam nós na prensa!")
		return
		
	var corpos = area_esmagamento.get_overlapping_bodies()
	var tem_lixo = false
	
	var soma_plastico = 0
	var soma_metal = 0
	var soma_papel = 0
	var soma_vidro = 0
	
	# 1. VARRE A ÁREA DE ESMAGAMENTO
	for corpo in corpos:
		if "peso_total" in corpo:
			tem_lixo = true
			
			if corpo.has_method("calcular_relatorio_triagem"):
				corpo.calcular_relatorio_triagem()
				
			if corpo.pesos_absolutos_materiais.has("Plastico"):
				soma_plastico += corpo.pesos_absolutos_materiais["Plastico"]
			if corpo.pesos_absolutos_materiais.has("Metal"):
				soma_metal += corpo.pesos_absolutos_materiais["Metal"]
			if corpo.pesos_absolutos_materiais.has("Papel"):
				soma_papel += corpo.pesos_absolutos_materiais["Papel"]
			if corpo.pesos_absolutos_materiais.has("Vidro"):
				soma_vidro += corpo.pesos_absolutos_materiais["Vidro"]
				
			# --- SOLUÇÃO DO CRASH ---
			# Cega o objeto para o RayCast antes de deletá-lo!
			corpo.collision_layer = 0
			corpo.collision_mask = 0
			corpo.visible = false
			corpo.queue_free()
			
	if not tem_lixo:
		print("Prensa vazia!")
		return
		
	# 3. CARREGA AS SUCATAS (Lembre de colocar seus caminhos certos aqui!)
	var cena_plastico = load("res://Itens/Sucatas/SucataPastico.tscn")
	var cena_metal = load("res://Itens/Sucatas/SucataMetal.tscn")
	var cena_papel = load("res://Itens/Sucatas/SucataPapel.tscn")
	var cena_vidro = load("res://Itens/Sucatas/SucataVidro.tscn")
	
	# 4. COSPE O RESULTADO (O uso do 'await' faz eles esperarem a vez deles)
	await _cuspir_sucatas(cena_plastico, soma_plastico)
	await _cuspir_sucatas(cena_metal, soma_metal)
	await _cuspir_sucatas(cena_papel, soma_papel)
	await _cuspir_sucatas(cena_vidro, soma_vidro)

func _cuspir_sucatas(cena_sucata: PackedScene, quantidade: int):
	if quantidade <= 0 or not cena_sucata:
		return
		
	for i in range(quantidade):
		var nova_sucata = cena_sucata.instantiate()
		get_tree().current_scene.add_child(nova_sucata)
		
		nova_sucata.global_position = ponto_de_saida.global_position
		
		if nova_sucata is RigidBody3D:
			var direcao_frente = ponto_de_saida.global_transform.basis.z 
			
			# --- AUMENTO DA FORÇA ---
			# Multipliquei a força do empurrão. Ajuste de 5.0 a 8.0 se quiser mais ou menos força
			var empurrao = (direcao_frente * randf_range(5.0, 8.0)) + Vector3(0, randf_range(2.0, 4.0), 0)
			empurrao += Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)) 
			
			nova_sucata.apply_impulse(empurrao)
			
		# --- O EFEITO DE FILA ---
		# O código pausa aqui por 0.2 segundos antes de cuspir a próxima sucata!
		await get_tree().create_timer(0.2).timeout
