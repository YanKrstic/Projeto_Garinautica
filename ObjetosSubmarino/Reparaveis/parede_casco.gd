extends StaticBody3D

@export_group("Modelos da Parede")
@export var modelo_normal: Node3D
@export var modelo_quebrado: Node3D

var esta_quebrada: bool = true

func _ready():
	# Força a parede a começar o jogo quebrada para podermos testar!
	quebrar_parede()

func quebrar_parede():
	esta_quebrada = true
	if modelo_normal: modelo_normal.visible = false
	if modelo_quebrado: modelo_quebrado.visible = true

func consertar_parede():
	esta_quebrada = false
	if modelo_normal: modelo_normal.visible = true
	if modelo_quebrado: modelo_quebrado.visible = false
	print("Parede consertada com sucesso!")

func interagir_abrir():
	if not esta_quebrada:
		print("A parede já está intacta.")
		return
		
	var player = get_tree().current_scene.find_child("Player", true, false)
	if not player: return

	# 1. Verifica se o player está segurando algo
	if player.objeto_na_mao != null:
		var item = player.objeto_na_mao
		
		# 2. Verifica se o que ele segura é uma Ferramenta e se é do tipo certo!
		if item is FerramentaReparo and item.tipo_reparo == "Casco":
			
			# Tira a placa da mão do player e limpa as exceções do RayCast
			player.objeto_na_mao = null
			player.remove_collision_exception_with(item)
			player.raycast.remove_exception(item)
			
			# Deleta a placa do mundo (ela foi "gasta" no conserto)
			item.queue_free()
			
			# Roda a função que troca os modelos visuais
			consertar_parede()
		else:
			print("Você precisa de uma Placa de Metal para consertar o casco!")
	else:
		print("Você está de mãos vazias!")
