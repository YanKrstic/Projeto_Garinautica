extends StaticBody3D
class_name ObjetoReparavel

@export_group("Configurações do Reparo")
@export var ferramenta_necessaria: String = "Casco" # Ex: "Casco", "Cano", "Fio"
@export var tempo_reparo: float = 2.5

@export_group("Visuais")
@export var modelo_normal: Node3D
@export var modelo_quebrado: Node3D

var esta_quebrado: bool = true
var progresso_atual: float = 0.0

func _ready():
	quebrar()

func quebrar():
	esta_quebrado = true
	progresso_atual = 0.0
	if modelo_normal: modelo_normal.visible = false
	if modelo_quebrado: modelo_quebrado.visible = true

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

func consertar(player):
	esta_quebrado = false
	if modelo_normal: modelo_normal.visible = true
	if modelo_quebrado: modelo_quebrado.visible = false
	
	var item = player.objeto_na_mao
	player.objeto_na_mao = null
	item.queue_free()
	
	cancelar_interacao(player)
	print("Reparo de " + ferramenta_necessaria + " concluído com sucesso!")
