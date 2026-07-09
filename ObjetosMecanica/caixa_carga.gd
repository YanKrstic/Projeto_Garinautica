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
			# A MÁGICA AQUI: O código que arrancava o item da mão foi removido!
			# Agora você pode passar livremente por dentro da área segurando itens.

var ejetando_carga: bool = false # NOVO: Trava contra o motor de física

func _on_body_exited(body):
	# SEGURANÇA: Se a caixa estiver a destruir os itens para ejetar, ignora esta saída!
	if ejetando_carga:
		return
		
	if "nome_do_material" in body:
		var tipo = body.nome_do_material
		
		if SistemaOxigenio:
			SistemaOxigenio.remover_item_da_cota(tipo)
			
		print("Caixa de Carga: ALERTA! Barra de ", tipo, " foi removida da caixa!")

# NOVA FUNÇÃO CIRÚRGICA DE EJEÇÃO
func ejetar_carga():
	if SistemaOxigenio.verificar_pode_avancar():
		print("Caixa de Carga: Ejetando material exigido para a superfície!")
		ejetando_carga = true 

		var player = get_tree().current_scene.find_child("Player", true, false)
		var metais_para_ejetar = SistemaOxigenio.cota_metal_requerida
		var plasticos_para_ejetar = SistemaOxigenio.cota_plastico_requerida

		for body in area_sensor.get_overlapping_bodies():
			if "nome_do_material" in body:
				var material = body.nome_do_material.to_lower() # Proteção aqui também!
				var foi_ejetado = false
				
				# Se for metal e ainda precisarmos ejetar, ele some
				if (material == "metal" or material == "barra_metal") and metais_para_ejetar > 0:
					metais_para_ejetar -= 1
					foi_ejetado = true
				# Se for plástico e ainda precisarmos ejetar, ele some
				elif (material == "plastico" or material == "barra_plastico") and plasticos_para_ejetar > 0:
					plasticos_para_ejetar -= 1
					foi_ejetado = true
					
				if foi_ejetado:
					if player and player.objeto_na_mao == body:
						player.soltar_objeto(0.0)
					body.queue_free()

		SistemaOxigenio.avancar_fase()
		await get_tree().process_frame
		ejetando_carga = false
		
	else:
		print("Caixa de Carga: Cota incompleta! Faltam materiais.")
