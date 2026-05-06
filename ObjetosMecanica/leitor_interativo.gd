extends StaticBody3D

@onready var mesa = get_parent()

func interagir_abrir():
	# Pegamos a referência do Player diretamente da árvore
	var player = get_tree().current_scene.find_child("Player", true, false)
	if not player: return

	# Caso o leitor esteja vazio e você tenha algo na mão
	if mesa.disquete_atual == null and player.objeto_na_mao != null:
		var item = player.objeto_na_mao
		
		# Verifica se o item na mão é da classe Disquete
		if item is Disquete:
			# 1. Tira da mão do player
			player.objeto_na_mao = null
			item.ao_ser_solto() # Devolve a física temporariamente
			
			player.remove_collision_exception_with(item) # Desbuga a física
			player.raycast.remove_exception(item)
			# 2. Conecta à mesa
			mesa.disquete_atual = item
			
			# 3. Gruda o disquete no slot
			item.reparent(mesa.slot_disquete) 
			item.global_transform = mesa.slot_disquete.global_transform
			item.freeze = true 
			item.set_collision_layer_value(3, false) # Desliga silhueta enquanto encaixado
			
			print("Disquete inserido com sucesso!")

	# Caso já tenha um disquete, a interação ejeta ele
	elif mesa.disquete_atual != null:
		ejetar_disquete()

func ejetar_disquete():
	var disquete = mesa.disquete_atual
	mesa.disquete_atual = null
	
	# Devolve para o mundo
	disquete.reparent(get_tree().current_scene)
	disquete.freeze = false
	disquete.set_collision_layer_value(3, true)
	
	# Dá um empurrãozinho para fora
	var direcao = global_transform.basis.z + Vector3(0, 0.5, 0)
	disquete.apply_central_impulse(direcao * 2.0)
