extends StaticBody3D
class_name ObjetoReparavel

@export_group("Configurações do Reparo")
@export var ferramenta_necessaria: String = "Casco" 
@export var tempo_reparo: float = 2.5
# NOVO: O quanto de oxigénio este objeto rouba por segundo quando está quebrado!
@export var dano_oxigenio: float = 2.0 

@export_group("Visuais")
@export var modelo_normal: Node3D
@export var modelo_quebrado: Node3D

var esta_quebrado: bool = false # MUDANÇA: O submarino começa 100% consertado
var progresso_atual: float = 0.0

func _ready():
	_atualizar_visual()

func quebrar():
	if esta_quebrado: return # Se já está quebrado, não quebra de novo
	
	esta_quebrado = true
	progresso_atual = 0.0
	_atualizar_visual()
	
	# MÁGICA: Avisa o sistema global que começou um vazamento!
	if SistemaOxigenio:
		SistemaOxigenio.adicionar_vazamento(dano_oxigenio)

func consertar(player):
	esta_quebrado = false
	_atualizar_visual()
	
	var item = player.objeto_na_mao
	player.objeto_na_mao = null
	item.queue_free()
	
	cancelar_interacao(player)
	
	# MÁGICA: Avisa o sistema para parar o vazamento, o buraco foi tapado!
	if SistemaOxigenio:
		SistemaOxigenio.remover_vazamento(dano_oxigenio)
		
	print("Reparo de " + ferramenta_necessaria + " concluído!")

func _atualizar_visual():
	if modelo_normal: modelo_normal.visible = !esta_quebrado
	if modelo_quebrado: modelo_quebrado.visible = esta_quebrado

# ... [MANTENHA SUAS FUNÇÕES interagir_segurando e cancelar_interacao EXATAMENTE COMO ESTAVAM AQUI EMBAIXO] ...
func interagir_segurando(delta, player):
	if not esta_quebrado: return
	
	if player.objeto_na_mao != null:
		var item = player.objeto_na_mao
		
		# A MÁGICA AQUI: Ele verifica se a ferramenta na mão combina com a exigência deste objeto!
		if item is FerramentaReparo and item.tipo_reparo == ferramenta_necessaria:
			
			progresso_atual += delta
			
			var barra = player.get_node_or_null("CanvasLayer/ProgressBar")
			if barra:
				barra.visible = true
				barra.max_value = tempo_reparo
				barra.value = progresso_atual
			
			if progresso_atual >= tempo_reparo:
				consertar(player)

func cancelar_interacao(player):
	progresso_atual = 0.0
	var barra = player.get_node_or_null("CanvasLayer/ProgressBar")
	if barra:
		barra.visible = false
