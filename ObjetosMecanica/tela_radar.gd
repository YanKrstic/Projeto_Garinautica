extends Control

@onready var icone = $IconeSubmarino
# Certifique-se de que este nome bate exatamente com o nó do seu retângulo preto!
@onready var tela_morta = $TelaMorta 

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
		# FIX DO BUG: Força a lona preta a desenhar por cima das pedras e lixos!
		tela_morta.z_index = 100

func _process(delta):
	# 1. Geração de Lixo e Pedras
	timer_atual += delta
	if timer_atual >= tempo_spawn:
		_spawnar_objeto()
		timer_atual = 0.0
		
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
