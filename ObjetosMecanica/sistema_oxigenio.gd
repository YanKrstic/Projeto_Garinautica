extends CanvasLayer

@onready var barra = $BarraOxigenio

# --- CONFIGURAÇÕES DE VIDA ---
var oxigenio_maximo: float = 100.0
var oxigenio_atual: float = 100.0

# O consumo base é o jogador respirando (ex: perde 1 ponto por segundo)
var consumo_base: float = 1.0 
# O vazamento extra será controlado pelas crises e buracos no casco
var vazamento_extra: float = 0.0 

func _ready():
	oxigenio_atual = oxigenio_maximo
	barra.max_value = oxigenio_maximo
	barra.value = oxigenio_atual

func _process(delta):
	# Se o jogo estiver pausado (no menu ESC) ou o jogador já morreu, o ar para de descer
	if get_tree().paused or oxigenio_atual <= 0: 
		return

	# Calcula quanto ar está sendo perdido neste exato momento
	var perda_total = consumo_base + vazamento_extra
	oxigenio_atual -= perda_total * delta
	
	# Atualiza a interface
	barra.value = oxigenio_atual
	
	# Checa a Condição de Derrota
	if oxigenio_atual <= 0:
		oxigenio_atual = 0
		_game_over()

func _game_over():
	print("GAME OVER! Ficaste sem oxigênio!")
	# Para testes rápidos, vamos apenas reiniciar a cena atual quando morrer:
	get_tree().reload_current_scene()

# ==========================================
# FUNÇÕES GLOBAIS PARA AS CRISES USAREM
# ==========================================

func adicionar_vazamento(valor: float):
	vazamento_extra += valor
	print("ALERTA CRÍTICO: Vazamento no casco! Perda extra: ", valor)

func remover_vazamento(valor: float):
	vazamento_extra -= valor
	if vazamento_extra < 0: vazamento_extra = 0
	print("Reparo concluído! Ar estabilizando...")

func recuperar_oxigenio(quantidade: float):
	oxigenio_atual += quantidade
	if oxigenio_atual > oxigenio_maximo: 
		oxigenio_atual = oxigenio_maximo
	print("Oxigênio restaurado em: ", quantidade)
