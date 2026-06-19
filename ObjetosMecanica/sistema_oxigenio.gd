extends CanvasLayer

@onready var barra = $BarraOxigenio
@onready var texto_cota = $TextoCota # <-- NOVO

# --- CONFIGURAÇÕES DE VIDA ---
var oxigenio_maximo: float = 100.0
var oxigenio_atual: float = 100.0
var consumo_base: float = 0.05 
var vazamento_extra: float = 0.0 

# --- CONFIGURAÇÕES DA COTA DA FASE ---
var cota_metal_requerida: int = 3
var cota_plastico_requerida: int = 2

var metal_coletado: int = 0
var plastico_coletado: int = 0

func _ready():
	oxigenio_atual = oxigenio_maximo
	barra.max_value = oxigenio_maximo
	barra.value = oxigenio_atual
	atualizar_hud_cota()

func _process(delta):
	if get_tree().paused or oxigenio_atual <= 0: 
		return

	var perda_total = consumo_base + vazamento_extra
	oxigenio_atual -= perda_total * delta
	barra.value = oxigenio_atual
	
	if oxigenio_atual <= 0:
		oxigenio_atual = 0
		_game_over()

func _game_over():
	print("GAME OVER!")
	get_tree().reload_current_scene()

# --- ATUALIZAÇÃO DA INTERFACE DA COTA ---
func atualizar_hud_cota():
	if texto_cota:
		texto_cota.text = "REQUISITOS DA MISSÃO:\n"
		texto_cota.text += "Barras de Metal: " + str(metal_coletado) + " / " + str(cota_metal_requerida) + "\n"
		texto_cota.text += "Barras de Plástico: " + str(plastico_coletado) + " / " + str(cota_plastico_requerida)

# Chamado pela Caixa de Carga quando o jogador joga um item lá dentro
func registrar_item_na_cota(tipo_item: String) -> bool:
	if tipo_item == "metal" and metal_coletado < cota_metal_requerida:
		metal_coletado += 1
		atualizar_hud_cota()
		return true
	elif tipo_item == "plastico" and plastico_coletado < cota_plastico_requerida:
		plastico_coletado += 1
		atualizar_hud_cota()
		return true
	
	return false # Retorna falso se o item enviado foi lixo errado ou cota já cheia

# Chamado pelo Botão de Ejetar
func verificar_vitoria_fase():
	if metal_coletado >= cota_metal_requerida and plastico_coletado >= cota_plastico_requerida:
		print("VITÓRIA! Carga ejetada com sucesso para a superfície!")
		# Provisório: Reinicia o jogo/fase ao vencer. Futuramente carrega a Fase 2.
		get_tree().reload_current_scene()
	else:
		print("Caixa de Carga: Cota incompleta! Não é possível ejetar ainda.")
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
	
func remover_item_da_cota(tipo_item: String):
	if tipo_item == "metal" and metal_coletado > 0:
		metal_coletado -= 1
		atualizar_hud_cota()
	elif tipo_item == "plastico" and plastico_coletado > 0:
		plastico_coletado -= 1
		atualizar_hud_cota()
		
# --- MECÂNICAS DO FILTRO DE AR ---
func entupir_filtro():
	# O consumo base normal é 1.0. Dobramos (ou mais) para sufocar o jogador!
	consumo_base = 1.0
	print("ALERTA CRÍTICO: Filtro de ar entupido! Consumo de O2 subiu drasticamente!")

func limpar_filtro():
	# Volta ao consumo padrão de repouso
	consumo_base = 1.0 
	print("Filtro de ar limpo! Consumo estabilizado.")
