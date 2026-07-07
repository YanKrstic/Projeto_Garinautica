extends StaticBody3D

@export var area_esmagamento: Area3D
@export var ponto_de_saida: Marker3D
@onready var prensa: MeshInstance3D = $PRENSAcaixa/Prensa

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
	
	# 1. VARRE A ÁREA DE ESMAGAMENTO E SOMA OS PESOS (Sem apagar ainda)
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
				
	if not tem_lixo:
		print("Prensa vazia!")
		return
		
	# 2. ANIMAÇÃO DE DESCIDA DA PRENSA
	var tween_descida = create_tween()
	# Faz a prensa descer até Y = 1.836 rapidamente (0.2s) com impacto
	tween_descida.tween_property(prensa, "position:y", 1.836, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# O código congela aqui e espera a prensa bater no fundo
	await tween_descida.finished
	
	# 3. APAGA OS ITENS ESMAGADOS
	# Como a prensa já bateu no fundo, fazemos os itens desaparecerem
	for corpo in corpos:
		if "peso_total" in corpo:
			corpo.collision_layer = 0
			corpo.collision_mask = 0
			corpo.visible = false
			corpo.queue_free()
			
	# 4. ANIMAÇÃO DE SUBIDA DA PRENSA
	var tween_subida = create_tween()
	# Faz a prensa subir de volta para Y = 3.732 de forma mecânica e mais lenta (0.6s)
	tween_subida.tween_property(prensa, "position:y", 3.732, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 5. CARREGA AS SUCATAS
	var cena_plastico = load("res://Itens/Sucatas/SucataPastico.tscn")
	var cena_metal = load("res://Itens/Sucatas/SucataMetal.tscn")
	var cena_papel = load("res://Itens/Sucatas/SucataPapel.tscn")
	var cena_vidro = load("res://Itens/Sucatas/SucataVidro.tscn")
	
	# 6. COSPE O RESULTADO
	# As sucatas vão começar a sair enquanto a prensa ainda está subindo, o que dá um visual muito legal!
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
			
			var empurrao = (direcao_frente * randf_range(5.0, 8.0)) + Vector3(0, randf_range(2.0, 4.0), 0)
			empurrao += Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)) 
			
			nova_sucata.apply_impulse(empurrao)
			
		await get_tree().create_timer(0.2).timeout
