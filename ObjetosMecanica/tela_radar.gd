extends Control

@onready var icone = $IconeSubmarino
# Certifique-se de que este nome bate exatamente com o nó do seu retângulo preto!
@onready var tela_morta = $TelaMorta 
@export var limite_esmagamento: float = 2.5 # Segundos esfregando na parede até morrer
var tempo_esmagado: float = 0.0

@export_group("Movimento e Controles")
@export var pixels_por_radiano: float = 30.0 

@export_group("Configurações da Esteira")
@export var velocidade_esteira: float = 120.0 
@export var tempo_spawn: float = 1.2 
@export var min_lixo_por_bloco: int = 3
@export var max_lixo_por_bloco: int = 6

var timer_atual: float = 0.0
var forca_corrente_atual: float = 0.0

# --- VARIÁVEIS DA NOVA MECÂNICA DE MAU CONTATO ---
var radar_quebrado: bool = false
var timer_piscar: float = 0.0

# --- VARIÁVEIS DA CRISE DE DIREÇÃO ---
var multiplicador_direcao: float = 1.0

func _ready():
	add_to_group("tela_radar")
	if tela_morta:
		tela_morta.hide()
		tela_morta.z_index = 100

func _process(delta):
	# 1. Geração de Lixo e Pedras
	timer_atual += delta
	if timer_atual >= tempo_spawn:
		timer_atual = 0.0
		
		# A MÁGICA DO RADAR:
		# Se estiver na Fase 3, tem 20% de chance de nascer um túnel em vez de lixo solto
		if SistemaOxigenio.fase_atual >= 3 and randf() < 0.2:
			_spawnar_tunel()
		else:
			_spawnar_objeto()
		
	# 2. Física e Colisões
	_mover_e_verificar_colisoes(delta)
	
	# 3. Correnteza
	if forca_corrente_atual != 0.0:
		icone.position.x += forca_corrente_atual * delta
		icone.position.x = clamp(icone.position.x, 0, size.x - icone.size.x)

	# 4. A MÁGICA DO PISCA-PISCA (Mau Contato)
	if radar_quebrado and tela_morta:
		timer_piscar -= delta
		if timer_piscar <= 0:
			if tela_morta.visible:
				# Se a tela estava PRETA, dá um vislumbre rápido do radar
				tela_morta.visible = false
				timer_piscar = randf_range(0.4, 1.2) # Fica visível entre 0.1s e 0.4s
			else:
				# Se a tela estava VISÍVEL, volta para o breu por mais tempo
				tela_morta.visible = true
				timer_piscar = randf_range(1, 4) # Fica apagada entre 0.5s e 2.0s

# --- COMANDOS DO RADAR ---

func aplicar_correnteza(forca: float):
	forca_corrente_atual = forca

func mover_submarino(giro_delta: float):
	icone.position.x += giro_delta * (pixels_por_radiano * multiplicador_direcao)
	icone.position.x = clamp(icone.position.x, 0, size.x - icone.size.x)

func _spawnar_objeto():
	var novo_obj = ColorRect.new()
	novo_obj.size = Vector2(25, 25) 
	
	var pos_x = randf_range(0, size.x - novo_obj.size.x)
	novo_obj.position = Vector2(pos_x, -30)
	
	if randf() < 0.3:
		novo_obj.color = Color.YELLOW
		novo_obj.add_to_group("lixos_radar")
	else:
		novo_obj.color = Color.RED
		novo_obj.add_to_group("pedras_radar")
		
	add_child(novo_obj)

func _mover_e_verificar_colisoes(delta):
	var meu_rect = icone.get_global_rect()
	
	for pedra in get_tree().get_nodes_in_group("pedras_radar"):
		pedra.position.y += velocidade_esteira * delta
		if pedra.position.y > size.y:
			pedra.queue_free()
			continue
			
		if meu_rect.intersects(pedra.get_global_rect()):
			print("BUM! Bateu na pedra!")
			var todos_os_cascos = get_tree().get_nodes_in_group("cascos")
			var cascos_inteiros = []
			for casco in todos_os_cascos:
				if not casco.esta_quebrado: cascos_inteiros.append(casco)
			
			if cascos_inteiros.size() > 0:
				var casco_sorteado = cascos_inteiros.pick_random()
				casco_sorteado.quebrar()
				print("Vazamento aberto!")
			else:
				print("BUM! Todos os buracos já estão abertos!")
			
			pedra.queue_free()
	var esta_batendo_no_tunel = false
	
	for parede in get_tree().get_nodes_in_group("tuneis_radar"):
		parede.position.y += velocidade_esteira * delta
		if parede.position.y > size.y:
			parede.queue_free()
			continue
			
		if meu_rect.intersects(parede.get_global_rect()):
			esta_batendo_no_tunel = true
			
	# Se estiver encostando na parede, a barra de esmagamento enche!
	if esta_batendo_no_tunel:
		tempo_esmagado += delta
		print("Dano crítico! Casco sob pressão extrema: ", tempo_esmagado)
		
		# Faz o ícone do submarino piscar vermelho para dar agonia!
		icone.modulate = Color.RED if randf() > 0.5 else Color.WHITE
		
		if tempo_esmagado >= limite_esmagamento:
			# CHAMA A TELA DE GAME OVER GLOBAL!
			if SistemaOxigenio:
				SistemaOxigenio.disparar_game_over("O casco foi esmagado pelas rochas do abismo.")
	else:
		# Se desgrudou da parede, o casco se recupera aos poucos
		icone.modulate = Color.WHITE
		tempo_esmagado -= delta
		if tempo_esmagado < 0: tempo_esmagado = 0
			
	for lixo in get_tree().get_nodes_in_group("lixos_radar"):
		lixo.position.y += velocidade_esteira * delta
		if lixo.position.y > size.y:
			lixo.queue_free()
			continue
			
		if meu_rect.intersects(lixo.get_global_rect()):
			var qtd = randi_range(min_lixo_por_bloco, max_lixo_por_bloco)
			print("Radar: Bloco Sugado! Gerando ", qtd, " lixos físicos...")
			get_tree().call_group("tubos_de_coleta", "receber_lixo", qtd)
			lixo.queue_free()

# --- COMANDOS DA CRISE DO RADAR ---

func avariar_tela():
	radar_quebrado = true
	if tela_morta: tela_morta.show() 
	print("Radar: Ecrã com mau contato! Navegação prejudicada!")

func reparar_tela():
	radar_quebrado = false
	if tela_morta: tela_morta.hide()
	print("Radar: Sinal restaurado e imagem limpa!")
	
# --- COMANDOS DA CRISE DE DIREÇÃO ---

func dificultar_direcao():
	# Reduz a eficiência do leme para 40% do normal
	multiplicador_direcao = 0.4 
	print("Radar: Direção pesada! O leme está com as engrenagens travadas!")

func normalizar_direcao():
	# Devolve a leveza original a 100%
	multiplicador_direcao = 1.0 
	print("Radar: Engrenagens lubrificadas. Direção normalizada!")
	
# --- MECÂNICA DE TÚNEIS (FASE 3) ---

func _spawnar_tunel():
	var tipo = randi() % 3
	var espaco_livre = 140.0 
	var meio = size.x / 2.0
	
	# ---> MÁGICA AQUI: Aumente este número para deixar o túnel mais longo! <---
	var comprimento_tunel = 400.0 
	
	print("Radar: A gerar túnel de rochas longo do tipo ", tipo)
	
	if tipo == 0: 
		_criar_bloco_parede(0, meio - (espaco_livre / 2.0), comprimento_tunel) 
		_criar_bloco_parede(meio + (espaco_livre / 2.0), size.x, comprimento_tunel)
		
	elif tipo == 1: 
		_criar_bloco_parede(0, size.x - espaco_livre, comprimento_tunel)
		
	elif tipo == 2: 
		_criar_bloco_parede(espaco_livre, size.x, comprimento_tunel)

# Atualizamos a função para receber o "comprimento"
func _criar_bloco_parede(pos_inicio_x: float, pos_fim_x: float, comprimento: float):
	var parede = ColorRect.new()
	
	# O eixo Y agora usa a nossa nova variável de comprimento
	parede.size = Vector2(pos_fim_x - pos_inicio_x, comprimento) 
	
	# Faz a parede nascer exatamente acima da tela (-comprimento) para descer suavemente
	parede.position = Vector2(pos_inicio_x, -comprimento - 10)
	
	parede.color = Color.RED
	parede.add_to_group("tuneis_radar")
	add_child(parede)
	
