extends Node3D

@onready var area_sensor = $Area3D 

func _ready():
	area_sensor.body_entered.connect(_on_body_entered)
	# NOVO: Conecta o sinal de saída!
	area_sensor.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if "nome_do_material" in body:
		var tipo = body.nome_do_material 
		var aceito = SistemaOxigenio.registrar_item_na_cota(tipo)
		
		if aceito:
			print("Caixa de Carga: Barra de ", tipo, " entrou na caixa!")
			
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player and player.objeto_na_mao == body:
				player.soltar_objeto(0.0)
				
			# O QUEUE_FREE FOI REMOVIDO DAQUI! A barra agora fica no mundo.

# NOVO: O que acontece se a barra for removida
func _on_body_exited(body):
	if "nome_do_material" in body:
		var tipo = body.nome_do_material
		
		# Tira o ponto do jogador no HUD!
		if SistemaOxigenio:
			SistemaOxigenio.remover_item_da_cota(tipo)
			
		print("Caixa de Carga: ALERTA! Barra de ", tipo, " foi removida da caixa!")
