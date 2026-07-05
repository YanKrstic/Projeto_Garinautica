extends Node3D

@onready var area_sensor = $Area3D 

func _ready():
	area_sensor.body_entered.connect(_on_body_entered)
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

func _on_body_exited(body):
	if "nome_do_material" in body:
		var tipo = body.nome_do_material
		
		if SistemaOxigenio:
			SistemaOxigenio.remover_item_da_cota(tipo)
			
		print("Caixa de Carga: ALERTA! Barra de ", tipo, " foi removida da caixa!")

# NOVO: A Alavanca de Ejeção deve chamar esta função!
func ejetar_carga():
	# Pergunta ao sistema global se temos os requisitos mínimos
	if SistemaOxigenio.verificar_pode_avancar():
		print("Caixa de Carga: Ejetando material para a superfície!")
		
		# Varrer tudo o que está dentro da área e destruir fisicamente as barras
		for body in area_sensor.get_overlapping_bodies():
			if "nome_do_material" in body:
				body.queue_free()
				
		# Avisa o cérebro do jogo que pode subir o nível de dificuldade!
		SistemaOxigenio.avancar_fase()
	else:
		print("Caixa de Carga: Cota incompleta! Faltam materiais.")
