extends Control

@onready var icone = $IconeSubmarino
var posicao_inicial_x: float

# --- CONFIGURAÇÕES DA ESTEIRA ---
var velocidade_esteira: float = 40.0 # Quão rápido as coisas descem (pixels por segundo)
var tempo_spawn: float = 6 # Segundos entre cada novo objeto
var timer_atual: float = 0.0

func _ready():
	posicao_inicial_x = icone.position.x

func _process(delta):
	# 1. O Relógio do Spawner (Cria novos itens com o passar do tempo)
	timer_atual += delta
	if timer_atual >= tempo_spawn:
		_spawnar_objeto()
		timer_atual = 0.0
		
	# 2. O Motor da Esteira (Move tudo para baixo e verifica batidas)
	_mover_e_verificar_colisoes(delta)

# Função que o seu Leme3D já está chamando!
func atualizar_posicao_submarino(giro_acumulado: float):
	# Ajuste o multiplicador final aqui se achar que ficou muito rápido ou devagar
	icone.position.x = posicao_inicial_x + (giro_acumulado * 20.0)
	
	# Trava de segurança para o submarino não sair da tela
	icone.position.x = clamp(icone.position.x, 0, size.x - icone.size.x)

# --- A MÁQUINA DE CRIAÇÃO ---
func _spawnar_objeto():
	var novo_obj = ColorRect.new()
	novo_obj.size = Vector2(25, 25) # Tamanho do obstáculo
	
	# Sorteia uma posição X aleatória lá no topo da tela (escondido acima da borda)
	var pos_x = randf_range(0, size.x - novo_obj.size.x)
	novo_obj.position = Vector2(pos_x, -30)
	
	# Sorteio: 30% de chance de ser Lixo, 70% de chance de ser Pedra
	if randf() < 0.3:
		novo_obj.color = Color.YELLOW
		novo_obj.add_to_group("lixos_radar")
	else:
		novo_obj.color = Color.RED
		novo_obj.add_to_group("pedras_radar")
		
	add_child(novo_obj)

# --- A FÍSICA DO RADAR ---
func _mover_e_verificar_colisoes(delta):
	# Pega a "caixa de colisão" do nosso submarino
	var meu_rect = icone.get_global_rect()
	
	# 1. Processa todas as PEDRAS
	for pedra in get_tree().get_nodes_in_group("pedras_radar"):
		pedra.position.y += velocidade_esteira * delta
		
		# Se a pedra saiu pelo fundo da tela, nós a deletamos para não pesar o jogo
		if pedra.position.y > size.y:
			pedra.queue_free()
			continue
			
		# BATIDA! Verifica se as caixas se cruzaram
		if meu_rect.intersects(pedra.get_global_rect()):
			print("BUM! Bateu na pedra! Vazamento no casco!")
			# TODO no futuro: Avisar o submarino para perder oxigênio e abrir um buraco
			pedra.queue_free()
			
	# 2. Processa todos os LIXOS
	for lixo in get_tree().get_nodes_in_group("lixos_radar"):
		lixo.position.y += velocidade_esteira * delta
		
		if lixo.position.y > size.y:
			lixo.queue_free()
			continue
			
		# COLETA!
		if meu_rect.intersects(lixo.get_global_rect()):
			print("Radar: LIXO SUGADO! Avisando o tubo...")
			
			# MÁGICA: Grita para qualquer objeto no mundo que esteja no grupo "tubos_de_coleta"
			get_tree().call_group("tubos_de_coleta", "receber_lixo")
			
			lixo.queue_free()
