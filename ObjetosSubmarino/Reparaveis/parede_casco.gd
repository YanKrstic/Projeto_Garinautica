extends StaticBody3D

@export_group("Modelos da Parede")
@export var modelo_normal: Node3D
@export var modelo_quebrado: Node3D

var esta_quebrada: bool = true
var tempo_reparo: float = 2.0 # Segundos necessários para consertar
var progresso_atual: float = 0.0

func _ready():
	quebrar_parede()

func quebrar_parede():
	esta_quebrada = true
	progresso_atual = 0.0
	if modelo_normal: modelo_normal.visible = false
	if modelo_quebrado: modelo_quebrado.visible = true

# Esta função roda 60 vezes por segundo enquanto o Player segura o "E"
func interagir_segurando(delta, player):
	if not esta_quebrada: return
	
	# 1. Verifica se tem o item na mão
	if player.objeto_na_mao != null:
		var item = player.objeto_na_mao
		
		# 2. Verifica se é a Placa de Metal
		if item is FerramentaReparo and item.tipo_reparo == "Casco":
			
			# Enche a barra!
			progresso_atual += delta
			
			# Mostra e atualiza a Barrinha de Progresso na tela do Player
			var barra = player.get_node_or_null("CanvasLayer/ProgressBar")
			if barra:
				barra.visible = true
				barra.max_value = tempo_reparo
				barra.value = progresso_atual
			
			# Se a barra encheu 100%, conserta!
			if progresso_atual >= tempo_reparo:
				consertar_parede(player)

func cancelar_interacao(player):
	# Se soltar o botão antes de terminar, a barra zera e some!
	progresso_atual = 0.0
	var barra = player.get_node_or_null("CanvasLayer/ProgressBar")
	if barra:
		barra.visible = false

func consertar_parede(player):
	esta_quebrada = false
	if modelo_normal: modelo_normal.visible = true
	if modelo_quebrado: modelo_quebrado.visible = false
	
	# Pega a placa da mão do Player e deleta direto
	var item = player.objeto_na_mao
	player.objeto_na_mao = null
	item.queue_free()
	
	cancelar_interacao(player)
	print("Parede consertada com sucesso!")
