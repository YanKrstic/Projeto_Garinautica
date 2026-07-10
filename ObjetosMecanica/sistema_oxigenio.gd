extends CanvasLayer

var bloqueia_pausa: bool = false
var camada_ui: CanvasLayer = null

var cena_vitoria = preload("res://ObjetosMecanica/tela_vitoria.tscn")
var tela_vitoria_instanciada = null

var cena_game_over = preload("res://ObjetosMecanica/tela_game_over.tscn")
var tela_instanciada = null

var cena_transicao = preload("res://ObjetosMecanica/tela_transicao.tscn")
var tela_transicao_instanciada = null

@onready var barra = $BarraOxigenio
@onready var texto_cota = $TextoCota # <-- NOVO

# Variáveis de Ranking
var tempo_total_jogado: float = 0.0
var total_lixo_reciclado: int = 0


# --- CONFIGURAÇÕES DE VIDA ---
var oxigenio_maximo: float = 100.0
var oxigenio_atual: float = 100.0
var consumo_base: float = 0.01
var vazamento_extra: float = 0.0 
var multiplicador_filtro: float = 1.0 # 1 -> total normal

# --- CONFIGURAÇÕES DA COTA DA FASE ---
var cota_metal_requerida: int = 1
var cota_plastico_requerida: int = 1

var metal_coletado: int = 0
var plastico_coletado: int = 0

# --- GERENCIADOR DE FASES ---
var fase_atual: int = 1

# Esta função será chamada pela Tela de Transição sempre que o jogador passar de fase
func iniciar_fase(numero_fase: int):
	fase_atual = numero_fase
	print("SISTEMA GLOBAL: Iniciando Fase ", fase_atual)
	
	# Aqui no futuro vamos mandar o Rádio tocar o áudio correspondente!
	# if fase_atual == 2: radio.play(audio_fase2)

func _ready():
	camada_ui = CanvasLayer.new()
	camada_ui.layer = 100 
	add_child(camada_ui)
	
	oxigenio_atual = oxigenio_maximo
	barra.max_value = oxigenio_maximo
	barra.value = oxigenio_atual
	atualizar_hud_cota()

func _process(delta):
	if get_tree().paused or oxigenio_atual <= 0: 
		return

	tempo_total_jogado += delta
	
	var perda_total = (consumo_base * multiplicador_filtro) + vazamento_extra
	oxigenio_atual -= perda_total * delta
	barra.value = oxigenio_atual
	
	if oxigenio_atual <= 0:
		oxigenio_atual = 0
		disparar_game_over("Ficou sem oxigênio. Asfixia letal.")

func disparar_game_over(motivo: String):
	bloqueia_pausa = true # Ativa o bloqueio do Esc
	if tela_instanciada == null:
		tela_instanciada = cena_game_over.instantiate()
		camada_ui.add_child(tela_instanciada) # <-- Adiciona na super camada!
	tela_instanciada.exibir(motivo)
	
# --- ATUALIZAÇÃO DA INTERFACE DA COTA ---
func atualizar_hud_cota():
	if texto_cota:
		texto_cota.text = "REQUISITOS DA MISSÃO:\n"
		texto_cota.text += "Barras de Metal: " + str(metal_coletado) + " / " + str(cota_metal_requerida) + "\n"
		texto_cota.text += "Barras de Plástico: " + str(plastico_coletado) + " / " + str(cota_plastico_requerida)

# Chamado pela Caixa de Carga quando o jogador joga um item lá dentro
func registrar_item_na_cota(tipo: String) -> bool:
	var material = tipo.to_lower() # Força a leitura em minúsculas
	
	if material == "metal" or material == "barra_metal":
		metal_coletado += 1
	elif material == "plastico" or material == "barra_plastico":
		plastico_coletado += 1

	atualizar_hud_cota()
	return true
	
func verificar_pode_avancar() -> bool:
	if metal_coletado >= cota_metal_requerida and plastico_coletado >= cota_plastico_requerida:
		return true
	return false

# A caixa de carga chama esta função quando ejeta os itens com sucesso!
func avancar_fase():
	# A MÁGICA: EM VEZ DE ZERAR TUDO, nós SUBTRAÍMOS o que foi ejetado!
	# Ex: Tinha 3, a cota era 2. Sobra 1 barra garantida para a próxima fase!
	metal_coletado -= cota_metal_requerida
	plastico_coletado -= cota_plastico_requerida

	if metal_coletado < 0: metal_coletado = 0
	if plastico_coletado < 0: plastico_coletado = 0

	if fase_atual == 1:
		fase_atual = 2
		# Novas exigências da Fase 2
		cota_metal_requerida = 1
		cota_plastico_requerida = 1
		atualizar_hud_cota()
		
		# ---> É AQUI QUE VOCÊ CHAMA A FUNÇÃO DA TELA! <---
		_tocar_mensagem_radio("Você passou da fase 1! Está pronto para descer mas fundo?")
		
	elif fase_atual == 2:
		fase_atual = 3
		# Novas exigências da Fase 3
		cota_metal_requerida = 1
		cota_plastico_requerida = 1
		atualizar_hud_cota()
		
		# ---> E AQUI PARA A FASE 3! <---
		_tocar_mensagem_radio("Você passou da fase 2! Está pronto para a ultima fase?")
		
	elif fase_atual == 3:
			print("VITÓRIA FINAL! Carga máxima atingida.")
			bloqueia_pausa = true
			# Pausa o jogo e chama a glória!
			if tela_vitoria_instanciada == null:
				tela_vitoria_instanciada = cena_vitoria.instantiate()
				camada_ui.add_child(tela_vitoria_instanciada)
			
			tela_vitoria_instanciada.exibir()
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
	
func remover_item_da_cota(tipo: String):
	var material = tipo.to_lower()
	
	if material == "metal" or material == "barra_metal":
		metal_coletado -= 1
	elif material == "plastico" or material == "barra_plastico":
		plastico_coletado -= 1

	if metal_coletado < 0: metal_coletado = 0
	if plastico_coletado < 0: plastico_coletado = 0

	atualizar_hud_cota()
# --- MECÂNICAS DO FILTRO DE AR ---
func entupir_filtro(percentagem_aumento: float):
	multiplicador_filtro += (percentagem_aumento / 100.0)
	print("Filtro entupido! Multiplicador de consumo subiu para: ", multiplicador_filtro, "x")

func limpar_filtro(percentagem_reducao: float):
	multiplicador_filtro -= (percentagem_reducao / 100.0)
	
	# Trava de segurança para não bugar a matemática
	if multiplicador_filtro < 1.0: 
		multiplicador_filtro = 1.0
		
	print("Filtro limpo! Multiplicador de consumo desceu para: ", multiplicador_filtro, "x")
	
	
func _tocar_mensagem_radio(texto_legenda: String):
	bloqueia_pausa = true # Ativa o bloqueio do Esc
	if tela_transicao_instanciada == null:
		tela_transicao_instanciada = cena_transicao.instantiate()
		camada_ui.add_child(tela_transicao_instanciada) # <-- Adiciona na super camada!
	tela_transicao_instanciada.exibir(texto_legenda)
	
func reiniciar_partida_completa():
	bloqueia_pausa = false
	
	# Esconde as telas se elas existirem
	if tela_instanciada: tela_instanciada.hide()
	if tela_transicao_instanciada: tela_transicao_instanciada.hide()
	if tela_vitoria_instanciada: tela_vitoria_instanciada.hide()

	# Zera TODA a sua progressão de volta para a Fase 1!
	fase_atual = 1
	metal_coletado = 0
	plastico_coletado = 0
	cota_metal_requerida = 1 # (coloque a sua cota inicial aqui)
	cota_plastico_requerida = 1 
	oxigenio_atual = 100.0
	consumo_base = 0.05
	multiplicador_filtro = 1.0
	vazamento_extra = 0.0
	
	tempo_total_jogado = 0.0
	total_lixo_reciclado = 0
	atualizar_hud_cota()

	# Despausa e recarrega o mapa do zero!
	get_tree().paused = false
	
	
