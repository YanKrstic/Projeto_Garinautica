extends Area3D

func _on_body_entered(body):
	# Verifica se o objeto tem a propriedade que identifica os itens do jogo
	# (Assim garantimos que a lixeira não tenta "engolir" o próprio Player ou as paredes)
	if "nome_do_material" in body:
		
		# 1. Encontra o jogador na cena
		var player = get_tree().current_scene.find_child("Player", true, false)
		
		# 2. Segurança: Se o item estiver colado na mão do jogador, obriga-o a soltar
		if player and player.objeto_na_mao == body:
			player.soltar_objeto(0.0) # Solta sem força para cair suavemente
			
		# 3. Registo opcional no Output para depuração
		print("Lixeira: O item '", body.nome_do_material, "' foi desintegrado!")
		
		# 4. A incineração final!
		body.queue_free()
