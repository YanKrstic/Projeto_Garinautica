extends Control

@onready var icone = $IconeSubmarino
@onready var tela_morta = $TelaMorta

@export_group("Movimento e Controles")
# Quanto maior esse número, mais o submarino anda pros lados a cada volta do mouse
@export var pixels_por_radiano: float = 30.0 

@export_group("Configurações da Esteira")
@export var velocidade_esteira: float = 120.0 
@export var tempo_spawn: float = 1.2 
@export var min_lixo_por_bloco: int = 3
@export var max_lixo_por_bloco: int = 6

var timer_atual: float = 0.0

# ---> 1. NOVA VARIÁVEL DA CORRENTEZA <---
var forca_corrente_atual: float = 0.0

func _ready():
	# Entra no grupo para que o Módulo Físico o consiga encontrar de qualquer lado
	add_to_group("tela_radar")
	if tela_morta:
		tela_morta.hide()

# --- MECÂNICAS DA CRISE DO RADAR ---

func avariar_tela():
	if tela_morta: 
		tela_morta.show()
	print("Radar: Ecrã sem sinal! Navegação às cegas!")

func reparar_tela():
	if tela_morta: 
		tela_morta.hide()
	print("Radar: Sinal restaurado e imagem limpa!")

func _process(delta):
	timer_atual += delta
	if timer_atual >= tempo_spawn:
		_spawnar_objeto()
		timer_atual = 0.0
		
	_mover_e_verificar_colisoes(delta)
	
	# ---> 2. O EMPURRÃO CONTÍNUO DA CORRENTEZA <---
	if forca_corrente_atual != 0.0:
		icone.position.x += forca_corrente_atual * delta
		icone.position.x = clamp(icone.position.x, 0, size.x - icone.size.x)

# ---> 3. A FUNÇÃO QUE O PAINEL 3D CHAMA <---
func aplicar_correnteza(forca: float):
	forca_corrente_atual = forca

# O Leme agora chama esta função para somar a posição atual do mouse
func mover_submarino(giro_delta: float):
	icone.position.x += giro_delta * pixels_por_radiano
	
	# O Clamp prende o ícone dentro da tela.
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
			print("BUM! Bateu na pedra! Procurando um casco para quebrar...")
			
			var todos_os_cascos = get_tree().get_nodes_in_group("cascos")
			var cascos_inteiros = []
			
			for casco in todos_os_cascos:
				if not casco.esta_quebrado:
					cascos_inteiros.append(casco)
			
			if cascos_inteiros.size() > 0:
				var casco_sorteado = cascos_inteiros.pick_random()
				casco_sorteado.quebrar()
				print("Vazamento aberto!")
			else:
				print("BUM! Todos os buracos já estão abertos! Estamos a afundar!")
			
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
